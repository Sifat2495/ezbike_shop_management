import 'package:bebshar_poristhiti_stock/widgets/all_common_functions.dart';
import 'package:flutter/material.dart';
import '../models/employee_model.dart';
import '../services/employee_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SalaryTransactionScreen extends StatefulWidget {
  final Employee employee;

  SalaryTransactionScreen({required this.employee});

  @override
  _SalaryTransactionScreenState createState() =>
      _SalaryTransactionScreenState();
}

class _SalaryTransactionScreenState extends State<SalaryTransactionScreen> {
  final TextEditingController _amountController = TextEditingController();
  final EmployeeService _employeeService = EmployeeService();
  final ScrollController _scrollController = ScrollController();

  double? _amountToPay = 0.0;
  bool _sendToCashbox = false;
  bool _isLoading = false;
  bool _hasMore = true; 
  bool _isSaving = false; 
  DocumentSnapshot? _lastDocument; 
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _checkAndUpdateAmountToPay();
    _loadTransactions();

    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent &&
          !_isLoading &&
          _hasMore) {
        _loadTransactions();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _sendToCashbox = false;
    super.dispose();
  }

  Future<void> _addTransaction(double amount) async {
    setState(() {
      _isSaving = true; 
    });
    try {
      await _employeeService.addSalaryTransaction(widget.employee.id, amount, _sendToCashbox);
      setState(() {
        _amountToPay = (_amountToPay ?? 0.0) - amount;
      });

      final userId = _employeeService.userId;
      final now = DateTime.now();

      final dailyDocRef = FirebaseFirestore.instance
          .collection('collection name')
          .doc(userId)
          .collection('collection name')
          .doc('${now.year}-${now.month}-${now.day}');

      await dailyDocRef.set({
        'expense': FieldValue.increment(amount),
      }, SetOptions(merge: true));

      
      final monthlyDocRef = FirebaseFirestore.instance
          .collection('collection name')
          .doc(userId)
          .collection('collection name')
          .doc('${now.year}-${now.month}');

      await monthlyDocRef.set({
        'expense': FieldValue.increment(amount),
      }, SetOptions(merge: true));

      
      final yearlyDocRef = FirebaseFirestore.instance
          .collection('collection name')
          .doc(userId)
          .collection('collection name')
          .doc('${now.year}');

      await yearlyDocRef.set({
        'expense': FieldValue.increment(amount),
      }, SetOptions(merge: true));

      
      final allTimeDocRef = FirebaseFirestore.instance
          .collection('collection name')
          .doc(userId)
          .collection('collection name')
          .doc('doc id/name');

      await allTimeDocRef.set({
        'expense': FieldValue.increment(amount),
      }, SetOptions(merge: true));

      if (_sendToCashbox) {
        final cashboxDoc = await allTimeDocRef.get();

        double currentCashboxTotal = cashboxDoc.exists
            ? (cashboxDoc.data()?['cashbox_total'] ?? 0.0) as double
            : 0.0;

        double newCashboxTotal = currentCashboxTotal - amount;

        await allTimeDocRef
            .set({'cashbox_total': newCashboxTotal}, SetOptions(merge: true));

        await FirebaseFirestore.instance
            .collection('collection name')
            .doc(userId)
            .collection('cashbox')
            .add({
          'time': Timestamp.now(),
          'amount': -amount,
          'reason': 'employee salary',
        });
      }

      
      _transactions.clear();
      _lastDocument = null; 
      _hasMore = true;
      await _loadTransactions();
    } catch (e) {
      showGlobalSnackBar(context,'Failed to add transaction: $e');
      } finally {
      setState(() {
        _isSaving = false; 
      });
    }
  }

  Future<void> _checkAndUpdateAmountToPay() async {
    final currentDate = DateTime.now();
    final employeeDoc = await FirebaseFirestore.instance
        .collection('collection name')
        .doc(_employeeService.userId)
        .collection('collection name')
        .doc(widget.employee.id)
        .get();

    if (employeeDoc.exists) {
      final data = employeeDoc.data() as Map<String, dynamic>;
      final lastTransactionDate =
      (data['lastTransactionDate'] as Timestamp?)?.toDate();
      final storedAmountToPay = (data['amountToPay'] ?? 0.0) as double;

      if (widget.employee.salary == null) {
        setState(() {
          _amountToPay = null;
        });
        return; 
      }

      if (lastTransactionDate == null ||
          lastTransactionDate.year != currentDate.year ||
          lastTransactionDate.month != currentDate.month) {
        setState(() {
          _amountToPay = storedAmountToPay + (widget.employee.salary ?? 0.0);
        });

        await employeeDoc.reference.update({
          'amountToPay': _amountToPay,
          'lastTransactionDate': Timestamp.fromDate(currentDate),
        });
      } else {
        setState(() {
          _amountToPay = storedAmountToPay;
        });
      }
    } else {
      setState(() {
        _amountToPay = widget.employee.salary ?? 0.0;
      });

      await employeeDoc.reference.set({
        'amountToPay': _amountToPay,
        'lastTransactionDate': Timestamp.fromDate(currentDate),
      });
    }
  }

  Future<void> _loadTransactions() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    QuerySnapshot querySnapshot;
    if (_lastDocument == null) {
      querySnapshot = await _employeeService.employeeCollection
          .doc(widget.employee.id)
          .collection('salary_transactions')
          .orderBy('time', descending: true)
          .limit(5)
          .get();
    } else {
      querySnapshot = await _employeeService.employeeCollection
          .doc(widget.employee.id)
          .collection('salary_transactions')
          .orderBy('time', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(5)
          .get();
    }

    if (querySnapshot.docs.isNotEmpty) {
      _lastDocument = querySnapshot.docs.last;
      _transactions.addAll(querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList());
    } else {
      _hasMore = false;
    }

    setState(() {
      _isLoading = false;
    });
  }

  

  Future<void> _editTransaction(String employeeId, String transactionId, double currentAmount) async {
    final updatedData = await _showEditDialog(currentAmount);
    if (updatedData != null) {
      final newAmount = updatedData['amount'];
      try {
        await _employeeService.updateSalaryTransaction(employeeId, transactionId, newAmount);
        setState(() {
          _transactions = _transactions.map((transaction) {
            if (transaction['id'] == transactionId) {
              return {...transaction, 'amount': newAmount};
            }
            return transaction;
          }).toList();
          _amountToPay = (_amountToPay ?? 0.0) - (newAmount - currentAmount);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update transaction: $e')),
        );
      }
    }
  }

  Future<void> _deleteTransaction(String employeeId, String transactionId, double amount) async {
    try {
      await _employeeService.deleteSalaryTransaction(employeeId, transactionId);
      setState(() {
        _transactions.removeWhere((transaction) => transaction['id'] == transactionId);
        _amountToPay = (_amountToPay ?? 0.0) + amount;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete transaction: $e')),
      );
    }
  }

  Future<Map<String, dynamic>?> _showEditDialog(double currentAmount) async {
    final TextEditingController amountController =
    TextEditingController(text: currentAmount.toString());

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Transaction'),
          content: TextField(
            controller: amountController,
            decoration: InputDecoration(labelText: 'Amount'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                if (amount != null) {
                  Navigator.of(context).pop({
                    'amount': amount,
                  });
                } else {
                  
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionItem(DocumentSnapshot transaction) {
    final amount = transaction['amount'].toDouble();
    final date = transaction['time'];

    String formattedDate = 'No date available';
    if (date != null && date is Timestamp) {
      formattedDate = DateFormat('MMM dd, yyyy, h:mm a').format(date.toDate());
    }

    return ListTile(
      title: Text('${convertToBengaliNumbers(amount.toStringAsFixed(0))}৳'),
      subtitle: Text('তারিখ: ${convertToBengaliNumbers(formattedDate)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              _editTransaction(widget.employee.id, transaction.id, amount);
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              _deleteTransaction(widget.employee.id, transaction.id, transaction['amount']);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('বেতনের হিসাব')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'বর্তমান বেতন: ${widget.employee.salary != null ? convertToBengaliNumbers(widget.employee.salary?.toStringAsFixed(0) ?? '0') : '0'}৳',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              _amountToPay != null
                  ? (_amountToPay! >= 0
                  ? 'দিতে হবে: ${convertToBengaliNumbers(_amountToPay!.toStringAsFixed(0))}৳'
                  : 'অগ্রিম দেয়া: ${convertToBengaliNumbers((-_amountToPay!).toStringAsFixed(0))}৳')
                  : 'বেতনের তথ্য পাওয়া যায়নি', 
              style: TextStyle(
                fontSize: 18,
                color: _amountToPay != null
                    ? (_amountToPay! >= 0 ? Colors.red : Colors.green)
                    : Colors.grey, 
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'বেতন পরিশোধের পরিমাণ',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: _sendToCashbox,
                  onChanged: (bool? value) {
                    setState(() {
                      _sendToCashbox = value ?? false;
                    });
                  },
                ),
                Text('ক্যাশবক্স থেকে দিলাম'),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () {
                final amount = double.tryParse(_amountController.text);
                if (amount != null && amount != 0) {
                  _addTransaction(amount);
                  _amountController.clear();
                  FocusScope.of(context).unfocus();
                } else {
                  showGlobalSnackBar(context,'সঠিক পরিমাণ দিন');
                  }
              },
              child: _isSaving ? CircularProgressIndicator() : Text('সেভ করুন'),
            ),
            SizedBox(height: 20),
            Text('লেনদেনের বিবরণ:', style: TextStyle(fontSize: 18)),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _employeeService.employeeCollection
                    .doc(widget.employee.id)
                    .collection('salary_transactions')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No transactions found'));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final transaction = snapshot.data!.docs[index];
                      return _buildTransactionItem(transaction);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
