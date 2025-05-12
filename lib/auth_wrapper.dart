import 'package:bebshar_poristhiti_stock/requirement/terminate_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'home_screen.dart';
import 'requirement/login_screen.dart';
import 'requirement/pin_verification_screen.dart';

class AuthWrapper extends StatelessWidget {
  Future<Map<String, dynamic>> _getUserState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    User? user = FirebaseAuth.instance.currentUser;
    bool isPinRequired = prefs.getBool('pinRequired') ?? true;

    if (user != null) {
      
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('collection name')
          .doc(user.uid)
          .get();

      
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      
      bool isTerminated = userData['terminate'] ?? false;

      return {
        'user': user,
        'isPinRequired': isPinRequired,
        'isTerminated': isTerminated,
      };
    }

    return {
      'user': null,
      'isPinRequired': isPinRequired,
      'isTerminated': false,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserState(),
      builder: (context, snapshot) {
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        
        if (snapshot.hasError) {
          return Center(child: Text("Something went wrong"));
        }

        
        Map<String, dynamic> data = snapshot.data ?? {};
        User? user = data['user'];
        bool isPinRequired = data['isPinRequired'] ?? false;
        bool isTerminated = data['isTerminated'] ?? false;

        if (user != null) {
          if (isTerminated) {
            
            return TerminatePage();
          }

          
          if (isPinRequired) {
            return PinVerificationScreen();
          }
          
          else {
            return HomeScreen();
          }
        } else {
          
          return LoginScreen();
        }
      },
    );
  }
}
