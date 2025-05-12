import 'dart:io';
import 'package:bebshar_poristhiti_stock/purchase_management/stock_purchase/purchase_receipt_dialog.dart';
import 'package:flutter/material.dart';
import '../../sms/SMSHelper.dart';
import '../../stock/product/dialogs.dart';
import '../../widgets/all_common_functions.dart';
import '../../widgets/image_upload_service.dart';
import 'supplier_selection_page.dart';
import 'purchase_product_selection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PurchaseStockPage extends StatefulWidget {
  const PurchaseStockPage({super.key});

  @override
  _PurchaseStockPageState createState() => _PurchaseStockPageState();
}

class _PurchaseStockPageState extends State<PurchaseStockPage> {
  bool isSmsActive = false;
  bool isKeyboardVisible = false;
  late FocusNode cashPaymentFocusNode;
  bool isProcessing = false;
  bool isPermissionGranted = false;
  String selectedSupplierName = '';
  String selectedSupplierPhone = '';
  double selectedPreviousTransaction = 0.0;
  double purchaseAmount = 0.0;
  double cashPayment = 0.0;
  String? selectedSupplierId;
  List<File> selectedPhotos = [];
  List<String> uploadedPhotoUrls = [];
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  List<TextEditingController> priceControllers = [];
  List<TextEditingController> stockControllers = [];
  List<Map<String, dynamic>> selectedProducts = [];
  double totalStockAmount = 0.0;
  double get totalProductPrice => selectedProducts.fold(
      0,
          (sum, product) =>
      sum + (product['purchase_price'] * product['purchase_stock']));

  double get grandTotal => selectedPreviousTransaction + totalProductPrice;
  final TextEditingController cashPaymentController = TextEditingController();

  @override
  void initState() {
    _checkUserPermission();
    super.initState();
    cashPaymentFocusNode = FocusNode();
    cashPaymentFocusNode.addListener(() {
      setState(() {
        isKeyboardVisible = cashPaymentFocusNode.hasFocus; 
      });
    });
  }

  Future<void> _checkUserPermission() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('collection name').doc(uid).get();

      if (userDoc.exists) {
        setState(() {
          isPermissionGranted = userDoc['permission'] ??
              false; 
        });
      }
    }
  }

  @override
  void dispose() {
    cashPaymentController.dispose();
    for (var controller in priceControllers) {
      controller.dispose();
    }
    for (var controller in stockControllers) {
      controller.dispose();
    }
    cashPaymentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (selectedPhotos.length >= 2) {
      showErrorDialog(context, '২টি ছবি আপলোড করতে পারবেন', () {});
      return; 
    }

    
    final pickedPhoto = await FirebasePhotoService.pickPhoto(context);

    if (pickedPhoto != null) {
      setState(() {
        
        if (selectedPhotos.length >= 2) {
          selectedPhotos.clear(); 
        }
        selectedPhotos.add(pickedPhoto); 
      });
    }
  }

  Future<void> _uploadPhoto(String purchasesId) async {
    if (selectedPhotos.length > 2) {
      showErrorDialog(context, 'আপনার দুটি ছবি নির্বাচন করুন', () {});
      return; 
    }

    try {
      final photoService = FirebasePhotoService();
      final urls = await photoService.uploadPhotos(
        photos: selectedPhotos,
        documentPath: 'collection name/$userId/purchases/$purchasesId',
        fieldName: 'purchase_photo',
      );

      if (urls.isNotEmpty) {
        setState(() {
          uploadedPhotoUrls.addAll(urls);
          selectedPhotos.clear(); 
        });
      }
    } catch (e) {
      showErrorDialog(context, 'Failed to upload photo: $e', () {});
    }
  }

  void showImagePreviewDialog({
    required BuildContext context,
    required List<dynamic> images, 
    required Function(dynamic image) onRemoveImage, 
  }) {
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Preview Images",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (images.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "No images selected.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              else
                Flexible(
                  child: SingleChildScrollView( 
                    child: Column(
                      children: [
                        for (var image in images)
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: image is File
                                    ? Image.file(
                                  image,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                )
                                    : Image.network(
                                  image,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              
                              Positioned(
                                top: 5,
                                right: 5,
                                child: GestureDetector(
                                  onTap: () {
                                    
                                    onRemoveImage(image); 
                                    Navigator.of(context).pop(); 
                                    
                                    Future.delayed(const Duration(milliseconds: 100), () {
                                      showImagePreviewDialog(
                                        context: context,
                                        images: List.from(images), 
                                        onRemoveImage: onRemoveImage,
                                      );
                                    });
                                  },
                                  child: const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Close"),
              ),
            ],
          ),
        );
      },
    );
  }


  void onRemoveImage(dynamic image) {
    setState(() {
      selectedPhotos.remove(image); 
    });
  }

  void _showPurchaseReceipt(BuildContext context) {
    if (selectedProducts.isEmpty) {
      showGlobalSnackBar(context,'কোনো পণ্য নির্বাচন করা হয়নি।');
      return;
    }

    
    showDialog(
      context: context,
      barrierDismissible: true, 
      builder: (BuildContext context) {
        return PopScope(
          canPop: true, 
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              
              setState(() {
                selectedProducts.clear();
                purchaseAmount = 0.0;
                cashPayment = 0.0;
                cashPaymentController.clear();
                selectedSupplierName = '';
                selectedSupplierPhone = '';
                selectedPreviousTransaction = 0.0;
                selectedSupplierId = null;
                isProcessing = false;
                FocusScope.of(context).unfocus();
              });
            }
          },
          child: ReceiptDialog(
            supplierName: selectedSupplierName,
            supplierPhone: selectedSupplierPhone,
            totalAmount: totalProductPrice,
            cashPayment: cashPayment,
            remainingAmount: grandTotal - cashPayment,
            grandTotal: grandTotal,
            selectedPreviousTransaction: selectedPreviousTransaction,
            purchaseDate: DateTime.now().toLocal().toString(),
            selectedProducts: selectedProducts,
            resetStateCallback: () {
              
              setState(() {
                selectedProducts.clear();
                purchaseAmount = 0.0;
                cashPayment = 0.0;
                cashPaymentController.clear();
                selectedSupplierName = '';
                selectedSupplierPhone = '';
                selectedPreviousTransaction = 0.0;
                selectedSupplierId = null;
                isProcessing = false;
                Navigator.of(context).pop();
                FocusScope.of(context).unfocus();
              });
            },
          ),
        );
      },
    );
  }

  String formatProductDetails(List<Map<String, dynamic>> selectedProducts) {
    List<String> productDetails = [];

    for (var product in selectedProducts) {
      double total = product['purchase_price'] * product['purchase_stock'];
      productDetails.add(
        '${product['name']} ${product['purchase_price']} X ${product['purchase_stock']} = $total',
      );
    }

    return productDetails.join('\n');
  }


  
  void _purchaseProducts() async {
    if (isPermissionGranted) {
      if (isProcessing) return;

      setState(() {
        isProcessing = true;
      });

      DateTime now = DateTime.now();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final dueAmount = grandTotal - cashPayment;
      var totalsDue = totalProductPrice - cashPayment;
      if (userId == null) {
        showGlobalSnackBar(context,'ইউজার লগ ইন নেই।');
        return;
      }

      if (selectedProducts.isEmpty) {
        showGlobalSnackBar(context,'দয়া করে পণ্য যুক্ত করুন।');
        return;
      }

      if (selectedSupplierName.isEmpty) {
        cashPayment = totalProductPrice;
        totalsDue = 0.0;
      } else {
        if(isSmsActive) {
          final shouldSendSMS =
          await SMSHelper.checkAndShowSMSWarning(context: context);
          if (shouldSendSMS) {
            await SMSHelper.sendSMS(
              phoneNumber: selectedSupplierPhone,
              message: 'ক্রয় ${totalProductPrice.toStringAsFixed(0)}, পরিশোধ ${cashPayment
                  .toStringAsFixed(0)}, বর্তমান দেনা: ${dueAmount.toStringAsFixed(0)}',
            );
          } else {
            setState(() {
              isSmsActive = false;
            });
          }
        }
      }

      try {
        await updateLossProfitCollection(
          selectedProducts,
          supplierName: selectedSupplierName.isEmpty
              ? null
              : selectedSupplierName, 
          supplierPhone: selectedSupplierPhone.isEmpty
              ? null
              : selectedSupplierPhone, 
        );

        String docId = '';  
        final supplierDocRef = await FirebaseFirestore.instance
            .collection('collection name')
            .doc(userId)
            .collection('suppliers')
            .where('phone', isEqualTo: selectedSupplierPhone)
            .limit(1)
            .get();

        if (supplierDocRef.docs.isNotEmpty) {
          docId = supplierDocRef.docs.first.id;
        }

        double updatedTransaction =
            selectedPreviousTransaction + totalProductPrice - cashPayment;
        if (selectedSupplierPhone.isNotEmpty) {
          final supplierRef = FirebaseFirestore.instance
              .collection('collection name')
              .doc(userId)
              .collection('suppliers')
              .doc(docId);  
          await supplierRef.update({
            'supplier_due': updatedTransaction,
          });
        }

        final purchaseDocRef = await FirebaseFirestore.instance
            .collection('collection name')
            .doc(userId)
            .collection('purchases')
            .add({
          'name': selectedSupplierName,
          'phone': selectedSupplierPhone,
          'totalPrice': totalProductPrice,
          'previousDue': selectedPreviousTransaction,
          'priceWithDue': grandTotal,
          'payment': cashPayment,
          'due': dueAmount,
          'products': selectedProducts,
          'time': now,
          'purchase_photo': uploadedPhotoUrls,
        });

        
        await _uploadPhoto(purchaseDocRef.id);
        if (docId.isNotEmpty) {
          
          String productDetailsString = formatProductDetails(selectedProducts);

          await FirebaseFirestore.instance
              .collection('collection name')
              .doc(userId)
              .collection('suppliers')
              .doc(docId)
              .collection('history')
              .add({
            'name': selectedSupplierName,
            'phone': selectedSupplierPhone,
            'amount': totalProductPrice,
            'payment': cashPayment,
            'due': dueAmount,
            'details': productDetailsString,  
            'time': now,
            'purchase_photo': uploadedPhotoUrls,  
          });
        }

        
        await FirebaseFirestore.instance
            .collection('collection name')
            .doc(userId)
            .collection('cashbox')
            .add({
          'amount': -cashPayment,
          'reason':
          'ক্রয়ঃ $selectedSupplierName এর থেকে $totalProductPrice টাকার পণ্য ক্রয় করে বর্তমান দেনা $updatedTransaction টাকা।',
          'time': now,
        });

        
        final dailyDocRef = FirebaseFirestore.instance
            .collection('collection name')
            .doc(userId)
            .collection('collection name')
            .doc('${now.year}-${now.month}-${now.day}');

        await dailyDocRef.set({
          'purchase_total': FieldValue.increment(totalProductPrice),
          'supplier_due': FieldValue.increment(totalsDue),
          'purchase_paid': FieldValue.increment(cashPayment),
          'date': now,
        }, SetOptions(merge: true));

        
        final monthlyDocRef = FirebaseFirestore.instance
            .collection('collection name')
            .doc(userId)
            .collection('collection name')
            .doc('${now.year}-${now.month}');

        await monthlyDocRef.set({
          'purchase_total': FieldValue.increment(totalProductPrice),
          'month': now.month,
          'year': now.year,
        }, SetOptions(merge: true));

        
        final yearlyDocRef = FirebaseFirestore.instance
            .collection('collection name')
            .doc(userId)
            .collection('collection name')
            .doc('${now.year}');

        await yearlyDocRef.set({
          'purchase_total': FieldValue.increment(totalProductPrice),
          'purchase_paid': FieldValue.increment(cashPayment),
          'year': now.year,
        }, SetOptions(merge: true));

        
        final allTimeDocRef = FirebaseFirestore.instance
            .collection('collection name')
            .doc(userId)
            .collection('collection name')
            .doc('doc id/name'); 

        await allTimeDocRef.set({
          'supplier_due': FieldValue.increment(totalsDue),
          'cashbox_total': FieldValue.increment(-cashPayment),
          'total_stock_price': FieldValue.increment(totalProductPrice),
        }, SetOptions(merge: true));

        showGlobalSnackBar(context,'ক্রয় সফল হয়েছে!');
      } catch (e) {
        showGlobalSnackBar(context, 'কেনাকাটা সম্পন্ন করতে সমস্যা হয়েছে: $e');
        } finally {
        setState(() {
          isProcessing = false;
        });
      }
    } else {
      
      showGlobalSnackBar(context,'দয়া করে পেমেন্ট করুন অথবা হেল্প লাইনে যোগাযোগ করুন');
    }
    _showPurchaseReceipt(context);
  }

  void _openSupplierSelection(BuildContext context) async {
    final selectedSupplier = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), 
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SupplierSelectionPage(),
          ),
        ),
      ),
    );

    if (selectedSupplier != null) {
      setState(() {
        selectedSupplierName = selectedSupplier['name'];
        selectedSupplierPhone = selectedSupplier['phone'];
        selectedPreviousTransaction = selectedSupplier['supplier_due'];
        selectedSupplierId = selectedSupplier['id'];
      });
    }
  }

  void _openProductSelection(BuildContext context) async {
    final selectedProduct = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: ProductSelectionPage(),
          ),
        ),
      ),
    );

    if (selectedProduct != null) {
      bool isProductAlreadySelected = selectedProducts
          .any((product) => product['name'] == selectedProduct['name']);

      if (!isProductAlreadySelected) {
        setState(() {
          totalStockAmount = selectedProduct['collection name'];
          selectedProducts.insert(0, {
            'name': selectedProduct['name'],
            'purchase_price': selectedProduct['purchase_price'],
            'collection name': totalStockAmount,
            'purchase_stock': 1,
            'netTotal': 1 * selectedProduct['purchase_price'],
          });
          priceControllers.insert(
              0,
              TextEditingController(
                  text: selectedProduct['purchase_price'].toStringAsFixed(0)));
          stockControllers.insert(0, TextEditingController(text: '1'));
          updateProducttotalAmount(0, '1');
        });
      }
    }
  }

  void updateProductPrice(int index, String value) {
    setState(() {
      double newPrice =
          double.tryParse(value) ?? selectedProducts[index]['purchase_price'];
      selectedProducts[index]['purchase_price'] = newPrice;

      
      selectedProducts[index]['netTotal'] =
          selectedProducts[index]['purchase_stock'] * newPrice;

      purchaseAmount = totalProductPrice;
    });
  }

  void updateProducttotalAmount(int index, String value) {
    setState(() {
      double newtotalAmount = double.tryParse(value) ?? 1.0;
      selectedProducts[index]['purchase_stock'] = newtotalAmount;

      
      selectedProducts[index]['netTotal'] =
          newtotalAmount * selectedProducts[index]['purchase_price'];

      purchaseAmount = totalProductPrice;
    });
  }

  void removeProduct(int index) {
    setState(() {
      selectedProducts.removeAt(index);
      priceControllers[index]
          .dispose(); 
      priceControllers.removeAt(index);
      stockControllers[index]
          .dispose(); 
      stockControllers
          .removeAt(index); 
    });
  }

  Future<void> updateLossProfitCollection(
      List<Map<String, dynamic>> selectedProducts, {
        String? supplierName, 
        String? supplierPhone, 
      }) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    DateTime now = DateTime.now();

    final CollectionReference lossProfitCollection =
    firestore.collection('collection name').doc(userId).collection('collection name');
    final CollectionReference stockCollection =
    firestore.collection('collection name').doc(userId).collection('collection name');

    for (var product in selectedProducts) {
      final String productName = product['name'];
      final double purchaseStock = (product['purchase_stock'] ?? 0) as double;
      final double purchaseNetTotal = (product['netTotal'] ?? 0.0) as double;

      
      final QuerySnapshot existingDocs = await lossProfitCollection
          .where('name', isEqualTo: productName)
          .limit(1)
          .get();

      double averagePrice;

      if (existingDocs.docs.isNotEmpty) {
        final docRef = existingDocs.docs.first.reference;
        final existingData =
        existingDocs.docs.first.data() as Map<String, dynamic>;

        final double existingPurchaseStock = (existingData['purchase_stock'] ?? 0.0) as double;
        final double existingPurchaseNetTotal = (existingData['purchase_netTotal'] ?? 0.0) as double;

        final double updatedStock = existingPurchaseStock + purchaseStock;
        final double updatedNetTotal =
            existingPurchaseNetTotal + purchaseNetTotal;
        averagePrice = (updatedNetTotal / updatedStock).toDouble();

        
        averagePrice = double.parse(averagePrice.toStringAsFixed(0));

        await docRef.update({
          'time': now,
          'purchase_stock': updatedStock,
          'purchase_netTotal': updatedNetTotal,
          'average_price': averagePrice,
          'supplier_name':
          supplierName ?? 'Unknown Supplier', 
          'supplier_phone':
          supplierPhone ?? 'No Phone', 
        });
      } else {
        averagePrice = purchaseNetTotal / purchaseStock;

        
        averagePrice = double.parse(averagePrice.toStringAsFixed(0));

        await lossProfitCollection.add({
          'name': productName,
          'purchase_stock': purchaseStock,
          'purchase_netTotal': purchaseNetTotal,
          'average_price': averagePrice,
          
          'supplier_name':
          supplierName ?? 'Unknown Supplier', 
          'supplier_phone':
          supplierPhone ?? 'No Phone', 
        });
      }

      
      final QuerySnapshot productSnapshot = await stockCollection
          .where('name', isEqualTo: productName)
          .limit(1)
          .get();

      if (productSnapshot.docs.isNotEmpty) {
        final productDoc = productSnapshot.docs.first;
        final stockData = productDoc.data() as Map<String, dynamic>;
        final double? currentPurchasePrice =
        stockData['purchase_price'] as double?;

        
        if (currentPurchasePrice == null ||
            currentPurchasePrice != averagePrice) {
          await productDoc.reference.update({
            'collection name': FieldValue.increment(purchaseStock),
            'purchase_price': averagePrice, 
            
            'supplier_name':
            supplierName ?? 'Unknown Supplier', 
            'supplier_phone':
            supplierPhone ?? 'No Phone', 
          });
        } else {
          
          await productDoc.reference.update({
            'collection name': FieldValue.increment(purchaseStock),
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); 
      },
      child: Scaffold(
        resizeToAvoidBottomInset: isKeyboardVisible,
        appBar: AppBar(
          title: Text('পণ্য ক্রয়/পার্টি লেনদেন'),
          backgroundColor: Colors.blue,
          centerTitle: true,  
        ),
        body: isProcessing 
            ? Center(
          child: CircularProgressIndicator(
            strokeWidth: 4.0, 
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        )
            : Padding(
          padding: EdgeInsets.only(top: screenHeight * 0.002, left:screenWidth * 0.02,right: screenWidth * 0.02, ),
          child: Column(
            children: [
              
              Expanded(
                child: Column(
                  children: [
                    Center(
                      child: Text(
                        'নির্বাচিত পণ্যসমূহ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.05,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: selectedProducts.length,
                        itemBuilder: (context, index) {
                          final product = selectedProducts[index];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: screenHeight*0.0035),
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical:screenHeight * 0.01, horizontal: screenWidth*0.03),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          
                                          Padding(
                                            padding: EdgeInsets.symmetric(vertical: 0.001), 
                                            child: Text(
                                              '${product['name']} (স্টক: ${product['collection name']})',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: screenWidth * 0.035,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          removeProduct(index);
                                        },
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.red,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex:3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'মূল্য',
                                              style: TextStyle(
                                                color: Colors.black, 
                                                fontWeight: FontWeight.w500,
                                                fontSize: screenHeight*0.0145,
                                              ),
                                            ), 
                                            TextFormField(
                                              controller: priceControllers[index],
                                              keyboardType: TextInputType.number,
                                              decoration: InputDecoration(
                                                filled: true, 
                                                fillColor: Colors.teal[100], 
                                                
                                                
                                                
                                                
                                                isDense: true, 
                                                contentPadding: EdgeInsets.symmetric(
                                                  vertical: 1.0, 
                                                  horizontal: 10.0,
                                                ),
                                              ),
                                              onChanged: (value) {
                                                updateProductPrice(index, value);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'পরিমাণ',
                                              style: TextStyle(
                                                color: Colors.black, 
                                                fontWeight: FontWeight.w500,
                                                fontSize: screenHeight*0.0145,
                                              ),
                                            ), 
                                            TextFormField(
                                              controller: stockControllers[index],
                                              keyboardType: TextInputType.number,
                                              decoration: InputDecoration(
                                                filled: true, 
                                                fillColor: Colors.teal[100], 
                                                
                                                
                                                
                                                
                                                isDense: true, 
                                                contentPadding: EdgeInsets.symmetric(
                                                  vertical: 1.0, 
                                                  horizontal: 10.0,
                                                ),
                                              ),
                                              onChanged: (value) {
                                                updateProducttotalAmount(index, value);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        ' = ৳${(product['purchase_price'] * product['purchase_stock']).toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: screenWidth *
                                              0.04, 
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openSupplierSelection(context),
                      icon: Icon(Icons.people, color: Colors.white),
                      label: Text('পার্টি/সাপ্লায়ার',
                          style: TextStyle(fontSize: screenWidth * 0.04)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  SizedBox(width: 1.8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openProductSelection(context),
                      icon: Icon(Icons.add_shopping_cart,
                          color: Colors.white),
                      label: Text('পণ্য নির্বাচন',
                          style: TextStyle(fontSize: screenWidth * 0.04)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              
              Container(
                padding: EdgeInsets.only(top: screenHeight*0.002, bottom: screenHeight*0.002),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 5,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'পার্টি/সাপ্লায়ার ইনফর্মেশন:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.045,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text('নামঃ'),
                              Text('$selectedSupplierName'),
                            ],
                          ),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text('ফোনঃ'),
                              Text('$selectedSupplierPhone'),
                            ],
                          ),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text('আগের দেনাঃ'),
                              Text(
                                  '৳${convertToBengaliNumbers(selectedPreviousTransaction.toStringAsFixed(0))}',
                                  style: TextStyle(
                                      fontSize: screenWidth * 0.04)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1, 
                      thickness: 0.5, 
                      color: Colors.grey, 
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text('মোট ক্রয় মূল্যঃ',
                                  style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                  '৳${convertToBengaliNumbers(totalProductPrice.toStringAsFixed(0))}',
                                  style: TextStyle(
                                      fontSize: screenWidth * 0.05,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text('দেনা সহ মোটঃ',
                                  style: TextStyle(
                                      fontSize: screenWidth * 0.04)),
                              Text(
                                  '৳${convertToBengaliNumbers(grandTotal.toStringAsFixed(0))}',
                                  style: TextStyle(
                                      fontSize: screenWidth * 0.048)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    TextField(
                      controller: cashPaymentController,
                      focusNode: cashPaymentFocusNode,
                      decoration: InputDecoration(
                        labelText: 'নগদ পরিশোধ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.008,
                            horizontal: 12), 
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [PriceInputFormatter()], 
                      enabled: selectedSupplierName.isNotEmpty,
                      onChanged: (value) {
                        setState(() {
                          cashPayment = double.tryParse(value.replaceAll(',', '')) ?? 0.0;
                        });
                      },
                    ),
                    SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment
                          .center, 
                      children: [
                        IconButton(
                          onPressed: () {
                            showImagePreviewDialog(
                              context: context,
                              images: selectedPhotos, 
                              onRemoveImage: (image) {
                                setState(() {
                                  selectedPhotos.remove(image); 
                                });
                              },
                            );
                          },
                          icon: Icon(
                            Icons.photo,
                            color: selectedPhotos.isEmpty ? Colors.grey : Colors.green, 
                            size: MediaQuery.of(context).size.width * 0.075,
                          ),
                        ),
                        SizedBox(
                            width: MediaQuery.of(context).size.width *
                                0.003),
                        
                        IconButton(
                          onPressed: _pickPhoto,
                          icon: Icon(
                            Icons.camera_alt,
                            color: Colors.grey, 
                            size: MediaQuery.of(context).size.width *
                                0.08, 
                          ),
                        ),
                        SizedBox(
                            width: MediaQuery.of(context).size.width *
                                0.003), 
                        
                        IconButton(
                          onPressed: () {
                            setState(() {
                              isSmsActive = !isSmsActive; 
                            });
                          },
                          icon: Icon(
                            Icons.sms,
                            color: isSmsActive
                                ? Colors.blue
                                : Colors.grey, 
                            size: MediaQuery.of(context).size.width *
                                0.075, 
                          ),
                        ),
                        SizedBox(
                            width: MediaQuery.of(context).size.width *
                                0.03), 
                        
                        ElevatedButton(
                          onPressed: selectedProducts.isNotEmpty
                              ? () {
                            _purchaseProducts();
                          }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical:
                                MediaQuery.of(context).size.height *
                                    0.009, 
                                horizontal:
                                MediaQuery.of(context).size.width *
                                    0.05), 
                          ),
                          child: Text(
                            'ক্রয় করুন',
                            style: TextStyle(
                                fontSize: MediaQuery.of(context)
                                    .size
                                    .width *
                                    0.05), 
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
