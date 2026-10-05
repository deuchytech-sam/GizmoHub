import 'package:flutter/material.dart';
import 'package:GizmoHub/data/models/product/product_model.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.onTap});

  final ProductModel product;
  final VoidCallback? onTap;

  // 1250000 -> ₦1,250,000
  String _naira(double value) {
    final digits = value.toStringAsFixed(0);
    final withCommas = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );

    return '₦$withCommas';
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product.oldPrice > product.price;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 195,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                product.imageUrl,
                width: double.infinity,
                height: 145,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 145,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_outlined, color: Colors.grey),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 4),

            Text(
              product.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              _naira(product.price),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 2),

            SizedBox(
              height: 16,
              child: hasDiscount
                  ? Row(
                      children: [
                        Text(
                          _naira(product.oldPrice),
                          style: const TextStyle(
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        if (product.discount.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Text(
                            product.discount,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ],
                    )
                  : null,
            ),

            const SizedBox(height: 5),

            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < product.rating.floor()
                        ? Icons.star
                        : Icons.star_border,
                    size: 16,
                    color: Colors.amber.shade600,
                  );
                }),
                const SizedBox(width: 5),
                Text(
                  '${product.reviews}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
