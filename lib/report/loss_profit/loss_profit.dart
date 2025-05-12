import 'package:bebshar_poristhiti_stock/report/loss_profit/total_loss_profit.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/all_common_functions.dart';

class LossProfitPage extends StatefulWidget {
  @override
  _LossProfitPageState createState() => _LossProfitPageState();
}

class _LossProfitPageState extends State<LossProfitPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  String? _userId;
  String _searchQuery = "";
  int _fetchLimit = 10;

  List<Map<String, dynamic>> _products = [];
  DocumentSnapshot? _lastDocument;
  bool _isFetchingMore = false;

  @override
  void initState() {
    super.initState();
    _getUserId();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent &&
          !_isFetchingMore) {
        _fetchMoreProducts();
      }
    });

    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
      _fetchInitialProducts(); 
    });
  }

  Future<void> _getUserId() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
      await _fetchInitialProducts();
    }
  }

  Future<void> _fetchInitialProducts() async {
    if (_userId == null) return;

    Query query = _firestore
        .collection('/collection name/$_userId/loss_profit')
        .orderBy('name')
        .limit(_fetchLimit);

    
    if (_searchQuery.isNotEmpty) {
      query = query
          .where('name', isGreaterThanOrEqualTo: _searchQuery)
          .where('name', isLessThanOrEqualTo: _searchQuery + '\uf8ff');
    }

    final querySnapshot = await query.get();
    setState(() {
      _products = querySnapshot.docs
          .map((doc) => _convertProductData(doc.data() as Map<String, dynamic>))
          .toList();
      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
      }
    });
  }

  Future<void> _fetchMoreProducts() async {
    if (_lastDocument == null || _isFetchingMore || _userId == null) return;

    setState(() => _isFetchingMore = true);

    Query query = _firestore
        .collection('/collection name/$_userId/loss_profit')
        .orderBy('name')
        .startAfterDocument(_lastDocument!)
        .limit(_fetchLimit);

    
    if (_searchQuery.isNotEmpty) {
      query = query
          .where('name', isGreaterThanOrEqualTo: _searchQuery)
          .where('name', isLessThanOrEqualTo: _searchQuery + '\uf8ff');
    }

    final querySnapshot = await query.get();

    setState(() {
      _products.addAll(querySnapshot.docs
          .map((doc) => _convertProductData(doc.data() as Map<String, dynamic>))
          .toList());
      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
      }
      _isFetchingMore = false;
    });
  }

  
  Map<String, dynamic> _convertProductData(Map<String, dynamic> data) {
    return {
      'name': data['name'] ?? 'Unknown Product',
      'purchase_netTotal': _convertToDouble(data['purchase_netTotal']),
      'purchase_stock': _convertToDouble(data['purchase_stock']),
      'sale_netTotal': _convertToDouble(data['sale_netTotal']),
      'sale_stock': _convertToDouble(data['sale_stock']),
      'field name': _convertToDouble(data['field name']),
    };
  }

  
  double _convertToDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    } else if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else {
      return 0.0; 
    }
  }

  Widget _buildSummaryRow(String label, double value, {bool showCurrency = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            '${showCurrency ? '৳' : ''}${convertToBengaliNumbers(value.toStringAsFixed(0))}', 
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: value >= 0 ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final lossProfit = product['field name'] ?? 0.0;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                product['name'] ?? 'Unknown Product',
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            _buildSummaryRow('মোট ক্রয়মূল্য:', product['purchase_netTotal'] ?? 0.0),
            _buildSummaryRow('ক্রয়ের পরিমাণ:', product['purchase_stock'] ?? 0, showCurrency: false),
            _buildSummaryRow('মোট বিক্রয়মূল্য:', product['sale_netTotal'] ?? 0.0),
            _buildSummaryRow('বিক্রয়ের পরিমাণ:', product['sale_stock'] ?? 0, showCurrency: false),
            const Divider(),
            Center(
              child: Text(
                lossProfit >= 0
                    ? 'লাভ: ৳${convertToBengaliNumbers(lossProfit.toStringAsFixed(0))}'
                    : 'লস: ৳${convertToBengaliNumbers((-lossProfit).toStringAsFixed(0))}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: lossProfit >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('লাভ লস'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            
            LossProfitSummaryWidget(),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'পণ্য সার্চ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(_products[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
