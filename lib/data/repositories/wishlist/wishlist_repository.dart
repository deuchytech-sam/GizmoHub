import 'package:GizmoHub/core/database/gizmo_db.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistRepository {
  DocumentReference<Map<String, dynamic>>? get _userRef {
    final user = FirebaseAuth.instance.currentUser;
    return user == null ? null : gizmoDb.collection('users').doc(user.uid);
  }

  Stream<Set<String>> watchIds() {
    final ref = _userRef;
    if (ref == null) return Stream.value(<String>{});
    return ref.snapshots().map((snapshot) {
      final items = snapshot.data()?['wishlist'];
      return items is Iterable
          ? items.map((item) => item.toString()).toSet()
          : <String>{};
    });
  }

  Future<void> setSaved(String productId, {required bool saved}) async {
    final ref = _userRef;
    if (ref == null) throw StateError('Sign in to update your wishlist.');
    await ref.set({
      'wishlist': saved
          ? FieldValue.arrayUnion([productId])
          : FieldValue.arrayRemove([productId]),
    }, SetOptions(merge: true));
  }
}
