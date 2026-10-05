import 'package:GizmoHub/core/configs/theme/app_colors.dart';
import 'package:GizmoHub/core/database/gizmo_db.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

String naira(num n) =>
    '₦${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';

void toast(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

DocumentReference<Map<String, dynamic>>? userRef() {
  final u = FirebaseAuth.instance.currentUser;
  return u == null ? null : gizmoDb.collection('users').doc(u.uid);
}

// ───────────────────────────── Models ─────────────────────────────

class CartLine {
  final String key, productId;
  final String? size;
  final int qty;
  final Map<String, dynamic> data; // live product document

  const CartLine({
    required this.key,
    required this.productId,
    required this.size,
    required this.qty,
    required this.data,
  });

  String get name => (data['name'] ?? '').toString();
  String get imageUrl => (data['imageUrl'] ?? '').toString();
  num get price => (data['price'] ?? 0) as num;
  num get oldPrice => (data['oldPrice'] ?? 0) as num;
  num get rating => (data['rating'] ?? 0) as num;
  String get discount => (data['discount'] ?? '').toString();
  num get total => price * qty;
}

class Coupon {
  final String code;
  final num percent, amount;
  const Coupon({required this.code, this.percent = 0, this.amount = 0});

  num discountFor(num subtotal) {
    final d = percent > 0 ? subtotal * percent / 100 : amount;
    return d > subtotal ? subtotal : d;
  }
}

class OrderDraft {
  final List<CartLine> lines;
  final Coupon? coupon;
  final num deliveryFee;
  final Map<String, dynamic> address;

  const OrderDraft({
    required this.lines,
    required this.coupon,
    required this.deliveryFee,
    required this.address,
  });

  num get subtotal => lines.fold<num>(0, (s, l) => s + l.total);
  num get discount => coupon?.discountFor(subtotal) ?? 0;
  num get total => subtotal - discount + deliveryFee;
}

// ───────────────────────────── Cart operations ─────────────────────────────

String cartKey(String productId, String? size) =>
    '${productId}__${(size ?? 'none').replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_')}';

/// Adds the product once. If it's already in the cart, nothing changes
/// (the customer adjusts quantity inside the cart).
Future<void> addToCart(String productId, {String? size}) async {
  final ref = userRef();
  if (ref == null) return;
  final key = cartKey(productId, size);
  final snap = await ref.get();
  final cart = snap.data()?['cart'];
  if (cart is Map && cart.containsKey(key)) return;
  await ref.set({
    'cart': {
      key: {'productId': productId, 'size': size, 'qty': 1}
    }
  }, SetOptions(merge: true));
}

Future<void> setQty(String key, int qty) async {
  if (qty < 1) return;
  await userRef()?.update({FieldPath(['cart', key, 'qty']): qty});
}

Future<void> removeLine(String key) async {
  await userRef()?.update({FieldPath(['cart', key]): FieldValue.delete()});
}

Future<void> clearCart() async {
  await userRef()?.update({'cart': FieldValue.delete()});
}

// ───────────────────────────── Coupons / settings ─────────────────────────────

/// coupons/{CODE}: { isActive: true, percent: 10 }  or  { isActive: true, amount: 500 }
Future<Coupon?> fetchCoupon(String raw) async {
  final code = raw.trim().toUpperCase();
  if (code.isEmpty) return null;
  final s = await gizmoDb.collection('coupons').doc(code).get();
  final d = s.data();
  if (d == null || d['isActive'] == false) return null;
  return Coupon(
    code: code,
    percent: (d['percent'] ?? 0) as num,
    amount: (d['amount'] ?? 0) as num,
  );
}

/// settings/payment: { bankName, accountName, accountNumber, deliveryFee }
Future<Map<String, dynamic>> loadPaymentSettings() async {
  final s = await gizmoDb.collection('settings').doc('payment').get();
  return s.data() ?? {};
}

// ───────────────────────────── Place order ─────────────────────────────

Future<String> placeOrder(OrderDraft d) async {
  final u = FirebaseAuth.instance.currentUser!;
  final ref = gizmoDb.collection('orders').doc();
  await ref.set({
    'userId': u.uid,
    'userEmail': u.email,
    'items': d.lines
        .map((l) => {
      'productId': l.productId,
      'name': l.name,
      'imageUrl': l.imageUrl,
      'price': l.price,
      'qty': l.qty,
      'size': l.size,
    })
        .toList(),
    'subtotal': d.subtotal,
    'discount': d.discount,
    'couponCode': d.coupon?.code,
    'deliveryFee': d.deliveryFee,
    'total': d.total,
    'address': d.address['address'],
    'phone': d.address['phone'],
    'paymentMethod': 'bank_transfer',
    'paymentStatus': 'awaiting_confirmation', // admin sets to 'confirmed'
    'deliveryStatus': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
  });
  await clearCart();
  return ref.id;
}

// ───────────────────────────── Live cart builder ─────────────────────────────

/// Joins the customer's cart with live active products.
class CartBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, List<CartLine> lines, int unavailable) builder;
  const CartBuilder({super.key, required this.builder});

  @override
  State<CartBuilder> createState() => _CartBuilderState();
}

class _CartBuilderState extends State<CartBuilder> {
  late final Stream<DocumentSnapshot<Map<String, dynamic>>>? _user = userRef()?.snapshots();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _products = gizmoDb
      .collection('product')
      .where('isActive', isEqualTo: true)
      .snapshots();

  Widget get _loader =>
      const Center(child: CircularProgressIndicator(color: AppColors.primary));

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const Center(child: Text('Log in to view your cart'));
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _user,
      builder: (context, u) {
        if (u.hasError) return Center(child: Text('${u.error}'));
        if (!u.hasData) return _loader;
        final cart = (u.data!.data()?['cart'] as Map?) ?? const {};
        if (cart.isEmpty) return widget.builder(context, const [], 0);

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _products,
          builder: (context, p) {
            if (p.hasError) return Center(child: Text('${p.error}'));
            if (!p.hasData) return _loader;
            final byId = {for (final d in p.data!.docs) d.id: d.data()};
            final lines = <CartLine>[];
            var unavailable = 0;
            cart.forEach((k, v) {
              final m = Map<String, dynamic>.from(v as Map);
              final id = m['productId'].toString();
              final data = byId[id];
              if (data == null) {
                unavailable++;
                return;
              }
              lines.add(CartLine(
                key: k.toString(),
                productId: id,
                size: m['size']?.toString(),
                qty: (m['qty'] as num?)?.toInt() ?? 1,
                data: data,
              ));
            });
            lines.sort((a, b) => a.key.compareTo(b.key));
            return widget.builder(context, lines, unavailable);
          },
        );
      },
    );
  }
}

// ───────────────────────────── Shared widgets ─────────────────────────────

class CartBottomBar extends StatelessWidget {
  final num total;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final VoidCallback? onDetails;
  const CartBottomBar({
    super.key,
    required this.total,
    required this.buttonLabel,
    required this.onPressed,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 10, offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(naira(total),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              if (onDetails != null)
                GestureDetector(
                  onTap: onDetails,
                  child: const Text('View Details',
                      style: TextStyle(color: AppColors.primary, fontSize: 12)),
                ),
            ],
          ),
          const Spacer(),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            onPressed: onPressed,
            child: Text(buttonLabel),
          ),
        ]),
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  const SummaryRow(this.label, this.value, {super.key, this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
        fontSize: bold ? 16 : 14, fontWeight: bold ? FontWeight.w800 : FontWeight.w500);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Text(label, style: style),
        const Spacer(),
        Text(value, style: style.copyWith(color: valueColor)),
      ]),
    );
  }
}