import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/all_common_functions.dart';

class TerminatePage extends StatefulWidget {
  @override
  _TerminatePageState createState() => _TerminatePageState();
}

class _TerminatePageState extends State<TerminatePage> {
  final String helpNumber = 'tel:01234567899';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _updateUserStatus();
  }

  Future<void> _updateUserStatus() async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        await _firestore.collection('collection name').doc(user.uid).update({
          'terminate': true,
        });
      } catch (e) {
        debugPrint('Error updating terminate status: $e');
      }
    }
  }

  Future<void> _launchDialer(BuildContext context) async {
    if (await canLaunchUrl(Uri.parse(helpNumber))) {
      await launchUrl(Uri.parse(helpNumber));
    } else {
      showGlobalSnackBar(context, 'Could not launch dialer');
      }
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 3,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: screenWidth * 0.2,
                ),
                SizedBox(height: 20),
                Text(
                  "আপনার ৭ দিনের ট্রায়াল শেষ হয়েছে।",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "দয়া করে হেল্পলাইনে যোগাযোগ করে প্রিমিয়াম ভার্সনে আপডেট করুন। ধন্যবাদ।",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () => _launchDialer(context),
                  icon: Icon(
                    Icons.phone,
                    color: Colors.white, 
                  ),
                  label: Text(
                    'কল করুন',
                    style: TextStyle(
                      fontSize: screenWidth * 0.05,
                      color: Colors.white, 
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 24,
                    ),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
