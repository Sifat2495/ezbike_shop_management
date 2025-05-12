import 'package:flutter/material.dart';
import '../purchase_management/stock_purchase/purchase_with_stock.dart';
import '../sales_management/stock_sale/sale_with_stock.dart';

class LargeActionButtons extends StatelessWidget {
  final BuildContext context;
  final double screenWidth;
  final double screenHeight;

  LargeActionButtons(this.context, this.screenWidth, this.screenHeight);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildLargeActionButton(
          'assets/sandii.png', 
          'ক্রয়',
          context,
          Colors.brown,
        ),
        _buildLargeActionButton(
          'assets/sell.png', 
          'বিক্রয়',
          context,
          Colors.transparent,
        ),
      ],
    );
  }

  Widget _buildLargeActionButton(
      String assetPath, String label, BuildContext context, Color color) {
    
    final Gradient gradient = (label == 'ক্রয়')
        ? LinearGradient(colors: [Colors.blue.shade100, Colors.yellow.shade100, Colors.blue.shade100])
        : LinearGradient(
        colors: [Colors.blue.shade100, Colors.yellow.shade100, Colors.blue.shade100]);

    return Expanded(
      child: InkWell(
        onTap: () {
          if (label == 'ক্রয়') {
            
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => PurchaseStockPage()));
          } else if (label == 'বিক্রয়') {
            
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => SaleStockPage()));
          }
        },
        child: Card(
          elevation: 8,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: gradient, 
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    assetPath, 
                    width: 90, 
                    height: 90, 
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold, 
                      color: Colors.black, 
                    ),
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
