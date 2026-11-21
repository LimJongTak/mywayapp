import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Firebase 인스턴스 접근점
class Fb {
  static FirebaseFirestore get db => FirebaseFirestore.instance;
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseStorage get storage => FirebaseStorage.instance;
  static FirebaseFunctions get functions =>
      FirebaseFunctions.instanceFor(region: 'asia-northeast3');

  static String? get uid => auth.currentUser?.uid;

  static Future<Map<String, dynamic>> call(String name, [Map<String, dynamic>? data]) async {
    final res = await functions.httpsCallable(name).call<Map<String, dynamic>>(data);
    return Map<String, dynamic>.from(res.data);
  }
}
