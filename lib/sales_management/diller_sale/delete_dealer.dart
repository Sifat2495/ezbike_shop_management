import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

Future<void> deleteDealerData(String saleDocId) async {
  try {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final FirebaseFirestore db = FirebaseFirestore.instance;
    final saleRef = db
        .collection('collection name')
        .doc(userId)
        .collection('sales')
        .doc(saleDocId);

    
    final saleSnapshot = await saleRef.get();
    if (!saleSnapshot.exists) {
      debugPrint("❌ বিক্রয়ের ডকুমেন্ট পাওয়া যায়নি।");
      return;
    }

    final saleData = saleSnapshot.data();
    if (saleData == null) return;

    final List<Map<String, dynamic>> products =
    List<Map<String, dynamic>>.from(saleData['products'] ?? []);
    final double totalPrice =
        (saleData['totalPrice'] as num?)?.toDouble() ?? 0.0;
    final double payment = (saleData['payment'] as num?)?.toDouble() ?? 0.0;
    final double due = (saleData['due'] as num?)?.toDouble() ?? 0.0;
    final DateTime saleTime = (saleData['time'] as Timestamp).toDate();

    double totalProfit = 0.0;
    final WriteBatch batch = db.batch();
    final stockRef = db.collection('collection name').doc(userId).collection('collection name');

    
    for (final product in products) {
      final productName = product['name'];
      final quantitySold = product['quantity'];

      final querySnapshot =
      await stockRef.where('name', isEqualTo: productName).limit(1).get();
      if (querySnapshot.docs.isNotEmpty) {
        final productDoc = querySnapshot.docs.first;
        final currentStock = (productDoc.data()['collection name'] as num?) ?? 0;
        batch.update(
            productDoc.reference, {'collection name': currentStock + quantitySold});
      }
    }

    
    final lossProfitRef =
    db.collection('collection name').doc(userId).collection('collection name');

    for (final product in products) {
      final productName = product['name'];
      final double saleStock = product['quantity'].toDouble();
      final double productTotalPrice = product['total_price'].toDouble();
      final double purchasePrice = product['purchase_price'].toDouble();
      final double profitPerProduct =
          productTotalPrice - (purchasePrice * saleStock);

      totalProfit += profitPerProduct;

      final lossProfitQuery = await lossProfitRef
          .where('name', isEqualTo: productName)
          .limit(1)
          .get();
      if (lossProfitQuery.docs.isNotEmpty) {
        final docRef = lossProfitQuery.docs.first.reference;
        batch.update(docRef, {
          'sale_stock': FieldValue.increment(-saleStock),
          'sale_netTotal': FieldValue.increment(-productTotalPrice),
          'field name': FieldValue.increment(-profitPerProduct),
        });
      }
    }

    
    final dailyPath = "${saleTime.year}-${saleTime.month}-${saleTime.day}";
    final monthlyPath = "${saleTime.year}-${saleTime.month}";
    final yearlyPath = "${saleTime.year}";

    await db.runTransaction((transaction) async {
      
      await _updateTotals(transaction, userId, 'collection name', dailyPath,
          -payment, -totalPrice, -due, -totalProfit);
      await _updateTotals(transaction, userId, 'collection name', monthlyPath, 0,
          -totalPrice, 0, -totalProfit);
      await _updateTotals(transaction, userId, 'collection name', yearlyPath, 0,
          -totalPrice, 0, -totalProfit);
      await _updateTotals(transaction, userId, 'collection name', 'doc id/name',
          -payment, 0, -due, -totalProfit);
    });

    
    batch.delete(saleRef);
    batch.delete(db
        .collection('collection name')
        .doc(userId)
        .collection('cashbox')
        .doc(saleDocId));
    batch.delete(db
        .collection('collection name')
        .doc(userId)
        .collection('dealers')
        .doc(saleDocId));

    await batch.commit();
    debugPrint("✅ বিক্রয় ডিলিট, স্টক আপডেট, লাভ-ক্ষতি ঠিক করা হয়েছে।");
  } catch (e) {
    debugPrint("❗ত্রুটি ঘটেছে: $e");
  }
}


Future<void> _updateTotals(
    Transaction transaction,
    String userId,
    String collectionPath,
    String documentPath,
    double payment,
    double totalPrice,
    double due,
    double profit,
    ) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final DocumentReference<Map<String, dynamic>> docRef = db
      .collection('collection name')
      .doc(userId)
      .collection(collectionPath)
      .doc(documentPath);

  
  transaction.update(docRef, {
    'sale_total': FieldValue.increment(totalPrice),
    'field name': FieldValue.increment(profit),
    if (collectionPath == 'collection name')
      'sale_paid': FieldValue.increment(payment),
    if (collectionPath == 'collection name' ||
        (collectionPath == 'collection name' && documentPath == 'doc id/name'))
      'total_due': FieldValue.increment(due),
  });
}
