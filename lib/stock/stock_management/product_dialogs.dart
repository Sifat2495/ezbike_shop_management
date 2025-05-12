import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/all_common_functions.dart';
import '../product/product_model.dart';

void showStockEditDialog(BuildContext context, FirebaseFirestore firestore,
    String userId, String docId, Product product) {
  TextEditingController stockController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return LayoutBuilder(
        builder: (context, constraints) {
          double dialogWidth = constraints.maxWidth * 0.9;
          double dialogHeight = constraints.maxHeight * 0.5;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: EdgeInsets.zero,
            titlePadding: EdgeInsets.zero,
            title: Container(
              width: dialogWidth,
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${product.name}-এর',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                          softWrap:
                          true,
                          overflow: TextOverflow
                              .ellipsis,
                          maxLines: 2,
                        ),
                        Text(
                          'স্টক হালনাগাদ',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(
                            height: 4),
                        Text(
                          'স্টক: ${convertToBengaliNumbers(product.stock.toString())} পিস',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          softWrap:
                          true,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      Navigator.of(context).pop();
                      showDeleteConfirmation(context, firestore, userId,
                          docId);
                    },
                  ),
                ],
              ),
            ),
            content: SizedBox(
              width: dialogWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0),
                    child: TextField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'পরিমাণ লিখুন',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            actions: [
              Padding(
                padding:
                const EdgeInsets.only(bottom: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _updateStockAmount(firestore, userId, docId, product,
                            stockController.text, 'add');
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(
                          vertical: dialogHeight * 0.02,
                          horizontal: dialogWidth * 0.05,
                        ),
                        minimumSize: Size(
                          dialogWidth * 0.3,
                          dialogHeight * 0.06,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'যোগ করুন',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 1),
                    ElevatedButton(
                      onPressed: () {
                        _updateStockAmount(firestore, userId, docId, product,
                            stockController.text, 'subtract');
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(
                          vertical: dialogHeight * 0.02,
                          horizontal: dialogWidth * 0.05,
                        ),
                        minimumSize: Size(
                          dialogWidth * 0.3,
                          dialogHeight * 0.06,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'কমিয়ে ফেলুন',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 1),
                    ElevatedButton(
                      onPressed: () {
                        _updateStockAmount(firestore, userId, docId, product,
                            stockController.text, 'update');
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(
                          vertical: dialogHeight * 0.02,
                          horizontal: dialogWidth * 0.05,
                        ),
                        minimumSize: Size(
                          dialogWidth * 0.3,
                          dialogHeight * 0.06,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'নতুন স্টক হিসাবে আপডেট করুন',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

void showDeleteConfirmation(BuildContext context, FirebaseFirestore firestore,
    String userId, String docId) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text(
              'ডিলিট করুন',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: const Text(
          'আপনি কি প্রোডাক্টটি ডিলিট করে দিতে চান?',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'না',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    deleteProduct(firestore, userId, docId);
                    Navigator.of(context)
                        .pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'হ্যাঁ',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

void deleteProduct(
    FirebaseFirestore firestore, String userId, String docId) async {
  final productDocRef =
  firestore.collection('collection name').doc(userId).collection('collection name').doc(docId);

  final totalStockPricedocref = firestore
      .collection('collection name')
      .doc(userId)
      .collection('collection name')
      .doc('doc name');

  await firestore.runTransaction((transaction) async {
    final productSnapshot = await transaction.get(productDocRef);

    if (productSnapshot.exists) {
      final productData = productSnapshot.data();
      final productTotalPrice = (productData?['field name'] ?? 0.0) *
          (productData?['field name'] ?? 0.0);

      final totalStockPricesnapshot =
      await transaction.get(totalStockPricedocref);
      if (totalStockPricesnapshot.exists) {
        final currentTotal =
            totalStockPricesnapshot.data()?['field name'] ?? 0.0;

        transaction.update(totalStockPricedocref, {
          'field name': currentTotal - productTotalPrice,
        });
      }
      final productImageUrls = productData?['field name'] as List?;
      if (productImageUrls != null && productImageUrls.isNotEmpty) {
        try {
          for (var imageUrl in productImageUrls) {
            final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
            await storageRef.delete();
          }
        } catch (e) {
          print('Error deleting image: $e');
        }
      }
    }


    transaction.delete(productDocRef);
  });
}

void _updateStockAmount(
    FirebaseFirestore firestore,
    String userId,
    String docId,
    Product product,
    String input,
    String action,
    ) async {
  double inputAmount = double.tryParse(input) ?? 0.0;
  double updatedStock = product.stock.toDouble();
  double priceChange = 0.0;

  if (action == 'add') {
    updatedStock += inputAmount;
    priceChange = inputAmount * product.purchasePrice;
  } else if (action == 'subtract') {
    updatedStock -= inputAmount;
    priceChange = -(inputAmount *
        product.purchasePrice);
  } else if (action == 'update') {
    priceChange = (inputAmount - updatedStock) *
        product.purchasePrice;
    updatedStock = inputAmount;
  }

  await firestore
      .collection('collection name')
      .doc(userId)
      .collection('collection name')
      .doc(docId)
      .update({'field name': updatedStock});

  final yearlyTotalsDoc = firestore
      .collection('collection name')
      .doc(userId)
      .collection('collection name')
      .doc('doc name');

  await firestore.runTransaction((transaction) async {
    final docSnapshot = await transaction.get(yearlyTotalsDoc);

    if (!docSnapshot.exists) {
      transaction.set(yearlyTotalsDoc, {
        'field name': priceChange,
      });
    } else {
      final currentTotal = docSnapshot.data()?['field name'] ?? 0.0;
      transaction.update(yearlyTotalsDoc, {
        'field name': currentTotal + priceChange,
      });
    }
  });
}
