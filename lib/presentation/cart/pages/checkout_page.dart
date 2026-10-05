import 'dart:async';
import 'package:GizmoHub/core/configs/theme/app_colors.dart';
import 'package:GizmoHub/core/database/gizmo_db.dart';
import 'package:GizmoHub/presentation/auth/pages/sign_in.dart';
import 'package:GizmoHub/presentation/cart/pages/cart_service.dart';
import 'package:GizmoHub/presentation/cart/pages/place_order_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Use these from anywhere (cart icon, "Go to cart", "Buy Now").
void openCart(BuildContext context) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutPage()));
}

Future<void> addAndOpenCart(BuildContext context, String productId, String? size) async {
  if (FirebaseAuth.instance.currentUser == null) {
    toast(context, 'Log in to use your cart');
    return;
  }
  try {
    await addToCart(productId, size: size);
    if (context.mounted) openCart(context);
  } on FirebaseException catch (e) {
    if (context.mounted) toast(context, e.message ?? 'Could not add to cart');
  }
}

class CheckoutPage extends StatefulWidget {
  final String title;
  final VoidCallback? onContinueShopping;
  const CheckoutPage({super.key, this.title = 'Checkout', this.onContinueShopping});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  Map<String, dynamic>? _address;

  @override
  void initState() {
    super.initState();
    _sub = userRef()?.snapshots().listen((s) {
      final a = s.data()?['deliveryAddress'];
      if (mounted) setState(() => _address = a is Map ? Map<String, dynamic>.from(a) : null);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  bool get _hasAddress => (_address?['address'] ?? '').toString().trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(title: Text(widget.title), centerTitle: true);
    if (FirebaseAuth.instance.currentUser == null) {
      return Scaffold(
        appBar: appBar,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Log in to view your cart'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const SignInPage())),
              child: const Text('Log in'),
            ),
          ]),
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: CartBuilder(builder: (context, lines, unavailable) {
        if (lines.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.shopping_cart_outlined, size: 56),
              const SizedBox(height: 12),
              const Text('Your cart is empty',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              if (unavailable > 0) ...[
                const SizedBox(height: 6),
                Text('$unavailable item(s) are no longer available'),
              ],
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continue shopping'),
              ),
            ]),
          );
        }

        final total = lines.fold<num>(0, (s, l) => s + l.total);
        return Column(children: [
          Expanded(
            child: ListView(padding: const EdgeInsets.all(16), children: [
              const Row(children: [
                Icon(Icons.location_on_outlined, size: 18),
                SizedBox(width: 6),
                Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 8),
              _addressCard(),
              const SizedBox(height: 20),
              const Text('Shopping List',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final l in lines) _CartItemCard(line: l),
              if (unavailable > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('$unavailable item(s) are no longer available and were skipped',
                      style: Theme.of(context).textTheme.bodySmall),
                ),
            ]),
          ),
          CartBottomBar(
            total: total,
            buttonLabel: 'Place Order',
            onPressed: () {
              if (!_hasAddress) {
                toast(context, 'Add a delivery address first');
                _editAddress();
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PlaceOrderPage(address: _address!)),
              );
            },
          ),
        ]);
      }),
    );
  }

  Widget _addressCard() {
    return InkWell(
      onTap: _editAddress,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: _hasAddress
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Address :', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text((_address!['address'] ?? '').toString()),
              const SizedBox(height: 4),
              Text('Contact : ${(_address!['phone'] ?? '').toString()}'),
            ])
                : const Text('Tap to add your delivery address'),
          ),
          Icon(_hasAddress ? Icons.edit_outlined : Icons.add_circle_outline, size: 20),
        ]),
      ),
    );
  }

  Future<void> _editAddress() async {
    final addr = TextEditingController(text: (_address?['address'] ?? '').toString());
    final phone = TextEditingController(text: (_address?['phone'] ?? '').toString());
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delivery address'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: addr,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Address'),
          ),
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone number'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved != true) return;
    if (addr.text.trim().isEmpty || phone.text.trim().isEmpty) {
      if (mounted) toast(context, 'Enter both address and phone number');
      return;
    }
    try {
      await userRef()?.set({
        'deliveryAddress': {'address': addr.text.trim(), 'phone': phone.text.trim()}
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      if (mounted) toast(context, e.message ?? 'Could not save address');
    }
  }
}

class _CartItemCard extends StatelessWidget {
  final CartLine line;
  const _CartItemCard({required this.line});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.image_outlined)),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 76,
              height: 90,
              child: line.imageUrl.isEmpty
                  ? placeholder
                  : Image.network(line.imageUrl,
                  fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(line.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                InkWell(
                  onTap: () => removeLine(line.key),
                  child: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                ),
              ]),
              if (line.size != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Text('Size : ', style: TextStyle(fontSize: 12)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(line.size!, style: const TextStyle(fontSize: 11)),
                  ),
                ]),
              ],
              const SizedBox(height: 4),
              Row(children: [
                for (int i = 1; i <= 5; i++)
                  Icon(i <= line.rating.round() ? Icons.star : Icons.star_border,
                      size: 12, color: Colors.amber),
                const SizedBox(width: 4),
                Text(line.rating.toString(), style: const TextStyle(fontSize: 11)),
              ]),
              const SizedBox(height: 4),
              Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(naira(line.price),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                if (line.oldPrice > line.price)
                  Text(naira(line.oldPrice),
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough)),
                if (line.discount.isNotEmpty)
                  Text(line.discount,
                      style: const TextStyle(fontSize: 11, color: Colors.deepOrange)),
              ]),
            ]),
          ),
        ]),
        const Divider(height: 16),
        Row(children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: line.qty > 1 ? () => setQty(line.key, line.qty - 1) : null,
          ),
          Text('${line.qty}', style: const TextStyle(fontWeight: FontWeight.w700)),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => setQty(line.key, line.qty + 1),
          ),
          const Spacer(),
          Text('Total Order (${line.qty}) : ',
              style: const TextStyle(fontSize: 12)),
          Text(naira(line.total), style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
      ]),
    );
  }
}