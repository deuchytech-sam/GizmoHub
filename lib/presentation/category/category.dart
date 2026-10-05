import 'package:GizmoHub/core/configs/assets/app_images.dart';
import 'package:flutter/material.dart';

import 'package:GizmoHub/common/widgets/category/category_item.dart';
import 'package:GizmoHub/data/models/category/category_model.dart';

class Categories extends StatelessWidget {
  const Categories({super.key});

  static const List<CategoryModel> categories = [
    CategoryModel(
      name: 'Laptops',
      image: AppImages.laptop,
    ),
    CategoryModel(
      name: 'Phones',
      image: AppImages.phone,
    ),
    CategoryModel(
      name: 'Accessories',
      image: AppImages.accessories,
    ),
    CategoryModel(
      name: 'Desktop PC',
      image: AppImages.desktopPC,
    ),
    CategoryModel(
      name: 'Tech Solutions',
      image: AppImages.techSolutions,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(
        horizontal: 1,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];

          return CategoryItem(
            name: category.name,
            image: category.image,
          );
        },
      ),
    );
  }
}