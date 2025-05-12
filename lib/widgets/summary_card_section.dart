import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'all_common_functions.dart';

class SummaryCardSection extends StatefulWidget {
  final double screenWidth;

  SummaryCardSection(this.screenWidth);

  @override
  SummaryCardSectionState createState() => SummaryCardSectionState();
}

class SummaryCardSectionState extends State<SummaryCardSection> {
  double totalDueAmount = 0.0;
  double totalPayableAmount = 0.0;
  double dailySales = 0.0;
  double dailyDue = 0.0;

  late StreamSubscription<DocumentSnapshot> customerDueListener;
  late StreamSubscription<DocumentSnapshot> supplierDueListener;
  late StreamSubscription<DocumentSnapshot> dailySalesListener;
  late StreamSubscription<DocumentSnapshot> dailyDueListener;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  
  void _setupListeners() {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    customerDueListener = FirebaseFirestore.instance
        .collection('collection name')
        .doc(uid)
        .collection('collection name')
        .doc('doc name')
        .snapshots()
        .listen((docSnapshot) {
      if (docSnapshot.exists && docSnapshot.data() != null) {
        double? totalDue =
            (docSnapshot.data()?['field name'] as num?)?.toDouble() ?? 0.0;
        if (mounted) {
          setState(() {
            totalDueAmount = totalDue;
          });
        }
      }
    });

    supplierDueListener = FirebaseFirestore.instance
        .collection('collection name')
        .doc(uid)
        .collection('collection name')
        .doc('doc name')
        .snapshots()
        .listen((docSnapshot) {
      if (docSnapshot.exists && docSnapshot.data() != null) {
        double? totalDue =
            (docSnapshot.data()?['field name'] as num?)?.toDouble() ?? 0.0;
        if (mounted) {
          setState(() {
            totalPayableAmount = totalDue;
          });
        }
      }
    });

    DateTime now = DateTime.now();
    String todayDocId = '${now.year}-${now.month}-${now.day}';

    dailySalesListener = FirebaseFirestore.instance
        .collection('collection name')
        .doc(uid)
        .collection('collection name')
        .doc(todayDocId)
        .snapshots()
        .listen((docSnapshot) {
      if (docSnapshot.exists && docSnapshot.data() != null) {
        double? totalSales =
            (docSnapshot.data()?['field name'] as num?)?.toDouble() ?? 0.0;
        if (mounted) {
          setState(() {
            dailySales = totalSales;
          });
        }
      }
    });

    dailyDueListener = FirebaseFirestore.instance
        .collection('collection name')
        .doc(uid)
        .collection('collection name')
        .doc(todayDocId)
        .snapshots()
        .listen((docSnapshot) {
      if (docSnapshot.exists && docSnapshot.data() != null) {
        double? customersDue =
            (docSnapshot.data()?['field name'] as num?)?.toDouble() ?? 0.0;
        if (mounted) {
          setState(() {
            dailyDue = customersDue;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    
    customerDueListener.cancel();
    supplierDueListener.cancel();
    dailySalesListener.cancel();
    dailyDueListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.tealAccent, Colors.grey],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'দৈনিক বিক্রি',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.004),
                        Text(
                          '৳ ${convertToBengaliNumbers(dailySales.toStringAsFixed(0))}',
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'দৈনিক বাকি',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.004),
                        Text(
                          '৳ ${convertToBengaliNumbers(dailyDue.toStringAsFixed(0))}',
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(height: screenHeight * 0.03, color: Colors.black),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'মোট দেনা',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.004),
                        Text(
                          '৳ ${convertToBengaliNumbers(totalPayableAmount.toStringAsFixed(0))}',
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'মোট বাকি',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.004),
                        Text(
                          '৳ ${convertToBengaliNumbers(totalDueAmount.toStringAsFixed(0))}',
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
