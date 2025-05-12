import 'package:flutter/material.dart';

class AppPaymentPage extends StatefulWidget {
  _ExpensePageState createState() => _ExpensePageState();
}

class _ExpensePageState extends State<AppPaymentPage> {
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'বিল পরিশোধ',
          style: TextStyle(
            color: Colors.green, 
            fontWeight: FontWeight.bold, 
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, 
            children: [
              Text(
                "বিকাশ বা নগদের মাধ্যমে বিল পরিশোধ করতে পারবেন। বিল পরিশোধের পর আপনার নোটিফিকেশান থেকে জানতে পারবেন। ধন্যবাদ...",
                style: TextStyle(
                  fontSize: 24.0, 
                  color: Colors.blue, 
                  fontWeight: FontWeight.bold, 
                ),
                textAlign: TextAlign.center, 
              ),
              SizedBox(height: 50),
              Text(
                "বিকাশ থেকে 01234567899 (01234567899) এই নম্বরে সেন্ড মানি করবেন।",
                style: TextStyle(
                  fontSize: 24.0, 
                  color: Colors.blue, 
                ),
              ),
              SizedBox(height: 10), 

              Center( 
                child: Image.asset(
                  'assets/image1.jpg', 
                  width: 200, 
                  height: 150, 
                ),
              ),
              SizedBox(height: 10), 

              Center( 
                child: Image.asset(
                  'assets/image2.jpg',
                  width: 200,
                  height: 300,
                ),
              ),
              SizedBox(height: 50),
              Text(
                "নগদ থেকে 01234567899 (01234567899) এই নম্বরে সেন্ড মানি করবেন।",
                style: TextStyle(
                  fontSize: 24.0, 
                  color: Colors.blue, 
                ),
              ),

              Center( 
                child: Image.asset(
                  'assets/image3.jpg',
                  width: 200,
                  height: 200,
                ),
              ),
              SizedBox(height: 10),

              Center( 
                child: Image.asset(
                  'assets/image4.jpg',
                  width: 200,
                  height: 200,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
