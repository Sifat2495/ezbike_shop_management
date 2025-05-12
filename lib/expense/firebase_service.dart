import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

import '../widgets/all_common_functions.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> addExpense(
      String reason, double amount, String type, BuildContext context) async {
    final User? user = _auth.currentUser;
    if (user == null || amount <= 0) return;

    final userId = user.uid;
    final now = DateTime.now();

    
    final sanitizedReason = reason.trim().isEmpty ? 'নেই' : reason;

    final expenseData = {
      'reason': sanitizedReason,
      'amount': amount,
      'type': type,
      'time': now,
    };

    try {
      
      showLoadingDialog(context, message: 'সার্ভারে যুক্ত হচ্ছে...');

      WriteBatch batch = _firestore.batch();

      
      final expenseDocRef = _firestore
          .collection('collection name')
          .doc(userId)
          .collection('expense')
          .doc();
      batch.set(expenseDocRef, expenseData);

      
      final allTimeDocRef = _firestore
          .collection('collection name')
          .doc(userId)
          .collection('collection name')
          .doc('doc id/name');

      final allTimeSnapshot = await allTimeDocRef.get();
      double cash = 0.0;
      if (allTimeSnapshot.exists) {
        cash = convertToDouble(allTimeSnapshot.data()?['cash']);
      }

      if (type == 'deposit') {
        cash += amount;
      } else if (type == 'cost') {
        cash -= amount;
      } else if (type == 'cashOut') {
        cash -= amount;
      }

      batch.set(allTimeDocRef, {'cash': cash}, SetOptions(merge: true));

      
      final dailyDocRef = _firestore
          .collection('collection name')
          .doc(userId)
          .collection('collection name')
          .doc('${now.year}-${now.month}-${now.day}');

      final dailySnapshot = await dailyDocRef.get();
      double addCash = 0.0;
      double cost = 0.0;
      double withdraw = 0.0;

      if (dailySnapshot.exists) {
        addCash = convertToDouble(dailySnapshot.data()?['add_cash']);
        cost = convertToDouble(dailySnapshot.data()?['cost']);
        withdraw = convertToDouble(dailySnapshot.data()?['withdraw']);
      }

      if (type == 'deposit') {
        addCash += amount;
        batch.set(dailyDocRef, {
          'add_cash': addCash,
        }, SetOptions(merge: true));
      } else if (type == 'cost') {
        cost += amount;
        batch.set(dailyDocRef, {
          'cost': cost,
        }, SetOptions(merge: true));
      } else if (type == 'cashOut') {
        withdraw += amount;
        batch.set(dailyDocRef, {
          'withdraw': withdraw,
        }, SetOptions(merge: true));
      }

      
      await batch.commit();

      
      showGlobalSnackBar(context, 'খরচ সফলভাবে যোগ হয়েছে।');
    } catch (e) {
      print('Error adding expense or updating totals: $e');
      showGlobalSnackBar(context, 'ডেটা সংরক্ষণে ত্রুটি ঘটেছে।');
    } finally {
      
      hideLoadingDialog(context);
    }
  }
}