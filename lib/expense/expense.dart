import 'package:flutter/material.dart';
import '../widgets/all_common_functions.dart';
import 'expense_page_ui.dart';
import 'firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpensePage extends StatefulWidget {
  @override
  _ExpensePageState createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  Future<void> _addExpense(String type) async {
    final reason = _reasonController.text;
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      showGlobalSnackBar(context, 'দয়া করে সঠিক পরিমাণ লিখুন।');
      return;
    }
    try {
      await FirebaseService.addExpense(reason, amount, type, context);
      _reasonController.clear();
      _amountController.clear();
    } catch (error) {
      showGlobalSnackBar(context, 'ত্রুটি ঘটেছে: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Center(
        child: Text(
          'কোনো ব্যবহারকারী লগইন করেনি।',
          style: TextStyle(fontSize: 18, color: Colors.red),
        ),
      );
    }

    final yearlyTotalsStream = FirebaseFirestore.instance
        .collection('collection name')
        .doc(user.uid)
        .collection('collection name')
        .doc('doc id/name')
        .snapshots();

    final dailyTotalsStream = FirebaseFirestore.instance
        .collection('collection name')
        .doc(user.uid)
        .collection('collection name')
        .doc('${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'জমা-খরচের হিসাব',
        ),
        centerTitle: true,
        backgroundColor: Colors.blue[400],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: yearlyTotalsStream,
        builder: (context, yearlySnapshot) {
          if (yearlySnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final yearlyData = yearlySnapshot.data?.data() ?? {};
          final double cash = yearlyData['cash'] ?? 0.0;

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: dailyTotalsStream,
            builder: (context, dailySnapshot) {
              if (dailySnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              final dailyData = dailySnapshot.data?.data() ?? {};
              final double addCash = dailyData['add_cash'] ?? 0.0;
              final double cost = dailyData['cost'] ?? 0.0;
              final double withdraw = dailyData['withdraw'] ?? 0.0;

              return ExpensePageUI(
                reasonController: _reasonController,
                amountController: _amountController,
                addExpense: _addExpense,
                addCash: addCash,
                cash: cash,
                cost: cost,
                withdraw: withdraw,
              );
            },
          );
        },
      ),
    );
  }
}
