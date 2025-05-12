import 'package:bebshar_poristhiti_stock/sms/sms_purchase_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../bill/app_payment.dart';
import '../employee_management/ui/employee_list_screen.dart';
import '../report/report_page.dart';
import '../requirement/change_pin.dart';
import '../requirement/pin_verification_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../stock/product/product_page.dart';
import 'all_common_functions.dart';

class CustomDrawer extends StatefulWidget {
  final String mobile;

  CustomDrawer({
    required this.mobile,
  });

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool showAdditionalButtons = false;
  bool switch1 = true;
  bool switch2 = true;
  bool switch3 = true;
  bool switch4 = true;

  @override
  void initState() {
    super.initState();
    _loadFirestoreStatus();
    _loadPinRequiredStatus();
    _loadEditRequiredStatus();
    _loadDeleteRequiredStatus();
    _loadStockRequiredStatus();
  }

  Future<bool> _verifyPinWithFirebase() async {
    
    String? enteredPin = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        TextEditingController _pinController = TextEditingController();
        return AlertDialog(
          title: Container(
            decoration: BoxDecoration(
              color: Colors.blueAccent, 
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15), 
                topRight: Radius.circular(15), 
              ),
            ),
            padding: EdgeInsets.all(12),
            child: Center(
              child: Text(
                'পিন যাচাই করুন',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, 
                ),
              ),
            ),
          ),
          content: TextField(
            controller: _pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              letterSpacing: 4,
            ),
            inputFormatters: [
              LengthLimitingTextInputFormatter(
                  4), 
            ],
            decoration: InputDecoration(
              hintText: 'পিন লিখুন',
              hintStyle: TextStyle(color: Colors.grey),
              contentPadding:
              EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.blueAccent, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.blue[50],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: const Text(
                'বাতিল',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(_pinController.text);
              },
              child: const Text(
                'যাচাই করুন',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (enteredPin == null) {
      return false; 
    }

    try {
      
      String userId = _auth.currentUser!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('collection name')
          .doc(userId)
          .get();

      String savedPin = userDoc['field name']; 

      
      if (enteredPin == savedPin) {
        return true; 
      } else {
        return false; 
      }
    } catch (e) {
      print("Error verifying pin with Firebase: $e");
      return false; 
    }
  }

  
  Future<void> _loadPinRequiredStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      switch1 = prefs.getBool('pinRequired') ?? false;
    });
  }

  Future<void> _loadEditRequiredStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      switch2 = prefs.getBool('editRequired') ?? false;
    });
  }

  Future<void> _loadDeleteRequiredStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      switch3 = prefs.getBool('deleteRequired') ?? false;
    });
  }

  Future<void> _loadStockRequiredStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      switch4 = prefs.getBool('stockRequired') ?? false;
    });
  }

  
  Future<void> _loadFirestoreStatus() async {
    String userId = _auth.currentUser!.uid;

    try {
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('collection name')
          .doc(userId)
          .get();
      setState(() {
        switch1 = docSnapshot['field name'] ?? false;
        switch2 = docSnapshot['field name'] ?? false;
        switch3 = docSnapshot['field name'] ?? false;
        switch4 = docSnapshot['field name'] ?? false;
      });
    } catch (e) {
      debugPrint('Error loading status: $e');
    }
  }

  
  Future<void> _savePinRequiredStatus(bool isPinRequired) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pinRequired', isPinRequired);

    try {
      String userId = _auth.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('collection name')
          .doc(userId)
          .update({'field name': isPinRequired});
    } catch (e) {
      debugPrint('Error saving pin status: $e');
    }
  }

  Future<void> _updateEditRequiredStatus(bool isEditRequired) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('editRequired', isEditRequired);

    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('collection name')
          .doc(userId)
          .update({'field name': isEditRequired});
    } catch (e) {
      debugPrint('Error saving edit status: $e');
    }
  }

  Future<void> _updateDeleteRequiredStatus(bool isDeleteRequired) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('deleteRequired', isDeleteRequired);

    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('collection name')
          .doc(userId)
          .update({'field name': isDeleteRequired});
    } catch (e) {
      debugPrint('Error saving delete status: $e');
    }
  }

  Future<void> _updateStockRequiredStatus(bool isStockRequired) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('stockRequired', isStockRequired);

    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('collection name')
          .doc(userId)
          .update({'field name': isStockRequired});
    } catch (e) {
      debugPrint('Error saving stock status: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth * 0.75,
      child: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[400]!, Colors.yellow[700]!],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: EdgeInsets.zero, 
              child: Container(
                width: double
                    .infinity, 
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: CircleAvatar(
                        backgroundImage:
                        AssetImage('assets/icon/app_icon_foreground.png'),
                        radius: 35,
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'হাজী অটো হাউজ',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 5,
                            color: Colors.black45,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '01234567899',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.people_alt,
                    text: 'কর্মচারী',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EmployeeListScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.shopping_cart,
                    text: 'প্রোডাক্ট যুক্ত করুন',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProductPage()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.note_alt_rounded,
                    text: 'ক্রয় বিক্রয় রিপোর্ট',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ReportPage()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.message_outlined,
                    text: 'SMS ক্রয়',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SMSPurchasePage()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.payment_outlined,
                    text: 'বিল পরিশোধ',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AppPaymentPage()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.lock_reset_sharp,
                    text: 'পিন পরিবর্তন করুন',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ChangePinScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings,
                    text: 'সেটিংস',
                    onTap: () {
                      setState(() {
                        showAdditionalButtons = !showAdditionalButtons;
                      });
                    },
                  ),
                  if (showAdditionalButtons) ...[
                    SwitchListTile(
                      title: Text('লগইনের জন্য পিন'),
                      value: switch1,
                      onChanged: (bool value) async {
                        bool pinVerified = await _verifyPinWithFirebase();

                        if (pinVerified) {
                          setState(() {
                            switch1 = value;
                          });
                          await _savePinRequiredStatus(switch1);
                          await _loadPinRequiredStatus();
                        } else {
                          showGlobalSnackBar(context, 'পিন সঠিক নয়');
                        }
                      },
                    ),
                    SwitchListTile(
                      title: Text('এডিটের জন্য পিন'),
                      value: switch2,
                      onChanged: (bool value) async {
                        bool pinVerified = await _verifyPinWithFirebase();

                        if (pinVerified) {
                          setState(() {
                            switch2 = value;
                          });
                          await _updateEditRequiredStatus(switch2);
                          await _loadEditRequiredStatus();
                        } else {
                          showGlobalSnackBar(context, 'পিন সঠিক নয়');
                        }
                      },
                    ),

                    SwitchListTile(
                      title: Text('ডিলিটের জন্য পিন'),
                      value: switch3,
                      onChanged: (bool value) async {
                        bool pinVerified = await _verifyPinWithFirebase();

                        if (pinVerified) {
                          setState(() {
                            switch3 = value;
                          });
                          await _updateDeleteRequiredStatus(switch3);
                          await _loadDeleteRequiredStatus();
                        } else {
                          showGlobalSnackBar(context, 'পিন সঠিক নয়');
                        }
                      },
                    ),

                    SwitchListTile(
                      title: Text('স্টকের জন্য পিন'),
                      value: switch4,
                      onChanged: (bool value) async {
                        bool pinVerified = await _verifyPinWithFirebase();

                        if (pinVerified) {
                          setState(() {
                            switch4 = value;
                          });
                          await _updateStockRequiredStatus(switch4);
                          await _loadStockRequiredStatus();
                        } else {
                          showGlobalSnackBar(context, 'পিন সঠিক নয়');
                        }
                      },
                    ),
                  ],
                  _buildDrawerItem(
                    icon: Icons.logout,
                    text: 'লগ আউট',
                    onTap: () async {
                      await _savePinRequiredStatus(
                          true);
                      setState(() {
                        switch1 = true;
                      });

                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => PinVerificationScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ListTile _buildDrawerItem(
      {required IconData icon, required String text, required Function onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text, style: TextStyle(fontSize: 18)),
      onTap: () => onTap(),
    );
  }
}
