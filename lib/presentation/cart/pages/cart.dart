import 'package:GizmoHub/presentation/cart/pages/checkout_page.dart';
import 'package:flutter/material.dart';

class Cart extends StatelessWidget {
  const Cart({super.key});

  @override
  Widget build(BuildContext context) {
    return const CheckoutPage(title: 'My Cart');
  }
}