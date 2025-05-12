import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../stock/barcode/barcode_service.dart';
import '../../widgets/all_common_functions.dart';

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
          .orderBy('field name')
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
                  'name': doc['field name'] ?? 'Unknown',
                  'sale_price': (doc['field name'] ?? 0).toDouble(),
                  'purchase_price': (doc['field name'] ?? 0).toDouble(),
                  'stock': (doc['field name'] ?? 0).toDouble(),
                  'barcode': doc['field name'] ?? '',
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
            'name': product['field name'],
            'collection name': product['field name'],
            'sale_price': product['field name'],
            'purchase_price': product['field name'],
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
          .where('field name', isEqualTo: scannedBarcode)
          .get();

      if (productSnapshot.docs.isNotEmpty) {
        final productData = productSnapshot.docs.first.data();
        final product = {
          'id': productSnapshot.docs.first.id,
          'name': productData['field name'] ?? 'Unknown',
          'sale_price': productData['field name'] ?? 0,
          'purchase_price': productData['field name'] ?? 0,
          'stock': productData['field name'] ?? 0,
          'barcode': productData['field name'] ?? '',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Center(child: Text('পণ্য নির্বাচন')),
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
                          : Text('আপনার স্টকে কোনো পণ্য নেই, প্রথমে পণ্য ক্রয় করুন অথবা স্টক থেকে যুক্ত করে বিক্রয় করুণ।',textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16)))
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
                            'স্টক: ${product['collection name'].toStringAsFixed(0)}',
                            style: TextStyle(color: Colors.blueGrey),
                          ),
                          trailing: Text(
                            'মূল্যঃ ৳${product['sale_price'].toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: product['collection name'] > 0
                              ? () => _selectProduct(product)
                              : () {
                            showGlobalSnackBar(context,
                                'আপনার নির্বাচিত পণ্যের পরিমাণ "0" শূন্য, উক্ত পণ্যটি স্টকে নেই। দয়াকরে ক্রয় করুন।');
                          },
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanAndFetchProduct,
        backgroundColor: Colors.green,
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}
