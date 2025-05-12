import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneValidationController {
  
  Future<bool> isPhoneValid(String phone) async {
    if (phone.length != 11) return false;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('collection name')
        .doc(userId)
        .collection('collection name')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();

    
    return querySnapshot.docs.isEmpty;
  }

  
  void validatePhoneAfter11Digits(String phone, Function callback) {
    if (phone.length == 11) {
      
      isPhoneValid(phone).then((isValid) {
        callback(isValid);
      });
    }
  }
}
