import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:GizmoHub/data/models/product/product_model.dart';
import 'package:GizmoHub/core/database/gizmo_db.dart';

class ProductRepository {
  final FirebaseFirestore _firestore;

  ProductRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? gizmoDb;

  Future<List<ProductModel>> getProducts() async {
    final snapshot = await _firestore.collection('product').get();
    return snapshot.docs
        .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
        .where((product) => product.isActive)
        .toList();
  }

  Stream<List<ProductModel>> watchProducts() => _firestore
      .collection('product')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
            .where((product) => product.isActive)
            .toList(),
      );
}
