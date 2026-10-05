import 'package:GizmoHub/core/configs/theme/app_colors.dart';
import 'package:GizmoHub/presentation/cart/pages/cart_service.dart';
import 'package:GizmoHub/presentation/cart/pages/payment_page.dart';
import 'package:flutter/material.dart';

class PlaceOrderPage extends StatefulWidget {
  final Map<String, dynamic> address;
  const PlaceOrderPage({super.key, required this.address});

  @override
  State<PlaceOrderPage> createState() => _PlaceOrderPageState();
}

class _PlaceOrderPageState extends State<PlaceOrderPage> {
  Coupon? _coupon;
  num _deliveryFee = 0;

  @override
  void initState() {
    super.initState();
    loadPaymentSettings().then((s) {
      if (mounted) setState(() => _deliveryFee = (s['deliveryFee'] ?? 0) as num);
    }).catchError((_) {});
  }

  OrderDraft _draft(List<CartLine> lines) => OrderDraft(
    lines: lines,
    coupon: _coupon,
    deliveryFee: _deliveryFee,
    address: widget.address,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Bag'), centerTitle: true),
      body: CartBuilder(builder: (context, lines, _) {
        if (lines.isEmpty) return const Center(child: Text('Your cart is empty'));
        final d = _draft(lines);

        return Column(children: [
          Expanded(
            child: ListView(padding: const EdgeInsets.all(16), children: [
              for (final l in lines) _BagItem(line: l),
              const Divider(height: 28),

              // Coupons
              InkWell(
                onTap: _coupon == null ? _enterCoupon : () => setState(() => _coupon = null),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    const Icon(Icons.local_offer_outlined, size: 20),
                    const SizedBox(width: 10),
                    Text(_coupon == null ? 'Apply Coupons' : 'Coupon ${_coupon!.code} applied',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(_coupon == null ? 'Select' : 'Remove',
                        style: const TextStyle(
                            color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
              const Divider(height: 28),

              const Text('Order Payment Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              ..._rows(d),
              const Divider(height: 28),
              SummaryRow('Order Total', naira(d.total), bold: true),
            ]),
          ),
          CartBottomBar(
            total: d.total,
            buttonLabel: 'Proceed to Payment',
            onDetails: () => showModalBottomSheet(
              context: context,
              builder: (_) => Padding(
                padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  ..._rows(d),
                  const Divider(),
                  SummaryRow('Order Total', naira(d.total), bold: true),
                ]),
              ),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PaymentPage(draft: d)),
            ),
          ),
        ]);
      }),
    );
  }

  List<Widget> _rows(OrderDraft d) => [
    SummaryRow('Order Amounts', naira(d.subtotal)),
    if (d.discount > 0)
      SummaryRow('Coupon discount', '- ${naira(d.discount)}', valueColor: Colors.green),
    SummaryRow(
      'Delivery Fee',
      d.deliveryFee == 0 ? 'Free' : naira(d.deliveryFee),
      valueColor: d.deliveryFee == 0 ? AppColors.primary : null,
    ),
  ];

  Future<void> _enterCoupon() async {
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Apply coupon'),
        content: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(hintText: 'Enter coupon code'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('Apply')),
        ],
      ),
    );
    if (code == null || code.trim().isEmpty) return;
    try {
      final c = await fetchCoupon(code);
      if (!mounted) return;
      if (c == null) {
        toast(context, 'Invalid or expired coupon');
      } else {
        setState(() => _coupon = c);
      }
    } catch (_) {
      if (mounted) toast(context, 'Could not check coupon');
    }
  }
}

class _BagItem extends StatelessWidget {
  final CartLine line;
  const _BagItem({required this.line});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.image_outlined)),
    );
    final delivery = (line.data['delivery'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 80,
            height: 96,
            child: line.imageUrl.isEmpty
                ? placeholder
                : Image.network(line.imageUrl,
                fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(line.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: [
              if (line.size != null) _chip('Size  ${line.size}'),
              _chip('Qty  ${line.qty}'),
            ]),
            const SizedBox(height: 6),
            Text(naira(line.total), style: const TextStyle(fontWeight: FontWeight.w800)),
            if (delivery.isNotEmpty)
              Text('Delivery in $delivery', style: const TextStyle(fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  Widget _chip(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade400),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(t, style: const TextStyle(fontSize: 12)),
  );
}