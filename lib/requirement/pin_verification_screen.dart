import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart'; 
import 'dart:math';
import 'dart:async';
import '../home_screen.dart';
import '../widgets/all_common_functions.dart';

class PinVerificationScreen extends StatefulWidget {
  @override
  _PinVerificationScreenState createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalAuthentication auth =
      LocalAuthentication(); 
  final TextEditingController _pinController = TextEditingController();
  User? _currentUser;
  late AnimationController _animationController;
  bool _isPinVisible = true;
  Timer? _timer;

  void _onPinChanged(String value) {
    if (value.isNotEmpty) {
      _timer?.cancel();
      _timer = Timer(Duration(milliseconds: 100), () {
        setState(() {
          _isPinVisible = false;
        });
      });

      setState(() {
        _isPinVisible = true;
      });
    } else {
      setState(() {
        _isPinVisible = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentUser();

    _animationController = AnimationController(
      duration: Duration(seconds: 6),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  void _getCurrentUser() {
    _currentUser = _auth.currentUser;
    if (_currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showGlobalSnackBar(context, 'No user logged in. Please log in first.');
      });
    }
  }

  
  Future<void> _authenticateWithBiometrics() async {
    try {
      bool isAuthenticated = await auth.authenticate(
        localizedReason: 'HE Software Solution',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (isAuthenticated) {
        _navigateToHome();
      } else {
        showGlobalSnackBar(context, 'Authentication failed');
      }
    } catch (e) {
      showGlobalSnackBar(context, 'আপনার Fingerprint যুক্ত করা নেই');
    }
  }

  
  void _verifyPin() async {
    if (_currentUser == null) {
      showGlobalSnackBar(context, 'No user logged in');
      return;
    }

    String enteredPin = _pinController.text.trim();
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('collection name')
        .doc(_currentUser?.uid)
        .get();

    if (userDoc.exists) {
      String storedPin = userDoc['pin'];
      if (enteredPin == storedPin) {
        _navigateToHome();
      } else {
        showGlobalSnackBar(context, 'আপনি ভুল পিন দিয়েছেন');
      }
    } else {
      showGlobalSnackBar(context, 'No PIN found. Please set up a PIN first.');
    }
  }

  
  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.green,
                      Colors.teal,
                      Colors.blue,
                      Colors.purpleAccent,
                    ],
                    stops: [
                      0.1 + 0.2 * sin(_animationController.value * 2 * pi),
                      0.4 +
                          0.2 *
                              sin(_animationController.value * 2 * pi + pi / 2),
                      0.7 + 0.2 * sin(_animationController.value * 2 * pi + pi),
                      1.0,
                    ],
                  ),
                ),
              );
            },
          ),
          Center(
              child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'লগইন করুন',
                        style: TextStyle(fontSize: 36, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                          height:
                              160), 
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _pinController,
                            decoration: InputDecoration(
                              hintText: '✱✱✱✱',
                              hintStyle:
                                  TextStyle(fontSize: 34, color: Colors.grey),
                              border: InputBorder.none,
                              counterText: "",
                            ),
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            style: TextStyle(fontSize: 34, letterSpacing: 8),
                            obscureText: !_isPinVisible,
                            obscuringCharacter: '✱',
                            onChanged: _onPinChanged,
                          ),
                        ),
                      ),
                      SizedBox(
                          height:
                              30), 
                      ElevatedButton(
                        onPressed: _verifyPin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          shadowColor: Colors.blueAccent.withOpacity(0.3),
                          elevation: 5,
                          textStyle: TextStyle(fontSize: 20),
                        ),
                        child: Text(
                          'পিন যাচাই',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 60.0),
                  child: IconButton(
                    onPressed: _authenticateWithBiometrics,
                    icon: Icon(
                      Icons.fingerprint,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
