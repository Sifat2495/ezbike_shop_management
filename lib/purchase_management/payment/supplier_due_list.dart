import 'package:bebshar_poristhiti_stock/purchase_management/payment/supplier_transaction_history.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../sms/sms_purchase_page.dart';
import '../../sms/sms_service.dart';
import 'add_new_supplier.dart';
import '../../widgets/all_common_functions.dart';

class SupplierPage extends StatefulWidget {
  @override
  _SupplierPageState createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> {
  bool sendSMSswitch = true; 
  String _searchText = ""; 
  DocumentSnapshot? _lastDocument; 
  bool _hasMoreData = true; 
  final List<DocumentSnapshot> _suppliers = []; 
  bool _isLoading = false; 
  late ScrollController _scrollController;

  
  String? getCurrentUserId() {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid; 
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    String? userId = getCurrentUserId();
    if (userId != null) {
      _loadSuppliers(userId, isInitialLoad: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
        _hasMoreData) {
      String? userId = getCurrentUserId();
      if (userId != null) {
        _loadSuppliers(userId);
      }
    }
  }

  Future<void> _loadSuppliers(String userId, {bool isInitialLoad = false}) async {
    if (_isLoading || !_hasMoreData) return;

    setState(() {
      _isLoading = true;
    });

    int fetchLimit = isInitialLoad ? 10 : 5;

    Query query = FirebaseFirestore.instance
        .collection('collection name')
        .doc(userId)
        .collection('suppliers')
        .orderBy('name')
        .limit(fetchLimit);

    if (_lastDocument != null && !isInitialLoad) {
      query = query.startAfterDocument(_lastDocument!);
    }

    QuerySnapshot querySnapshot = await query.get();
    setState(() {
      if (isInitialLoad) {
        _suppliers.clear();
      }
      _suppliers.addAll(querySnapshot.docs);
      _lastDocument = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;
      _hasMoreData = querySnapshot.docs.length == fetchLimit;
      _isLoading = false;
    });
  }

  Future<void> _refreshSuppliers() async {
    String? userId = getCurrentUserId();
    if (userId != null) {
      setState(() {
        _lastDocument = null;
        _hasMoreData = true;
        _suppliers.clear(); 
      });
      await _loadSuppliers(userId, isInitialLoad: true);
    }
  }

  Widget _buildSupplierList(String userId) {
    List<DocumentSnapshot> filteredSuppliers = _suppliers.where((supplier) {
      var supplierData = supplier.data() as Map<String, dynamic>;
      var name = supplierData['name'].toString().toLowerCase();
      return name.contains(_searchText.toLowerCase());
    }).toList();

    return RefreshIndicator(
      onRefresh: _refreshSuppliers,
      child: ListView.builder(
        controller: _scrollController,
        physics: AlwaysScrollableScrollPhysics(),
        itemCount: filteredSuppliers.length + 1,
        itemBuilder: (context, index) {
          if (index == filteredSuppliers.length) {
            return _isLoading ? Center(child: CircularProgressIndicator()) : SizedBox();
          }
          var supplier = filteredSuppliers[index];
          return _buildSupplierTile(context, supplier, userId);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? userId = getCurrentUserId();

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('সাপ্লায়ার/পার্টির হিসাব')),
        body: Center(child: Text('User is not logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text("দেনার খাতা"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            SizedBox(height: 10),
            _buildSearchBar(),
            Expanded(child: _buildSupplierList(userId)),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.009),
        child: FloatingActionButton(
          backgroundColor: Colors.blue[400],
          foregroundColor: Colors.white,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.height * 0.65,
                    child: AddSupplierPage(),
                  ),
                ),
              ),
            );
          },
          child: Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width *
            0.01, 
      ),
      child: TextField(
        decoration: InputDecoration(
          labelText: 'সাপ্লায়ার খুঁজুন',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          isDense: true, 
          contentPadding: EdgeInsets.symmetric(
            vertical: MediaQuery.of(context).size.width < 400
                ? 8.0
                : 10.0, 
            horizontal: 12.0, 
          ),
        ),
        style: TextStyle(
          fontSize: MediaQuery.of(context).size.width < 400
              ? 14
              : 16, 
        ),
        onChanged: (value) {
          setState(() {
            _searchText = value; 
          });
        },
      ),
    );
  }

  Widget _buildSupplierTile(
      BuildContext context, DocumentSnapshot supplier, String userId) {
    Map<String, dynamic>? supplierData =
        supplier.data() as Map<String, dynamic>?;

    String imageUrl =
        (supplierData != null && supplierData.containsKey('image'))
            ? supplierData['image']
            : 'assets/placeholder.png';
    String name = supplierData?['name'] ?? 'Unknown';
    String phone = supplierData?['phone'] ?? 'Unknown';
    String supplierId =
        supplier.id; 

    return ListTile(
      leading: GestureDetector(
        onTap: () {
          _showImageBySize(context, imageUrl, supplier);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Image.network(
            imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              
              return Container(
                width: 45,
                height: 45,
                alignment: Alignment.center,
                color: Colors.grey[200], 
                child: Icon(Icons.person,
                    size: 30, color: Colors.grey), 
              );
            },
          ),
        ),
      ),
      title: GestureDetector(
        onTap: () {
          _dueCallection(context, supplier);
        },
        child: Text(name),
      ),
      subtitle: GestureDetector(
        onTap: () {
          _dueCallection(context, supplier);
        },
        child: Row(
          children: [
            Icon(
              Icons.call_sharp,
              color: Colors.grey, 
              size: 16, 
            ),
            SizedBox(width: 2), 
            Text(phone), 
          ],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '৳ ${convertToBengaliNumbers((supplierData?['supplier_due'] ?? '0').toStringAsFixed(0))}',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          SizedBox(width: 0), 
          Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.all(0.001),
            width: 20, 
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.blue), 
              onSelected: (value) {
                if (value == 'Image Collection') {
                  _showImageDialog(context, imageUrl, supplier);
                } else if (value == 'Transaction Report') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SupplierHistoryPage(
                        userId: userId,
                        supplierId: supplierId,
                        supplierName: name,
                        supplierImageUrl: imageUrl,
                        supplierPhoneNumber: phone,
                      ),
                    ),
                  );
                } else if (value == 'Edit & Delete') {
                  _showEditPopup(context, userId, supplier);
                } else if (value == 'Send SMS') {}
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value: 'Image Collection',
                    child: Container(
                      width: MediaQuery.of(context).size.width *
                          0.40, 
                      padding:
                          EdgeInsets.symmetric(vertical: 12), 
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.start, 
                        children: [
                          Icon(Icons.person, color: Colors.teal), 
                          SizedBox(
                              width:
                                  7), 
                          Text('ছবি পরিবর্তন'), 
                        ],
                      ),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'Edit & Delete',
                    child: Container(
                      width: MediaQuery.of(context).size.width *
                          0.40, 
                      padding:
                          EdgeInsets.symmetric(vertical: 12), 
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.start, 
                        children: [
                          Icon(Icons.edit, color: Colors.teal), 
                          SizedBox(
                              width:
                                  7), 
                          Text('এডিট ও ডিলিট'), 
                        ],
                      ),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'Transaction Report',
                    child: Container(
                      width: MediaQuery.of(context).size.width *
                          0.40, 
                      padding:
                          EdgeInsets.symmetric(vertical: 12), 
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.start, 
                        children: [
                          Icon(Icons.receipt, color: Colors.teal), 
                          SizedBox(
                              width:
                                  7), 
                          Text('লেনদেনের রিপোর্ট'), 
                        ],
                      ),
                    ),
                  ),
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                ];
              },
            ),
          ),
        ],
      ),
    );
  }

  
  void _showSMSWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0), 
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sms_failed_outlined,
                color: Colors.red,
                size: 50,
              ),
              SizedBox(height: 10),
              Text(
                'আপনার এসএমএস শেষ!',
                textAlign: TextAlign.center, 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            'দয়া করে নতুন করে এসএমএস ক্রয় করুন।',
            textAlign: TextAlign.center, 
            style: TextStyle(fontSize: 16),
          ),
          actionsAlignment:
              MainAxisAlignment.spaceEvenly, 
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey, 
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0), 
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); 
              },
              child: Text(
                'ঠিক আছে',
                style: TextStyle(color: Colors.white), 
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, 
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0), 
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SMSPurchasePage(),
                  ),
                );
              },
              child: Text(
                'SMS কিনুন',
                style: TextStyle(color: Colors.white), 
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _showPinVerificationDialog(BuildContext context) async {
    TextEditingController pinController = TextEditingController();
    bool pinVerified = false;
    String? userId = getCurrentUserId(); 

    if (userId != null) {
      
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('collection name')
          .doc(userId)
          .get();
      String? savedPin = userDoc['pin']; 

      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('পিন যাচাই করুন'),
            content: TextField(
              controller: pinController,
              decoration: InputDecoration(
                labelText: 'পিন প্রবেশ করুন',
              ),
              obscureText: true, 
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  String enteredPin = pinController.text;
                  
                  if (enteredPin == savedPin) {
                    pinVerified = true; 
                  }
                  Navigator.of(context).pop();
                },
                child: Text('যাচাই করুন'),
              ),
            ],
          );
        },
      );
    }
    return pinVerified; 
  }

  void _dueCallection(BuildContext context, DocumentSnapshot supplier) {
    Map<String, dynamic>? supplierData =
        supplier.data() as Map<String, dynamic>?;
    TextEditingController amountController = TextEditingController();
    final userId = getCurrentUserId();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          supplierData?['name'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width < 400
                                ? 18
                                : 24,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Image.network(
                      supplierData?['image'] ?? '',
                      height:
                          MediaQuery.of(context).size.width < 400 ? 250 : 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/placeholder.png',
                        height:
                            MediaQuery.of(context).size.width < 400 ? 150 : 300,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),

                  
                  Text(
                    'মোট দেনা: ৳${convertToBengaliNumbers((supplierData?['supplier_due'] ?? '0').toStringAsFixed(0))}',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize:
                          MediaQuery.of(context).size.width < 400 ? 16 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),

                  
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: 'পরিমাণ লিখুন',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 12.0),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 10),

                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('collection name')
                            .doc(userId)
                            .collection('collection name')
                            .doc('doc id/name')
                            .get(),
                        builder: (context, yearlySnapshot) {
                          if (yearlySnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Text(
                              'লোড হচ্ছে...',
                              style: TextStyle(fontSize: 16),
                            );
                          }
                          if (yearlySnapshot.hasError) {
                            return Text(
                              'ত্রুটি হয়েছে!',
                              style: TextStyle(fontSize: 16, color: Colors.red),
                            );
                          }

                          final yearlyData = yearlySnapshot.data?.data()
                          as Map<String, dynamic>?;
                          final smsCount = yearlyData?['sms_count'] ?? 0;

                          
                          
                          

                          
                          if (smsCount <= 0) {
                            sendSMSswitch = false;
                          } else {
                            
                          }

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'SMS প্রদান ($smsCount)', 
                                style: TextStyle(fontSize: 16),
                              ),
                              Transform.scale(
                                scale: 0.7,
                                child: StatefulBuilder(
                                  builder: (context, setState) {
                                    return Switch(
                                      value: sendSMSswitch,
                                      onChanged: (value) async {
                                        if (smsCount <= 0 && value) {
                                          _showSMSWarningDialog(context);
                                        } else {
                                          setState(() {
                                            sendSMSswitch = value;
                                          });
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding:
                          EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    onPressed: () async {
                      showLoadingDialog(context, message: "অপেক্ষা করুন...");
                      DocumentSnapshot userDoc = await FirebaseFirestore
                          .instance
                          .collection('collection name')
                          .doc(userId)
                          .get();
                      bool isPermissionGranted =
                          userDoc.get('permission') ?? false;

                      if (isPermissionGranted) {
                        if (amountController.text.isNotEmpty) {
                          final amount = double.tryParse(amountController.text);

                          if (amount != null) {
                            try {
                              
                              final previousDue =
                                  supplierData?['supplier_due'] ?? 0.0;
                              final updatedDue = previousDue - amount;

                              
                              await supplier.reference.update({
                                'supplier_due': updatedDue,
                              });
                              
                              try {
                                
                                await supplier.reference
                                    .collection('history')
                                    .add({
                                  'amount': 0,
                                  'payment': amount,
                                  'due': updatedDue,
                                  'time':
                                      Timestamp.now(), 
                                  'details':
                                      'দেনা পরিশোধ', 
                                });
                              } catch (e) {
                                showGlobalSnackBar(context,'Failed to add transaction to history.');
                              }
                              
                              await FirebaseFirestore.instance
                                  .collection('collection name')
                                  .doc(userId)
                                  .collection('cashbox')
                                  .add({
                                'amount': -amount,
                                'reason':
                                    'দেনা পরিশোধঃ "${supplierData?['name']}" নামের সাপ্লায়ার $amount টাকা দেনা পরিশোধ করেছেন।',
                                'time': FieldValue.serverTimestamp(),
                              });

                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              

                              
                              final yearlyTotalsDoc = FirebaseFirestore.instance
                                  .collection('collection name')
                                  .doc(userId)
                                  .collection('collection name')
                                  .doc('doc id/name');

                              Map<String, dynamic> updateData = {
                                
                                'supplier_due': FieldValue.increment(-amount),
                              };

                              if (sendSMSswitch) {
                                updateData['sms_count'] =
                                    FieldValue.increment(-1);
                              }
                              await yearlyTotalsDoc.set(
                                  updateData, SetOptions(merge: true));

                              
                              if (sendSMSswitch) {
                                final supplierPhone =
                                    supplierData?['phone'] ?? '';
                                if (supplierPhone.isNotEmpty) {
                                  sendSMSToSupplier(
                                    supplierPhone,
                                    'দেনা ${previousDue.toStringAsFixed(0)}, পরিশোধ ${amount.toStringAsFixed(0)}, বর্তমান দেনা: ${updatedDue.toStringAsFixed(0)}',
                                  );
                                } else {
                                  showGlobalSnackBar(context,'সাপ্লায়ারের ফোন নম্বর নেই।');
                                  }
                              }
                              hideLoadingDialog(context);
                              
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  final screenWidth =
                                      MediaQuery.of(context).size.width;
                                  final screenHeight =
                                      MediaQuery.of(context).size.height;

                                  return Center(
                                    child: Container(
                                      margin: EdgeInsets.symmetric(
                                          horizontal: screenWidth *
                                              0.05), 
                                      child: AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15.0),
                                        ),
                                        title: Center(
                                          child: Text(
                                            'দেনা পরিশোধ সফল হয়েছে!',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: screenWidth *
                                                    0.05), 
                                          ),
                                        ),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'দেনা পরিশোধ: ৳${amount.toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  fontSize: screenWidth *
                                                      0.04, 
                                                  color: Colors.blue,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              SizedBox(
                                                  height: screenHeight *
                                                      0.02), 
                                              Text(
                                                'বর্তমান দেনা: ৳${updatedDue.toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  fontSize: screenWidth *
                                                      0.04, 
                                                  color: Colors.red,
                                                ),
                                                textAlign: TextAlign
                                                    .center, 
                                              ),
                                              if (sendSMSswitch &&
                                                  supplierData?['phone']
                                                          ?.isNotEmpty ==
                                                      true) ...[
                                                SizedBox(
                                                    height: screenHeight *
                                                        0.02), 
                                                Text(
                                                  'সাপ্লায়ারকে মেসেজ দেয়া হয়েছে।',
                                                  style: TextStyle(
                                                    fontSize: screenWidth *
                                                        0.04, 
                                                    color: Colors.blue,
                                                  ),
                                                  textAlign: TextAlign
                                                      .center, 
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          Center(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                padding: EdgeInsets.symmetric(
                                                  vertical:
                                                      screenHeight * 0.015,
                                                  horizontal: screenWidth * 0.1,
                                                ), 
                                                backgroundColor: Colors.blue,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12), 
                                                ),
                                              ),
                                              onPressed: () {
                                                Navigator.pop(context);
                                                Navigator.pop(
                                                    context); 
                                              },
                                              child: Text(
                                                'ঠিক আছে',
                                                style: TextStyle(
                                                  fontSize: screenWidth *
                                                      0.045, 
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            } catch (e) {
                              hideLoadingDialog(context);
                              showGlobalSnackBar(context,
                                  'কিছু ভুল হয়েছে! আবার চেষ্টা করুন।');
                            }
                          } else {
                            hideLoadingDialog(context);
                            showGlobalSnackBar(
                                context, 'ভ্যালিড সংখ্যা ইনপুট করুন।');
                          }
                        } else {
                          hideLoadingDialog(context);
                          showGlobalSnackBar(context, 'পরিমাণ লিখুন');
                        }
                      } else {
                        hideLoadingDialog(context);
                        showGlobalSnackBar(
                            context, 'আপনার বিল মেয়াদ শেষ হয়েছে।');
                      }
                    },
                    child: Text(
                      'দেনা পরিশোধ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize:
                            MediaQuery.of(context).size.width < 400 ? 18 : 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  
  void sendSMSToSupplier(String phoneNumber, String message) async {
    
    await SMSService.sendSMS(
      phoneNumber: phoneNumber,
      message: message,
    );
  }

  void _showImageDialog(
      BuildContext context, String imageUrl, DocumentSnapshot supplier) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: LayoutBuilder(
            builder: (context, constraints) {
              
              double imageWidth = constraints.maxWidth; 
              double imageHeight =
                  constraints.maxHeight * 0.6; 

              
              if (MediaQuery.of(context).orientation == Orientation.portrait) {
                imageHeight = MediaQuery.of(context).size.height *
                    0.6; 
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  
                  Image.network(
                    imageUrl,
                    width: imageWidth,
                    height: imageHeight,
                    fit: BoxFit.contain, 
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset('assets/placeholder.png');
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.cancel),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () async {
                          await _pickAndUploadImage(context, supplier);
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showImageBySize(
      BuildContext context, String imageUrl, DocumentSnapshot supplier) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: LayoutBuilder(
            builder: (context, constraints) {
              
              double imageWidth = constraints.maxWidth; 
              double imageHeight =
                  constraints.maxHeight * 0.5; 

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  
                  Image.network(
                    imageUrl,
                    width: imageWidth,
                    height: imageHeight,
                    fit: BoxFit.contain, 
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset('assets/placeholder.png');
                    },
                  ),
                  
                  Center(
                    child: IconButton(
                      icon: Icon(Icons.cancel_outlined,
                          size: 30, color: Colors.red),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(
      BuildContext context, DocumentSnapshot supplier) async {
    try {
      
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            contentPadding: EdgeInsets.symmetric(vertical: 16), 
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(ImageSource.gallery);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.image,
                        size: MediaQuery.of(context).size.width * 0.2, 
                      ),
                      const SizedBox(height: 8),
                      const Text('Gallery'),
                    ],
                  ),
                ),

                
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(ImageSource.camera);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: MediaQuery.of(context).size.width * 0.2, 
                      ),
                      const SizedBox(height: 8),
                      const Text('Camera'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return; 

      
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: source);

      if (pickedFile == null) {
        showGlobalSnackBar(context,'No image selected');
        return;
      }

      
      File originalFile = File(pickedFile.path);
      Uint8List originalBytes = await originalFile.readAsBytes();

      Uint8List? compressedBytes = await FlutterImageCompress.compressWithList(
        originalBytes,
        minWidth: 800, 
        quality: 50, 
      );

      
      final Directory tempDir = await Directory.systemTemp.createTemp();
      final File compressedFile = File('${tempDir.path}/${supplier.id}.jpg');
      await compressedFile.writeAsBytes(compressedBytes);

      
      Map<String, dynamic>? supplierData =
          supplier.data() as Map<String, dynamic>?;
      String fileName =
          'users/${getCurrentUserId()}/supplier_images/${supplierData?['name']}${supplierData?['phone']}.jpg';
      Reference storageReference =
          FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageReference.putFile(compressedFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      
      await FirebaseFirestore.instance
          .collection('collection name')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('suppliers')
          .doc(supplier.id)
          .update({'image': downloadUrl});

      
      await compressedFile.delete();

      Navigator.pop(context);
      showGlobalSnackBar(context,'ছবি সফলভাবে আপলোড করা হয়েছে');
      } catch (e) {
      showGlobalSnackBar(context,'ছবি আপলোডে সমস্যা হয়েছে: $e');
      }
  }

  void _showEditPopup(
      BuildContext context, String userId, DocumentSnapshot supplier) {
    TextEditingController nameController =
        TextEditingController(text: supplier['name']);
    TextEditingController phoneController =
        TextEditingController(text: supplier['phone']);
    String? phoneError;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('এডিট করুন'),
                  IconButton(
                    icon: Icon(Icons.delete_forever_outlined,
                        color: Colors.red), 
                    onPressed: () {
                      _showDeleteConfirmation(context, supplier);
                    },
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'নাম'),
                  ),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.number,
                    maxLength: 11,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'ফোন নম্বর',
                      errorText:
                          phoneError, 
                    ),
                    onChanged: (value) {
                      setState(() {
                        if (value.length == 11) {
                          phoneError = null; 
                        } else {
                          phoneError =
                              'ফোন নম্বর ১১ সংখ্যার হতে হবে'; 
                        }
                      });
                    },
                  ),
                ],
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('বাতিল'),
                    ),
                    
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        
                        if (phoneController.text.length != 11) {
                          setState(() {
                            phoneError = 'ফোন নম্বর ১১ সংখ্যার হতে হবে';
                          });
                          return;
                        }

                        
                        final phoneQuerySnapshot = await FirebaseFirestore
                            .instance
                            .collection('collection name')
                            .doc(getCurrentUserId() ?? '')
                            .collection('suppliers')
                            .where('phone', isEqualTo: phoneController.text)
                            .get();

                        if (phoneQuerySnapshot.docs.isNotEmpty &&
                            phoneQuerySnapshot.docs.first.id != supplier.id) {
                          setState(() {
                            phoneError =
                                'এই ফোন নম্বরটি ইতিমধ্যে ব্যবহৃত হচ্ছে';
                          });
                          return; 
                        }

                        
                        await FirebaseFirestore.instance
                            .collection('collection name')
                            .doc(getCurrentUserId() ?? '')
                            .collection('suppliers')
                            .doc(supplier.id)
                            .update({
                          'name': nameController.text,
                          'phone': phoneController.text,
                        });
                        Navigator.pop(context); 
                        showGlobalSnackBar(context,'সফলভাবে পরিবর্তন হয়েছে');
                        },
                      child: Text('পরিবর্তন করুন'),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, DocumentSnapshot supplier) async {
    
    double transactionAmount = supplier['supplier_due'] ?? 0;

    
    if (transactionAmount != 0) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('ডিলিট সম্ভব নয়', textAlign: TextAlign.center),
            content: Text(
              '${supplier['name']} - এর সাথে $transactionAmount টাকা লেনদেন রয়েছে।\n'
              'দুঃখিত, লেনদেন "0" না হলে আপনি কোনো সাপ্লায়ার ডিলিট করতে পারবেন না।',
              textAlign: TextAlign.center,
            ),
            actions: [
              Align(
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('ঠিক আছে'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
      return; 
    }

    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ডিলিট নিশ্চিত করুন'),
          content: Text(
              'আপনি কি ${supplier['name']} নামের সাপ্লায়ারকে ডিলিট করতে চান? আপনি যদি ডিলিট করেন তাহলে ${supplier['name']}-এর সকল লেনদেনের হিসাব মুছে যাবে।'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                
                bool pinVerified = await _showPinVerificationDialog(context);

                if (pinVerified) {
                  try {
                    
                    String? imageUrl = supplier['image'];

                    
                    if (imageUrl != null && imageUrl.isNotEmpty) {
                      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
                      await ref.delete();
                    }

                    
                    await FirebaseFirestore.instance
                        .collection('collection name')
                        .doc(getCurrentUserId() ?? '')
                        .collection('suppliers')
                        .doc(supplier.id)
                        .delete();

                    Navigator.of(context).pop(); 
                    Navigator.of(context).pop(); 
                    showGlobalSnackBar(context,'সফলভাবে ডিলিট হয়েছে');
                    } catch (e) {
                    showGlobalSnackBar(context,'ডিলিট করতে সমস্যা হয়েছে: $e');
                    }
                } else {
                  showGlobalSnackBar(context,'ভুল পিন, আবার চেষ্টা করুন');
                  }
              },
              child: Text('হ্যাঁ চাই'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('না'),
            ),
          ],
        );
      },
    );
  }
}
