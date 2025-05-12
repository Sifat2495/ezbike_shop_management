import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../notification/notification_manager.dart';
import '../../sms/sms_purchase_page.dart';
import '../../sms/sms_service.dart';
import '../../widgets/all_common_functions.dart';
import '../due/due_pdf.dart';
import 'dealer_history.dart';
import 'delete_dealer.dart';

class DealerDueList extends StatefulWidget {
  const DealerDueList({super.key});

  @override
  _DealerDueListState createState() => _DealerDueListState();
}

class _DealerDueListState extends State<DealerDueList> {
  bool sendSMSswitch = true; 
  String _searchText = ""; 
  DocumentSnapshot? _lastDocument; 
  bool _hasMoreData = true; 
  bool _isLoading = false; 
  final List<DocumentSnapshot> _dealers = []; 
  StreamSubscription<DocumentSnapshot>? dealerDueListener; 
  late ScrollController _scrollController;
  DateTime? _nextDate;
  DateTime _selectedDate = DateTime.now(); 
  String _selectedFilter = 'সকল হিসাব';
  double totalDueAmount = 0.0;

  
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
      _loadDealers(userId, isInitialLoad: true);

      
      dealerDueListener = FirebaseFirestore.instance
          .collection('collection name')
          .doc(userId)
          .collection('collection name')
          .doc('doc id/name')
          .snapshots()
          .listen((docSnapshot) {
        if (docSnapshot.exists && docSnapshot.data() != null) {
          double? totalDue =
              (docSnapshot.data()?['total_due'] as num?)?.toDouble() ?? 0.0;
          if (mounted) {
            setState(() {
              totalDueAmount = totalDue;  
            });
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent &&
        _hasMoreData) {
      String? userId = getCurrentUserId();
      if (userId != null) {
        _loadDealers(userId); 
      }
    }
  }

  
  
  
  
  
  
  
  
  
  
  
  

  Future<void> _loadDealers(String userId,
      {bool isInitialLoad = false}) async {
    if (_isLoading || !_hasMoreData) return;

    setState(() {
      _isLoading = true;
    });

    
    int fetchLimit = isInitialLoad ? 10 : 7;

    Query query = FirebaseFirestore.instance
        .collection('collection name')
        .doc(userId)
        .collection('dealers')
        .limit(fetchLimit);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    QuerySnapshot querySnapshot = await query.get();
    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        _dealers.addAll(querySnapshot.docs);
        _lastDocument = querySnapshot.docs.last;
        _hasMoreData = querySnapshot.docs.length == fetchLimit;
      });
    } else {
      setState(() {
        _hasMoreData = false;
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width *
            0.01, 
      ),
      child: TextField(
        decoration: InputDecoration(
          labelText: 'ডিলার খুঁজুন',
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

  Widget _buildDealerList(String userId) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('collection name')
          .doc(userId)
          .collection('dealers')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var dealers = snapshot.data?.docs ?? [];

        if (_searchText.isNotEmpty) {
          dealers = dealers.where((dealer) {
            var dealerData = dealer.data() as Map<String, dynamic>?; 

            if (dealerData == null) return false; 

            var name = dealerData['name']?.toString().toLowerCase() ?? ''; 
            var phone = dealerData['phone']?.toString().toLowerCase() ?? ''; 

            
            if (name.contains(_searchText.toLowerCase())) {
              return true;
            }

            
            if (_searchText.length >= 3 && phone.contains(_searchText.toLowerCase())) {
              return true;
            }

            return false;
          }).toList();
        }

        if (_selectedFilter == 'অটোর খাতা') {
          dealers = dealers.where((dealer) {
            var dealerData = dealer.data();
            return dealerData['chassis'] != null &&
                dealerData['chassis'].isNotEmpty;
          }).toList();
        } else if (_selectedFilter == 'ব্যাটারির খাতা') {
          dealers = dealers.where((dealer) {
            var dealerData = dealer.data();
            return dealerData['chassis'] == null ||
                dealerData['chassis'].isEmpty;
          }).toList();
        } else if (_selectedFilter == '২০২২') {
          dealers = dealers.where((dealer) {
            var dealerData = dealer.data();
            if (dealerData['time'] != null) {
              DateTime timestamp = dealerData['time'].toDate(); 
              return timestamp.year == 2022; 
            }
            return false; 
          }).toList();
        } else if (_selectedFilter == '২০২৩') {
          dealers = dealers.where((dealer) {
            var dealerData = dealer.data();
            if (dealerData['time'] != null) {
              DateTime timestamp = dealerData['time'].toDate(); 
              return timestamp.year == 2023; 
            }
            return false; 
          }).toList();
        } else if (_selectedFilter == '২০২৪') {
          dealers = dealers.where((dealer) {
            var dealerData = dealer.data();
            if (dealerData['time'] != null) {
              DateTime timestamp = dealerData['time'].toDate(); 
              return timestamp.year == 2024; 
            }
            return false; 
          }).toList();
        } else if (_selectedFilter == '২০২৫') {
          dealers = dealers.where((dealer) {
            var dealerData = dealer.data();
            if (dealerData['time'] != null) {
              DateTime timestamp = dealerData['time'].toDate(); 
              return timestamp.year == 2025; 
            }
            return false; 
          }).toList();
        }

        return ListView.builder(
          controller: _scrollController,
          itemCount: dealers.length,
          itemBuilder: (context, index) {
            var dealer = dealers[index];
            return _buildDealerTile(context, dealer, userId);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    
    String? userId = getCurrentUserId();

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('ডিলার খাতা'),
        ),
        body: Center(
          child: Text('User is not logged in.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text("ডিলার খাতা"),
        centerTitle: true,
        actions: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 12.0), 
            padding: EdgeInsets.symmetric(horizontal: 10.0),
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent[100], 
              borderRadius: BorderRadius.circular(6.0), 
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFilter,
                items: <String>[
                  'সকল হিসাব',
                  '২০২২',
                  '২০২৩',
                  '২০২৪',
                  '২০২৫',
                  'অটোর খাতা',
                  'ব্যাটারির খাতা'
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 13, 
                        fontWeight: FontWeight.w600,
                        color: Colors.black, 
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedFilter = newValue!;
                  });
                },
                dropdownColor: Colors.orange[200], 
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.black, 
                  size: 14, 
                ),
                style: TextStyle(
                  fontSize: 16, 
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                SizedBox(height: 1),
                _buildSearchBar(),
                SizedBox(height: 3),
              ],
            ),
          ),
          Expanded(child: _buildDealerList(userId)), 
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
        ],
      ),
    );
  }

  Widget _buildDealerTile(
      BuildContext context, DocumentSnapshot dealer, String userId) {
    Map<String, dynamic>? dealerData =
    dealer.data() as Map<String, dynamic>?;

    String imageUrl = dealerData?['image'];
    String name = dealerData?['name'] ?? 'Unknown';
    List<String> phoneNumbers = List<String>.from(dealerData?['phones'] ?? []);
    String phone = dealerData?['phone'] ?? 'Unknown';
    String presentAddress = dealerData?['present_address'] ?? '';
    DateTime? txnTime = dealerData?['time'] != null
        ? (dealerData?['time'] as Timestamp).toDate()
        : null;
    String dealerId =
        dealer.id;
    bool status = dealerData?['status'] ?? false; 


    String formattedDate = txnTime != null
        ? DateFormat('dd MMM yyyy').format(txnTime) 
        : 'No Date Available';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.5), 
      child: Container(
        decoration: BoxDecoration(
          color: status ? Colors.deepOrange : Colors.deepOrange, 
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.green.shade700,
              spreadRadius: 2,
              blurRadius: 4,
              offset: Offset(0, 2), 
            ),
          ],
        ),
        child: ListTile(
          leading: GestureDetector(
            onTap: () {
              _showImageBySize(context, imageUrl, dealer);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: imageUrl.isNotEmpty
                  ? Image.network(
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
                    child: Icon(Icons.person, size: 30, color: Colors.grey),
                  );
                },
              )
                  : Image.asset(
                'assets/placeholder.png',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                color: Colors.white,
              ),
            ),
          ),
          title: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DealerHistory(
                    userId: userId,
                    dealerId: dealerId,
                    dealerName: name,
                    dealerImageUrl: imageUrl,
                    dealerPhoneNumber: phone,
                    phones: phoneNumbers,
                    address: presentAddress,
                  ),
                ),
              );
            },
            child: Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          subtitle: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DealerHistory(
                    userId: userId,
                    dealerId: dealerId,
                    dealerName: name,
                    dealerImageUrl: imageUrl,
                    dealerPhoneNumber: phone,
                    phones: phoneNumbers,
                    address: presentAddress,
                  ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '৳ ${convertToBengaliNumbers((dealerData?['dealers_due'] ?? '0').toStringAsFixed(0))}',
                style: TextStyle(
                  color: Colors.yellowAccent, 
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
                  icon: Icon(Icons.more_vert, color: Colors.white), 
                  onSelected: (value) {
                    if (value == 'Image Collection') {
                      _showImageDialog(context, imageUrl, dealer);
                    } else if (value == 'Due Collection') {
                      _dueCallection(context, dealer);
                    } else if (value == 'Delete') {
                      _showDelete(context, userId, dealer);
                    } else if (value == 'Send SMS') {
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem<String>(
                        value: 'Due Collection',
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.40,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(Icons.monetization_on_sharp, color: Colors.teal),
                              SizedBox(width: 7),
                              Text('কিস্তি আদায়'),
                            ],
                          ),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'Image Collection',
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.40,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(Icons.person, color: Colors.deepOrangeAccent),
                              SizedBox(width: 7),
                              Text('ছবি পরিবর্তন'),
                            ],
                          ),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'Delete',
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.40,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(Icons.delete_forever, color: Colors.teal),
                              SizedBox(width: 7),
                              Text('ডিলিট'),
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
        ),
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

    if (userId == null) return false;

    
    showLoadingDialog(context, message: 'পিন যাচাই করা হচ্ছে...');

    try {
      
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('collection name')
          .doc(userId)
          .get();
      String? savedPin = userDoc['pin']; 

      
      hideLoadingDialog(context);

      
      await showDialog(
        context: context,
        barrierDismissible: false, 
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('🔐 পিন যাচাই করুন'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'আপনার পিন প্রবেশ করুন',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number, 
                  textAlign: TextAlign.center,
                  obscureText: true, 
                  maxLength: 6, 
                  decoration: InputDecoration(
                    hintText: '******',
                    counterText: "", 
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('বাতিল'),
              ),
              ElevatedButton(
                onPressed: () {
                  String enteredPin = pinController.text.trim();

                  if (enteredPin.isEmpty) {
                    showGlobalSnackBar(context, '⚠️ পিন লিখুন!');
                  } else if (enteredPin == savedPin) {
                    pinVerified = true; 
                    Navigator.of(context).pop();
                  } else {
                    showGlobalSnackBar(context, '❌ ভুল পিন, আবার চেষ্টা করুন');
                  }
                },
                child: Text('✔ যাচাই করুন'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      hideLoadingDialog(context);
      showGlobalSnackBar(context, '❌ পিন যাচাই করতে সমস্যা হয়েছে: $e');
    }

    return pinVerified; 
  }

  Future<void> _scheduleNotification(
      DateTime scheduledDate, String dealerName, double dueAmount) async {
    try {
      
      String? userId = getCurrentUserId();

      if (userId == null) {
        print("No user is logged in.");
        return;
      }

      
      final userNotificationsRef = FirebaseFirestore.instance
          .collection('collection name')
          .doc(userId)
          .collection('user_notifications');

      
      await userNotificationsRef.add({
        'title': 'কিস্তি আদায়',
        'description':
        '$dealerName এর বাকি পরিমাণ: ৳${dueAmount.toStringAsFixed(0)}, আজকে কিস্তি কালেকশনের দিন।',
        'time': Timestamp.fromDate(scheduledDate),
      });

      print("Notification data saved successfully!");
    } catch (e) {
      print("Error saving data to Firestore: $e");
    }

    
    final notificationManager = NotificationManager();
    await notificationManager.processUserNotifications(
        getCurrentUserId() ?? ''); 
  }

  void _dueCallection(BuildContext context, DocumentSnapshot dealer) {
    Map<String, dynamic>? dealerData =
    dealer.data() as Map<String, dynamic>?;
    TextEditingController amountController = TextEditingController();
    TextEditingController discountController = TextEditingController();
    TextEditingController collectorController = TextEditingController();
    final userId = getCurrentUserId();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
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
                              dealerData?['name'] ?? 'Unknown',
                              style: TextStyle(
                                fontSize:
                                MediaQuery.of(context).size.width < 400
                                    ? 18
                                    : 24,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () {
                              Navigator.pop(context);
                              _nextDate = null;
                            },
                          ),
                        ],
                      ),
                      

                      
                      if (dealerData?['image'] != null && dealerData!['image'].isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.network(
                            dealerData!['image'],
                            height: MediaQuery.of(context).size.width < 400 ? 200 : 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      SizedBox(height: 10),

                      
                      Text(
                        'মোট বাকি: ৳${convertToBengaliNumbers((dealerData?['dealers_due'] ?? '0').toStringAsFixed(0))}',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize:
                          MediaQuery.of(context).size.width < 400 ? 16 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 6, horizontal: MediaQuery.of(context).size.width * 0.04),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  DateFormat('লেনদেনের তারিখঃ dd-MMM-yyyy').format(_selectedDate), 
                                  style: TextStyle(fontSize: 16, color: Colors.black),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.calendar_month_outlined, color: Colors.black54),
                            ],
                          ),
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
                      
                      TextField(
                        controller: discountController,
                        decoration: InputDecoration(
                          labelText: 'ডিস্কাউন্ট',
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
                      TextField(
                        controller: collectorController,
                        decoration: InputDecoration(
                          labelText: 'আদায়কারীর স্বাক্ষর',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 12.0),
                        ),
                        keyboardType: TextInputType.text,
                      ),
                      SizedBox(height: 10),
                      GestureDetector(
                        onTap: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _nextDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDate != null) {
                            final TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
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
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical:
                            MediaQuery.of(context).size.width < 400 ? 4 : 6,
                            horizontal: MediaQuery.of(context).size.width < 400
                                ? 12
                                : 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _nextDate == null
                                      ? 'পরের কিস্তি দেয়ার তারিখ'
                                      : 'পরের কিস্তি দেয়ার তারিখঃ ${_nextDate!.day}-${_nextDate!.month}-${_nextDate!.year} সময়ঃ ${_nextDate!.hour > 12 ? _nextDate!.hour - 12 : _nextDate!.hour}:${_nextDate!.minute} ${_nextDate!.hour >= 12 ? 'PM' : 'AM'}',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.black),
                                ),
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
                              Icon(Icons.calendar_month_sharp,
                                  color: Colors.black54),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 5),

                      
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
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.red),
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
                            if ((double.tryParse(amountController.text) ?? 0) > 0 ||
                                (double.tryParse(discountController.text) ?? 0) > 0) {
                              final amount = double.tryParse(amountController.text) ?? 0.0;
                              final discount = double.tryParse(discountController.text) ?? 0.0;

                              final controller = collectorController.text.isEmpty
                                  ? "সাক্ষর নাই"
                                  : collectorController.text;

                              if (amount > 0.0 || discount > 0.0) {
                                try {
                                  final Timestamp transactionDate = Timestamp.fromDate(_selectedDate);

                                  
                                  final previousDue = dealerData?['dealers_due'] ?? 0.0;
                                  final adjustedAmount = (amount ?? 0.0) + (discount ?? 0.0);
                                  final updatedDue = previousDue - adjustedAmount;
                                  String reason;
                                  if (amount != null && discount != null) {
                                    reason = 'কিস্তি পরিশোধ ও ডিসকাউন্ট';
                                  } else if (amount != null) {
                                    reason = 'কিস্তি পরিশোধ';
                                  } else {
                                    reason = 'ডিসকাউন্ট';
                                  }

                                  
                                  await dealer.reference.update({'dealers_due': updatedDue});

                                  final Map<String, dynamic> transactionData = {
                                    'time': transactionDate,
                                    'description': 'বাকী পরিশোধ',
                                    'due': updatedDue,
                                    'payment': amount,
                                    'discount': discount,
                                    'collector': controller,
                                  };

                                  await FirebaseFirestore.instance
                                      .collection('collection name')
                                      .doc(userId)
                                      .collection('dealers')
                                      .doc(dealer.id)
                                      .collection('history')
                                      .add(transactionData);

                                  
                                  await FirebaseFirestore.instance
                                      .collection('collection name')
                                      .doc(userId)
                                      .collection('cashbox')
                                      .add({
                                    'amount': amount,
                                    'reason':
                                    'কিস্তি আদায়ঃ "${dealerData?['name']}" নামের কাস্টমার $amount টাকা বাকি পরিশোধ করেছেন।',
                                    'time': FieldValue.serverTimestamp(),
                                  });

                                  
                                  if (_nextDate != null && updatedDue > 0) {
                                    _scheduleNotification(
                                      _nextDate!,
                                      dealerData?['name'] ?? 'Unknown',
                                      updatedDue,
                                    );
                                  }

                                  
                                  final yearlyTotalsDoc = FirebaseFirestore
                                      .instance
                                      .collection('collection name')
                                      .doc(userId)
                                      .collection('collection name')
                                      .doc('doc id/name');

                                  Map<String, dynamic> updateData = {
                                    
                                    'total_due': FieldValue.increment(-adjustedAmount),
                                  };

                                  if (sendSMSswitch) {
                                    updateData['sms_count'] =
                                        FieldValue.increment(-1);
                                  }
                                  await yearlyTotalsDoc.set(
                                      updateData, SetOptions(merge: true));

                                  
                                  if (sendSMSswitch) {
                                    final dealerPhone =
                                        dealerData?['phone'] ?? '';
                                    if (dealerPhone.isNotEmpty) {
                                      sendSMSToDealer(
                                        dealerPhone,
                                        'দেনা ${previousDue.toStringAsFixed(0)}, পরিশোধ ${(amount > 0 ? amount : discount).toStringAsFixed(0)}, বর্তমান বাকি: ${updatedDue.toStringAsFixed(0)}',
                                      );
                                    } else {
                                      showGlobalSnackBar(context, 'কাস্টমারের ফোন নম্বর পাওয়া যায়নি।');
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
                                              horizontal: screenWidth * 0.05),
                                          
                                          child: AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(15.0),
                                            ),
                                            title: Center(
                                              child: Text(
                                                'বাকি আদায় সফল হয়েছে!',
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
                                                    'বাকি আদায়: ৳${amount.toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      fontSize:
                                                      screenWidth * 0.04,
                                                      
                                                      color: Colors.green,
                                                    ),
                                                    textAlign: TextAlign
                                                        .center, 
                                                  ),
                                                  SizedBox(height: screenHeight * 0.02),
                                                  Text(
                                                    'ডিসকাউন্ট: ৳${discount.toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      fontSize:
                                                      screenWidth * 0.04,
                                                      
                                                      color: Colors.green,
                                                    ),
                                                    textAlign: TextAlign
                                                        .center, 
                                                  ),
                                                  SizedBox(height: screenHeight * 0.02),
                                                  
                                                  Text(
                                                    'বর্তমান বাকি: ৳${updatedDue.toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      fontSize:
                                                      screenWidth * 0.04,
                                                      
                                                      color: Colors.red,
                                                    ),
                                                    textAlign: TextAlign
                                                        .center, 
                                                  ),
                                                  if (sendSMSswitch &&
                                                      dealerData?['phone']
                                                          ?.isNotEmpty ==
                                                          true) ...[
                                                    SizedBox(
                                                        height: screenHeight *
                                                            0.02), 
                                                    Text(
                                                      'ডিলারকে মেসেজ দেয়া হয়েছে।',
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
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      onPressed: () async {
                                                        var customerData = dealerData;
                                                        await generateAndOpenDuePdf(
                                                          customerName: customerData?['name'] ?? '',
                                                          customerPhone: customerData?['phone'] ?? '',
                                                          previousDue: customerData?['customer_due'] ?? 0.0,
                                                          cashPayment: amount,
                                                          remainingDue: updatedDue,
                                                          discount: discount,
                                                          presentAddress: customerData?['present_address'] ?? '',
                                                          dueCollectionDate: _selectedDate.toString(),
                                                          nextDate: _nextDate.toString() ?? '',
                                                        );
                                                        showGlobalSnackBar(context, 'রসিদ সফলভাবে ডাউনলোড হয়েছে!');
                                                      },
                                                      icon: Icon(Icons.print, color: Colors.blue, size: screenWidth * 0.09),
                                                    ),
                                                    SizedBox(width: 1),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        padding: EdgeInsets.symmetric(
                                                          vertical: screenHeight * 0.005,
                                                          horizontal: screenWidth * 0.05,
                                                        ), 
                                                        backgroundColor: Colors.green,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(12), 
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        Navigator.pop(context);
                                                        _nextDate = null;
                                                      },
                                                      child: Text(
                                                        'ঠিক আছে',
                                                        style: TextStyle(
                                                          fontSize: screenWidth * 0.045,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
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
                                  showGlobalSnackBar(context, 'কিছু ভুল হয়েছে! আবার চেষ্টা করুন।');
                                }
                              } else {
                                hideLoadingDialog(context);
                                showGlobalSnackBar(context, 'ভ্যালিড সংখ্যা ইনপুট করুন।');
                              }
                            } else {
                              hideLoadingDialog(context);
                              showGlobalSnackBar(context, 'পরিমাণ লিখুন।');
                            }
                          } else {
                            hideLoadingDialog(context);
                            showGlobalSnackBar(context, 'আপনার বিল মেয়াদ শেষ হয়েছে।');
                          }
                        },
                        child: Text(
                          'কিস্তি আদায়',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: MediaQuery.of(context).size.width < 400
                                ? 18
                                : 22,
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
      },
    ).then((_) {
      
      _nextDate = null;
      _selectedDate = DateTime.now();
    });
  }

  
  void sendSMSToDealer(String phoneNumber, String message) async {
    
    await SMSService.sendSMS(
      phoneNumber: phoneNumber,
      message: message,
    );
  }

  void _showImageDialog(
      BuildContext context, String imageUrl, DocumentSnapshot dealer) {
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
                      return Image.asset('assets/error.jpg');
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
                          await _pickAndUploadImage(context, dealer);
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
      BuildContext context, String imageUrl, DocumentSnapshot dealer) {
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
                      return Image.asset('assets/error.jpg');
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

  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickAndUploadImage(
      BuildContext context, DocumentSnapshot dealer) async {
    try {
      showLoadingDialog(context, message: 'ছবি আপলোড হচ্ছে...');

      
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
                        size: MediaQuery.of(context).size.width *
                            0.13, 
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
                        size: MediaQuery.of(context).size.width *
                            0.13, 
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
        showGlobalSnackBar(context, 'No image selected');
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
      final File compressedFile = File('${tempDir.path}/${dealer.id}.jpg');
      await compressedFile.writeAsBytes(compressedBytes);

      
      Map<String, dynamic>? dealerData =
      dealer.data() as Map<String, dynamic>?;
      String fileName =
          'collection name/${getCurrentUserId()}/dealers_images/${dealerData?['name']}${dealerData?['phone']}.jpg';
      Reference storageReference =
      FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageReference.putFile(compressedFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      
      await FirebaseFirestore.instance
          .collection('collection name')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('dealers')
          .doc(dealer.id)
          .update({'image': downloadUrl});

      
      await compressedFile.delete();

      
      hideLoadingDialog(context);
      Navigator.pop(context);
      showGlobalSnackBar(context, 'ছবি সফলভাবে আপলোড করা হয়েছে');
    } catch (e) {
      hideLoadingDialog(context);
      showGlobalSnackBar(context, 'ছবি আপলোডে সমস্যা হয়েছে: $e');
    }
  }

  void _showDelete(
      BuildContext context, String userId, DocumentSnapshot dealer) {
    
    double transactionAmount = dealer['dealers_due'] ?? 0;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ডিলিট সতর্কতা!', textAlign: TextAlign.center),
          content: Text(
            '${dealer['name']} - এর সাথে $transactionAmount টাকা লেনদেন রয়েছে।\n'
                'যদি ডিলিট করে দেন এই লেনদেন আর ফেরত পারবেন না।',
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
                    onPressed: () async {
                      if (userId == null) return;

                      final FirebaseFirestore db = FirebaseFirestore.instance;

                      try {
                        
                        final historySnapshot = await db
                            .collection('collection name')
                            .doc(userId)
                            .collection('dealers')
                            .doc(dealer.id)
                            .collection('history')
                            .limit(1) 
                            .get();

                        if (historySnapshot.docs.isNotEmpty) {
                          
                          debugPrint("❌ এই কাস্টমারের হিস্ট্রি আছে, ডিলিট করা যাবে না।");

                          if (mounted) {
                            Navigator.of(context).pop();
                            showGlobalSnackBar(context,'এই কাস্টমারের কিস্তি নেয়া হয়েছে, ডিলিট করা যাবে না।');
                          }
                        } else {
                          
                          if (mounted) {
                            Navigator.of(context).pop();
                            _showDeleteConfirmation(context, dealer);
                          }
                        }
                      } catch (e) {
                        debugPrint("Error checking history: $e");

                        if (mounted) { 
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("কিছু সমস্যা হয়েছে।"),
                            ),
                          );
                        }
                      }
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
  }

  Future<bool> _checkIsDelete() async {
    String? userId = getCurrentUserId();
    if (userId != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('collection name')
          .doc(userId)
          .get();
      return userDoc.get('isDelete') ?? false; 
    }
    return false;
  }

  void _showDeleteConfirmation(
      BuildContext context, DocumentSnapshot dealer) async {

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ডিলিট নিশ্চিত করুন'),
          content: Text(
              'আপনি কি ${dealer['name']} নামের কাস্টমারকে ডিলিট করতে চান? আপনি যদি ডিলিট করেন তাহলে ${dealer['name']}-এর পূর্বের সকল বাকির হিসাব মুছে যাবে।'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                bool isDelete = await _checkIsDelete();
                if (isDelete) {
                  
                  bool pinVerified = await _showPinVerificationDialog(context);
                  if (pinVerified) {
                    try {
                      
                      showLoadingDialog(context, message: 'ডিলিট করা হচ্ছে...');

                      
                      String? imageUrl = dealer['image'];

                      
                      if (imageUrl != null && imageUrl.isNotEmpty) {
                        final ref = FirebaseStorage.instance.refFromURL(imageUrl);
                        await ref.delete();
                      }

                      await deleteDealerData(dealer.id);

                      
                      hideLoadingDialog(context); 
                      Navigator.of(context).pop(); 
                      Navigator.of(context).pop();
                      showGlobalSnackBar(context, 'সফলভাবে ডিলিট হয়েছে');
                    } catch (e) {
                      hideLoadingDialog(context); 
                      Navigator.of(context).pop(); 
                      showGlobalSnackBar(context, 'ডিলিট করতে সমস্যা হয়েছে: $e');
                    }
                  } else {
                    hideLoadingDialog(context); 
                    showGlobalSnackBar(context, 'ভুল পিন, আবার চেষ্টা করুন');
                  }
                } else {
                  try {
                    
                    showLoadingDialog(context, message: 'ডিলিট করা হচ্ছে...');

                    
                    
                    
                    
                    
                    
                    
                    

                    await deleteDealerData(dealer.id);

                    
                    hideLoadingDialog(context);
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                    showGlobalSnackBar(context, 'কাস্টমারের সকল লেনদেন সফলভাবে ডিলিট করা হয়েছে!');
                  } catch (e) {
                    hideLoadingDialog(context);
                    Navigator.of(context).pop();
                    showGlobalSnackBar(context, 'ডিলিট করতে সমস্যা হয়েছে: $e');
                  }
                }
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
              child: Text('না'),
            ),
          ],
        );
      },
    );
  }
}
