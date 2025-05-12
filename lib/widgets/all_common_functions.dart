import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

double convertToDouble(dynamic value) {
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

class PriceInputFormatter extends TextInputFormatter {
  final _formatter = NumberFormat('#,###', 'en_US');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String newText = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');

    if (newText.isNotEmpty) {
      final parsedNumber = double.tryParse(newText.replaceAll(',', ''));
      if (parsedNumber != null) {
        newText = _formatter.format(parsedNumber);
        if (parsedNumber == parsedNumber.toInt()) {
          newText = newText.replaceAll('.0', '');
        }
      }
    }
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

String convertToBengaliNumbers(String input) {
  final List<String> englishNumbers = [
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
  ];
  final List<String> bengaliNumbers = [
    '০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'
  ];

  String converted = input;
  for (int i = 0; i < englishNumbers.length; i++) {
    converted = converted.replaceAll(englishNumbers[i], bengaliNumbers[i]);
  }
  return converted;
}
void showGlobalSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Center(
        child: Text(
          message,
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center, 
        ),
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: EdgeInsets.all(16),
    ),
  );
}

void showLoadingDialog(BuildContext context, {String? message}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    strokeWidth: 4,
                  ),
                  const SizedBox(height: 20),
                  if (message != null) ...[
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

void hideLoadingDialog(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pop();
}


Future<bool> hasInternetConnection() async {
  var connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) {
    return false;
  }
  return true;
}

Future<bool> checkPinPermission(BuildContext context, {required bool isDelete, required bool isEdit}) async {
  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    return false;
  }

  DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('collection name').doc(currentUser.uid).get();
  bool hasPermission = false;

  if (userDoc.exists) {
    bool pinRequired = isDelete || isEdit;
    if (pinRequired) {
      String storedPin = userDoc['field name'] ?? '';
      String userInputPin = '';
      bool pinVerified = false;

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            title: Center(
              child: Text(
                'পিন যাচাই করুণ',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (value) {
                    userInputPin = value;
                  },
                  decoration: InputDecoration(
                    labelText: '৪ সংখ্যার পিন',
                    labelStyle: TextStyle(color: Colors.black87),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                    prefixIcon: Icon(
                      Icons.lock,
                      color: Colors.grey,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: TextStyle(fontSize: 18.0),
                ),
                SizedBox(height: 2),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: Text(
                      'বাতিল',
                      style: TextStyle(color: Colors.black, fontSize: 16.0),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: Text(
                      'যাচাই করুণ',
                      style: TextStyle(color: Colors.white, fontSize: 16.0),
                    ),
                    onPressed: () async {
                      pinVerified = (userInputPin == storedPin);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          );
        },
      );

      if (pinVerified) {
        hasPermission = true;
      } else {
        showGlobalSnackBar(context, 'আবার চেষ্টা করুণ।');
      }
    } else {
      hasPermission = true;
    }
  }
  return hasPermission;
}

Future<bool> checkPermission(BuildContext context, {required String permissionField}) async {
  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    showGlobalSnackBar(context, 'আপনার লগইন করা প্রয়োজন');
    return false;
  }

  try {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('collection name').doc(currentUser.uid).get();
    bool permission = userDoc[permissionField] ?? false;

    return permission;
  } catch (e) {
    showGlobalSnackBar(context, 'ডাটাবেজ থেকে তথ্য লোড করতে সমস্যা হয়েছে');
    return false;
  }
}