import 'package:bebshar_poristhiti_stock/widgets/all_common_functions.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../sms/SMSHelper.dart';
import 'customer_sales_page.dart';

class Transaction {
  final String id;
  final String description;
  final String collector;
  final double totalSale;
  final double cashPayment;
  final double cashDiscount;
  final double remainingAmount;
  final DateTime date;

  Transaction({
    required this.id,
    required this.description,
    required this.collector,
    required this.totalSale,
    required this.cashPayment,
    required this.cashDiscount,
    required this.remainingAmount,
    required this.date,
  });

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      description: data['reason'] ?? '',
      collector: data['collector'] ?? '',
      totalSale: data['amount']?.toDouble() ?? 0.0,
      cashPayment: data['payment']?.toDouble() ?? 0.0,
      cashDiscount: data['discount']?.toDouble() ?? 0.0,
      remainingAmount: data['due']?.toDouble() ?? 0.0,
      date: (data['time'] as Timestamp).toDate(),
    );
  }
}

class CustomerHistoryPage extends StatefulWidget {
  final String userId;
  final String customerId;
  final String address;
  final String customerName;
  final String customerImageUrl;
  final String customerPhoneNumber;
  final List<String> phones;

  const CustomerHistoryPage({
    super.key,
    required this.userId,
    required this.customerId,
    required this.address,
    required this.customerName,
    required this.customerImageUrl,
    required this.customerPhoneNumber,
    required this.phones,
  });

  @override
  _CustomerHistoryPageState createState() => _CustomerHistoryPageState();
}

class _CustomerHistoryPageState extends State<CustomerHistoryPage> {
  double _totalRemaining = 0.0;
  String _father = '';
  String _mother = '';
  String _customerName = '';
  String _customerPhoneNumber = '';
  String _address = '';
  bool _isSwitchOn = false; 
  bool _showDetails = false; 
  List<String> allNumbers = [];

  @override
  void initState() {
    super.initState();
    _customerName = widget.customerName;
    _customerPhoneNumber = widget.customerPhoneNumber;
    _address = widget.address;
    allNumbers = [widget.customerPhoneNumber, ...widget.phones]
        .where((num) => num.isNotEmpty) 
        .toSet()
        .toList();
    _fetchCustomerDue();
    _fetchSwitchState();
  }

  void _closeDetails() {
    setState(() {
      _showDetails = false; 
    });
  }

  void _updateCustomerInfo(Map<String, dynamic> updatedData) {
    setState(() {
      _customerName = updatedData['name'];
      _customerPhoneNumber = updatedData['phone'];
      _address = updatedData['present_address']; 
    });
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Transaction'),
          content: Text('Are you sure you want to delete this transaction?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      double paymentDifference = transaction.cashPayment;

      try {
        await FirebaseFirestore.instance.runTransaction((firebaseTransaction) async {
          DocumentReference transactionRef = FirebaseFirestore.instance
              .collection('collection name')
              .doc(widget.userId)
              .collection('collection name')
              .doc(widget.customerId)
              .collection('history')
              .doc(transaction.id);

          DocumentReference customerRef = FirebaseFirestore.instance
              .collection('collection name')
              .doc(widget.userId)
              .collection('collection name')
              .doc(widget.customerId);

          DocumentReference yearlyTotalsRef = FirebaseFirestore.instance
              .collection('collection name')
              .doc(widget.userId)
              .collection('collection name')
              .doc('doc id/name');

          
          print('Deleting transaction: ${transaction.id}');
          print('Payment difference: $paymentDifference');

          
          DocumentSnapshot customerDoc = await firebaseTransaction.get(customerRef);
          if (!customerDoc.exists) {
            throw Exception('Customer document does not exist.');
          }

          double currentCustomerDue = (customerDoc.data() as Map<String, dynamic>)['customer_due']?.toDouble() ?? 0.0;

          
          DocumentSnapshot yearlyTotalsDoc = await firebaseTransaction.get(yearlyTotalsRef);
          if (!yearlyTotalsDoc.exists) {
            throw Exception('Yearly totals document does not exist.');
          }

          
          QuerySnapshot subsequentTransactions = await FirebaseFirestore.instance
              .collection('collection name')
              .doc(widget.userId)
              .collection('collection name')
              .doc(widget.customerId)
              .collection('history')
              .orderBy('time')
              .startAfter([Timestamp.fromDate(transaction.date)]) 
              .get();

          
          firebaseTransaction.delete(transactionRef);

          
          firebaseTransaction.update(customerRef, {
            'customer_due': currentCustomerDue + paymentDifference,
          });

          
          firebaseTransaction.update(yearlyTotalsRef, {
            'total_due': FieldValue.increment(paymentDifference),
          });

          
          for (var doc in subsequentTransactions.docs) {
            double currentDue = (doc.data() as Map<String, dynamic>)['due']?.toDouble() ?? 0.0;
            double adjustedRemainingAmount = currentDue + paymentDifference;

            firebaseTransaction.update(doc.reference, {
              'due': adjustedRemainingAmount,
            });
          }
        });
        _fetchCustomerDue(); 
      } catch (error) {
        print("Failed to delete transaction: $error");
      }
    }
  }

  Future<void> _fetchSwitchState() async {
    DocumentReference customerRef = FirebaseFirestore.instance
        .collection('collection name')
        .doc(widget.userId)
        .collection('collection name')
        .doc(widget.customerId);

    DocumentSnapshot customerDoc = await customerRef.get();

    if (customerDoc.exists) {
      setState(() {
        _isSwitchOn = (customerDoc.data() as Map<String, dynamic>)['status'] ?? false;
      });
    } else {
      
      await customerRef.set({'status': false}, SetOptions(merge: true));
      setState(() {
        _isSwitchOn = false;
      });
    }
  }

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  

  String formatDate(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  void _sendSMSpopup(String customerName) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        
        final screenWidth = MediaQuery.of(context).size.width;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), 
          ),
          title: Column(
            children: [
              Icon(
                Icons.sms_outlined,
                size: screenWidth * 0.15, 
                color: Colors.blue,
              ),
              SizedBox(height: screenWidth * 0.02),
              Text(
                'বাকির এসএমএস',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.05, 
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            'আপনি কি $customerName কে SMS দিয়ে কিস্তি মনে করাতে চান?',
            style: TextStyle(
              fontSize: screenWidth * 0.04, 
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly, 
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); 
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent, 
                padding: EdgeInsets.symmetric(
                  vertical: screenWidth * 0.02, 
                  horizontal: screenWidth * 0.05,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'বাতিল',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.045, 
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final shouldSendSMS =
                await SMSHelper.checkAndShowSMSWarning(context: context);
                if (shouldSendSMS) {
                  await SMSHelper.sendSMS(
                    phoneNumber: widget.customerPhoneNumber,
                    message: 'হাজি অটো হাউজে কিস্তি পরিশোধ করুন, আপনার মোট বাকি ${_totalRemaining.toStringAsFixed(0)} টাকা।',
                  );
                  Navigator.of(context).pop(); 
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, 
                padding: EdgeInsets.symmetric(
                  vertical: screenWidth * 0.02, 
                  horizontal: screenWidth * 0.05,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'SMS পাঠান',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.045, 
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Stream<List<Transaction>> _transactionHistoryStream() {
    return FirebaseFirestore.instance
        .collection('collection name')
        .doc(widget.userId)
        .collection('collection name')
        .doc(widget.customerId)
        .collection('history')
        .orderBy('time', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Transaction.fromFirestore(doc))
        .toList());
  }

  Future<void> _fetchCustomerDue() async {
    DocumentSnapshot customerDoc = await FirebaseFirestore.instance
        .collection('collection name')
        .doc(widget.userId)
        .collection('collection name')
        .doc(widget.customerId)
        .get();

    if (customerDoc.exists) {
      setState(() {
        _totalRemaining = (customerDoc.data() as Map<String, dynamic>)['customer_due']?.toDouble() ?? 0.0;
        _father = (customerDoc.data() as Map<String, dynamic>)['father_name'] ?? '';
        _mother = (customerDoc.data() as Map<String, dynamic>)['mother_name'] ?? '';
      });
    }
  }

  void _updateMainPhoneNumber(String newNumber) {
    FirebaseFirestore.instance
        .collection('collection name')
        .doc(widget.userId)
        .collection('collection name')
        .doc(widget.customerId)
        .update({'phone': newNumber});
  }

  void _updateAdditionalPhones(List<String> updatedList) {
    FirebaseFirestore.instance
        .collection('collection name')
        .doc(widget.userId)
        .collection('collection name')
        .doc(widget.customerId)
        .update({'phones': updatedList});
  }


  Future<void> _makeCall(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url,
          mode: LaunchMode
              .externalApplication); 
    } else {
      throw 'Could not launch $url';
    }
  }

  void _showPhoneNumberDialog(BuildContext context) {
    TextEditingController phoneController = TextEditingController();

    
    String mainPhoneNumber = widget.customerPhoneNumber;
    List<String> additionalPhones = List<String>.from(widget.phones);

    bool isEditingMain = false;
    TextEditingController mainPhoneController = TextEditingController(text: mainPhoneNumber);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Manage Phone Numbers"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  
                  Row(
                    children: [
                      Expanded(
                        child: isEditingMain
                            ? TextField(
                          controller: mainPhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(border: OutlineInputBorder()),
                        )
                            : GestureDetector(
                          onTap: () => _makeCall(mainPhoneNumber),
                          child: Text(mainPhoneNumber, style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      SizedBox(width: 10),
                      isEditingMain
                          ? GestureDetector(
                        onTap: () async {
                          String newValue = mainPhoneController.text.trim();
                          if (newValue.isNotEmpty && newValue != mainPhoneNumber) {
                            bool confirmed = await _showConfirmationDialog(
                                context, "Confirm Edit", "Save changes to primary number?");
                            if (confirmed) {
                              setState(() {
                                mainPhoneNumber = newValue;
                                isEditingMain = false;
                              });
                              _updateMainPhoneNumber(newValue); 
                            }
                          } else {
                            setState(() => isEditingMain = false);
                          }
                        },
                        child: Icon(Icons.check, color: Colors.green, size: 24),
                      )
                          : GestureDetector(
                        onTap: () => setState(() => isEditingMain = true),
                        child: Icon(Icons.edit, color: Colors.blue, size: 24),
                      ),
                      SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _makeCall(mainPhoneNumber),
                        child: Icon(Icons.call, color: Colors.green, size: 24),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: "Add New Number",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          String newPhone = phoneController.text.trim();
                          if (newPhone.isNotEmpty && !additionalPhones.contains(newPhone)) {
                            setState(() {
                              additionalPhones.add(newPhone);
                            });
                            _updateAdditionalPhones(additionalPhones);
                            phoneController.clear();
                          }
                        },
                        child: Icon(Icons.add, color: Colors.green, size: 24),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  
                  ...additionalPhones.asMap().entries.map((entry) {
                    int index = entry.key;
                    String phone = entry.value;
                    bool isEditing = false;
                    TextEditingController editController = TextEditingController(text: phone);

                    return StatefulBuilder(
                      builder: (context, innerSetState) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            isEditing
                                ? Expanded(
                              child: TextField(
                                controller: editController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(border: InputBorder.none),
                                autofocus: true,
                              ),
                            )
                                : Expanded(
                              child: GestureDetector(
                                onTap: () => _makeCall(phone),
                                child: Text(phone, style: TextStyle(fontSize: 16)),
                              ),
                            ),

                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _makeCall(phone),
                                  child: Icon(Icons.call, color: Colors.green, size: 20),
                                ),
                                SizedBox(width: 10),
                                isEditing
                                    ? GestureDetector(
                                  onTap: () async {
                                    String newValue = editController.text.trim();
                                    if (newValue.isNotEmpty && newValue != phone) {
                                      bool confirmed = await _showConfirmationDialog(
                                          context, "Confirm Edit", "Save changes to this number?");
                                      if (confirmed) {
                                        setState(() {
                                          additionalPhones[index] = newValue;
                                        });
                                        _updateAdditionalPhones(additionalPhones);
                                      }
                                    }
                                    innerSetState(() => isEditing = false);
                                  },
                                  child: Icon(Icons.check, color: Colors.green, size: 20),
                                )
                                    : GestureDetector(
                                  onTap: () {
                                    innerSetState(() => isEditing = true);
                                  },
                                  child: Icon(Icons.edit, color: Colors.blue, size: 20),
                                ),
                                SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () async {
                                    bool confirmed = await _showConfirmationDialog(
                                        context, "Confirm Delete", "Are you sure you want to delete this number?");
                                    if (confirmed) {
                                      setState(() {
                                        additionalPhones.removeAt(index);
                                      });
                                      _updateAdditionalPhones(additionalPhones);
                                    }
                                  },
                                  child: Icon(Icons.delete, color: Colors.red, size: 20),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  }).toList(),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Close"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _showConfirmationDialog(
      BuildContext context, String title, String message) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Confirm"),
          ),
        ],
      ),
    ) ??
        false;
  }

  void _editTransaction(Transaction transaction) async {
    TextEditingController cashPaymentController = TextEditingController(text: transaction.cashPayment.toStringAsFixed(0));

    bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
            child: Text(
              'কিস্তি এডিট এবং ডিলিট',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple, 
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              
              Row(
                children: [
                  
                  Expanded(
                    child: TextField(
                      controller: cashPaymentController,
                      decoration: InputDecoration(
                        labelText: 'কিস্তির পরিমাণ',
                        labelStyle: TextStyle(color: Colors.deepPurple), 
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8), 
                          borderSide: BorderSide(color: Colors.deepPurple),
                        ),
                      ),
                      style: TextStyle(fontSize: 16), 
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red, size: 28), 
                    onPressed: () async {
                      bool dPermission = await checkPermission(context, permissionField: 'isDelete');
                      if (dPermission) {
                        bool pinVerified = await checkPinPermission(
                            context,
                            isDelete: true,
                            isEdit: false);
                        if (pinVerified) {
                          Navigator.pop(context, false); 
                          await _deleteTransaction(transaction); 
                        }
                      } else {
                        Navigator.pop(context, false); 
                        await _deleteTransaction(transaction); 
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'বাতিল',
                style: TextStyle(color: Colors.deepPurple, fontSize: 16), 
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'সেভ করুন',
                style: TextStyle(color: Colors.deepPurple, fontSize: 16), 
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      double newCashPayment = double.tryParse(cashPaymentController.text) ?? transaction.cashPayment;
      double paymentDifference = newCashPayment - transaction.cashPayment;

      FirebaseFirestore.instance.runTransaction((firebaseTransaction) async {
        DocumentReference transactionRef = FirebaseFirestore.instance
            .collection('collection name')
            .doc(widget.userId)
            .collection('collection name')
            .doc(widget.customerId)
            .collection('history')
            .doc(transaction.id);

        DocumentReference customerRef = FirebaseFirestore.instance
            .collection('collection name')
            .doc(widget.userId)
            .collection('collection name')
            .doc(widget.customerId);

        DocumentReference yearlyTotalsRef = FirebaseFirestore.instance
            .collection('collection name')
            .doc(widget.userId)
            .collection('collection name')
            .doc('doc id/name');

        
        DocumentSnapshot customerDoc = await firebaseTransaction.get(customerRef);
        double currentCustomerDue = (customerDoc.data() as Map<String, dynamic>)['customer_due']?.toDouble() ?? 0.0;

        
        QuerySnapshot subsequentTransactions = await FirebaseFirestore.instance
            .collection('collection name')
            .doc(widget.userId)
            .collection('collection name')
            .doc(widget.customerId)
            .collection('history')
            .orderBy('time')
            .startAfter([transaction.date])
            .get();

        
        firebaseTransaction.update(transactionRef, {
          'payment': newCashPayment,
          'due': transaction.remainingAmount - paymentDifference,
        });

        
        firebaseTransaction.update(customerRef, {
          'customer_due': currentCustomerDue - paymentDifference,
        });

        firebaseTransaction.update(yearlyTotalsRef, {
          'total_due': FieldValue.increment(-paymentDifference),
        });

        
        for (var doc in subsequentTransactions.docs) {
          double currentDue = (doc.data() as Map<String, dynamic>)['due']?.toDouble() ?? 0.0;
          double adjustedRemainingAmount = currentDue - paymentDifference;

          firebaseTransaction.update(doc.reference, {
            'due': adjustedRemainingAmount,
          });
        }
      }).then((_) {
        _fetchCustomerDue(); 
      }).catchError((error) {
        print("Failed to update transaction: $error");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'কিস্তির খাতা',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.lightGreenAccent,
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            
            Container(
              padding: const EdgeInsets.all(10.0),
              color: Colors.greenAccent,
              child: Row(
                children: [
                  SizedBox(
                    width: 50.0, 
                    height: 80.0, 
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4.0), 
                      child: Image(
                        image: (widget.customerImageUrl.isNotEmpty &&
                            Uri.tryParse(widget.customerImageUrl)?.isAbsolute == true)
                            ? NetworkImage(widget.customerImageUrl)
                            : const AssetImage('assets/placeholder.png'),
                        fit: BoxFit.cover, 
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/placeholder.png',
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _customerName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _customerPhoneNumber,
                          style: const TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        Text(
                          _address,
                          style: const TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showDetails = !_showDetails; 
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, backgroundColor: Colors.blue, 
                          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0), 
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0), 
                          ),
                        ),
                        child: const Text(
                          'বিস্তারিত',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Visibility(
              visible: _showDetails,
              child: CustomerSalesPage(
                userId: widget.userId,
                customerDocId: widget.customerId,
                fatherName: _father,
                motherName: _mother,
                onGuarantorUpdated: _closeDetails,
                onCustomerInfoUpdated: _updateCustomerInfo,
              ),
            ),
            
            Container(
              padding: const EdgeInsets.all(10.0),
              color: Colors.red,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'বর্তমান বাকি: ${convertToBengaliNumbers(_totalRemaining.toStringAsFixed(0))}/-',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.yellowAccent),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showPhoneNumberDialog(context),
                    child: Icon(
                      Icons.call,
                      color: Colors.yellow,
                      size: 24.0,
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _sendSMSpopup(widget.customerName),
                        child: const Icon(
                          Icons.local_post_office_rounded,
                          color: Colors.yellow,
                          size: 24.0, 
                        ),
                      ),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('collection name')
                            .doc(widget.userId)
                            .collection('collection name')
                            .doc('doc id/name')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Text('...');
                          }
                          if (snapshot.hasError) {
                            return const Text('Error');
                          }
                          if (!snapshot.hasData || snapshot.data?.data() == null) {
                            return const Text('0');
                          }

                          final data = snapshot.data!.data() as Map<String, dynamic>;
                          final smsCount = data['sms_count'] ?? 0;

                          return Text(
                            '(${smsCount.toString()})',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.yellowAccent),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                ],
              ),
            ),

            StreamBuilder<List<Transaction>>(
              stream: _transactionHistoryStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(
                      child: Text('লেনদেনের ইতিহাস লোড করতে সমস্যা হয়েছে'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('কোনো কিস্তির লেনদেন পাওয়া যায়নি'));
                } else {
                  return Column(
                    children: [
                      
                      Table(
                        border: TableBorder.all(color: Colors.black, width: 1),
                        columnWidths: const {
                          0: FlexColumnWidth(1), 
                          1: FlexColumnWidth(1), 
                          2: FlexColumnWidth(1), 
                          3: FlexColumnWidth(1), 
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: Colors.lightBlueAccent),
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'তারিখ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'জমা',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'বাকী',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'স্বাক্ষর',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      Table(
                        border: TableBorder.all(color: Colors.black, width: 1),
                        columnWidths: const {
                          0: FlexColumnWidth(1), 
                          1: FlexColumnWidth(1), 
                          2: FlexColumnWidth(1), 
                          3: FlexColumnWidth(1), 
                        },
                        children: List.generate(snapshot.data!.length, (index) {
                          final transaction = snapshot.data![index];
                          return TableRow(
                            decoration: BoxDecoration(
                              color: index.isEven ? Colors.yellowAccent[100] : Colors.tealAccent,
                            ),
                            children: [
                              GestureDetector(
                                onTap: () {
                                  _editTransaction(transaction);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    formatDate(transaction.date),
                                    style: const TextStyle(fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  _editTransaction(transaction);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      if (transaction.cashPayment > 0 && transaction.cashDiscount == 0)
                                        Text(
                                          '${convertToBengaliNumbers(transaction.cashPayment.toStringAsFixed(0))}/-',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                      if (transaction.cashPayment > 0 && transaction.cashDiscount > 0)
                                        Text(
                                          'জমাঃ ${convertToBengaliNumbers(transaction.cashPayment.toStringAsFixed(0))}/-',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                      if (transaction.cashDiscount > 0)
                                        Text(
                                          'ডিসকাউন্টঃ ${convertToBengaliNumbers(transaction.cashDiscount.toStringAsFixed(0))}/-',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  bool ePermission = await checkPermission(context, permissionField: 'isEdit');
                                  if (ePermission) {
                                    bool pinVerified = await checkPinPermission(
                                        context,
                                        isDelete: true,
                                        isEdit: false);
                                    if (pinVerified) {
                                      _editTransaction(transaction);
                                    }
                                  } else {
                                    _editTransaction(transaction);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    '${convertToBengaliNumbers(transaction.remainingAmount.toStringAsFixed(0))}/-',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  bool ePermission = await checkPermission(context, permissionField: 'isEdit');
                                  if (ePermission) {
                                    bool pinVerified = await checkPinPermission(
                                        context,
                                        isDelete: true,
                                        isEdit: false);
                                    if (pinVerified) {
                                      _editTransaction(transaction);
                                    }
                                  } else {
                                    _editTransaction(transaction);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    transaction.collector,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
