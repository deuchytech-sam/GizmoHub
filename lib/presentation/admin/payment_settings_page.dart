import 'package:GizmoHub/core/configs/theme/app_colors.dart';
import 'package:GizmoHub/core/database/gizmo_db.dart';
import 'package:GizmoHub/presentation/cart/pages/cart_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaymentSettingsPage extends StatefulWidget {
  const PaymentSettingsPage({super.key});

  @override
  State<PaymentSettingsPage> createState() => _PaymentSettingsPageState();
}

class _PaymentSettingsPageState extends State<PaymentSettingsPage> {
  final _form = GlobalKey<FormState>();
  final _bank = TextEditingController();
  final _name = TextEditingController();
  final _number = TextEditingController();
  final _fee = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bank.dispose();
    _name.dispose();
    _number.dispose();
    _fee.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final s = await loadPaymentSettings();
      _bank.text = (s['bankName'] ?? '').toString();
      _name.text = (s['accountName'] ?? '').toString();
      _number.text = (s['accountNumber'] ?? '').toString();
      _fee.text = ((s['deliveryFee'] ?? 0) as num).toStringAsFixed(0);
    } catch (_) {
      if (mounted) toast(context, 'Could not load current settings');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await gizmoDb.collection('settings').doc('payment').set({
        'bankName': _bank.text.trim(),
        'accountName': _name.text.trim(),
        'accountNumber': _number.text.trim(),
        'deliveryFee': int.tryParse(_fee.text.trim()) ?? 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) toast(context, 'Payment settings saved');
    } on FirebaseException catch (e) {
      if (mounted) toast(context, e.message ?? 'Could not save');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const Text(
            'Customers see these details on the payment screen and transfer '
                'their order total to this account.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bank,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
                labelText: 'Bank name', border: OutlineInputBorder()),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Enter the bank name' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
                labelText: 'Account name', border: OutlineInputBorder()),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Enter the account name' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _number,
            keyboardType: TextInputType.number,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
                labelText: 'Account number', border: OutlineInputBorder()),
            validator: (v) =>
            (v ?? '').trim().length == 10 ? null : 'Account number must be 10 digits',
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _fee,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Delivery fee (₦)',
              helperText: 'Enter 0 for free delivery',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Enter 0 for free delivery' : null,
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save'),
          ),
        ]),
      ),
    );
  }
}