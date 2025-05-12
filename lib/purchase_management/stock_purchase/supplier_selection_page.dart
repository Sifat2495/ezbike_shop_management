import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../payment/add_new_supplier.dart';

class SupplierSelectionPage extends StatefulWidget {
  @override
  _SupplierSelectionPageState createState() => _SupplierSelectionPageState();
}

class _SupplierSelectionPageState extends State<SupplierSelectionPage> {
  String _searchText = ""; 
  DocumentSnapshot? _lastDocument; 
  bool _hasMoreData = true; 
  List<DocumentSnapshot> _suppliers = []; 
  bool _isLoading = false; 
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    String? userId = getCurrentUserId();
    if (userId != null) {
      _loadSuppliers(userId,
          isInitialLoad: true); 
    }
  }

  String? getCurrentUserId() {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid; 
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent &&
        _hasMoreData) {
      String? userId = getCurrentUserId();
      if (userId != null) {
        _loadSuppliers(userId); 
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    String? userId = getCurrentUserId();

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('সাপ্লায়ার/পার্টি নির্বাচন'),
        ),
        body: Center(
          child: Text('User is not logged in.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Center(child: Text("সাপ্লায়ার/পার্টি নির্বাচন")),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                SizedBox(height: 10),
                _buildSearchBar(),
                Expanded(
                  child: _buildSupplierList(
                      userId), 
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return Dialog(
                      insetPadding: EdgeInsets.symmetric(horizontal: 10), 
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), 
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15), 
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.8, 
                          height: MediaQuery.of(context).size.height * 0.65, 
                          child: AddSupplierPage(),
                        ),
                      ),
                    );
                  },
                );
                setState(() {}); 
              },
              backgroundColor: Colors.green,
              child: Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        labelText: 'সাপ্লায়ার/পার্টি খুঁজুন',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onChanged: (value) {
        setState(() {
          _searchText = value; 
        });
      },
    );
  }

  Widget _buildSupplierList(String userId) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('collection name')
          .doc(userId)
          .collection('suppliers')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var suppliers = snapshot.data?.docs ?? [];

        
        if (_searchText.isNotEmpty) {
          suppliers = suppliers.where((supplier) {
            var supplierData = supplier.data();
            var name = supplierData['name'].toString().toLowerCase();
            return name.contains(_searchText.toLowerCase());
          }).toList();
        }

        return ListView.builder(
          itemCount: suppliers.length,
          itemBuilder: (context, index) {
            var supplier = suppliers[index];
            return _buildSupplierTile(context, supplier, userId);
          },
        );
      },
    );
  }

  Widget _buildSupplierTile(
      BuildContext context, DocumentSnapshot supplier, String userId) {
    Map<String, dynamic>? supplierData =
    supplier.data() as Map<String, dynamic>?;

    String imageUrl = (supplierData != null && supplierData.containsKey('image') &&
        supplierData['image'] != null &&
        supplierData['image'].toString().isNotEmpty)
        ? supplierData['image']
        : 'assets/placeholder.png';
    String name = supplierData?['name'] ?? 'Unknown';
    String phone = supplierData?['phone'] ?? 'Unknown';
    double supplier_due = supplierData?['supplier_due']?.toDouble() ?? 0.0;

    return ListTile(
      leading: GestureDetector(
        child: CircleAvatar(
          backgroundImage: imageUrl.startsWith('http')
              ? NetworkImage(imageUrl)
              : AssetImage(imageUrl) as ImageProvider,
          
          onBackgroundImageError: (_, __) {
            
          },
          child: imageUrl.startsWith('http')
              ? null 
              : Image.asset('assets/placeholder.png'), 
        ),
      ),
      title: Text(name),
      subtitle: Text(phone),
      trailing: Text(
        '৳ ${supplier_due.toStringAsFixed(0)}',
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      onTap: () {
        
        Navigator.pop(context, {
          'name': name,
          'phone': phone,
          'supplier_due': supplier_due,
        });
      },
    );
  }

  Future<void> _loadSuppliers(String userId,
      {bool isInitialLoad = false}) async {
    if (_isLoading || !_hasMoreData) return;

    setState(() {
      _isLoading = true;
    });

    
    int fetchLimit = isInitialLoad ? 15 : 10;

    Query query = FirebaseFirestore.instance
        .collection('collection name')
        .doc(userId)
        .collection('suppliers')
        .limit(fetchLimit);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    QuerySnapshot querySnapshot = await query.get();
    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        _suppliers.addAll(querySnapshot.docs);
        _lastDocument = querySnapshot.docs.last;
        _hasMoreData = querySnapshot.docs.length == fetchLimit;
      });
    } else {
      setState(() {
        _hasMoreData = false;
      });
    }
    setState(() {
      _isLoading = false;
    });
  }
}
