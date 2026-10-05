import 'package:GizmoHub/presentation/wishlist/pages/wishlist.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:GizmoHub/core/configs/theme/app_colors.dart';
import 'package:GizmoHub/core/configs/theme/bloc/theme_cubit.dart';
import 'package:GizmoHub/core/database/gizmo_db.dart';
import 'package:GizmoHub/presentation/auth/pages/sign_in.dart';
import 'package:GizmoHub/presentation/profile/profile_page.dart';
// import your settings, cart/orders and admin pages here:
// import 'package:GizmoHub/presentation/settings/settings_page.dart';
// import 'package:GizmoHub/admin/admin_pages.dart';

Future<void> showOptionsSheet(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close menu',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: .82,
          child: SafeArea(child: OptionsSheet()),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      return SlideTransition(position: slide, child: child);
    },
  );
}

class OptionsSheet extends StatelessWidget {
  const OptionsSheet({super.key});

  Future<bool> _isAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    try {
      final doc = await gizmoDb.collection('admins').doc(uid).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  void _go(BuildContext context, Widget page) {
    Navigator.pop(context); // close sheet first
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _signOut(BuildContext context) async {
    final nav = Navigator.of(context, rootNavigator: true);
    await FirebaseAuth.instance.signOut();
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInPage()),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    return Material(
      color: theme.scaffoldBackgroundColor,
      borderRadius: const BorderRadius.horizontal(
        right: Radius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withOpacity(.15),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Welcome to GizmoHub',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (user?.email != null)
                          Text(
                            user!.email!,
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close menu',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  _OptionTile(
                    icon: Icons.person_outline,
                    label: 'My Profile',
                    onTap: () => _go(
                      context,
                      const ProfilePage(),
                    ),
                  ),
                  _OptionTile(
                    icon: Icons.favorite_border,
                    label: 'Wishlist',
                    onTap: () => _go(
                      context,
                      const WishlistPage(),
                    ),
                  ),
                  _OptionTile(
                    icon: Icons.receipt_long_outlined,
                    label: 'My Orders',
                    onTap: () => Navigator.pop(context),
                  ),
                  _OptionTile(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => Navigator.pop(context),
                  ),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                    ),
                    secondary: Icon(
                      isDark
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                    ),
                    title: const Text('Dark mode'),
                    value: isDark,
                    activeColor: AppColors.primary,
                    onChanged: (value) {
                      context.read<ThemeCubit>().updateTheme(
                        value
                            ? ThemeMode.dark
                            : ThemeMode.light,
                      );
                    },
                  ),
                  FutureBuilder<bool>(
                    future: _isAdmin(),
                    builder: (context, snapshot) {
                      if (snapshot.data != true) {
                        return const SizedBox.shrink();
                      }

                      return _OptionTile(
                        icon: Icons.admin_panel_settings_outlined,
                        label: 'Admin Dashboard',
                        onTap: () => Navigator.pop(context),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _OptionTile(
                icon: Icons.logout,
                label: 'Sign out',
                color: Colors.redAccent,
                onTap: () => _signOut(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      trailing: color == null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }
}
