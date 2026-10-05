import 'package:GizmoHub/core/configs/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const double _barHeight = 64;
  static const double _cartSize = 62;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _barHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  _item(context, 0, 'Home', Icons.home_outlined, Icons.home_rounded),
                  _item(context, 1, 'Wishlist', Icons.favorite_border_rounded,
                      Icons.favorite_rounded),
                  const Expanded(child: SizedBox()), // space for cart
                  _item(context, 3, 'Search', Icons.search_rounded,
                      Icons.search_rounded),
                  _item(context, 4, 'Setting', Icons.settings_outlined,
                      Icons.settings_rounded),
                ],
              ),
              Positioned(
                top: -(_cartSize / 2),
                child: _cartButton(context, bg),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(
      BuildContext context,
      int index,
      String label,
      IconData icon,
      IconData activeIcon,
      ) {
    final isActive = currentIndex == index;
    final color = isActive
        ? AppColors.primary
        : Theme.of(context).colorScheme.onSurface;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartButton(BuildContext context, Color ringColor) {
    final isActive = currentIndex == 2;

    return GestureDetector(
      onTap: () => onTap(2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _cartSize,
        height: _cartSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
          border: Border.all(color: ringColor, width: 5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: isActive ? 0.55 : 0.3),
              blurRadius: isActive ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.shopping_cart_outlined,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}