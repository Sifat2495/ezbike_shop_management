import 'package:bebshar_poristhiti_stock/requirement/pin_setup_screen.dart';
import 'package:bebshar_poristhiti_stock/requirement/pin_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/all_common_functions.dart';

class LoginScreen extends StatefulWidget {

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String _verificationId = '';
  bool _isOtpSent = false;
  static const String _secretPin = '**********'; // Replace with your actual secret pin
  
  
  static const String _targetPhoneNumber = '+8801234567899';

  @override
  void dispose() {
    _pinController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final String enteredPin = _pinController.text.trim();
    if (enteredPin == _secretPin) {
      try {
        
        showLoadingDialog(context, message: 'OTP পাঠানো হচ্ছে...');

        await _auth.verifyPhoneNumber(
          phoneNumber: _targetPhoneNumber,
          verificationCompleted: (PhoneAuthCredential credential) async {
            await _auth.signInWithCredential(credential);
            hideLoadingDialog(context); 
            _handleUserNavigation();
          },
          verificationFailed: (FirebaseAuthException e) {
            hideLoadingDialog(context); 
            showGlobalSnackBar(context,'Verification failed: ${e.message}');
          },
          codeSent: (String verificationId, int? resendToken) {
            hideLoadingDialog(context); 
            setState(() {
              _verificationId = verificationId;
              _isOtpSent = true;
            });
            showGlobalSnackBar(context,'OTP পাঠানো হয়েছে।');
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            _verificationId = verificationId;
          },
        );
      } catch (e) {
        hideLoadingDialog(context); 
        showGlobalSnackBar(context,'OTP পাঠানো ব্যর্থ হয়েছে: $e');
      }
    } else {
      showGlobalSnackBar(context,'দয়াকরে সঠিক গোপন পিন দিন');
    }
  }

  Future<void> _verifyOtp() async {
    final String otp = _otpController.text.trim();
    if (_verificationId.isNotEmpty && otp.isNotEmpty) {
      try {
        
        showLoadingDialog(context, message: 'OTP যাচাই হচ্ছে...');

        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId,
          smsCode: otp,
        );
        await _auth.signInWithCredential(credential);

        hideLoadingDialog(context); 
        _handleUserNavigation();
      } catch (e) {
        hideLoadingDialog(context); 
        showGlobalSnackBar(context,'ভুল OTP দিয়েছেন, আবার চেষ্টা করুন');
      }
    } else {
      showGlobalSnackBar(context,'দয়াকরে সঠিক OTP দিন');
    }
  }

  Future<void> _handleUserNavigation() async {
    User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      print("Current User ID: ${currentUser.uid}"); 

      
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('collection name')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        
        bool isPinRequired = userDoc['isPinRequired'] ?? false;

        
        if (isPinRequired) {
          _navigateToPinVerificationScreen();
        } else {
          
          _navigateToPinVerificationScreen();
        }
      } else {
        
        await _saveUserDataToFirestore();
        _navigateToPinSetupScreen();
      }
    } else {
      print("No user is signed in."); 
      showGlobalSnackBar(context,'ব্যবহারকারী সাইন ইন করা হয়নি।');
    }
  }

  Future<void> _saveUserDataToFirestore() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      print("Saving user data to Firestore for user: ${currentUser.uid}"); 

      
      await FirebaseFirestore.instance.collection('collection name').doc(currentUser.uid).set({
        'phone': currentUser.phoneNumber ?? 'N/A', 
        'createdAt': FieldValue.serverTimestamp(),
        
        'isDelete': true,
        'isEdit': true,
        'isPinRequired': false,
        'isStock': true,
        'permission': true,
        'terminate': false,
      }).then((value) async {
        print("User data saved successfully.");

        
        await FirebaseFirestore.instance
            .collection('collection name')
            .doc(currentUser.uid)
            .collection('collection name')
            .doc('doc id/name')
            .set({
          'sms_count': 0,
          'cash': 0.0,
        }).then((value) {
          print("Yearly totals document created successfully.");
        }).catchError((error) {
          print("Error creating yearly totals document: $error");
        });
      }).catchError((error) {
        print("Error saving user data: $error");
      });
    } else {
      print("No user is currently signed in.");
    }
  }

  void _navigateToPinSetupScreen() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PinSetupScreen(),
      ),
    );
  }

  void _navigateToPinVerificationScreen() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PinVerificationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/login_pic.jpg',
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'হাজী অটো হাউজ',
                    style: TextStyle(
                      fontSize: screenWidth * 0.08,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.001),
                  Text(
                    'লগইন করুন',
                    style: TextStyle(
                      fontSize: screenWidth * 0.07,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  if (!_isOtpSent) ...[
                    _buildTextField(_pinController, 'গোপন পিন নম্বর', TextInputType.number, obscureText: true),
                    SizedBox(height: 16),
                    _buildButton('লগইন', _sendOtp),
                  ] else ...[
                    TextField(
                      controller: _otpController,
                      decoration: InputDecoration(
                        labelText: 'এখানে SMS থেকে পাওয়া OTP-টি দিন',
                        labelStyle: TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        counterText: '',
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 16),
                    _buildButton('OTP যাচাই করুন', _verifyOtp),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, TextInputType inputType, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      keyboardType: inputType,
      style: TextStyle(color: Colors.white),
      textAlign: TextAlign.center,
      obscureText: obscureText,
      obscuringCharacter: '✱',
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    
    Color buttonColor = text == 'লগইন'
        ? Colors.green 
        : text == 'OTP যাচাই করুন'
        ? Colors.blue 
        : Colors.grey; 

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
        backgroundColor: buttonColor, 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }
}
