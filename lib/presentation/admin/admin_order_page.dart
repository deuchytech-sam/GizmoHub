import 'package:GizmoHub/core/configs/theme/app_colors.dart';
import 'package:GizmoHub/core/database/gizmo_db.dart';
import 'package:GizmoHub/presentation/admin/payment_settings_page.dart';
import 'package:GizmoHub/presentation/cart/pages/cart_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _awaiting = 'awaiting_confirmation';
const _confirmed = 'confirmed';
const _rejected = 'rejected';
const _pending = 'pending';
const _delivered = 'delivered';
const _cancelled = 'cancelled';

String _fmtDate(dynamic ts) {
  if (ts is! Timestamp) return 'Just now';
  final d = ts.toDate().toLocal();
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final min = d.minute.toString().padLeft(2, '0');
  final ap = d.hour >= 12 ? 'PM' : 'AM';
  return '${d.day} ${m[d.month - 1]} ${d.year}, $h:$min $ap';
}

class AdminOrder {
  final String id;
  final Map<String, dynamic> d;
  AdminOrder(this.id, this.d);

  String get shortId =>
      id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id.toUpperCase();
  String get payment => (d['paymentStatus'] ?? _awaiting).toString();
  String get delivery => (d['deliveryStatus'] ?? _pending).toString();
  num get total => (d['total'] ?? 0) as num;
  List<Map<String, dynamic>> get items => ((d['items'] as List?) ?? const [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  int get itemCount => items.fold(0, (s, i) => s + ((i['qty'] as num?)?.toInt() ?? 1));
}

String _statusLabel(AdminOrder o) {
  if (o.payment == _rejected) return 'Payment rejected';
  if (o.delivery == _delivered) return 'Delivered';
  if (o.payment == _confirmed) return 'Paid · to deliver';
  return 'Awaiting payment';
}

Color _statusColor(AdminOrder o) {
  if (o.payment == _rejected) return Colors.red;
  if (o.delivery == _delivered) return Colors.green;
  if (o.payment == _confirmed) return Colors.blue;
  return Colors.orange;
}

class _StatusChip extends StatelessWidget {
  final AdminOrder order;
  const _StatusChip(this.order);

  @override
  Widget build(BuildContext context) {
    final c = _statusColor(order);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(_statusLabel(order),
          style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ───────────────────────────── Orders list ─────────────────────────────

/// Full-screen version with its own app bar.
class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            tooltip: 'Payment settings',
            icon: const Icon(Icons.account_balance_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaymentSettingsPage()),
            ),
          ),
        ],
      ),
      body: const AdminOrdersView(),
    );
  }
}

/// The orders UI without a Scaffold, so it can sit inside a dashboard tab.
class AdminOrdersView extends StatefulWidget {
  const AdminOrdersView({super.key});

  @override
  State<AdminOrdersView> createState() => _AdminOrdersViewState();
}

class _AdminOrdersViewState extends State<AdminOrdersView> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream =
  gizmoDb.collection('orders').orderBy('createdAt', descending: true).snapshots();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('${snap.error}'));
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final orders = snap.data!.docs.map((d) => AdminOrder(d.id, d.data())).toList();
        final toConfirm = orders.where((o) => o.payment == _awaiting).toList();
        final toDeliver =
        orders.where((o) => o.payment == _confirmed && o.delivery == _pending).toList();
        final delivered = orders.where((o) => o.delivery == _delivered).toList();
        final rejected = orders.where((o) => o.payment == _rejected).toList();

        num sum(Iterable<AdminOrder> l) => l.fold<num>(0, (s, o) => s + o.total);
        final received = sum(orders.where((o) => o.payment == _confirmed));

        return DefaultTabController(
          length: 5,
          child: Column(children: [
            TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'To confirm (${toConfirm.length})'),
                Tab(text: 'To deliver (${toDeliver.length})'),
                Tab(text: 'Delivered (${delivered.length})'),
                Tab(text: 'Rejected (${rejected.length})'),
                Tab(text: 'All (${orders.length})'),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(children: [
                _Stat('Money received', naira(received), Colors.green),
                const SizedBox(width: 8),
                _Stat('Awaiting confirmation', naira(sum(toConfirm)), Colors.orange),
                const SizedBox(width: 8),
                _Stat('To deliver', '${toDeliver.length}', Colors.blue),
              ]),
            ),
            Expanded(
              child: TabBarView(children: [
                _OrderList(toConfirm),
                _OrderList(toDeliver),
                _OrderList(delivered),
                _OrderList(rejected),
                _OrderList(orders),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        ),
      ]),
    ),
  );
}

class _OrderList extends StatelessWidget {
  final List<AdminOrder> orders;
  const _OrderList(this.orders);

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return const Center(child: Text('Nothing here'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (_, i) => _OrderCard(orders[i]),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final AdminOrder o;
  const _OrderCard(this.o);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final first = o.items.isNotEmpty ? o.items.first : null;
    final img = (first?['imageUrl'] ?? '').toString();
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.image_outlined, size: 20)),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AdminOrderDetailsPage(orderId: o.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: img.isEmpty
                    ? placeholder
                    : Image.network(img,
                    fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Order #${o.shortId}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text(naira(o.total), style: const TextStyle(fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 2),
                Text('${o.itemCount} item(s) · ${(o.d['phone'] ?? '').toString()}',
                    style: const TextStyle(fontSize: 12)),
                Text(_fmtDate(o.d['createdAt']),
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 6),
                _StatusChip(o),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ───────────────────────────── Order details ─────────────────────────────

class AdminOrderDetailsPage extends StatefulWidget {
  final String orderId;
  const AdminOrderDetailsPage({super.key, required this.orderId});

  @override
  State<AdminOrderDetailsPage> createState() => _AdminOrderDetailsPageState();
}

class _AdminOrderDetailsPageState extends State<AdminOrderDetailsPage> {
  late final DocumentReference<Map<String, dynamic>> _ref =
  gizmoDb.collection('orders').doc(widget.orderId);
  bool _busy = false;

  Future<void> _transition({
    required String expectPayment,
    String? expectDelivery,
    required Map<String, dynamic> updates,
  }) {
    return gizmoDb.runTransaction((tx) async {
      final snap = await tx.get(_ref);
      final d = snap.data() ?? {};
      final pay = (d['paymentStatus'] ?? _awaiting).toString();
      final del = (d['deliveryStatus'] ?? _pending).toString();
      if (pay != expectPayment || (expectDelivery != null && del != expectDelivery)) {
        throw StateError('This order was already updated');
      }
      tx.update(_ref, updates);
    });
  }

  Future<void> _act({
    required String title,
    required String message,
    required String confirmLabel,
    required String expectPayment,
    String? expectDelivery,
    required Map<String, dynamic> updates,
    bool destructive = false,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: destructive ? Colors.red : AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      await _transition(
          expectPayment: expectPayment, expectDelivery: expectDelivery, updates: updates);
      if (mounted) toast(context, 'Order updated');
    } on FirebaseException catch (e) {
      if (mounted) toast(context, e.message ?? 'Update failed');
    } on StateError catch (e) {
      if (mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order details')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _ref.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (!snap.data!.exists) return const Center(child: Text('Order not found'));
          final o = AdminOrder(snap.data!.id, snap.data!.data()!);
          final d = o.d;
          final coupon = (d['couponCode'] ?? '').toString();
          final discount = (d['discount'] ?? 0) as num;
          final fee = (d['deliveryFee'] ?? 0) as num;

          return Column(children: [
            Expanded(
              child: ListView(padding: const EdgeInsets.all(16), children: [
                Row(children: [
                  Text('Order #${o.shortId}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  _StatusChip(o),
                ]),
                const SizedBox(height: 2),
                Text(_fmtDate(d['createdAt']),
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),

                _section('Customer'),
                _info('Email', (d['userEmail'] ?? '-').toString()),
                _info('Phone', (d['phone'] ?? '-').toString(), copy: true),
                _info('Address', (d['address'] ?? '-').toString(), copy: true),

                _section('Items'),
                for (final i in o.items) _ItemRow(i),

                _section('Payment'),
                _info('Method', 'Bank transfer'),
                SummaryRow('Subtotal', naira((d['subtotal'] ?? 0) as num)),
                if (discount > 0)
                  SummaryRow('Discount${coupon.isEmpty ? '' : ' ($coupon)'}',
                      '- ${naira(discount)}',
                      valueColor: Colors.green),
                SummaryRow('Delivery fee', fee == 0 ? 'Free' : naira(fee)),
                const Divider(),
                SummaryRow('Expected transfer', naira(o.total), bold: true),
                if (d['paymentConfirmedAt'] != null)
                  _info('Payment confirmed', _fmtDate(d['paymentConfirmedAt'])),
                if (d['deliveredAt'] != null)
                  _info('Delivered', _fmtDate(d['deliveredAt'])),
              ]),
            ),
            _actions(o),
          ]);
        },
      ),
    );
  }

  Widget _actions(AdminOrder o) {
    Widget? child;

    if (o.payment == _awaiting) {
      child = Row(children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _busy
                ? null
                : () => _act(
              title: 'Reject payment?',
              message:
              'Use this if the ${naira(o.total)} never arrived. The order will be cancelled.',
              confirmLabel: 'Reject',
              destructive: true,
              expectPayment: _awaiting,
              updates: {
                'paymentStatus': _rejected,
                'deliveryStatus': _cancelled,
                'rejectedAt': FieldValue.serverTimestamp(),
              },
            ),
            child: const Text('Reject payment'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _busy
                ? null
                : () => _act(
              title: 'Confirm payment?',
              message:
              'Confirm only after you see ${naira(o.total)} in your bank account.',
              confirmLabel: 'Confirm',
              expectPayment: _awaiting,
              updates: {
                'paymentStatus': _confirmed,
                'paymentConfirmedAt': FieldValue.serverTimestamp(),
              },
            ),
            child: const Text('Confirm payment'),
          ),
        ),
      ]);
    } else if (o.payment == _confirmed && o.delivery == _pending) {
      child = SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.local_shipping_outlined),
          label: const Text('Mark as delivered'),
          onPressed: _busy
              ? null
              : () => _act(
            title: 'Mark as delivered?',
            message: 'This order will move to Delivered.',
            confirmLabel: 'Yes, delivered',
            expectPayment: _confirmed,
            expectDelivery: _pending,
            updates: {
              'deliveryStatus': _delivered,
              'deliveredAt': FieldValue.serverTimestamp(),
            },
          ),
        ),
      );
    }

    if (child == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 10, offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(top: false, child: child),
    );
  }

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
  );

  Widget _info(String label, String value, {bool copy = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 120,
        child: Text(label, style: const TextStyle(color: Colors.grey)),
      ),
      Expanded(child: Text(value)),
      if (copy)
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            toast(context, '$label copied');
          },
          child: const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(Icons.copy, size: 16),
          ),
        ),
    ]),
  );
}

class _ItemRow extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ItemRow(this.item);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = (item['imageUrl'] ?? '').toString();
    final qty = (item['qty'] as num?)?.toInt() ?? 1;
    final price = (item['price'] ?? 0) as num;
    final size = item['size']?.toString();
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.image_outlined, size: 20)),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 52,
            height: 60,
            child: url.isEmpty
                ? placeholder
                : Image.network(url,
                fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text((item['name'] ?? '').toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('${size != null ? 'Size $size · ' : ''}Qty $qty × ${naira(price)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
        ),
        Text(naira(price * qty), style: const TextStyle(fontWeight: FontWeight.w700)),
      ]),
    );
  }
}