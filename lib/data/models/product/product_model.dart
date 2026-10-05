import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double oldPrice;
  final String discount;
  final double rating;
  final int reviews;
  final String imageUrl;
  final String category;
  final bool isActive;
  final int stockQuantity;
  final DateTime? createdAt;
  int get discountValue =>
      int.tryParse(discount.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.oldPrice,
    required this.discount,
    required this.rating,
    required this.reviews,
    required this.imageUrl,
    required this.category,
    required this.isActive,
    this.stockQuantity = 0,
    this.createdAt,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: _asDouble(map['price']),
      oldPrice: _asDouble(map['oldPrice']),
      discount: (map['discount'] ?? '').toString(),
      rating: _asDouble(map['rating']),
      reviews: _asInt(map['reviews']),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      category: _categoryName(map['categories'] ?? map['category']),
      isActive: map['isActive'] is bool ? map['isActive'] as bool : true,
      stockQuantity:
          map.containsKey('stockQuantity') || map.containsKey('stock')
          ? _asInt(map['stockQuantity'] ?? map['stock'])
          : 1,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : map['createdAt'] is DateTime
          ? map['createdAt'] as DateTime
          : null,
    );
  }

  static double _asDouble(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;

  static int _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

  static String _categoryName(dynamic value) => value is List
      ? value.map((item) => item.toString()).join(', ')
      : (value ?? '').toString();
}
