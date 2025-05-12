import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MonthReportPage extends StatefulWidget {
  final bool isPurchase;

  const MonthReportPage({required this.isPurchase, Key? key}) : super(key: key);

  @override
  _MonthReportPageState createState() => _MonthReportPageState();
}

class _MonthReportPageState extends State<MonthReportPage> {
  int? selectedYear;
  String? selectedMonth;
  List<Map<String, dynamic>> dailyData = [];
  double monthlyTotal = 0;

  final List<int> years = List.generate(14, (index) => 2022 + index);
  final List<String> months = [
    'জানুয়ারী', 'ফেব্রুয়ারী', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'অগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    
    final DateTime now = DateTime.now();
    selectedYear = now.year;  
    selectedMonth = months[now.month - 1];  

    
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'মাসিক রিপোর্ট',
          style: TextStyle(fontSize: width < 600 ? 18 : 22),
        ),
        backgroundColor: Colors.teal,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            buildDropdowns(),
            SizedBox(height: 20),
            if (selectedYear != null && selectedMonth != null)
              Text(
                '($selectedMonth $selectedYear) - এর সকল ${widget.isPurchase ? 'ক্রয়' : 'বিক্রয়'} রিপোর্ট',
                style: TextStyle(
                  fontSize: width < 600 ? 16 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800],
                ),
              ),
            SizedBox(height: 20),
            isLoading
                ? Center(child: CircularProgressIndicator())
                : buildReportList(),
            SizedBox(height: 20),
            if (selectedYear != null && selectedMonth != null)
              buildMonthlyTotal(),
          ],
        ),
      ),
    );
  }

  
  Widget buildDropdowns() {
    return Row(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButton<int>(
              isExpanded: true,
              value: selectedYear,
              hint: const Text('বছর নির্বাচন করুন'),
              onChanged: (value) {
                setState(() {
                  selectedYear = value;
                  fetchData();
                });
              },
              menuMaxHeight: 400,
              items: years.map((year) {
                return DropdownMenuItem(
                  value: year,
                  child: Text('$year'),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedMonth,
              hint: const Text('মাস নির্বাচন করুন'),
              onChanged: (value) {
                setState(() {
                  selectedMonth = value;
                  fetchData();
                });
              },
              menuMaxHeight: 400,
              items: months.map((month) {
                return DropdownMenuItem(
                  value: month,
                  child: Text(month),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  
  Widget buildReportList() {
    if (dailyData.isEmpty) {
      return const Expanded(
        child: Center(child: Text('কোনো ডেটা পাওয়া যায়নি।')),
      );
    }
    return Expanded(
      child: ListView.separated(
        itemCount: dailyData.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final data = dailyData[index];
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    data['date'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'মোট বিক্রিঃ ${data['total'].toStringAsFixed(0)}',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold, 
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  
  Widget buildMonthlyTotal() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$selectedMonth - এর মোট ${widget.isPurchase ? 'ক্রয়' : 'বিক্রয়'}: ${monthlyTotal.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center, 
        ),
      ),
    );
  }

  
  void fetchData() async {
    if (selectedYear == null || selectedMonth == null) return;

    setState(() {
      isLoading = true;
      dailyData.clear();
      monthlyTotal = 0;
    });

    final String userId = FirebaseAuth.instance.currentUser!.uid;

    final monthIndex = months.indexOf(selectedMonth!) + 1;
    final monthString = monthIndex.toString();  
    final yearMonth = '${selectedYear!}-$monthString';  

    try {
      
      final dailySnapshot = await _firestore
          .collection('collection name')
          .doc(userId)
          .collection('collection name')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: '$yearMonth-1')  
          .where(FieldPath.documentId, isLessThanOrEqualTo: '$yearMonth-31')  
          .get();

      final dailyList = dailySnapshot.docs.map((doc) {
        return {
          'date': doc.id,
          'total': doc[widget.isPurchase ? 'purchase_total' : 'sale_total'],
        };
      }).toList();

      final monthlySnapshot = await _firestore
          .collection('collection name')
          .doc(userId)
          .collection('collection name')
          .doc(yearMonth)
          .get();

      setState(() {
        dailyData = dailyList;

        
        monthlyTotal = monthlySnapshot.exists
            ? (monthlySnapshot[widget.isPurchase ? 'purchase_total' : 'sale_total'] ?? 0.0).toDouble()
            : 0.0;
      });

    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
