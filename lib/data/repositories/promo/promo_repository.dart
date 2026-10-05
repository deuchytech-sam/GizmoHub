import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:GizmoHub/data/models/promo/promo_model.dart';

class PromoRepository {
  final FirebaseFirestore _firestore;

  PromoRepository({FirebaseFirestore? firestore})
    : _firestore =
          firestore ??
          FirebaseFirestore.instanceFor(
            app: Firebase.app(),
            databaseId: 'gizmohub',
          );

  Future<PromoModel?> getHomePromo() async {
    final document = await _firestore
        .collection('promos')
        .doc('home_promo')
        .get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    final promo = PromoModel.fromMap(document.data()!);

    if (!promo.isActive) {
      return null;
    }

    return promo;
  }

  Future<List<PromoModel>> getActivePromo() async {
    final snapshot = await _firestore.collection('promos').get();

    return snapshot.docs
        .map((document) => PromoModel.fromMap(document.data()))
        .where((promo) => promo.isActive)
        .toList();
  }
}
