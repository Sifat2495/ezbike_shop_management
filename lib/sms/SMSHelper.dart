import 'package:bebshar_poristhiti_stock/sms/sms_purchase_page.dart';
import 'package:bebshar_poristhiti_stock/sms/sms_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/all_common_functions.dart';

class SMSHelper {
  static Future<void> sendSMS({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('লগইন ব্যবহারকারী পাওয়া যায়নি।');
      }

      final uid = currentUser.uid;

      final yearlyTotalsDoc = FirebaseFirestore.instance
          .collection('collection name')
          .doc(uid)
          .collection('collection name')
          .doc('doc id/name');

      final updateData = {
        'field name': FieldValue.increment(-1),
      };

      await yearlyTotalsDoc.set(updateData, SetOptions(merge: true));

      await SMSService.sendSMS(
        phoneNumber: phoneNumber,
        message: message,
      );
    } catch (e) {
      print('ডেটা আপডেট করতে সমস্যা হয়েছে: ${e.toString()}');
    }
  }

  static Future<bool> checkAndShowSMSWarning({
    required BuildContext context,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('লগইন ব্যবহারকারী পাওয়া যায়নি।');
      }

      final uid = currentUser.uid;

      final yearlyTotalsDoc = await FirebaseFirestore.instance
          .collection('collection name')
          .doc(uid)
          .collection('collection name')
          .doc('doc id/name')
          .get();

      final data = yearlyTotalsDoc.data();
      final smsCount = data?['field name'] ?? 0;

      if (smsCount <= 0) {
        _showSMSWarningDialog(context);
        return false;
      } else {
        print('SMS count is sufficient: $smsCount');
        return true;
      }
    } catch (e) {
      if (context.mounted) {
        showGlobalSnackBar(context, 'ত্রুটি: ${e.toString()}');
        } return false;
    }
  }

  static void _showSMSWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sms_failed_outlined,
                color: Colors.red,
                size: 50,
              ),
              SizedBox(height: 10),
              Text(
                'আপনার এসএমএস শেষ!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            'দয়া করে নতুন করে এসএমএস ক্রয় করুন।',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'ঠিক আছে',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SMSPurchasePage(),
                  ),
                );
              },
              child: Text(
                'SMS কিনুন',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

