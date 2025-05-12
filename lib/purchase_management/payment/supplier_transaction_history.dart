import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../sms/SMSHelper.dart';
import '../../widgets/all_common_functions.dart';

class Transaction {
  final String id;
  final String description;
  final double totalPurchase;
  final double cashPayment;
  final double remainingAmount;
  final DateTime date;
  final List<String>? imageUrl;

  Transaction({
    required this.id,
    required this.description,
    required this.totalPurchase,
    required this.cashPayment,
    required this.remainingAmount,
    required this.date,
    this.imageUrl,
  });

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      description: data['details'] ?? '',
      totalPurchase: data['amount']?.toDouble() ?? 0.0,
      cashPayment: data['payment']?.toDouble() ?? 0.0,
      remainingAmount: data['due']?.toDouble() ?? 0.0,
      date: (data['time'] as Timestamp).toDate(),
      imageUrl: List<String>.from(data['purchase_photo'] ?? []),
    );
  }
}

class TransactionDetails extends StatefulWidget {
  final String description;

  const TransactionDetails({required this.description, Key? key})
      : super(key: key);

  @override
  _TransactionDetailsState createState() => _TransactionDetailsState();
}

class _TransactionDetailsState extends State<TransactionDetails> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'বিস্তারিত: ${widget.description}',
          style: const TextStyle(fontSize: 10),
          maxLines: _isExpanded ? null : 1, 
          overflow: TextOverflow
              .ellipsis, 
        ),
        if (!_isExpanded) 
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = true; 
              });
            },
            child: const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
            ),
          ),
        if (_isExpanded) 
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = false; 
              });
            },
            child: const Icon(
              Icons.keyboard_arrow_up,
              size: 18,
            ),
          ),
      ],
    );
  }
}

class SupplierHistoryPage extends StatefulWidget {
  final String userId;
  final String supplierId;
  final String supplierName;
  final String supplierImageUrl;
  final String supplierPhoneNumber;

  const SupplierHistoryPage({
    Key? key,
    required this.userId,
    required this.supplierId,
    required this.supplierName,
    required this.supplierImageUrl,
    required this.supplierPhoneNumber,
  }) : super(key: key);

  @override
  _SupplierHistoryPageState createState() => _SupplierHistoryPageState();
}

class _SupplierHistoryPageState extends State<SupplierHistoryPage> {
  int smsCount = 0; 
  double _totalRemaining = 0.0;
  late Future<List<Transaction>> _transactionHistory;

  @override
  void initState() {
    super.initState();
    _transactionHistory = fetchSupplierHistory();
    _transactionHistoryStream().listen((transactions) {
      if (transactions.isNotEmpty) {
        _totalRemaining = transactions.first.remainingAmount;
      } else {
        
        _totalRemaining = 0.0; 
      }
    });
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
                'Cancel',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.045, 
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await SMSHelper.sendSMS(
                  phoneNumber: widget.supplierPhoneNumber,
                  message: 'আপনার কিস্তি পরিশোধ করুন, আপনার মোট বাকি ${_totalRemaining.toStringAsFixed(0)} টাকা। হাজি অটো হাউজে।',
                );
                Navigator.of(context).pop(); 
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
                'Send SMS',
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
        .collection('suppliers')
        .doc(widget.supplierId)
        .collection('history')
        .orderBy('time', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Transaction.fromFirestore(doc))
        .toList());
  }

   Future<List<Transaction>> fetchSupplierHistory() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('collection name')
        .doc(widget.userId)
        .collection('suppliers')
        .doc(widget.supplierId)
        .collection('history')
        .orderBy('time', descending: true)
        .get();

    List<Transaction> transactions = querySnapshot.docs
        .map((doc) => Transaction.fromFirestore(doc))
        .toList();

    if (transactions.isNotEmpty) {
      _totalRemaining = transactions.first.remainingAmount;
    } else {
      
      _totalRemaining = 0.0; 
    }
    return transactions;
  }

  Future<void> updateTransactionAndRecalculate(Transaction transaction,
      double newTotalPurchase, double newCashPayment) async {
    final transactionRef = FirebaseFirestore.instance
        .collection('collection name')
        .doc(widget.userId)
        .collection('suppliers')
        .doc(widget.supplierId)
        .collection('history')
        .doc(transaction.id);

    double previousRemainingAmount = transaction.remainingAmount;
    double newRemainingAmount =
        previousRemainingAmount + (newTotalPurchase - newCashPayment);

    await transactionRef.update({
      'amount': newTotalPurchase,
      'payment': newCashPayment,
      'due': newRemainingAmount,
    });

    recalculateRemainingAmounts();
  }

  Future<void> recalculateRemainingAmounts() async {
    QuerySnapshot historySnapshot = await FirebaseFirestore.instance
        .collection('collection name')
        .doc(widget.userId)
        .collection('suppliers')
        .doc(widget.supplierId)
        .collection('history')
        .orderBy('time')
        .get();

    double cumulativeRemainingAmount = 0.0;

    for (var doc in historySnapshot.docs) {
      double totalPurchase = doc['amount'];
      double cashPayment = doc['payment'];
      cumulativeRemainingAmount =
          cumulativeRemainingAmount + (totalPurchase - cashPayment);

      await doc.reference.update({
        'due': cumulativeRemainingAmount,
      });
    }

    await FirebaseFirestore.instance
        .collection('collection name')
        .doc(widget.userId)
        .collection('suppliers')
        .doc(widget.supplierId)
        .update({
      'supplier_due': cumulativeRemainingAmount,
    });
  }

  Future<void> _editTransaction(Transaction transaction) async {
    TextEditingController totalPurchaseController =
    TextEditingController(text: transaction.totalPurchase.toString());
    TextEditingController cashPaymentController =
    TextEditingController(text: transaction.cashPayment.toString());
    TextEditingController descriptionController =
    TextEditingController(text: transaction.description);
    
    
    

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("লেনদেন সম্পাদনা করুন"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: totalPurchaseController,
                  decoration: const InputDecoration(labelText: "মোট ক্রয়"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: cashPaymentController,
                  decoration: const InputDecoration(labelText: "ক্যাশ পেমেন্ট"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: "বিস্তারিত"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("বাতিল"),
            ),
            TextButton(
              onPressed: () async {
                double newTotalPurchase =
                double.parse(totalPurchaseController.text);
                double newCashPayment =
                double.parse(cashPaymentController.text);
                String newDescription = descriptionController.text;
                

                double cashDifference =
                    newCashPayment - transaction.cashPayment;
                double oldTotalPurchase = transaction.totalPurchase;
                double oldCashPayment = transaction.cashPayment;

                await FirebaseFirestore.instance
                    .collection('collection name')
                    .doc(widget.userId)
                    .collection('suppliers')
                    .doc(widget.supplierId)
                    .collection('history')
                    .doc(transaction.id)
                    .update({
                  'amount': newTotalPurchase,
                  'payment': newCashPayment,
                  'details':
                  'edited.. $newDescription\n(পুরানো বিক্রয়: $oldTotalPurchase টাকা, পুরানো পেমেন্ট: $oldCashPayment টাকা)..',
                  
                });
                await updateTransactionAndRecalculate(
                    transaction, newTotalPurchase, newCashPayment);
                setState(() {
                  _transactionHistory = fetchSupplierHistory();
                });

                Navigator.pop(context);
                await FirebaseFirestore.instance
                    .collection('collection name')
                    .doc(widget.userId)
                    .collection('cashbox')
                    .add({
                  'amount': -cashDifference,
                  'time': Timestamp.now(),
                  'reason':
                  ' ${widget.supplierName} এর আপডেট হওয়া বিক্রয় লেনদেন\n(পুরানো বিক্রয়: $oldTotalPurchase টাকা, পুরানো পেমেন্ট: $oldCashPayment টাকা)\nনতুন বিক্রয়: $newTotalPurchase টাকা, নতুন নগদ পেমেন্ট: $newCashPayment টাকা',
                });
              },
              child: const Text("সংরক্ষণ করুন"),
            ),
            TextButton(
              onPressed: () async {
                bool confirmDelete = await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('আপনি কি ডিলিট করতে চান?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, false);
                          },
                          child: const Text("না"),
                        ),
                        TextButton(
                          onPressed: () async {
                            double newTotalPurchase =
                            double.parse(totalPurchaseController.text);
                            double newCashPayment =
                            double.parse(cashPaymentController.text);

                            await updateTransactionAndRecalculate(
                                transaction, newTotalPurchase, newCashPayment);
                            Navigator.pop(context, true);
                          },
                          child: const Text("হ্যাঁ"),
                        ),
                      ],
                    );
                  },
                );
                
                if (confirmDelete == true) {
                  double deleteAmount = transaction.cashPayment;
                  double totalAmmount = transaction.totalPurchase;
                  await FirebaseFirestore.instance
                      .collection('collection name')
                      .doc(widget.userId)
                      .collection('suppliers')
                      .doc(widget.supplierId)
                      .collection('history')
                      .doc(transaction.id)
                      .delete();

                  setState(() {
                    _transactionHistory = fetchSupplierHistory();
                  });
                  Navigator.pop(context);
                  await FirebaseFirestore.instance
                      .collection('collection name')
                      .doc(widget.userId)
                      .collection('cashbox')
                      .add({
                    'amount': deleteAmount,
                    'time': Timestamp.now(),
                    'reason':
                    ' ${widget.supplierName} এর ডিলিট হওয়া লেনদেন\n(মোট বিক্রয়: $totalAmmount টাকা, নগদ পরিশোধ: $deleteAmount টাকা)',
                  });
                }
              },
              child: const Text("ডিলিট"),
            ),
          ],
        );
      },
    );
  }

  String formatDateWithBengaliMonth(DateTime date) {
    const List<String> bengaliMonths = [
      'জানুয়ারী', 'ফেব্রুয়ারী', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'অগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];
    String day = convertToBengaliDigits(date.day.toDouble());
    String month = bengaliMonths[date.month - 1];
    String year = convertToBengaliDigits(date.year.toDouble());

    return '$day $month $year';
  }

  String convertToBengaliDigits(double value) {
    String bengaliDigits = '';

    
    if (value % 1 == 0) {
      
      String valueStr = value.toInt().toString(); 
      for (int i = 0; i < valueStr.length; i++) {
        bengaliDigits += _getBengaliDigit(valueStr[i]);
      }
    } else {
      
      String valueStr = value.toStringAsFixed(0);
      List<String> digits = valueStr.split('.');

      
      for (int i = 0; i < digits[0].length; i++) {
        bengaliDigits += _getBengaliDigit(digits[0][i]);
      }

      bengaliDigits += '.'; 

      
      for (int i = 0; i < digits[1].length; i++) {
        bengaliDigits += _getBengaliDigit(digits[1][i]);
      }
    }

    return bengaliDigits;
  }

  String _getBengaliDigit(String digit) {
    switch (digit) {
      case '0':
        return '০';
      case '1':
        return '১';
      case '2':
        return '২';
      case '3':
        return '৩';
      case '4':
        return '৪';
      case '5':
        return '৫';
      case '6':
        return '৬';
      case '7':
        return '৭';
      case '8':
        return '৮';
      case '9':
        return '৯';
      default:
        return digit;
    }
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

  void _showImage(BuildContext context, List<String> imageUrls) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              Expanded(
                child: ListView.builder(
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    final imageUrl = imageUrls[index];

                    
                    if (imageUrl.isNotEmpty && Uri.tryParse(imageUrl)?.isAbsolute == true) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: InteractiveViewer(
                          child: Image.network(
                            imageUrl,
                            errorBuilder: (context, error, stackTrace) {
                              
                              return const Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              );
                            },
                          ),
                        ),
                      );
                    } else {
                      
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.supplierName} এর লেনদেন'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          
          Container(
            padding: const EdgeInsets.all(10.0),
            color: Colors.white,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30.0,
                  backgroundImage: (widget.supplierImageUrl.isNotEmpty &&
                      Uri.tryParse(widget.supplierImageUrl)?.isAbsolute ==
                          true)
                      ? NetworkImage(widget.supplierImageUrl) as ImageProvider
                      : const AssetImage('assets/placeholder.png'),
                  onBackgroundImageError: (exception, stackTrace) {
                    debugPrint('Error loading image: $exception');
                  },
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.supplierName,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.supplierPhoneNumber,
                        style:
                        const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: () => _makeCall(widget.supplierPhoneNumber),
                ),
                IconButton(
                  icon: const Icon(Icons.message),
                  onPressed: () async {
                    await SMSHelper.checkAndShowSMSWarning(context: context);
                    _sendSMSpopup(widget.supplierName);
                  }
                ),
              ],
            ),
          ),
          
          StreamBuilder<List<Transaction>>(
            stream: _transactionHistoryStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError) {
                return const Center(
                    child: Text('Error loading transaction history'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No transactions found'));
              } else {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'বর্তমান বাকী: ৳${convertToBengaliDigits(_totalRemaining)}',
                    style: const TextStyle(
                        fontSize: 18,
                        color: Colors.red,
                        fontWeight: FontWeight.bold),
                  ),
                );
              }
            },
          ),
          
          Expanded(
            child: StreamBuilder<List<Transaction>>(
              stream: _transactionHistoryStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(
                      child: Text('লেনদেনের ইতিহাস লোড করতে সমস্যা হয়েছে'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('কোনো লেনদেন পাওয়া যায়নি'));
                } else {
                  return Column(
                    children: [
                      
                      Table(
                        border: TableBorder.all(color: Colors.black, width: 1),
                        columnWidths: const {
                          0: FlexColumnWidth(2), 
                          1: FlexColumnWidth(1), 
                          2: FlexColumnWidth(1), 
                        },
                        children: [
                          TableRow(
                            decoration:
                            BoxDecoration(color: Colors.lightBlue[100]),
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'লেনদেনের বিবরণ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'মোট মূল্য',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'পরিশোধ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children:
                            List.generate(snapshot.data!.length, (index) {
                              final transaction = snapshot.data![index];
                              return GestureDetector(
                                onTap: () {
                                  _editTransaction(
                                      transaction); 
                                },
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment
                                            .start, 
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Padding(
                                              padding: const EdgeInsets.only(left: 8.0), 
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  
                                                  Text(
                                                    'মোট বাকি: ${convertToBengaliDigits(transaction.remainingAmount)}৳',
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                  ),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      
                                                      Text(
                                                        formatDateWithBengaliMonth(transaction.date),
                                                        style: const TextStyle(fontSize: 12),
                                                      ),
                                                      
                                                      GestureDetector(
                                                        onTap: () {
                                                          
                                                          if (transaction.imageUrl != null &&
                                                              transaction.imageUrl!.isNotEmpty) {
                                                            _showImage(context, transaction.imageUrl!); 
                                                          } else {
                                                            
                                                            showGlobalSnackBar(context,'No images available for this transaction.');
                                                            }
                                                        },
                                                        child: Icon(
                                                          transaction.imageUrl != null && transaction.imageUrl!.isNotEmpty
                                                              ? Icons.image
                                                              : Icons.broken_image,
                                                          size: 20.0,
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      
                                                      Text(
                                                        '${transaction.totalPurchase - transaction.cashPayment < 0 ? 'অগ্রিম পরিশোধ' : 'বাকি'}: ${convertToBengaliDigits((transaction.totalPurchase - transaction.cashPayment).abs())}৳',
                                                        style: const TextStyle(fontSize: 12),
                                                      ),
                                                    ],
                                                  ),
                                                  
                                                  TransactionDetails(description: transaction.description),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(8.0),
                                              child: Text(
                                                '৳${convertToBengaliDigits(transaction.totalPurchase)}',
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                    FontWeight.bold),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(8.0),
                                              child: Text(
                                                '৳${convertToBengaliDigits(transaction.cashPayment)}',
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                    FontWeight.bold),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: Colors.black), 
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
