import 'package:GizmoHub/common/helpers/is_dark_mode.dart';
import 'package:flutter/material.dart';

class BasicAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final Widget? action;
  final Widget? leading;
  final Color? backgroundColor;
  final bool hideBack;
  final Color? foregroundColor;

  const BasicAppBar({
    super.key,
    this.title,
    this.action,
    this.leading,
    this.backgroundColor,
    this.hideBack = false,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? Colors.transparent,
      foregroundColor: foregroundColor,
      centerTitle: true,
      elevation: 0,
      title: title ?? const SizedBox.shrink(),
      actions: [
        if (action != null) action!,
      ],
      leading: leading ??
          (hideBack
              ? null
              : IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? Colors.white.withOpacity(0.03)
                    : Colors.black.withOpacity(0.04),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_ios_sharp,
                size: 15,
                color: context.isDarkMode
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          )),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}