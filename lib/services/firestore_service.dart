import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // Singleton instance
  static final FirestoreService _instance = FirestoreService._internal();

  factory FirestoreService() => _instance;

  FirestoreService._internal();

  // Get Firestore instance
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  // Get a collection reference
  CollectionReference collection(String path) {
    return firestore.collection(path);
  }

  // Get a document reference
  DocumentReference document(String path) {
    return firestore.doc(path);
  }

  // Create a batch write
  WriteBatch batch() {
    return firestore.batch();
  }
}
