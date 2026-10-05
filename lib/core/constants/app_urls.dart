class AppUrls{

  static const dealProductsFireStorage =
      'https://firebasestorage.googleapis.com/v0/b/gizmohub-40b3b.firebasestorage.app/o/';

  static String dealProductsUrl({
    required String title,
  }) {
    final objectName = 'deal_product/$title.jpg';

    return '$dealProductsFireStorage${Uri.encodeComponent(objectName)}?alt=media';
  }

}