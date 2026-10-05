// lib/profile/profile_page.dart
//
// pubspec.yaml needs: firebase_auth, cloud_firestore
//
// Saves to Firestore document  users/{uid}:
//   fullName, phone, email,
//   address: { postalCode, line, city, state, country },
//   bank:    { accountNumber, accountName, bankName },
//   updatedAt

import 'package:GizmoHub/core/configs/theme/app_colors.dart';
import 'package:GizmoHub/core/database/gizmo_db.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const nigerianStates = [
  'Abia', 'Adamawa', 'Akwa Ibom', 'Anambra', 'Bauchi', 'Bayelsa', 'Benue',
  'Borno', 'Cross River', 'Delta', 'Ebonyi', 'Edo', 'Ekiti', 'Enugu',
  'FCT (Abuja)', 'Gombe', 'Imo', 'Jigawa', 'Kaduna', 'Kano', 'Katsina',
  'Kebbi', 'Kogi', 'Kwara', 'Lagos', 'Nasarawa', 'Niger', 'Ogun', 'Ondo',
  'Osun', 'Oyo', 'Plateau', 'Rivers', 'Sokoto', 'Taraba', 'Yobe', 'Zamfara',
];

const nigerianBanks = [
  'Access Bank', 'Citibank Nigeria', 'Ecobank Nigeria', 'Fidelity Bank',
  'First Bank of Nigeria', 'FCMB', 'Globus Bank', 'GTBank', 'Heritage Bank',
  'Keystone Bank', 'Kuda Bank', 'Moniepoint MFB', 'OPay', 'PalmPay',
  'Polaris Bank', 'Providus Bank', 'Stanbic IBTC Bank',
  'Standard Chartered Bank', 'Sterling Bank', 'TAJBank', 'Titan Trust Bank',
  'Union Bank', 'UBA', 'Unity Bank', 'Wema Bank', 'Zenith Bank', 'Other',
];

void _toast(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

String _authMessage(FirebaseAuthException e) =>
    (e.code == 'wrong-password' || e.code == 'invalid-credential')
        ? 'Incorrect password'
        : (e.message ?? 'Something went wrong');

// ───────────────────────────── Profile page ─────────────────────────────

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _postal = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();
  final _accNumber = TextEditingController();
  final _accName = TextEditingController();
  String? _stateValue;
  String? _bankValue;

  bool _loading = true;
  bool _saving = false;
  bool _hideAccount = true;

  User? get _user => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>>? get _ref => _user == null
      ? null
      : gizmoDb.collection('users').doc(_user!.uid);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _name, _phone, _postal, _address, _city, _country,
      _accNumber, _accName,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _s(Map m, String k) => (m[k] ?? '').toString();

  Future<void> _load() async {
    final ref = _ref;
    if (ref == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final d = (await ref.get()).data() ?? {};
      final a = (d['address'] as Map?) ?? {};
      final b = (d['bank'] as Map?) ?? {};
      _name.text = _s(d, 'fullName');
      _phone.text = _s(d, 'phone');
      _postal.text = _s(a, 'postalCode');
      _address.text = _s(a, 'line');
      _city.text = _s(a, 'city');
      final st = _s(a, 'state');
      _stateValue = nigerianStates.contains(st) ? st : null;
      _country.text = 'Nigeria';
      _accNumber.text = _s(b, 'accountNumber');
      _accName.text = _s(b, 'accountName');
      final bk = _s(b, 'bankName');
      _bankValue = nigerianBanks.contains(bk) ? bk : null;
    } on FirebaseException catch (e) {
      if (mounted) _toast(context, e.message ?? 'Could not load profile');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ref = _ref;
    if (ref == null) return;
    setState(() => _saving = true);
    try {
      await ref.set({
        'fullName': _name.text.trim(),
        'phone': _phone.text.trim(),
        'email': _user!.email,
        'address': {
          'postalCode': _postal.text.trim(),
          'line': _address.text.trim(),
          'city': _city.text.trim(),
          'state': _stateValue ?? '',
          'country': 'Nigeria',
        },
        'bank': {
          'accountNumber': _accNumber.text.trim(),
          'accountName': _accName.text.trim(),
          'bankName': _bankValue ?? '',
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) _toast(context, 'Profile saved');
    } on FirebaseException catch (e) {
      if (mounted) _toast(context, e.message ?? 'Could not save profile');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── small builders ──

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold)),
  );

  Widget _tf(
      TextEditingController c,
      String label, {
        TextInputType? keyboard,
        String? Function(String?)? validator,
        int lines = 1,
        bool obscure = false,
        bool enabled = true,
        Widget? suffix,
        TextCapitalization caps = TextCapitalization.none,
      }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          keyboardType: keyboard,
          maxLines: lines,
          obscureText: obscure,
          enabled: enabled,
          textCapitalization: caps,
          validator: validator,
          decoration: InputDecoration(labelText: label, suffixIcon: suffix),
        ),
      );

  Widget _dropdown(String label, List<String> items, String? value,
      ValueChanged<String?> onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: [
            for (final i in items) DropdownMenuItem(value: i, child: Text(i)),
          ],
          onChanged: onChanged,
        ),
      );

  // Optional fields: only checked when the customer typed something.
  String? Function(String?) _optional(RegExp re, String msg) =>
          (v) => (v == null || v.trim().isEmpty || re.hasMatch(v.trim())) ? null : msg;

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: user == null
          ? const Center(child: Text('Please log in to edit your profile.'))
          : _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            _section('Personal Details'),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                initialValue: user.email ?? '',
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  suffixIcon: Icon(Icons.lock_outline),
                ),
              ),
            ),
            _tf(_name, 'Full Name', caps: TextCapitalization.words),
            _tf(_phone, 'Phone Number',
                keyboard: TextInputType.phone,
                validator: (v) {
                  final t = (v ?? '').replaceAll(' ', '');
                  if (t.isEmpty) return null;
                  return RegExp(r'^(\+234|234|0)[789][01][0-9]{8}$')
                      .hasMatch(t)
                      ? null
                      : 'Use a Nigerian number e.g. 08012345678';
                }),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Password'),
                child: Row(children: [
                  const Expanded(child: Text('••••••••••')),
                  TextButton(
                    onPressed: () => showChangePasswordDialog(context),
                    child: const Text('Change Password'),
                  ),
                ]),
              ),
            ),

            _section('Business Address Details'),
            _tf(_postal, 'Postal Code',
                keyboard: TextInputType.number,
                validator: _optional(
                    RegExp(r'^[0-9]{6}$'), 'Postal codes have 6 digits')),
            _tf(_address, 'Address', lines: 2),
            _tf(_city, 'City'),
            _dropdown('State', nigerianStates, _stateValue,
                    (v) => setState(() => _stateValue = v)),
            _tf(_country, 'Country', enabled: false),

            _section('Bank Account Details'),
            _tf(
              _accNumber,
              'Bank Account Number',
              keyboard: TextInputType.number,
              obscure: _hideAccount,
              validator: _optional(
                  RegExp(r'^[0-9]{10}$'), 'Account numbers have 10 digits'),
              suffix: IconButton(
                icon: Icon(_hideAccount
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () =>
                    setState(() => _hideAccount = !_hideAccount),
              ),
            ),
            _tf(_accName, "Account Holder's Name",
                caps: TextCapitalization.words),
            _dropdown('Bank Name', nigerianBanks, _bankValue,
                    (v) => setState(() => _bankValue = v)),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── Password helpers (also used by Settings) ───────────────────────

/// Asks for the current password and re-authenticates. Returns true on success.
/// Needed before sensitive actions such as deleting the account.
/// (Assumes email + password sign-in.)
Future<bool> reauthenticateWithPassword(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  final email = user?.email;
  if (user == null || email == null) return false;

  final pass = TextEditingController();
  String? error;
  bool busy = false;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Confirm your password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: pass,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
              setState(() {
                busy = true;
                error = null;
              });
              try {
                await user.reauthenticateWithCredential(
                  EmailAuthProvider.credential(
                      email: email, password: pass.text),
                );
                if (ctx.mounted) Navigator.pop(ctx, true);
              } on FirebaseAuthException catch (e) {
                setState(() {
                  busy = false;
                  error = _authMessage(e);
                });
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    ),
  );
  return ok ?? false;
}

Future<void> showChangePasswordDialog(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  final email = user?.email;
  if (user == null || email == null) return;

  final key = GlobalKey<FormState>();
  final current = TextEditingController();
  final next = TextEditingController();
  final confirm = TextEditingController();
  String? error;
  bool busy = false;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Change password'),
        content: Form(
          key: key,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: current,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current password'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: next,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
                validator: (v) =>
                (v == null || v.length < 8) ? 'At least 8 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirm,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm new password'),
                validator: (v) => v != next.text ? 'Passwords do not match' : null,
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!, style: const TextStyle(color: Colors.red)),
                ),
            ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
              if (!key.currentState!.validate()) return;
              setState(() {
                busy = true;
                error = null;
              });
              try {
                await user.reauthenticateWithCredential(
                  EmailAuthProvider.credential(
                      email: email, password: current.text),
                );
                await user.updatePassword(next.text);
                if (ctx.mounted) Navigator.pop(ctx, true);
              } on FirebaseAuthException catch (e) {
                setState(() {
                  busy = false;
                  error = _authMessage(e);
                });
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    ),
  );

  if (ok == true && context.mounted) _toast(context, 'Password updated');
}