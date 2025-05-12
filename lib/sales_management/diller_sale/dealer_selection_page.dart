import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DealerSelectionPage extends StatefulWidget {
  @override
  _DealerSelectionPageState createState() => _DealerSelectionPageState();
}

class _DealerSelectionPageState extends State<DealerSelectionPage> {
  String _searchText = ""; 
  DocumentSnapshot? _lastDocument; 
  bool _hasMoreData = true; 
  final List<DocumentSnapshot> _dealers = []; 
  bool _isLoading = false; 
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    String? userId = getCurrentUserId();
    if (userId != null) {
      _loadDealers(userId, isInitialLoad: true); 
    }
  }

  String? getCurrentUserId() {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid; 
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && _hasMoreData) {
      String? userId = getCurrentUserId();
      if (userId != null) {
        _loadDealers(userId); 
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
          title: Text('ডিলার নির্বাচন w'),
        ),
        body: Center(
          child: Text('User is not logged in.'),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                SizedBox(height: 10),
                _buildSearchBar(),
                Expanded(
                  child: _buildDealerList(userId), 
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width *
            0.01, 
      ),
      child: TextField(
        decoration: InputDecoration(
          labelText: 'ডিলার খুঁজুন',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          isDense: true, 
          contentPadding: EdgeInsets.symmetric(
            vertical: MediaQuery.of(context).size.width < 400
                ? 8.0
                : 10.0, 
            horizontal: 12.0, 
          ),
        ),
        style: TextStyle(
          fontSize: MediaQuery.of(context).size.width < 400
              ? 14
              : 16, 
        ),
        onChanged: (value) {
          setState(() {
            _searchText = value; 
          });
        },
      ),
    );
  }

  Widget _buildDealerList(String userId) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('collection name')
          .doc(userId)
          .collection('dealers')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var dealers = snapshot.data?.docs ?? [];

        
        if (_searchText.isNotEmpty) {
          dealers = dealers.where((dealer) {
            var dealerData = dealer.data();
            var name = dealerData['name'].toString().toLowerCase();
            return name.contains(_searchText.toLowerCase());
          }).toList();
        }

        return ListView.builder(
          itemCount: dealers.length,
          itemBuilder: (context, index) {
            var dealer = dealers[index];
            return _buildDealerTile(context, dealer, userId);
          },
        );
      },
    );
  }

  Widget _buildDealerTile(BuildContext context, DocumentSnapshot dealer, String userId) {
    Map<String, dynamic>? dealerData = dealer.data() as Map<String, dynamic>?;

    String imageUrl = (dealerData != null && dealerData.containsKey('image') && dealerData['image'] != null && dealerData['image'].toString().isNotEmpty)
        ? dealerData['image']
        : 'assets/placeholder.png';
    String name = dealerData?['name'] ?? 'Unknown';
    String father_name = dealerData?['father_name'] ?? '';
    String mother_name = dealerData?['mother_name'] ?? '';
    String phone = dealerData?['phone'] ?? 'Unknown';
    double dealer_due = dealerData?['dealers_due']?.toDouble() ?? 0.0;
    String presentAddress = dealerData?['present_address'] ?? 'Unknown';
    String permanentAddress = dealerData?['permanent_address'] ?? 'Unknown';
    String nid = dealerData?['nid'] ?? 'Unknown';
    DateTime? birthDate = dealerData?['birthDate'] != null
        ? (dealerData?['birthDate'] as Timestamp).toDate()
        : null;
    DateTime? time = dealerData?['time'] != null
        ? (dealerData?['time'] as Timestamp).toDate()
        : null;

    return ListTile(
      leading: GestureDetector(
        child: CircleAvatar(
          backgroundImage: imageUrl.startsWith('http')
              ? NetworkImage(imageUrl)
              : AssetImage(imageUrl) as ImageProvider,
          onBackgroundImageError: (_, __) {},
          child: imageUrl.startsWith('http') ? null : Image.asset('assets/placeholder.png'),
        ),
      ),
      title: Text(name),
      subtitle: Text(phone),
      trailing: Text(
        '৳ ${dealer_due.toStringAsFixed(0)}',
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      onTap: () {
        Navigator.pop(context, {
          'name': name,
          'father_name': father_name,
          'mother_name': mother_name,
          'phone': phone,
          'previousDealer_due': dealer_due,
          'present_address': presentAddress,
          'permanent_address': permanentAddress,
          'nid': nid,
          'birth_date': birthDate,
          'time': time,
        });
      },
    );
  }

  Future<void> _loadDealers(String userId, {bool isInitialLoad = false}) async {
    if (_isLoading || !_hasMoreData) return;

    setState(() {
      _isLoading = true;
    });

    
    int fetchLimit = isInitialLoad ? 15 : 10;

    Query query = FirebaseFirestore.instance
        .collection('collection name')
        .doc(userId)
        .collection('dealers')
        .limit(fetchLimit);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    QuerySnapshot querySnapshot = await query.get();
    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        _dealers.addAll(querySnapshot.docs);
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
