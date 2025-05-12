import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../notification/notification_manager.dart';
import '../../sms/SMSHelper.dart';
import '../../widgets/all_common_functions.dart';
import '../stock_sale/sale_receipt_dialog.dart';
import 'DealerSaleService.dart';

class DealerConfirmationPopup extends StatefulWidget {
  final String name;
  final String license;
  final String description;
  final String collector;
  final String fatherName;
  final String motherName;
  final String phone;
  final String presentAddress;
  final String permanentAddress;
  final String nid;
  final List<String> chassis;
  final List<String> phones;
  final List<Map<String, String>> guarantors;
  final List<Map<String, dynamic>> products;
  final String imagePath;
  final DateTime birthDate;
  final DateTime time;
  final double previousDealerDue;

  const DealerConfirmationPopup({
    super.key,
    required this.name,
    required this.license,
    required this.description,
    required this.collector,
    required this.fatherName,
    required this.motherName,
    required this.phone,
    required this.presentAddress,
    required this.permanentAddress,
    required this.nid,
    required this.chassis,
    required this.phones,
    required this.guarantors,
    required this.products,
    required this.imagePath,
    required this.birthDate,
    required this.time,
    required this.previousDealerDue
  });

  @override
  _DealerConfirmationPopupState createState() => _DealerConfirmationPopupState();
}

class _DealerConfirmationPopupState extends State<DealerConfirmationPopup> {
  final TextEditingController _downPaymentController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final FocusNode _downPaymentFocusNode = FocusNode();
  final FocusNode _monthFocusNode = FocusNode();
  final DealerSaleService _dealerSaleService = DealerSaleService();
  double _remainingAmount = 0.0;
  double _installmentAmount = 0.0;
  bool sendSMSswitch = false;
  bool sendSMSswitchInitialized = false;
  int smsCount = 0;
  DateTime? _nextDate;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  final Map<String, TextEditingController> _quantityControllers = {};
  final Map<String, TextEditingController> _priceControllers = {};
  final Map<String, double> _previousPrices = {};
  double _totalPrice = 0.0;
  final NumberFormat formatter = NumberFormat('#,###', 'en_US');

  @override
  void initState() {
    super.initState();
    _downPaymentController.addListener(_calculateRemainingAmount);
    _monthController.addListener(_calculateRemainingAmount);

    widget.products.forEach((product) {
      String productName = product['name'];
      int quantity = product['quantity'] ?? 0;
      double price = product['sale_price'];

      _quantityControllers[productName] = TextEditingController(text: '$quantity');
      _priceControllers[productName] = TextEditingController(text: (price * quantity).toStringAsFixed(0));
      _previousPrices[productName] = price;

      _quantityControllers[productName]!.addListener(() {
        _updateTotalPrice();
        _updatePriceControllers();
      });

      _priceControllers[productName]!.addListener(() {
        _updateTotalPrice();
      });
    });

    _updateTotalPrice();
    _updatePriceControllers();
  }

  @override
  void dispose() {
    _downPaymentController.removeListener(_calculateRemainingAmount);
    _downPaymentController.dispose();
    _monthController.removeListener(_calculateRemainingAmount);
    _monthController.dispose();
    _downPaymentFocusNode.dispose();
    _monthFocusNode.dispose();
    _quantityControllers.forEach((key, controller) {
      controller.removeListener(_updateTotalPrice);
      controller.dispose();
    });
    _priceControllers.forEach((key, controller) {
      controller.removeListener(_updateTotalPrice);
      controller.dispose();
    });
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: DateTime.now().hour, minute: DateTime.now().minute),
      );

      if (pickedTime != null) {
        setState(() {
          
          _nextDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _scheduleNotification(DateTime scheduledDate, String dealerName, double dueAmount) async {
    try {

      if (userId == null) {
        print("No user is logged in.");
        return;
      }

      
      final userNotificationsRef = FirebaseFirestore.instance
          .collection('collection name')
          .doc(userId)
          .collection('user_notifications');

      
      await userNotificationsRef.add({
        'title': 'বাকি আদায়',
        'description': '$dealerName এর বাকি পরিমাণ: ৳${dueAmount.toStringAsFixed(0)}, আজকে কিস্তি পরিশোধ করবেন।',
        'time': Timestamp.fromDate(scheduledDate),
      });

      print("Notification data saved successfully!");
    } catch (e) {
      print("Error saving data to Firestore: $e");
    }

    
    final notificationManager = NotificationManager();
    await notificationManager.processUserNotifications(userId ?? ''); 
  }

  void _calculateRemainingAmount() {
    final downPayment = double.tryParse(_downPaymentController.text) ?? 0.0;
    final months = int.tryParse(_monthController.text) ?? 1;
    setState(() {
      _remainingAmount = (_totalPrice + widget.previousDealerDue) - downPayment;
      
    });
  }

  void _updateTotalPrice() {
    double totalPrice = 0.0;
    _priceControllers.forEach((productName, controller) {
      double price = double.tryParse(controller.text.replaceAll('৳', '')) ?? 0.0;
      totalPrice += price;
    });

    setState(() {
      _totalPrice = totalPrice;
    });
    _calculateRemainingAmount();
  }

  void _updatePriceControllers() {
    widget.products.forEach((product) {
      String productName = product['name'];
      int quantity = int.tryParse(_quantityControllers[productName]!.text) ?? 1;
      double price = product['sale_price'];
      double totalProductPrice = price * quantity;

      
      _priceControllers[productName]!.text = totalProductPrice.toStringAsFixed(0);
    });
  }

  Future<String?> _uploadDealerImage(String imagePath) async {
    if (imagePath.isEmpty) return null;

    File imageFile = File(imagePath);
    String userId = FirebaseAuth.instance.currentUser!.uid;
    String fileName = '${widget.name}_${widget.phone}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    String filePath = 'collection name/$userId/dealers_images/$fileName';

    try {
      
      final ref = FirebaseStorage.instance.ref(filePath);
      await ref.putFile(imageFile);

      
      String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception("Failed to upload image: $e");
    }
  }

  Future<List<Map<String, String>>> _uploadGuarantorPhotos(List<Map<String, String>> guarantors) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    List<Map<String, String>> updatedGuarantors = [];

    for (var guarantor in guarantors) {
      String? imagePath = guarantor['selectedImage'];

      if (imagePath != null && imagePath.isNotEmpty) {
        File imageFile = File(imagePath);
        String fileName = '${guarantor['name']}_${guarantor['phone']}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        String filePath = 'collection name/$userId/guarantor_images/$fileName';

        try {
          
          final ref = FirebaseStorage.instance.ref(filePath);
          await ref.putFile(imageFile);

          
          String imageUrl = await ref.getDownloadURL();
          guarantor['selectedImage'] = imageUrl;
        } catch (e) {
          throw Exception("Failed to upload image: $e");
        }
      }

      updatedGuarantors.add(guarantor);
    }

    return updatedGuarantors;
  }

  void _handleSale() async {

    showLoadingDialog(context, message: 'বিক্রি করা হচ্ছে...');

    double payment = double.tryParse(_downPaymentController.text) ?? 0.0;
    double due = (_totalPrice + widget.previousDealerDue) - payment;

    List<Map<String, dynamic>> processedProducts = [];

    for (var product in widget.products) {
      String productName = product['name'];
      int quantity = int.tryParse(_quantityControllers[productName]!.text) ?? 1;
      double salePrice = product['sale_price'];
      double purchasePrice = product['purchase_price'];
      double totalPrice = double.tryParse(_priceControllers[productName]!.text.replaceAll('৳', '')) ?? 0.0;

      processedProducts.add({
        'name': productName,
        'quantity': quantity,
        'sale_price': salePrice,
        'purchase_price': purchasePrice,
        'total_price': totalPrice,
      });
    }

    String? imageUrl;
    if (widget.imagePath.isNotEmpty) {
      imageUrl = await _uploadDealerImage(widget.imagePath);
    }

    List<Map<String, String>> updatedGuarantors = await _uploadGuarantorPhotos(widget.guarantors);

    await _dealerSaleService.saveSaleData(
      name: widget.name,
      license: widget.license,
      description: widget.description,
      collector: widget.collector,
      fatherName: widget.fatherName,
      motherName: widget.motherName,
      birthDate: widget.birthDate,
      time: widget.time,
      phone: widget.phone,
      presentAddress: widget.presentAddress,
      permanentAddress: widget.permanentAddress,
      nid: widget.nid,
      chassis: widget.chassis,
      phones: widget.phones,
      image: imageUrl != null ? XFile(imageUrl) : null,
      guarantors: updatedGuarantors,
      products: processedProducts,
      totalPrice: _totalPrice,
      payment: payment,
      due: due,
      installments: [],
    );

    
    if (sendSMSswitch) {
      await SMSHelper.sendSMS(
        phoneNumber: widget.phone,
        message: 'বিক্রি ${_totalPrice.toStringAsFixed(0)}, পরিশোধ ${payment
            .toStringAsFixed(0)}, বর্তমান বাকি: ${due.toStringAsFixed(0)}',
      );
    }

    
    if (_nextDate != null && due > 0) {
      _scheduleNotification(
        _nextDate!,
        widget.name,
        due,
      );
    }
    hideLoadingDialog(context);
    Navigator.pop(context, 'sale_completed');
    showGlobalSnackBar(context, 'Sale data submitted successfully!');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SaleReceiptDialog(
          customerName: widget.name,
          customerPhone: widget.phone,
          totalAmount: _totalPrice,
          cashPayment: payment,
          remainingAmount: due,
          saleDate: DateTime.now().toString(),
          selectedProducts: processedProducts,
          presentAddress: widget.presentAddress,
          permanentAddress: widget.permanentAddress,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    Map<String, int> productQuantities = {};
    widget.products.forEach((product) {
      productQuantities[product['name']] =
          (productQuantities[product['name']] ?? 0) + 1;
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'বিক্রির তথ্য',
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width *
                0.05, 
            fontWeight: FontWeight.bold, 
            color: Colors.white, 
          ),
        ),
        centerTitle: true, 
        backgroundColor: Colors.deepOrangeAccent, 
        elevation: 4.0, 
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ডিলার তথ্যঃ',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                )),
            Row(
              children: [
                if (widget.imagePath.isNotEmpty)
                  Image.file(
                    File(widget.imagePath),
                    width: screenWidth * 0.1,
                    height: screenWidth * 0.1,
                  ),
                SizedBox(width: screenWidth * 0.02),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'তারিখ: ${DateFormat('dd-MM-yyyy hh:mm a').format(widget.time)}',
                      style: TextStyle(fontSize: screenWidth * 0.035),
                    ),
                    Text('নাম: ${widget.name}',
                        style: TextStyle(fontSize: screenWidth * 0.035)),
                    Text('ফোন: ${widget.phone}',
                        style: TextStyle(fontSize: screenWidth * 0.035)),
                    Text(
                      'জন্ম: ${DateFormat('dd-MM-yyyy').format(widget.birthDate)}',
                      style: TextStyle(fontSize: screenWidth * 0.035),
                    ),
                    Text('পিতা: ${widget.fatherName}',
                        style: TextStyle(fontSize: screenWidth * 0.035)),
                    Text('মাতা: ${widget.motherName}',
                        style: TextStyle(fontSize: screenWidth * 0.035)),
                    Text('বর্তমান ঠিকানা: ${widget.presentAddress}',
                        style: TextStyle(fontSize: screenWidth * 0.035)),
                    Text('স্থায়ী ঠিকানা: ${widget.permanentAddress}',
                        style: TextStyle(fontSize: screenWidth * 0.035)),
                    Text('জাতীয় পরিচয়পত্র(NID): ${widget.nid}',
                        style: TextStyle(fontSize: screenWidth * 0.035)),
                    Text('অটোর চেসিস নম্বর: ${widget.chassis}',
                        style: TextStyle(fontSize: screenWidth * 0.035)),
                    Text('লাইসেন্স: ${widget.license}',
                        style: TextStyle(fontSize: screenWidth * 0.035)),
                    Text('বিবরণ: ${widget.description}',
                        style: TextStyle(fontSize: screenWidth * 0.035)),
                    Text('স্বাক্ষর: ${widget.collector}',
                        style: TextStyle(fontSize: screenWidth * 0.035)),
                  ],
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              'জামিনদার:',
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.bold,
              ),
            ),
            ...widget.guarantors.map((guarantor) {
              return Row(
                children: [
                  if (guarantor['selectedImage'] != null &&
                      guarantor['selectedImage']!.isNotEmpty)
                    Image.file(
                      File(guarantor['selectedImage']!),
                      width: screenWidth * 0.1,
                      height: screenWidth * 0.1,
                    ),
                  SizedBox(width: screenWidth * 0.02),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'নাম: ${guarantor['name']}',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.bold, 
                        ),
                      ),
                      Text('ফোন: ${guarantor['phone']}',
                          style: TextStyle(fontSize: screenWidth * 0.035)),
                      Text('বর্তমান ঠিকানা: ${guarantor['presentAddress']}',
                          style: TextStyle(fontSize: screenWidth * 0.035)),
                      Text('স্থায়ী ঠিকানা: ${guarantor['permanentAddress']}',
                          style: TextStyle(fontSize: screenWidth * 0.035)),
                      Text('জাতীয় পরিচয়পত্র(NID): ${guarantor['nid']}',
                          style: TextStyle(fontSize: screenWidth * 0.035)),
                    ],
                  ),
                ],
              );
            }),
            SizedBox(height: screenHeight * 0.02),
            Table(
              columnWidths: {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  children: [
                    Text('পণ্য',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.039)),
                    Text('পরিমাণ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.039)),
                    Text('মুল্য',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.039),
                        textAlign: TextAlign.right),
                  ],
                ),
                ...widget.products.map((product) {
                  String productName = product['name'];
                  return TableRow(
                    children: [
                      Text(productName,
                          style: TextStyle(fontSize: screenWidth * 0.035)),
                      Center(
                        child: TextField(
                          controller: _quantityControllers[productName],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.005,
                              horizontal: screenWidth * 0.01,
                            ),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      TextField(
                        controller: _priceControllers[productName],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.005,
                            horizontal: screenWidth * 0.01,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  );
                }).toList(),
                TableRow(
                  children: [
                    Divider(
                      thickness: 1.0,
                      color: Colors.black,
                    ),
                    Divider(
                      thickness: 1.0,
                      color: Colors.black,
                    ),
                    Divider(
                      thickness: 1.0,
                      color: Colors.black,
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Text('মোট প্রোডাক্ট মূল্যঃ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.037)),
                    Text(''),
                    Text('৳${formatter.format(_totalPrice)}', 
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.037),
                        textAlign: TextAlign.right),
                  ],
                ),
                TableRow(
                  children: [
                    Text('পূর্বের বাকি',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.035)),
                    Text(''),
                    Text(
                        '৳${formatter.format((widget.previousDealerDue ?? 0).toInt())}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.035),
                        textAlign: TextAlign.right),
                  ],
                ),
                TableRow(
                  children: [
                    Text('বাকীসহ মোট',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.035)),
                    Text(''),
                    Text(
                        '৳${formatter.format((_totalPrice + (widget.previousDealerDue ?? 0)).toInt())}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.035),
                        textAlign: TextAlign.right),
                  ],
                ),
                TableRow(
                  children: [
                    Text('নগদ পরিশোধ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.035)),
                    Text(''),
                    Text(
                        '৳${formatter.format((_downPaymentController.text.isEmpty ? 0 : double.tryParse(_downPaymentController.text) ?? 0))}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.035),
                        textAlign: TextAlign.right),
                  ],
                ),
                TableRow(
                  children: [
                    Text('পরিশোধের পরে বাকী',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.035)),
                    Text(''),
                    Text('৳${formatter.format(_remainingAmount)}', 
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.035),
                        textAlign: TextAlign.right),
                  ],
                ),
              ],
            ),
            
            
            
            
            
            
            
            
            
            
            
            SizedBox(height: screenHeight * 0.02),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      FocusScope.of(context).requestFocus(_downPaymentFocusNode);
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _downPaymentController,
                        focusNode: _downPaymentFocusNode,
                        decoration: InputDecoration(
                          labelText: 'নগদ পরিশোধ',
                          labelStyle: TextStyle(fontSize: screenWidth * 0.04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.015,
                            horizontal: screenWidth * 0.035,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                
                
                
                
                
                
                
                
                
                
                
                
                
                
                
                
                
                
                
                
                
                
                
                
                
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white, 
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha((0.2 * 255).toInt()),
              spreadRadius: 3,
              blurRadius: 5,
              offset: Offset(0, -1), 
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width *
              0.04, 
          vertical: MediaQuery.of(context).size.height *
              0.015, 
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    "পরের কিস্তির তারিখ",
                    textAlign: TextAlign.center, 
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: Text(
                    "কাস্টমারকে SMS",
                    textAlign: TextAlign.center, 
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal:
                        MediaQuery.of(context).size.width < 400 ? 12 : 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _nextDate == null
                                ? 'তারিখ নির্বাচন'
                                : '${_nextDate!.day}-${_nextDate!.month}-${_nextDate!.year}',
                            style: TextStyle(fontSize: 13, color: Colors.black),
                          ),
                          if (_nextDate != null)
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _nextDate = null;
                                });
                              },
                            ),
                          Icon(Icons.calendar_month_sharp, color: Colors.blue[800]),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('collection name')
                            .doc(userId)
                            .collection('collection name')
                            .doc('doc id/name')
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Text('লোড হচ্ছে...', style: TextStyle(fontSize: 12));
                          }
                          if (snapshot.hasError) {
                            return Text('ত্রুটি!', style: TextStyle(fontSize: 12, color: Colors.red));
                          }

                          final yearlyData = snapshot.data?.data() as Map<String, dynamic>?;
                          smsCount = yearlyData?['sms_count'] ?? 0;

                          
                          if (!sendSMSswitchInitialized) {
                            sendSMSswitchInitialized = true;
                            sendSMSswitch = smsCount > 0; 
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              setState(() {}); 
                            });
                            print('ডিফল্ট sendSMSswitch সেট করা হলো: $sendSMSswitch (smsCount: $smsCount)');
                          }

                          return Text(
                            'SMS (${smsCount ?? 0})',
                            style: TextStyle(fontSize: 13, color: Colors.black54),
                          );
                        },
                      ),
                      Spacer(),
                      Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: sendSMSswitch,
                          onChanged: (value) {
                            setState(() {
                              if ((smsCount ?? 0) == 0) {
                                sendSMSswitch = false; 
                                SMSHelper.checkAndShowSMSWarning(context: context);
                              } else {
                                sendSMSswitch = value;
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 1),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          MediaQuery.of(context).size.width * 0.03,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.height * 0.015,
                      ),
                    ),
                    child: Text(
                      'Back',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleSale,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrangeAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          MediaQuery.of(context).size.width * 0.03,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.height * 0.015,
                      ),
                    ),
                    child: Text(
                      'বিক্রি',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
