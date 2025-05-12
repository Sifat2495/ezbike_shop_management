import 'dart:async';
import 'package:bebshar_poristhiti_stock/widgets/all_common_functions.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'PopUpPage.dart';
import 'notification/notification_button.dart';
import 'report/all_transactions/all_transactions.dart';
import 'widgets/large_action_buttons.dart';
import 'widgets/summary_card_section.dart';
import 'widgets/action_grid.dart';
import 'widgets/support_section.dart';
import 'widgets/custom_drawer.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final String _mobile = "phone number";
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String formattedDate =
  DateFormat('EEEE, d MMMM, y', 'bn_BD').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowPopup();
    });
  }

  Future<void> _checkAndShowPopup() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('PopUpPage')
        .where('about_permission', isEqualTo: true)
        .get();


    if (querySnapshot.docs.isNotEmpty) {
      _showPopupPage();
    }
  }

  void _showPopupPage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PopUpPage();
      },
    );
  }

  Future<void> _refreshData() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor:
            Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF22A6F8),
                Color(
                    0xFF0267A1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'হাজী অটো হাউজ',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              formattedDate,
              style: TextStyle(
                  color: Colors.black54, fontSize: screenWidth * 0.035),
            ),
          ],
        ),
        actions: [
          NotificationButton(
              iconSize: screenWidth *
                  0.07),
          SizedBox(width: screenWidth * 0.03),
        ],
      ),
      drawer: CustomDrawer(
        mobile: _mobile,
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentBalance(screenWidth, screenHeight),
            SizedBox(height: screenHeight * 0.01),

            SummaryCardSection(screenWidth),
            SizedBox(height: screenHeight * 0.007),

            LargeActionButtons(context, screenWidth, screenHeight),
            SizedBox(height: screenHeight * 0.007),
            ActionGrid(screenWidth, screenHeight),
            SizedBox(height: screenHeight * 0.01), 
            SupportSection(screenWidth),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildCurrentBalance(double screenWidth, double screenHeight) {
    final User? user = _auth.currentUser; 
    if (user == null) {
      return Center(child: Text("User not logged in"));
    }

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('collection name')
          .doc(user.uid) 
          .collection('collection name')
          .doc('doc id/name')
          .snapshots(),
      builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          FirebaseFirestore.instance
              .collection('collection name')
              .doc(user.uid)
              .collection('collection name')
              .doc('doc id/name')
              .set({'cash': 0.0});

          return Center(child: Text("Initializing..."));
        }

        final doc = snapshot.data!;
        final data = doc.data() as Map<String, dynamic>;

        double cashboxTotal = data.containsKey('cash')
            ? (data['cash'] is int
            ? (data['cash'] as int).toDouble()
            : (data['cash'] as double? ?? 0.0))
            : 0.0; 
        String formattedBalance = cashboxTotal % 1 == 0
            ? convertToBengaliNumbers(cashboxTotal.toInt().toString())
            : convertToBengaliNumbers(cashboxTotal.toStringAsFixed(2));

        if (cashboxTotal == 0) {
          formattedBalance = "৳০";
        }

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AllTransactions()),
            );
          },
          child: Container(
            width: screenWidth * 1.0,
            padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.02,
              horizontal: screenWidth * 0.05,
            ),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [Colors.white54, Colors.blue.shade400],
                center: Alignment.bottomCenter,
                radius: 1.2,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'ক্যাশবক্স',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.07,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                Text(
                  formattedBalance,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.08,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
