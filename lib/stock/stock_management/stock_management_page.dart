import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../product/product_model.dart';
import '../product/product_page.dart';
import 'product_card.dart';
import 'search_field.dart';

class StockManagementPage extends StatefulWidget {
  @override
  _StockManagementPageState createState() => _StockManagementPageState();
}

class _StockManagementPageState extends State<StockManagementPage> {
  String _searchQuery = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => unfocusKeyboard(context),
      child: Scaffold(
        appBar: buildAppBar(context, userId, _firestore),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              buildSearchField(_searchProducts),
              SizedBox(height: 20),
              Expanded(
                child: buildProductList(_firestore, userId, _searchQuery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _searchProducts(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  void unfocusKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  AppBar buildAppBar(
      BuildContext context, String userId, FirebaseFirestore firestore) {
    return AppBar(
      backgroundColor: const Color.fromARGB(122, 3, 180, 148),
      elevation: 0,
      title: const Text('স্টকের খবর'),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () async {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return Dialog(
                  insetPadding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: ProductPage(),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget buildProductList(
      FirebaseFirestore firestore, String userId, String searchQuery) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('collection name')
          .doc(userId)
          .collection('collection name')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        List<QueryDocumentSnapshot> productDocs = snapshot.data!.docs;
        List<Product> products = productDocs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return Product(
            barcode: data['field name'],
            name: data['field name'] as String,
            purchasePrice: _parseStringToDouble(data['field name']),
            salePrice: _parseStringToDouble(data['field name']),
            stock: _parseStringToDouble(data['field name']),
            supplierName: data['field name'],
            supplierPhone: data['field name'],
            photoUrls: List<String>.from(data['field name'] ?? []),
          );
        }).toList();

        if (searchQuery.isNotEmpty) {
          products = products
              .where(
                  (product) => product.name.toLowerCase().contains(searchQuery))
              .toList();
        }

        return products.isEmpty
            ? const Center(
          child: Text(
            'কোনও প্রোডাক্ট খুঁজে পাওয়া যায় নি',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey),
          ),
        )
            : ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final docId = productDocs[index].id;

            _updateFirestoreTypes(firestore, userId, docId, product);

            return buildProductCard(
              context,
              firestore,
              userId,
              product,
              docId, 
            );
          },
        );
      },
    );
  }

  double _parseStringToDouble(dynamic value) {
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  void _updateFirestoreTypes(FirebaseFirestore firestore, String userId,
      String docId, Product product) {
    firestore
        .collection('collection name')
        .doc(userId)
        .collection('collection name')
        .doc(docId)
        .update({
      'field name': product.purchasePrice,
      'field name': product.salePrice,
      'field name': product.stock,
    });
  }
}
