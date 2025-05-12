import 'dart:io';
import 'package:bebshar_poristhiti_stock/stock/product/product_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/all_common_functions.dart';
import '../../widgets/calculator_page.dart';
import '../../widgets/image_upload_service.dart';
import '../barcode/barcode_service.dart';
import 'form_widgets.dart';
import 'dialogs.dart';
import 'package:flutter/services.dart';

class ProductPage extends StatefulWidget {
  final Product? existingProduct;

  ProductPage({this.existingProduct});

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _purchasePriceController =
  TextEditingController();
  final TextEditingController _salePriceController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  bool _isSubmitting = false;
  final List<File> _selectedPhotos = [];
  final List<String> _uploadedPhotoUrls = [];

  Future<void> _pickPhoto() async {
    if (_selectedPhotos.length >= 2) {
      showErrorDialog(context, '২টি ছবি আপলোড করতে পারবেন', () {});
      return;
    }

    final pickedPhoto = await FirebasePhotoService.pickPhoto(context);

    if (pickedPhoto != null) {
      setState(() {
        _selectedPhotos.add(pickedPhoto);
      });
    }
  }

  Future<void> scanBarcode() async {
    final barcodeValue = await BarcodeService.scanBarcode(context);
    if (barcodeValue != null && barcodeValue.isNotEmpty) {
      final userProductsCollection =
      _firestore.collection('collection').doc(userId).collection('collection');
      final existingBarcode = await userProductsCollection
          .where('field name', isEqualTo: barcodeValue)
          .get();

      if (existingBarcode.docs.isNotEmpty) {
        final matchedProductName =
            existingBarcode.docs.first['field name'] ?? 'Unknown Product';

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Duplicate Barcode'),
              content: Text(
                  'The scanned barcode already exists in "$matchedProductName".'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        setState(() {
          _barcodeController.text = barcodeValue;
        });
      }
    }
  }

  void _removeSelectedImage(dynamic image) {
    setState(() {
      _selectedPhotos.remove(image);
    });
  }

  Future<void> _uploadPhoto(String stockId) async {
    if (_selectedPhotos.isEmpty) return;

    try {
      final photoService = FirebasePhotoService();
      final urls = await photoService.uploadPhotos(
        photos: _selectedPhotos,
        documentPath: 'collection/$userId/collection/$stockId',
        fieldName: 'field name',
      );

      if (urls.isNotEmpty) {
        setState(() {
          _uploadedPhotoUrls.addAll(urls);
          _selectedPhotos.clear();
        });
      }
    } catch (e) {
      showErrorDialog(context, 'Failed to upload photo: $e', () {});
    }
  }

  void _addProduct() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });

    showLoadingDialog(context, message: 'প্রোডাক্ট যুক্ত হচ্ছে...');

    if (_nameController.text.trim().isEmpty) {
      showErrorDialog(context, 'Product name is required.', () {
        setState(() {
          _isSubmitting = false;
        });
      });
      return;
    }

    final product = Product(
      barcode: _barcodeController.text.trim(),
      name: _nameController.text.trim(),
      purchasePrice: double.tryParse(_purchasePriceController.text.trim()) ?? 0,
      salePrice: double.tryParse(_salePriceController.text.trim()) ?? 0,
      stock: 0.0,
      supplierName: '',
      supplierPhone: '',
      photoUrls: _uploadedPhotoUrls,
    );

    final userProductsCollection =
    _firestore.collection('collection').doc(userId).collection('collection');

    final existingProduct = await userProductsCollection
        .where('field name', isEqualTo: product.name.trim())
        .get();

    if (existingProduct.docs.isNotEmpty) {
      showProductExistsDialog(context);
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    final existingProductBarcode = await userProductsCollection
        .where('field name', isEqualTo: product.barcode?.trim() ?? '')
        .get();

    final validBarcodes = existingProductBarcode.docs.where((doc) {
      final barcode = (doc.data()['field name'] ?? '').toString().trim();
      return barcode.isNotEmpty;
    }).toList();

    if (validBarcodes.isNotEmpty) {
      showProductExistsDialog(context);
      setState(() {
        _isSubmitting = false;
      });
      return;
    }
    try {
      final docRef = await userProductsCollection.add(product.toMap());
      if (_selectedPhotos.isNotEmpty) {
        await _uploadPhoto(docRef.id);
      }

      final yearlyTotalsDoc = _firestore
          .collection('collection')
          .doc(userId)
          .collection('collection')
          .doc('document name/id');

      await _firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(yearlyTotalsDoc);

        if (!docSnapshot.exists) {
          transaction.set(yearlyTotalsDoc, {
            'field name': product.stock * product.purchasePrice,
          });
        } else {
          final currentTotal = docSnapshot.data()?['field name'] ?? 0.0;
          transaction.update(yearlyTotalsDoc, {
            'field name': currentTotal + (product.stock * product.purchasePrice),
          });
        }
      });

      hideLoadingDialog(context);
      showProductDetailsDialog(context, product, () {
        setState(() {
          _nameController.clear();
          _purchasePriceController.clear();
          _salePriceController.clear();
          _barcodeController.clear();
          _selectedPhotos.clear();
          _uploadedPhotoUrls.clear();
        });
        FocusScope.of(context).unfocus();
      });
    } catch (e) {
      hideLoadingDialog(context);
       showErrorDialog(context, 'An error occurred. Please try again.', () {
        setState(() {
          _isSubmitting = false;
        });
      });
    }

     setState(() {
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(122, 3, 180, 148),
        elevation: 0,
        title: Text(
          '  প্রোডাক্ট যুক্ত করুন',
          textAlign: TextAlign.start,
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.close, size: 30),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),

      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  labelText: 'Barcode',
                  suffixIcon: GestureDetector(
                    onTap: scanBarcode,
                    child: Icon(Icons.qr_code_scanner),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              buildTitle('প্রোডাক্টের বিস্তারিত'),
              SizedBox(height: screenHeight * 0.01),
              buildTextField(
                _nameController,
                'প্রোডাক্টের নাম',
                'প্রোডাক্টের নাম লিখুন',
                Icons.shopping_bag_outlined,
                maxLines: null,
                inputFormatters: [],
              ),

              SizedBox(height: screenHeight * 0.01),
              buildTextField(
                _purchasePriceController,
                'প্রতি পিসের ক্রয়মূল্য',
                'ক্রয়মূল্য লিখুন',
                Icons.attach_money_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.calculate,
                    size: 35.0,
                  ),
                   onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => CalculatorPage(
                        onValueSelected: (value) {
                           _purchasePriceController.text = value.toString();
                        },
                      ),
                    );
                  },
                ),
              ),


              SizedBox(height: screenHeight * 0.01),
              buildTextField(
                _salePriceController,
                'বিক্রয়মূল্য',
                'বিক্রয়মূল্য লিখুন',
                Icons.attach_money_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),

              SizedBox(height: screenHeight * 0.01),
              FirebasePhotoService.getImagePreview(
                images: _selectedPhotos,
                onRemoveImage:
                _removeSelectedImage,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   SizedBox(
                    width: screenWidth * 0.33,
                    child: ElevatedButton(
                      onPressed: _pickPhoto,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.teal,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'ছবি আপলোড',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                   SizedBox(
                    width: screenWidth * 0.33,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _addProduct,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: _isSubmitting ? Colors.grey : Colors.teal,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        _isSubmitting ? 'যুক্ত হচ্ছে' : 'যুক্ত করুন',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
