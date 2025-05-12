import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/all_common_functions.dart';

class SMSPurchaseUI extends StatelessWidget {
  final Stream<int> smsCountStream;
  final List<Map<String, dynamic>> packages;
  final Future<void> Function(int) onPurchase;

  SMSPurchaseUI({
    required this.smsCountStream,
    required this.packages,
    required this.onPurchase,
  });

  void showPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'আন্তরিক ভাবে দুঃখিত!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: MediaQuery.of(context).size.width < 600 ? 22 : 20,
              color: Colors.red,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'অনলাইন পেমেন্ট এখনো যুক্ত করা হয়নাই।\n\n',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 16,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'বিকাশ নম্বর: ',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: '01234567899'));
                          showGlobalSnackBar(context, 'বিকাশ নম্বর কপি হয়েছে!');
                          },
                        child: Row(
                          children: [
                            Text(
                              '01234567899',
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width < 600 ? 16 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.copy, size: 20, color: Colors.blue),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'নগদ নম্বর: ',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: '01234567899'));
                          showGlobalSnackBar(context, 'নগদ নম্বর কপি হয়েছে!');
                          },
                        child: Row(
                          children: [
                            Text(
                              '01234567899',
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width < 600 ? 16 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.copy, size: 20, color: Colors.blue),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '\n\nনগদ বা বিকাশের মাধ্যমে Send Money করে সরাসরি SMS কিনতে পাড়বেন।',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 16,
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
          actions: [
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                  child: Text(
                    'বন্ধ করুন',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('Purchase SMS'),
        centerTitle: true,
        elevation: 2.0,
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenWidth * 0.03,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<int>(
                stream: smsCountStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    return Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: Colors.red,
                      ),
                    );
                  }
                  final smsCount = snapshot.data ?? 0;
                  return Container(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueAccent, width: 1.0),
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(0, 4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Available SMS:',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            '$smsCount',
                            style: TextStyle(
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),

                  );
                },
              ),
              SizedBox(height: screenWidth * 0.05),
              Align(
                alignment: Alignment.center,
                child: Text(
                  'Choose a package to purchase:',
                  style: TextStyle(
                    fontSize: screenWidth * 0.044,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: screenWidth * 0.04),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: screenWidth < 600 ? 2 : 3,
                  mainAxisSpacing: screenWidth * 0.03,
                  crossAxisSpacing: screenWidth * 0.03,
                  childAspectRatio: screenWidth < 600 ? 1.2 : 1.5,
                ),
                itemCount: packages.length,
                itemBuilder: (context, index) {
                  final package = packages[index];
                  return Card(
                    elevation: 5.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.02),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${package['messages']} Messages',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Price: ${package['price']} BDT',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[600],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: screenWidth * 0.01),
                            child: ElevatedButton(
                              onPressed: () async {
                                showPaymentDialog(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: screenWidth * 0.015,
                                  horizontal: screenWidth * 0.08,
                                ),
                                minimumSize: Size(screenWidth * 0.4, screenWidth * 0.07),
                              ),
                              child: Text(
                                'Buy',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.05,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}