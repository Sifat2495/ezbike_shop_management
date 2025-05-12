import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home_screen.dart';
import '../widgets/all_common_functions.dart';

class PinSetupScreen extends StatefulWidget {
  @override
  _PinSetupScreenState createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  
  void _savePin() async {
    String pin = _pinController.text.trim();
    String confirmPin = _confirmPinController.text.trim();

    
    if (pin.length == 4 && confirmPin.length == 4) {
      if (pin == confirmPin) {
        try {
          
          await FirebaseFirestore.instance
              .collection('collection name')
              .doc(_auth.currentUser?.uid)
              .set({'pin': pin}, SetOptions(merge: true));

          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomeScreen(),
            ),
          );
        } catch (e) {
          showGlobalSnackBar(context,'Error saving PIN: $e');
          }
      } else {
        showGlobalSnackBar(context,'পিনগুলি মেলে না, অনুগ্রহ করে পুনরায় পরীক্ষা করুন');
      }
    } else {
      showGlobalSnackBar(context,'দয়া করে ৪ সংখ্যার সঠিক পিন দিন');
    }
  }

  
  Future<bool> _onWillPop() async {
    return false; 
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade200, Colors.purple.shade200],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    
                    Text(
                      'পিন যুক্ত করুন',
                      style: TextStyle(
                        fontSize: screenWidth * 0.08,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 30),
                    Text(
                      'দয়া করে ৪ সংখ্যার গোপন পিন সেটআপ করুন',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),

                    
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true, 
                        style: TextStyle(
                          fontSize: screenWidth * 0.05,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center, 
                        decoration: InputDecoration(
                          hintText: '৪ সংখ্যার পিন দিন',
                          counterText: '',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _confirmPinController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true, 
                        style: TextStyle(
                          fontSize: screenWidth * 0.05,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center, 
                        decoration: InputDecoration(
                          hintText: 'পুনরায় ৪ সংখ্যার পিন দিন',
                          counterText: '',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    
                    ElevatedButton(
                      onPressed: _savePin,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.2,
                          vertical: screenWidth * 0.04,
                        ),
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                      ),
                      child: Text(
                        'Save PIN',
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
