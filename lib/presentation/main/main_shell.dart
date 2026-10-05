import 'package:GizmoHub/common/widgets/navigation/app_bottom_nav.dart';
import 'package:GizmoHub/presentation/cart/pages/cart.dart';
import 'package:GizmoHub/presentation/home/pages/home_page.dart';
import 'package:GizmoHub/presentation/search/pages/search_page.dart';
import 'package:GizmoHub/presentation/settings/pages/settings.dart';
import 'package:GizmoHub/presentation/wishlist/pages/wishlist.dart';
import 'package:GizmoHub/core/di/service_locator.dart';
import 'package:GizmoHub/data/repositories/product/product_repository.dart';
import 'package:GizmoHub/presentation/product/bloc/product_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final List<Widget> _pages = const [
    HomePage(),
    WishlistPage(),
    Cart(),
    SearchPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ProductCubit(productRepository: sl<ProductRepository>())
            ..watchProducts(),
      child: Scaffold(
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: AppBottomNav(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}
