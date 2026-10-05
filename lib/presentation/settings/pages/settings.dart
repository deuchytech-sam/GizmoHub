// lib/presentation/settings/settings_page.dart
//
// pubspec.yaml needs: flutter_bloc, shared_preferences, firebase_auth, cloud_firestore
// Open it with:
//   Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));

import 'package:GizmoHub/core/configs/theme/bloc/theme_cubit.dart';
import 'package:GizmoHub/core/database/gizmo_db.dart';
import 'package:GizmoHub/presentation/admin/admin_pages.dart'; // <- change if your admin file lives elsewhere
import 'package:GizmoHub/presentation/auth/pages/sign_in.dart';
import 'package:GizmoHub/presentation/profile/profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

const appVersion = '1.0.0'; // keep in step with pubspec.yaml

void _toast(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _kOrders = 'notif_orders';
  static const _kPromos = 'notif_promos';

  bool _orders = true;
  bool _promos = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _checkAdmin();
  }

  /// Shows the "Admin dashboard" row only for accounts listed in `admins`.
  Future<void> _checkAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await gizmoDb
          .collection('admins')
          .doc(user.uid)
          .get();
      if (mounted) setState(() => _isAdmin = doc.exists);
    } on FirebaseException {
      // Not an admin (or rules denied the read): keep the row hidden.
    }
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _orders = p.getBool(_kOrders) ?? true;
      _promos = p.getBool(_kPromos) ?? true;
    });
  }

  Future<void> _savePref(String key, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, value);
  }

  Future<bool> _confirm(String title, String body, String yes) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(yes)),
        ],
      ),
    );
    return r ?? false;
  }

  void _goToSignIn() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInPage()),
          (route) => false,
    );
  }

  Future<void> _signOut() async {
    if (!await _confirm('Sign out?', 'You will need to log in again.', 'Sign out')) {
      return;
    }
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    _goToSignIn();
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final sure = await _confirm(
      'Delete account?',
      'This permanently deletes your account and saved profile. '
          'Past orders are kept for record-keeping.',
      'Delete',
    );
    if (!sure || !mounted) return;

    // Firebase requires a recent login before deleting an account.
    final ok = await reauthenticateWithPassword(context);
    if (!ok || !mounted) return;

    try {
      await gizmoDb.collection('users').doc(user.uid).delete();
      await user.delete();
      if (mounted) _goToSignIn();
    } on FirebaseException catch (e) {
      if (mounted) _toast(context, e.message ?? 'Could not delete account');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeCubit>().state;
    final loggedIn = FirebaseAuth.instance.currentUser != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto),
                      label: Text('System')),
                  ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode),
                      label: Text('Light')),
                  ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode),
                      label: Text('Dark')),
                ],
                selected: {mode},
                onSelectionChanged: (s) =>
                    context.read<ThemeCubit>().updateTheme(s.first),
              ),
            ),
          ),

          const _SectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('Order updates'),
            subtitle: const Text('Payment confirmed, out for delivery, delivered'),
            value: _orders,
            onChanged: (v) {
              setState(() => _orders = v);
              _savePref(_kOrders, v);
            },
          ),
          SwitchListTile(
            title: const Text('Promotions & deals'),
            subtitle: const Text('New offers and discounts'),
            value: _promos,
            onChanged: (v) {
              setState(() => _promos = v);
              _savePref(_kPromos, v);
            },
          ),

          if (loggedIn) ...[
            const _SectionHeader('Account'),
            if (_isAdmin)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Admin dashboard'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminGate()),
                ),
              ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('My profile'),
              subtitle: const Text('Personal, address and bank details'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Change password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showChangePasswordDialog(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: _signOut,
            ),
          ],

          const _SectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About GizmoHub'),
            subtitle: const Text('Version $appVersion'),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'GizmoHub',
              applicationVersion: appVersion,
            ),
          ),

          if (loggedIn) ...[
            const _SectionHeader('Danger zone'),
            ListTile(
              leading: Icon(Icons.delete_forever,
                  color: Theme.of(context).colorScheme.error),
              title: Text('Delete account',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: _deleteAccount,
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    ),
  );
}