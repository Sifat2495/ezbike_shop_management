import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChangePinScreen extends StatefulWidget {
  @override
  _ChangePinScreenState createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _oldPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmNewPinController = TextEditingController();

  bool _isOldPinVisible = false; 
  bool _isNewPinVisible = false; 
  bool _isConfirmNewPinVisible = false; 

  void _changePin() async {
    User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      String uid = currentUser.uid;
      String oldPin = _oldPinController.text.trim();
      String newPin = _newPinController.text.trim();
      String confirmNewPin = _confirmNewPinController.text.trim();

      
      if (newPin.length != 4 || confirmNewPin.length != 4) {
        _showMessage('পিন ৪ সংখ্যার হতে হবে');
        return;
      }

      
      if (newPin != confirmNewPin) {
        _showMessage('নতুন পিন এবং নিশ্চিত পিন মিলছে না');
        return;
      }

      try {
        
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('collection name')
            .doc(uid)
            .get();

        String storedPin = userDoc['pin']; 

        
        if (oldPin != storedPin) {
          _showMessage('বর্তমান পিন সঠিক নয়');
          return;
        }

        
        await FirebaseFirestore.instance.collection('collection name').doc(uid).update({
          'pin': newPin,
        });

        _showMessage('পিন সফলভাবে পরিবর্তন হয়েছে', isSuccess: true);

        
        Navigator.of(context).pop();
      } catch (e) {
        _showMessage('পিন পরিবর্তন করতে ব্যর্থ হয়েছে: $e');
      }
    }
  }

  
  void _showMessage(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('পিন পরিবর্তন করুন'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.redAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Text(
                    'এখানে ৪ সংখ্যার পিন পরিবর্তন করুন',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 30),
                _buildPinInputField('বর্তমান পিন দিন', _oldPinController, _isOldPinVisible, () {
                  setState(() {
                    _isOldPinVisible = !_isOldPinVisible;
                  });
                }),
                SizedBox(height: 10),
                _buildPinInputField('নতুন পিন (৪ সংখ্যার)', _newPinController, _isNewPinVisible, () {
                  setState(() {
                    _isNewPinVisible = !_isNewPinVisible;
                  });
                }),
                SizedBox(height: 10),
                _buildPinInputField('নতুন পিন নিশ্চিত করুন', _confirmNewPinController, _isConfirmNewPinVisible, () {
                  setState(() {
                    _isConfirmNewPinVisible = !_isConfirmNewPinVisible;
                  });
                }),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _changePin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                    shadowColor: Colors.black,
                    textStyle: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 18,
                    ),
                  ),
                  child: Text(
                    'পরিবর্তন করুন',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  
  Widget _buildPinInputField(String label, TextEditingController controller, bool isPinVisible, VoidCallback toggleVisibility) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50.0), 
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white),
          filled: true,
          fillColor: Colors.white24,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isPinVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.white,
            ),
            onPressed: toggleVisibility,
          ),
        ),
        style: TextStyle(color: Colors.white),
        keyboardType: TextInputType.number,
        obscureText: !isPinVisible,
        maxLength: 4,
        textAlign: TextAlign.center, 
      ),
    );
  }
}
