import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../product/product_model.dart';

Future<Product?> fetchProductDetails(String documentId) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId != null) {
    final doc = await FirebaseFirestore.instance
        .collection('collection')
        .doc(userId)
        .collection('collection')
        .doc(documentId)
        .get();

    if (doc.exists) {
      return Product.fromMap(doc.data() as Map<String, dynamic>);
    }
  }

  return null;
}

Future<void> updateProductImages(
    String documentId, List<String> updatedUrls) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId != null) {
    await FirebaseFirestore.instance
        .collection('collection')
        .doc(userId)
        .collection('collection')
        .doc(documentId)
        .update({'field name': updatedUrls});
  }
}
