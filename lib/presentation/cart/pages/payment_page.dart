import 'package:GizmoHub/core/configs/theme/app_colors.dart';
import 'package:GizmoHub/presentation/admin/admin_pages.dart';
import 'package:GizmoHub/presentation/cart/pages/cart_service.dart' hide naira;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaymentPage extends StatefulWidget {
  final OrderDraft draft;
  const PaymentPage({super.key, required this.draft});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late final Future<Map<String, dynamic>> _settings = loadPaymentSettings();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout'), centerTitle: true),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _settings,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final s = snap.data ?? {};
          final bank = (s['bankName'] ?? '').toString();
          final name = (s['accountName'] ?? '').toString();
          final number = (s['accountNumber'] ?? '').toString();
          final ready = number.isNotEmpty;

          return ListView(padding: const EdgeInsets.all(20), children: [
            SummaryRow('Order', naira(d.subtotal)),
            if (d.discount > 0)
              SummaryRow('Discount', '- ${naira(d.discount)}', valueColor: Colors.green),
            SummaryRow('Shipping', d.deliveryFee == 0 ? 'Free' : naira(d.deliveryFee)),
            const Divider(height: 24),
            SummaryRow('Total', naira(d.total), bold: true),
            const SizedBox(height: 28),
            const Text('Payment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            // Bank transfer card (selected style from the design)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(6),
              ),
              child: ready
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.account_balance, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Bank Transfer',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ]),
                const SizedBox(height: 12),
                if (bank.isNotEmpty) Text('Bank: $bank'),
                if (name.isNotEmpty) Text('Account name: $name'),
                const SizedBox(height: 4),
                Row(children: [
                  Text(number,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: 'Copy account number',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: number));
                      toast(context, 'Account number copied');
                    },
                  ),
                ]),
              ])
                  : const Text('Payment details are not available yet. Please contact the store.'),
            ),
            const SizedBox(height: 12),
            Text(
              'Transfer exactly ${naira(d.total)} to the account above, then tap '
                  '"I\'ve made the transfer". We confirm your payment before delivery.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 28),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: (!ready || _busy) ? null : _continue,
              child: _busy
                  ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text("I've made the transfer", style: TextStyle(fontSize: 16)),
            ),
          ]);
        },
      ),
    );
  }

  Future<void> _continue() async {
    setState(() => _busy = true);
    try {
      await placeOrder(widget.draft);
      if (!mounted) return;
      await _showSuccess();
    } on FirebaseException catch (e) {
      if (mounted) toast(context, e.message ?? 'Could not place order');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showSuccess() {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Order placed successfully!',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              'Once we confirm your transfer, we will start your delivery.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
              child: const Text('Done'),
            ),
          ]),
        ),
      ),
    );
  }
}