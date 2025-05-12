import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../barcode/barcode_service.dart';
import '../product/dialogs.dart';
import '../product/product_model.dart';

Widget buildSearchField(Function(String) onSearch) {
  return Material(
    elevation: 5,
    shadowColor: Colors.grey.withOpacity(0.2),
    borderRadius: BorderRadius.circular(10),
    child: TextField(
      decoration: InputDecoration(
        labelText: 'প্রোডাক্ট খুঁজুন',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: onSearch,
    ),
  );
}

void showEditProductDialog(BuildContext context, FirebaseFirestore firestore,
    String userId, String docId, Product product) {
  final TextEditingController nameController =
  TextEditingController(text: product.name);
  final TextEditingController salePriceController =
  TextEditingController(text: product.salePrice.toString());
  final TextEditingController barcodeController =
  TextEditingController(text: product.barcode ?? '');
  final TextEditingController supplierNameController =
  TextEditingController(text: product.supplierName ?? '');
  final TextEditingController supplierPhoneController =
  TextEditingController(text: product.supplierPhone ?? '');

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Center(
          child: Text(
            'প্রোডাক্ট এডিট করুন',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'প্রোডাক্টের নাম',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                minLines: 1,
                maxLines: 2,
                keyboardType: TextInputType
                    .multiline,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: salePriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'বিক্রয়মূল্য',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: supplierNameController,
                decoration: InputDecoration(
                  labelText: 'সাপ্লায়ারের নাম',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: supplierPhoneController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(
                      11),
                ],
                decoration: InputDecoration(
                  labelText: 'সাপ্লায়ারের নাম্বার',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && value.length != 11) {
                    print(
                        'Invalid phone number: Must be either 11 digits or empty.');
                  } else {
                    print('Valid phone number.');
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: barcodeController,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'বারকোড',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon:
                    const Icon(Icons.qr_code_scanner, color: Colors.green),
                    onPressed: () async {
                      if (product.barcode != null &&
                          product.barcode!.isNotEmpty) {
                        final bool shouldEdit = await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('বারকোড সম্পাদনা'),
                              content: const Text(
                                  'বারকোড ইতিমধ্যে সেট করা হয়েছে। এটি সম্পাদনা করতে চান?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(false);
                                  },
                                  child: const Text('না'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(true);
                                  },
                                  child: const Text('হ্যাঁ'),
                                ),
                              ],
                            );
                          },
                        ) ??
                            false;

                        if (!shouldEdit) return;
                      }

                      final String? scannedBarcode =
                      await BarcodeService.scanBarcode(context);
                      if (scannedBarcode != null) {
                        barcodeController.text = scannedBarcode;
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('বাতিল করুন'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                showErrorDialog(context, 'প্রোডাক্টের নাম আবশ্যক।', () {});
                return;
              }
              final phone = supplierPhoneController.text.trim();
              if (phone.isNotEmpty && phone.length != 11) {
                showErrorDialog(
                    context, 'ফোন নাম্বারটি খালি বা ১১ ডিজিট হতে হবে।', () {});
                return;
              }
              if (barcodeController.text.trim().isNotEmpty) {
                final duplicateBarcode = await firestore
                    .collection('collection name')
                    .doc(userId)
                    .collection('collection name')
                    .where('field name', isEqualTo: barcodeController.text.trim())
                    .get();

                if (duplicateBarcode.docs.isNotEmpty &&
                    duplicateBarcode.docs.first.id != docId) {
                  final matchedProductName =
                      duplicateBarcode.docs.first['field name'] ?? 'অজানা প্রোডাক্ট';
                  showErrorDialog(
                    context,
                    'এই বারকোডটি ইতিমধ্যে \"$matchedProductName\"-এ ব্যবহৃত হয়েছে।',
                        () {},
                  );
                  return;
                }
              }
              try {
                await firestore
                    .collection('collection name')
                    .doc(userId)
                    .collection('collection name')
                    .doc(docId)
                    .update({
                  'field name': nameController.text.trim(),
                  'field name': supplierNameController.text.trim(),
                  'field name': supplierPhoneController.text.trim(),
                  'field name': double.parse(salePriceController.text.trim()),
                  'field name': barcodeController.text.trim(),
                });

                Navigator.of(context).pop();
                showSuccessDialog(context, 'প্রোডাক্ট সফলভাবে আপডেট হয়েছে।');
              } catch (e) {
                showErrorDialog(context, 'আপডেট করতে সমস্যা হয়েছে: $e', () {});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'সংরক্ষণ করুন',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );
}

void showSuccessDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text(
          'সফলভাবে সম্পন্ন',
          style: TextStyle(color: Colors.green),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('ঠিক আছে'),
          ),
        ],
      );
    },
  );
}
