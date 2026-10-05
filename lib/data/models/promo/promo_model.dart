class PromoModel {
  final String title;
  final String subtitle;
  final String buttonText;
  final String imageUrl;
  final bool isActive;

  const PromoModel({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.imageUrl,
    required this.isActive,
  });

  factory PromoModel.fromMap(Map<String, dynamic> map) {
    return PromoModel(
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      buttonText: map['buttonText'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      // Treat an omitted flag as active so older promo documents still show.
      isActive: map['isActive'] as bool? ?? true,
    );
  }
}
