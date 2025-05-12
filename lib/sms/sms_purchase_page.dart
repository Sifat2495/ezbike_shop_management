import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/all_common_functions.dart';
import 'sms_purchase_ui.dart';

class SMSPurchasePage extends StatefulWidget {
  @override
  _SMSPurchasePageState createState() => _SMSPurchasePageState();
}

class _SMSPurchasePageState extends State<SMSPurchasePage> {
  final List<Map<String, dynamic>> packages = [
    {'messages': 25, 'price': 17},
    {'messages': 50, 'price': 35},
    {'messages': 100, 'price': 50},
    {'messages': 150, 'price': 80},
    {'messages': 250, 'price': 120},
    {'messages': 500, 'price': 220},
  ];

  Stream<int> smsCountStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Stream.value(0);
    }

    return FirebaseFirestore.instance
        .collection('collection')
        .doc(userId)
        .collection('collection')
        .doc('doc id/name')
        .snapshots()
        .map((snapshot) {
      return snapshot.data()?['field name'] ?? 0;
    });
  }

  Future<void> updateSMSCount(int messages) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final userDoc = FirebaseFirestore.instance
        .collection('collection')
        .doc(userId)
        .collection('collection')
        .doc('doc id/name');

    await userDoc.update({
      'field name': FieldValue.increment(messages),
    });
  }

  Future<void> _purchasePackage(int messages) async {
    try {
      await updateSMSCount(messages);
      showGlobalSnackBar(context, 'Successfully purchased $messages SMS!');
      } catch (e) {
      showGlobalSnackBar(context, 'Failed to purchase SMS: $e');
      }
  }

  @override
  Widget build(BuildContext context) {
    return SMSPurchaseUI(
      smsCountStream: smsCountStream(),
      packages: packages,
      onPurchase: _purchasePackage,
    );
  }
}