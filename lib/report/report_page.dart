import 'package:flutter/material.dart';
import 'date_report_page.dart';
import 'loss_profit/loss_profit.dart';
import 'month_report_page.dart';
import 'year_report_page.dart';

class ReportPage extends StatefulWidget {
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> with SingleTickerProviderStateMixin {
  bool? isPurchaseSelected;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    
    _controller = AnimationController(
      vsync: this, 
      duration: Duration(seconds: 3), 
    )..repeat(reverse: true); 
  }

  @override
  void dispose() {
    _controller.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('রিপোর্ট'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade50, 
              Colors.white, 
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => LossProfitPage()),
                            );
                          },
                          child: AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              return Container(
                                padding: EdgeInsets.all(screenWidth * 0.025,),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.red,
                                      Colors.blue,
                                      Colors.green,
                                    ],
                                    stops: [0.0, 0.5, 1.0],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    transform: GradientRotation(
                                        _controller.value * 2 * 3.1416),
                                  ),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: Center(
                                  child: Text(
                                    'লাভ/লস',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.06,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenWidth * 0.05),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: ChoiceButton(
                          title: 'ক্রয় রিপোর্ট',
                          isSelected: isPurchaseSelected == true,
                          onTap: () => setState(() => isPurchaseSelected = true),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Flexible(
                        child: ChoiceButton(
                          title: 'বিক্রয় রিপোর্ট',
                          isSelected: isPurchaseSelected == false,
                          onTap: () => setState(() => isPurchaseSelected = false),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenWidth * 0.08),
                  
                  if (isPurchaseSelected != null)
                    Column(
                      children: [
                        ReportButton(
                          title: 'তারিখ ভিত্তিক বিস্তারিত রিপোর্ট দেখুন',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DateReportPage(isPurchase: isPurchaseSelected!),
                              ),
                            );
                          },
                          isSelected: isPurchaseSelected,
                        ),
                        SizedBox(height: screenWidth * 0.04),
                        ReportButton(
                          title: 'মাস ভিত্তিক রিপোর্ট দেখুন',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    MonthReportPage(isPurchase: isPurchaseSelected!),
                              ),
                            );
                          },
                          isSelected: isPurchaseSelected,
                        ),
                        SizedBox(height: screenWidth * 0.04),
                        ReportButton(
                          title: 'বছর ভিত্তিক রিপোর্ট দেখুন',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    YearReportPage(isPurchase: isPurchaseSelected!),
                              ),
                            );
                          },
                          isSelected: isPurchaseSelected,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class ChoiceButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  ChoiceButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    Color backgroundColor = Colors.teal;
    TextStyle textStyle = TextStyle(color: Colors.white);

    if (isSelected) {
      backgroundColor = title == 'ক্রয় রিপোর্ট' ? Colors.green.shade800 : Colors.blue.shade900;
      textStyle = TextStyle(color: Colors.white);
    }

    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.black,
          padding: EdgeInsets.symmetric(
            vertical: screenWidth * 0.04,
            horizontal: screenWidth * 0.06,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 5,
        ),
        child: Text(
          title,
          style: textStyle.copyWith(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}


class ReportButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool? isSelected;

  ReportButton({
    required this.title,
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    Color backgroundColor = Colors.teal;
    if (isSelected != null) {
      backgroundColor = isSelected! ? Colors.green : Colors.blue.shade500;
    }

    return Container(
      width: screenWidth * 0.8,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.black,
          padding: EdgeInsets.symmetric(
            vertical: screenWidth * 0.05,
            horizontal: screenWidth * 0.07,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 6,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
