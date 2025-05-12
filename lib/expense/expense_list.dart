import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/all_common_functions.dart';

class ExpenseList extends StatefulWidget {
  @override
  _ExpenseListState createState() => _ExpenseListState();
}

class _ExpenseListState extends State<ExpenseList> {
  final int _pageSize = 6;
  final List<DocumentSnapshot> _expenses = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  final Map<String, bool> _isButtonDisabled = {};

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  @override
  void dispose() {
    _expenses.clear();
    super.dispose();
  }

  void _fetchExpenses() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      Query query = FirebaseFirestore.instance
          .collection('collection name')
          .doc(user.uid)
          .collection('expense')
          .orderBy('time', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _lastDocument = snapshot.docs.last;
          _expenses.addAll(snapshot.docs);
          _hasMore = snapshot.docs.length == _pageSize;
        });
      } else {
        setState(() {
          _hasMore = false;
        });
      }
    } catch (e) {
      print("Error fetching expenses: $e");
      
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _editExpense(
      DocumentSnapshot expense, BuildContext context) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final Map<String, dynamic> data = expense.data() as Map<String, dynamic>;
    final TextEditingController reasonController =
        TextEditingController(text: data['reason']);
    final TextEditingController amountController =
        TextEditingController(text: data['amount'].toString());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('এডিট করুণ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reasonController,
                decoration: InputDecoration(labelText: 'বর্ণনা'),
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'টাকার পরিমাণ'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('বাতিল'),
            ),
            ElevatedButton(
              onPressed: () async {
                showLoadingDialog(context, message: 'এডিট হচ্ছে...');
                final reason = reasonController.text.trim();
                final newAmount = double.tryParse(amountController.text);
                final oldAmount = data['amount'];
                final type = data['type'];

                if (reason.isEmpty || newAmount == null || newAmount <= 0) {
                  showGlobalSnackBar(context, 'সঠিক তথ্য দিন।');
                  return;
                }

                try {
                  
                  await FirebaseFirestore.instance
                      .collection('collection name')
                      .doc(user.uid)
                      .collection('expense')
                      .doc(expense.id)
                      .update({
                    'reason': reason,
                    'amount': newAmount,
                  });

                  
                  final allTimeDocRef = FirebaseFirestore.instance
                      .collection('collection name')
                      .doc(user.uid)
                      .collection('collection name')
                      .doc('doc id/name');

                  if (type == 'deposit') {
                    await allTimeDocRef.update({
                      'cash': FieldValue.increment(newAmount - oldAmount),
                    });
                  } else {
                    await allTimeDocRef.update({
                      'cash': FieldValue.increment(oldAmount - newAmount),
                    });
                  }

                  
                  final dailyDocRef = FirebaseFirestore.instance
                      .collection('collection name')
                      .doc(user.uid)
                      .collection('collection name')
                      .doc(
                          '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}');

                  if (type == 'deposit') {
                    await dailyDocRef.update({
                      'add_cash': FieldValue.increment(newAmount - oldAmount),
                    });
                  } else if (type == 'cost') {
                    await dailyDocRef.update({
                      'cost': FieldValue.increment(newAmount - oldAmount),
                    });
                  } else if (type == 'cashOut') {
                    await dailyDocRef.update({
                      'withdraw': FieldValue.increment(newAmount - oldAmount),
                    });
                  }

                  Navigator.pop(context);
                  showGlobalSnackBar(context, 'খরচ আপডেট হয়েছে।');
                  hideLoadingDialog(context);
                } catch (e) {
                  print('Error: $e');
                  showGlobalSnackBar(context, 'ডেটা আপডেটে সমস্যা।');
                  hideLoadingDialog(context);
                }
              },
              child: Text('ঠিক আছে'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteExpense(DocumentSnapshot expense) async {
    showLoadingDialog(context, message: 'ডিলিট হচ্ছে...');
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      hideLoadingDialog(context);
      return;
    }

    final Map<String, dynamic>? data = expense.data() as Map<String, dynamic>?;
    if (data == null ||
        !data.containsKey('amount') ||
        !data.containsKey('type')) {
      hideLoadingDialog(context);
      return;
    }

    final double amount = data['amount'] is double
        ? data['amount']
        : double.tryParse(data['amount'].toString()) ?? 0.0;

    final String type = data['type'] ?? '';

    if (amount <= 0 || type.isEmpty) {
      hideLoadingDialog(context);
      return;
    }

    DateTime now = DateTime.now();

    try {
      
      await FirebaseFirestore.instance
          .collection('collection name')
          .doc(user.uid)
          .collection('expense')
          .doc(expense.id)
          .delete();

      
      final allTimeDocRef = FirebaseFirestore.instance
          .collection('collection name')
          .doc(user.uid)
          .collection('collection name')
          .doc('doc id/name');

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(allTimeDocRef);

        if (!snapshot.exists) {
          transaction.set(allTimeDocRef, {'cash': 0.0});
        }

        final allTimeData = snapshot.data() ?? {};
        double cash = allTimeData['cash'] is double
            ? allTimeData['cash']
            : double.tryParse(allTimeData['cash'].toString()) ?? 0.0;

        if (type == 'deposit') {
          cash -= amount;
        } else if (type == 'cost' || type == 'cashOut') {
          cash += amount;
        }

        transaction.update(allTimeDocRef, {'cash': cash});
      });

      
      final dailyDocRef = FirebaseFirestore.instance
          .collection('collection name')
          .doc(user.uid)
          .collection('collection name')
          .doc('${now.year}-${now.month}-${now.day}');

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final dailySnapshot = await transaction.get(dailyDocRef);

        if (!dailySnapshot.exists) {
          transaction.set(dailyDocRef, {'add_cash': 0.0, 'cost': 0.0, 'withdraw': 0.0});
        }

        final dailyData = dailySnapshot.data() ?? {};
        double addCash = dailyData['add_cash'] is double
            ? dailyData['add_cash']
            : double.tryParse(dailyData['add_cash'].toString()) ?? 0.0;
        double cost = dailyData['cost'] is double
            ? dailyData['cost']
            : double.tryParse(dailyData['cost'].toString()) ?? 0.0;
        double withdraw = dailyData['withdraw'] is double
            ? dailyData['withdraw']
            : double.tryParse(dailyData['withdraw'].toString()) ?? 0.0;

        if (type == 'deposit') {
          addCash -= amount;
        } else if (type == 'cost') {
          cost -= amount;
        } else if (type == 'cashOut') {
          withdraw -= amount; 
        }

        transaction.update(dailyDocRef, {
          'add_cash': addCash,
          'cost': cost,
          'withdraw': withdraw,
        });
      });

      
      setState(() {
        _expenses.removeWhere((e) => e.id == expense.id);
      });
    } catch (e) {
      print('Error deleting expense: $e');
    }
    _fetchExpenses();
    hideLoadingDialog(context);
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, DocumentSnapshot expense) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ডিলিট নিশ্চিত করুন'),
          content: Text(
              'আপনি কি ডিলিট করতে চান? আপনি যদি ডিলিট করেন তাহলে এই হিসাব একেবারে মুছে যাবে।'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(context).pop(); 

                
                await _deleteExpense(expense);
                _disableButton(expense.id); 
              },
              child: Text('হ্যাঁ চাই'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop(); 
              },
              child: Text('চাই না'),
            ),
          ],
        );
      },
    );
  }

  void _disableButton(String expenseId) {
    setState(() {
      _isButtonDisabled[expenseId] = true;
    });
  }

  void _enableAllButtons() {
    setState(() {
      _isButtonDisabled.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!_isLoading &&
            _hasMore &&
            scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          _fetchExpenses();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _enableAllButtons();
            _expenses.clear();
            _lastDocument = null;
            _hasMore = true;
          });
          _fetchExpenses();
        },
        child: _expenses.isEmpty
            ? Center(
                child: Text(
                  'কোনো জমা-খরচ যুক্ত করা হয়নাই।',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: _expenses.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _expenses.length) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final expense = _expenses[index];
                  final data = expense.data() as Map<String, dynamic>;
                  final reason = data['reason'] ?? 'No reason';
                  final amount = data['amount']?.toStringAsFixed(2) ?? '0.0';
                  final type = data['type'];
                  final timestamp = (data['time'] as Timestamp).toDate();
                  final formattedDate =
                      DateFormat('dd-MM-yyyy').format(timestamp);
                  final formattedTime = DateFormat('hh:mm a').format(timestamp);

                  
                  Color color = Colors.grey;
                  String displayType = '';

                  if (type == 'deposit') {
                    color = Colors.green;
                    displayType = 'জমা';
                  } else if (type == 'cashOut') {
                    color = Colors.blue;
                    displayType = 'উত্তোলন';
                  } else if (type == 'cost') {
                    color = Colors.red;
                    displayType = 'খরচ';
                  }

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                    color: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15), 
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(1),
                      title: Padding(
                        padding:
                            const EdgeInsets.only(left: 15.0), 
                        child: Text(
                          'টাকা: ৳${double.tryParse(amount)?.toStringAsFixed(0) ?? amount}',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      subtitle: Padding(
                        padding:
                            const EdgeInsets.only(left: 15.0), 
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$displayType: $reason',
                              style: TextStyle(color: Colors.white),
                            ),
                            Text(
                              'তারিখ: $formattedDate, $formattedTime',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: _isButtonDisabled[expense.id] == true ? Colors.grey : Colors.white, 
                            ),
                            onPressed: _isButtonDisabled[expense.id] == true
                                ? null 
                                : () async {
                              bool ePermission = await checkPermission(context,
                                  permissionField: 'isEdit');
                              if (ePermission) {
                                bool pinVerified = await checkPinPermission(
                                    context,
                                    isDelete: false,
                                    isEdit: true);
                                if (pinVerified) {
                                  _editExpense(expense, context);
                                  _disableButton(expense.id); 
                                }
                              } else {
                                _editExpense(expense, context);
                                _disableButton(expense.id); 
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_forever,
                              color: _isButtonDisabled[expense.id] == true ? Colors.grey : Colors.white, 
                            ),
                            onPressed: _isButtonDisabled[expense.id] == true
                                ? null 
                                : () async {
                              bool dPermission = await checkPermission(
                                context,
                                permissionField: 'isDelete',
                              );

                              if (dPermission) {
                                bool pinVerified = await checkPinPermission(
                                  context,
                                  isDelete: true,
                                  isEdit: false,
                                );

                                if (pinVerified) {
                                  
                                  _showDeleteConfirmationDialog(context, expense);
                                }
                              } else {
                                
                                _showDeleteConfirmationDialog(context, expense);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
