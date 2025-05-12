import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';

class AllTransactions extends StatefulWidget {
  @override
  _AllTransactionsState createState() => _AllTransactionsState();
}

class _AllTransactionsState extends State<AllTransactions> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> _transactions = [];
  bool _isLoadingMore = false;
  bool _hasMore = true; 
  DocumentSnapshot? _lastVisible; 
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('en_BD', null);
    _loadTransactions(); 

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore && _hasMore) {
        _loadTransactions(loadMore: true); 
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions({bool loadMore = false}) async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      Query query = _firestore
          .collection('collection name')
          .doc(_auth.currentUser!.uid)
          .collection('cashbox')
          .orderBy('time', descending: true)
          .limit(7); 

      if (loadMore && _lastVisible != null) {
        query = query.startAfterDocument(_lastVisible!);
      }

      QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          if (loadMore) {
            _transactions.addAll(snapshot.docs);
          } else {
            _transactions = snapshot.docs;
          }
          _lastVisible = snapshot.docs.last;
          _hasMore = snapshot.docs.length == 7; 
        });
      } else {
        setState(() {
          _hasMore = false; 
        });
      }
    } catch (e) {
      print("Error loading transactions: $e");
    }

    setState(() {
      _isLoadingMore = false;
    });
  }

  String _formatAmountCurrency(double value) {
    return NumberFormat.currency(
        locale: 'en_US', symbol: 'ক্যাশ ৳', decimalDigits: 0)
        .format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'সাম্প্রতিক লেনদেন',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.green,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pink.shade200, Colors.blue.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 5),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _transactions.length + (_hasMore ? 1 : 0), 
                  itemBuilder: (context, index) {
                    if (index == _transactions.length) {
                      return _isLoadingMore
                          ? Center(child: CircularProgressIndicator())
                          : SizedBox(); 
                    }

                    final transaction = _transactions[index];
                    final amount = transaction['amount'] is int
                        ? (transaction['amount'] as int).toDouble()
                        : transaction['amount'] as double;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: amount < 0 ? Colors.blue[400] : Colors.greenAccent[400],
                      child: ListTile(
                        title: Text(
                          _formatAmountCurrency(amount),
                          style: TextStyle(
                            color: amount < 0 ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'বিবরণ: ${transaction['reason']}',
                              style: TextStyle(
                                color: amount < 0 ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              DateFormat('EEE, dd-MM-yyyy – hh:mm a', 'en_BD')
                                  .format(transaction['time'].toDate().toLocal()),
                              style: TextStyle(
                                color: amount < 0 ? Colors.white : Colors.black,
                              ),
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
      ),
    );
  }
}
