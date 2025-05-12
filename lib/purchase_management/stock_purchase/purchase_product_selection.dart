import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../stock/barcode/barcode_service.dart';
import '../../widgets/all_common_functions.dart';
import '../../widgets/calculator_page.dart';

class ProductSelectionPage extends StatefulWidget {
  @override
  _ProductSelectionPageState createState() => _ProductSelectionPageState();
}

class _ProductSelectionPageState extends State<ProductSelectionPage> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  String searchQuery = '';
  bool isLoading = false;
  DocumentSnapshot? lastFetchedDocument;
  final int initialFetchCount = 15;
  final int loadMoreCount = 10;
  StreamSubscription? _productSubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _purchasePriceController = TextEditingController();
  final TextEditingController _salePriceController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  void _fetchProducts({bool isLoadMore = false}) {
    if (isLoading || !mounted) return;

    setState(() => isLoading = true);

    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      Query query = FirebaseFirestore.instance
          .collection('collection name')
          .doc(userId)
          .collection('collection name')
          .orderBy('name')
          .limit(isLoadMore && lastFetchedDocument != null
          ? loadMoreCount
          : initialFetchCount);

      if (isLoadMore && lastFetchedDocument != null) {
        query = query.startAfterDocument(lastFetchedDocument!);
      }

      _productSubscription?.cancel(); 

      _productSubscription = query.snapshots().listen((snapshot) {
        if (mounted) { 
          setState(() {
            if (snapshot.docs.isNotEmpty) {
              products = snapshot.docs.map((doc) {
                return {
                  'id': doc.id,
                  'name': doc['name'] ?? 'Unknown',
                  'sale_price': (doc['sale_price'] ?? 0).toDouble(),
                  'purchase_price': (doc['purchase_price'] ?? 0).toDouble(),
                  'collection name': (doc['collection name'] ?? 0).toDouble(),
                  'barcode': doc['barcode'] ?? '',
                };
              }).toList();
              filteredProducts = products;
              lastFetchedDocument = snapshot.docs.last;
            }
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
      debugPrint('Error fetching products: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    if (_productSubscription != null) {
      _productSubscription?.cancel();
      _productSubscription = null; 
    }
    print('ProductSelectionPage disposed');
    super.dispose();
  }

  void _selectProduct(Map<String, dynamic> product) {
    if (mounted) {
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          Navigator.pop(context, {
            'name': product['name'],
            'collection name': product['collection name'],
            'sale_price': product['sale_price'],
            'purchase_price': product['purchase_price'],
          });
        }
      });
    }
  }


  void _filterProducts(String query) {
    setState(() {
      searchQuery = query;
      filteredProducts = products.where((product) {
        final productName = product['name'].toLowerCase();
        final searchLower = query.toLowerCase();
        return productName.contains(searchLower);
      }).toList();
    });
  }

  Future<void> scanBarcode() async {
    final barcodeValue = await BarcodeService.scanBarcode(context);
    if (barcodeValue != null && barcodeValue.isNotEmpty) {
      
      final userProductsCollection =
      _firestore.collection('collection name').doc(userId).collection('collection name');
      final existingBarcode = await userProductsCollection
          .where('barcode', isEqualTo: barcodeValue)
          .get();

      if (existingBarcode.docs.isNotEmpty) {
        
        final matchedProductName =
            existingBarcode.docs.first['name'] ?? 'Unknown Product';

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


  Future<void> _scanAndFetchProduct() async {
    try {
      String? scannedBarcode = await BarcodeService.scanBarcode(context);

      if (scannedBarcode == null || scannedBarcode.isEmpty) {
        showGlobalSnackBar(context, 'বারকোড স্ক্যানিং বাতিল হয়েছে।');
        return; 
      }

      setState(() => isLoading = true);

      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final productSnapshot = await FirebaseFirestore.instance
          .collection('collection name')
          .doc(userId)
          .collection('collection name')
          .where('barcode', isEqualTo: scannedBarcode)
          .get();

      if (productSnapshot.docs.isNotEmpty) {
        final productData = productSnapshot.docs.first.data();
        final product = {
          'id': productSnapshot.docs.first.id,
          'name': productData['name'] ?? 'Unknown',
          'sale_price': productData['sale_price'] ?? 0,
          'purchase_price': productData['purchase_price'] ?? 0,
          'collection name': productData['collection name'] ?? 0,
          'barcode': productData['barcode'] ?? '',
        };

        _selectProduct(product);
      } else {
        showGlobalSnackBar(context, 'বারকোডটি কোনো পণ্যের সাথে মেলেনি।');
      }
    } catch (e) {
      showGlobalSnackBar(context, 'বারকোড স্ক্যানিং ব্যর্থ হয়েছে: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }


  Future<void> _showAddProductDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(20), 
          ),
          title: Text('নতুন পণ্য যুক্ত করুন'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  labelText: 'Barcode',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.qr_code_scanner),
                    onPressed: scanBarcode,
                  ),
                ),
              ),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'পণ্যের নাম'),
              ),
              TextField(
                controller: _purchasePriceController,
                decoration: InputDecoration(
                  labelText: '*প্রতি পিসের ক্রয় মূল্য',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calculate),
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
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _salePriceController,
                decoration: InputDecoration(labelText: 'বিক্রয় মূল্য প্রতি পিস(৳)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _barcodeController.clear();
                _nameController.clear();
                _purchasePriceController.clear();
                _salePriceController.clear();
                _totalAmountController.clear();
                Navigator.pop(context);
              },
              child: Text('বাতিল'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                Colors.green, 
                foregroundColor: Colors.white, 
                padding: EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10), 
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(10), 
                ),
              ),
              onPressed: () async {
                if (_nameController.text.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('দুঃখিত',style: TextStyle(color: Colors.red),),
                        content: Text('অনুগ্রহ করে পণ্যের নাম লিখুন', style: TextStyle(fontWeight: FontWeight.bold),),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); 
                            },
                            child: Text('ঠিক আছে', style: TextStyle(fontWeight: FontWeight.bold),),
                          ),
                        ],
                      );
                    },
                  );
                } else if (_purchasePriceController.text.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('দুঃখিত',style: TextStyle(color: Colors.red),),
                        content: Text('অনুগ্রহ করে ক্রয়মূল্য লিখুন', style: TextStyle(fontWeight: FontWeight.bold),),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); 
                            },
                            child: Text('ঠিক আছে', style: TextStyle(fontWeight: FontWeight.bold),),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  
                  await _addProduct();
                  Navigator.pop(context);
                  _resetData();
                }
              },
              child: Text(
                'যুক্ত করুন',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addProduct() async {
    try {
      showLoadingDialog(context, message: 'কেনা হচ্ছে...');
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      String productName = _nameController.text.trim();
      String barcode = _barcodeController.text.trim();

      
      QuerySnapshot existingProduct = await FirebaseFirestore.instance
          .collection('collection name')
          .doc(userId)
          .collection('collection name')
          .where('name', isEqualTo: productName)
          .limit(1)
          .get();

      if (existingProduct.docs.isNotEmpty) {
        showGlobalSnackBar(context,'এই নামের পণ্য ইতিমধ্যেই আছে');
        return;
      }

      
      double purchase_price =
          double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
      double sale_price = double.tryParse(_salePriceController.text.trim()) ?? 0.0;
      

      
      
      
      
      
      

      await FirebaseFirestore.instance
          .collection('collection name')
          .doc(userId)
          .collection('collection name')
          .add({
        'barcode': barcode,
        'name': productName,
        'purchase_price': purchase_price,
        'sale_price': sale_price,
        'collection name': 0.0,
      });
      showGlobalSnackBar(context,'পণ্য সফলভাবে যুক্ত হয়েছে');
      _nameController.clear();
      _purchasePriceController.clear();
      _salePriceController.clear();
      _totalAmountController.clear();
      _resetData();
      hideLoadingDialog(context);
    } catch (e) {
      hideLoadingDialog(context);
      showGlobalSnackBar(context,'পণ্য যুক্ত করতে সমস্যা হয়েছে');
    }
  }

  void _resetData() {
    products.clear();
    filteredProducts.clear();
    lastFetchedDocument = null;
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Center(child: Text('পণ্য নির্বাচন')),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  onChanged: _filterProducts,
                  decoration: InputDecoration(
                    labelText: 'পণ্য অনুসন্ধান করুন',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.qr_code_scanner),
                      onPressed: _scanAndFetchProduct,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
              ),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (scrollNotification) {
                    if (scrollNotification.metrics.pixels ==
                        scrollNotification.metrics.maxScrollExtent &&
                        !isLoading) {
                      _fetchProducts(isLoadMore: true);
                    }
                    return true;
                  },
                  child: filteredProducts.isEmpty
                      ? Center(
                      child: isLoading
                          ? CircularProgressIndicator()
                          : Text('কোনো পণ্য নেই'))
                      : ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return Card(
                        margin: EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        elevation: 4,
                        child: ListTile(
                          title: Text(
                            product['name'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'পণ্যের পরিমাণ: ${product['collection name']}',
                            style: TextStyle(color: Colors.blueGrey),
                          ),
                          trailing: Text(
                            'ক্রয় মূল্যঃ ৳${product['purchase_price']}',
                            style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold),
                          ),
                          onTap: () => _selectProduct(product),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (isLoading)
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _showAddProductDialog,
              backgroundColor: Colors.blue,
              child: Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
