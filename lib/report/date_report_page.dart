import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'detail_popup.dart';

class DateReportPage extends StatefulWidget {
  final bool
      isPurchase; 

  DateReportPage({required this.isPurchase});

  @override
  _DateReportPageState createState() => _DateReportPageState();
}

class _DateReportPageState extends State<DateReportPage> {
  DateTime? _fromDate;
  bool _isLoading = false;
  bool _hasMore = true;
  List<QueryDocumentSnapshot> _reportDocuments = [];
  DocumentSnapshot? _lastDocument;
  double _dailyTotal = 0.0;

  final int _initialLimit = 10;

  @override
  void initState() {
    super.initState();

    _fromDate = DateTime.now();
    _loadInitialData();
    _loadDailyTotal();
  }

  
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _fromDate) {
      setState(() {
        _fromDate = picked;
        _reportDocuments.clear();
        _lastDocument = null;
      });
      _loadInitialData();
      _loadDailyTotal();
    }
  }

  _showDetails(
      BuildContext context, Map<String, dynamic> reportData, bool isPurchase) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DetailPopup(
          reportData: reportData,
          isPurchase: isPurchase, 
        );
      },
    );
  }

  
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _reportDocuments.clear(); 
      _lastDocument =
          null; 
    });

    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid;
      String collection = widget.isPurchase ? 'purchases' : 'sales';

      
      Query reportQuery = FirebaseFirestore.instance
          .collection('collection name/$userId/$collection')
          .orderBy('time', descending: true)
          .limit(_initialLimit);

      if (_fromDate != null) {
        DateTime selectedDateStart =
            DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
        DateTime selectedDateEnd = selectedDateStart.add(Duration(days: 1));

        reportQuery = reportQuery
            .where('time',
                isGreaterThanOrEqualTo: Timestamp.fromDate(selectedDateStart))
            .where('time', isLessThan: Timestamp.fromDate(selectedDateEnd));
      }

      QuerySnapshot snapshot = await reportQuery.get();

      setState(() {
        _reportDocuments = snapshot.docs;
        _hasMore = snapshot.docs.length == _initialLimit;
        _isLoading = false;
      });

      if (_reportDocuments.isNotEmpty) {
        _lastDocument = _reportDocuments.last;
      }
    } catch (error) {
      print('Error fetching data: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  
  Future<void> _loadDailyTotal() async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    
    DateTime now = _fromDate ?? DateTime.now(); 
    String todayDocId = '${now.year}-${now.month}-${now.day}';

    
    FirebaseFirestore.instance
        .collection('collection name')
        .doc(uid)
        .collection('collection name')
        .doc(todayDocId)
        .snapshots() 
        .listen((docSnapshot) {
      if (docSnapshot.exists && docSnapshot.data() != null) {
        
        double? total = widget.isPurchase
            ? (docSnapshot.data()?['purchase_total'] as num?)?.toDouble() ?? 0.0
            : (docSnapshot.data()?['sale_total'] as num?)?.toDouble() ?? 0.0;

        
        setState(() {
          _dailyTotal = total;
        });
      } else {
        setState(() {
          _dailyTotal = 0.0; 
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportType = widget.isPurchase ? 'ক্রয়ের' : 'বিক্রয়ের';
    final dateText = _fromDate != null
        ? DateFormat('dd-MM-yyyy').format(_fromDate!)
        : 'তারিখ নির্বাচন করুন';

    return Scaffold(
      appBar: AppBar(
        title: Text('$reportType রিপোর্ট'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ElevatedButton.icon(
                onPressed: _selectDate,
                icon: Icon(
                  Icons.calendar_month_sharp, 
                  color: Colors.white, 
                  size: 20, 
                ),
                label: Text(
                  'তারিখ নির্বাচন করুন',
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.white, 
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, 
                  foregroundColor: Colors.white, 
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12), 
                  ),
                  elevation: 4, 
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                '($dateText) তারিখের সকল $reportType রিপোর্ট',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 16),

            
            Expanded(
              child: _reportDocuments.isEmpty && !_isLoading
                  ? Center(child: Text('ডেটা পাওয়া যায়নি।'))
                  : NotificationListener<ScrollNotification>(
                      onNotification: (scrollNotification) {
                        if (scrollNotification is ScrollEndNotification &&
                            scrollNotification.metrics.pixels ==
                                scrollNotification.metrics.maxScrollExtent) {
                          _loadMoreData();
                        }
                        return false;
                      },
                      child: ListView.builder(
                        itemCount: _reportDocuments.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _reportDocuments.length) {
                            return Center(child: CircularProgressIndicator());
                          }

                          final doc = _reportDocuments[index];
                          Timestamp timeStamp = doc['time'];
                          String formattedDate = DateFormat('dd-MM-yyyy')
                              .format(timeStamp.toDate());
                          String formattedTime =
                              DateFormat('hh:mm a').format(timeStamp.toDate());

                          
                          return GestureDetector(
                            onTap: () {
                              _showDetails(
                                  context,
                                  doc.data() as Map<String, dynamic>,
                                  widget
                                      .isPurchase); 
                            },
                            child: Card(
                              margin: EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'তারিখ: $formattedDate',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'সময়: $formattedTime',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '৳ ${doc['totalPrice'].toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),

            
            Divider(thickness: 2),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                
                child: Text(
                  'মোট $reportType মূল্য: ৳ ${_dailyTotal.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid;
      String collection = widget.isPurchase ? 'purchases' : 'sales';

      Query reportQuery = FirebaseFirestore.instance
          .collection('collection name/$userId/$collection')
          .orderBy('time', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_initialLimit);

      
      if (_fromDate != null) {
        reportQuery =
            reportQuery.where('time', isGreaterThanOrEqualTo: _fromDate);
      }

      QuerySnapshot snapshot = await reportQuery.get();

      setState(() {
        _reportDocuments.addAll(snapshot.docs);
        _hasMore = snapshot.docs.length == _initialLimit;
        _isLoading = false;
      });

      
      if (_reportDocuments.isNotEmpty) {
        _lastDocument = _reportDocuments.last;
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
