import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportSection extends StatelessWidget {
  final double screenWidth;

  SupportSection(this.screenWidth);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.blue.shade600, width: 2), 
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade500,
              Colors.blue.shade200,
              Colors.blue.shade500,
              Colors.blue.shade200,
              Colors.blue.shade500,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: 10),
              Text(
                'আপনার যদি কোনও সমস্যা বা প্রশ্ন থাকে, দয়া করে আমাদের সাথে যোগাযোগ করুন।',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _makePhoneCall('+8801234567899'),
                    icon: Icon(Icons.call, color: Colors.white),
                    label: Text(
                      'কল করুন',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(screenWidth * 0.4, 50),
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }
}
