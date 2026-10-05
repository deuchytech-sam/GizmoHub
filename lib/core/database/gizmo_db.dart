// lib/core/gizmo_db.dart
//
// GizmoHub's data lives in a NAMED Firestore database ("gizmohub"), not "(default)".
// Use `gizmoDb` everywhere instead of FirebaseFirestore.instance.
//
// pubspec.yaml needs: firebase_core, cloud_firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

final FirebaseFirestore gizmoDb = FirebaseFirestore.instanceFor(
  app: Firebase.app(),
  databaseId: 'gizmohub',
);
