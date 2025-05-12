import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class YearReportPage extends StatefulWidget {
  final bool isPurchase;

  YearReportPage({required this.isPurchase});

  @override
  _YearReportPageState createState() => _YearReportPageState();
}

class _YearReportPageState extends State<YearReportPage> {
  int? selectedYear;
  final List<int> years = List.generate(13, (index) => 2022 + index);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, double> monthlyTotals = {};
  double yearlyTotal = 0;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedYear = DateTime.now().year; 
    fetchData(); 
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text('বছর রিপোর্ট', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.black54, Colors.black]
                : [Colors.white, Colors.teal.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            
            Container(
              decoration: _boxDecoration(isDarkMode),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: DropdownButton<int>(
                value: selectedYear,
                isExpanded: true,
                hint: const Text('বছর নির্বাচন করুন', style: TextStyle(fontSize: 16)),
                icon: const Icon(Icons.arrow_drop_down),
                underline: SizedBox(),
                dropdownColor: isDarkMode ? Colors.grey[850] : Colors.white,
                menuMaxHeight: 500, 
                onChanged: (value) {
                  setState(() {
                    selectedYear = value;
                    fetchData();
                  });
                },
                items: years.map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text(
                      '$year',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            
            if (selectedYear != null)
              Text(
                '$selectedYear সালের ${widget.isPurchase ? 'ক্রয়ের' : 'বিক্রয়ের'} রিপোর্ট',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 20),

            
            Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: Text('       মাস', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '   মোট বিক্রয়',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const Divider(),

            
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final monthName = [
                      'জানুয়ারী',
                      'ফেব্রুয়ারী',
                      'মার্চ',
                      'এপ্রিল',
                      'মে',
                      'জুন',
                      'জুলাই',
                      'অগস্ট',
                      'সেপ্টেম্বর',
                      'অক্টোবর',
                      'নভেম্বর',
                      'ডিসেম্বর'
                    ][index];
                    final monthKey = '$selectedYear-${(index + 1)}';
                    final total = monthlyTotals[monthKey] ?? 0;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: _boxDecoration(isDarkMode),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text(monthName)),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'বিক্রিঃ ${total.toStringAsFixed(0)} ৳',
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                color: Colors.black, 
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            
            if (selectedYear != null)
              Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(16),
                decoration: _boxDecoration(isDarkMode),
                child: Text(
                  '$selectedYear -এর মোট ${widget.isPurchase ? 'ক্রয়' : 'বিক্রয়'}: ${yearlyTotal.toStringAsFixed(0)} ৳',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
              ),
          ],
        ),
      ),
    );
  }

  
  BoxDecoration _boxDecoration(bool isDarkMode) {
    return BoxDecoration(
      color: isDarkMode ? Colors.grey[850] : Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: isDarkMode ? Colors.black54 : Colors.grey.shade300,
          offset: const Offset(4, 4),
          blurRadius: 10,
        ),
        BoxShadow(
          color: isDarkMode ? Colors.black87 : Colors.white,
          offset: const Offset(-4, -4),
          blurRadius: 10,
        ),
      ],
    );
  }

  
  Future<void> fetchData() async {
    if (selectedYear == null) return;

    setState(() {
      isLoading = true;
      monthlyTotals.clear();
      yearlyTotal = 0;
    });

    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final yearString = selectedYear.toString();

    try {
      
      for (int month = 1; month <= 12; month++) {
        final monthKey = '$yearString-${month.toString()}';
        final monthlySnapshot = await _firestore
            .collection('collection name')
            .doc(userId)
            .collection('collection name')
            .doc(monthKey)
            .get();

        debugPrint('Checking monthKey: $monthKey');
        if (monthlySnapshot.exists) {
          final data = monthlySnapshot.data();
          final total = data?[widget.isPurchase ? 'purchase_total' : 'sale_total'] ?? 0;

          monthlyTotals[monthKey] = (total is int) ? total.toDouble() : total;
          debugPrint('Rendering MonthKey: $monthKey, Total: $total');
        }
      }

      
      final yearlySnapshot = await _firestore
          .collection('collection name')
          .doc(userId)
          .collection('collection name')
          .doc(yearString)
          .get();

      setState(() {
        yearlyTotal = yearlySnapshot.exists
            ? yearlySnapshot[
        widget.isPurchase ? 'purchase_total' : 'sale_total'] ??
            0
            : 0;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
