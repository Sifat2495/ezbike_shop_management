import 'package:flutter/material.dart';
import 'expense_list.dart';

class ExpensePageUI extends StatelessWidget {
  final TextEditingController reasonController;
  final TextEditingController amountController;
  final Function(String) addExpense;
  final double addCash, cash, cost, withdraw;

  ExpensePageUI({
    required this.reasonController,
    required this.amountController,
    required this.addExpense,
    required this.addCash,
    required this.cash,
    required this.cost,
    required this.withdraw,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade200, 
            Colors.yellow.shade100, 
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCard('ক্যাশবক্স', cash),
                ],
              ),
              SizedBox(height: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCard('জমা', addCash),
                  _buildCard('উত্তোলন', withdraw),
                  _buildCard('খরচ', cost),
                ],
              ),
              SizedBox(height: 8),
              _buildTextField(
                controller: reasonController,
                label: 'বিবরণ লিখুন',
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: 5),
              _buildTextField(
                controller: amountController,
                label: 'টাকার পরিমাণ',
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton('জমা', Colors.green, () => addExpense('deposit'), context),
                  _buildActionButton('উত্তোলন', Colors.blue, () => addExpense('cashOut'), context),
                  _buildActionButton('খরচ', Colors.red, () => addExpense('cost'), context),
                ],
              ),
              SizedBox(height: 16),
              Center(
                child: Text(
                  'সকল জমা-খরচ লিস্ট',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center, 
                ),
              ),
              SizedBox(height: 8),
              Align(
                alignment: Alignment.bottomCenter, 
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: ExpenseList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required TextInputType keyboardType,
  }) {
    return Container(
      height: 45, 
      width: double.infinity, 
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.black), 
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.black),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30), 
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30), 
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30), 
            borderSide: BorderSide(color: Colors.grey),
          ),
          fillColor: Colors.white.withOpacity(0.1),
          filled: true,
        ),
      ),
    );
  }

  
  Widget _buildActionButton(String label, Color color, Function onPressed, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      width: screenWidth * 0.28, 
      height: 37, 
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color, 
          foregroundColor: Colors.white, 
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
        ),
        onPressed: () => onPressed(),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13, 
          ),
        ),
      ),
    );
  }

  
  Widget _buildCard(String title, double value) {
    Color cardColor;

    
    if (title == 'জমা') {
      cardColor = Colors.green; 
    } else if (title == 'উত্তোলন') {
      cardColor = Colors.blue; 
    } else if (title == 'খরচ') {
      cardColor = Colors.red; 
    } else {
      cardColor = Colors.yellow; 
    }

    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 8,
        color: cardColor,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: title == 'ক্যাশবক্স' ? 20 : 18, 
                  fontWeight: FontWeight.bold,
                  color: title == 'ক্যাশবক্স' ? Colors.black : Colors.white, 
                ),
              ),
              SizedBox(height: 3),
              Text(
                '৳${value.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: title == 'ক্যাশবক্স' ? 20 : 15, 
                  fontWeight: FontWeight.w600,
                  color: title == 'ক্যাশবক্স' ? Colors.black : Colors.white, 
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
