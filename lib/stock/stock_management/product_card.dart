import 'package:bebshar_poristhiti_stock/stock/stock_management/search_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/all_common_functions.dart';
import '../product/product_model.dart';
import 'dialogs/product_details_dialog.dart';
import 'product_dialogs.dart';
import 'package:intl/intl.dart';

String formatPrice(double price) {
  final formatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: '',
    decimalDigits:
    (price % 1 == 0) ? 0 : 2,
  );
  return formatter.format(price);
}

Future<bool> showPinVerificationDialog(
    BuildContext context, String? savedPin) async {
  String enteredPin = '';

  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('পিন যাচাই করুন'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('দয়া করে আপনার পিন ইনপুট করুন:'),
            TextField(
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              onChanged: (value) {
                enteredPin = value;
              },
              decoration: const InputDecoration(
                hintText: 'পিন লিখুন',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('বাতিল'),
          ),
          TextButton(
            onPressed: () {
              if (enteredPin == savedPin) {
                Navigator.of(context).pop(true);
              } else {
                showGlobalSnackBar(context,'পিন ভুল!');
                }
            },
            child: const Text('যাচাই করুন'),
          ),
        ],
      );
    },
  ) ??
      false;
}

Widget buildProductCard(BuildContext context, FirebaseFirestore firestore,
    String userId, Product product, String docId) {
  return GestureDetector(
    onTap: () {
      showProductDetailsDialogStock(context, product, docId, userId);
    },
    child: Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: const Color.fromARGB(255, 240, 255, 252),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          children: [
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'প্রতি এককের মূল্য: ${convertToBengaliNumbers(formatPrice(product.purchasePrice))} ৳',
                    style: TextStyle(color: Colors.grey[900], fontSize: 13),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'স্টক:\n ${convertToBengaliNumbers(product.stock.toString())}',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(width: 2),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 24, color: Colors.grey),
                  color: const Color.fromARGB(
                      255, 214, 250, 243),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onSelected: (String value) async {
                    final userId = FirebaseAuth.instance.currentUser?.uid;

                    if (userId == null) {
                      showGlobalSnackBar(context,'ইউজার সনাক্ত করা যায়নি।');
                      return;
                    }

                    final DocumentSnapshot userDoc = await FirebaseFirestore.instance
                        .collection('collection name')
                        .doc(userId)
                        .get();

                    if (userDoc.exists) {
                      final bool isStock = userDoc['field name'] ?? false;
                      final String? savedPin = userDoc['field name'];

                      if (isStock) {
                        final bool isPinVerified =
                        await showPinVerificationDialog(context, savedPin);

                        if (!isPinVerified) {
                          return;
                        }
                      }
                    } else {
                      showGlobalSnackBar(context,'ইউজারের তথ্য পাওয়া যায়নি।');
                      return;
                    }

                    switch (value) {
                      case 'Edit':
                        showStockEditDialog(context, firestore, userId, docId,
                            product);
                        break;
                      case 'Edit Product':
                        showEditProductDialog(context, firestore, userId, docId, product);
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem<String>(
                        value: 'Edit',
                        child: Row(
                          children: const [
                            Icon(Icons.edit, color: Colors.green, size: 18),
                            SizedBox(width: 8),
                            Text('স্টক এডিট/ডিলিট'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'Edit Product',
                        child: Row(
                          children: const [
                            Icon(Icons.edit_document, color: Colors.teal, size: 18),
                            SizedBox(width: 2),
                            Text('প্রোডাক্ট এডিট'),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
