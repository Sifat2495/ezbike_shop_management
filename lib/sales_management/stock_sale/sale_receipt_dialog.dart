import 'package:bebshar_poristhiti_stock/sales_management/stock_sale/pdf_generator.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../report/all_transactions/all_transactions.dart';
import '../../widgets/all_common_functions.dart';

class SaleReceiptDialog extends StatelessWidget {
  final String customerName;
  final String customerPhone;
  final double totalAmount;
  final double cashPayment;
  final double remainingAmount;
  final String saleDate;
  final String presentAddress;
  final String permanentAddress;
  final List<Map<String, dynamic>> selectedProducts;

  SaleReceiptDialog({
    required this.customerName,
    required this.customerPhone,
    required this.totalAmount,
    required this.cashPayment,
    required this.remainingAmount,
    required this.presentAddress,
    required this.permanentAddress,
    required this.saleDate,
    required this.selectedProducts,
  });

  Widget buildReceiptRow({
    required String label,
    required String value,
    IconData? icon,
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
          if (icon != null)
            Icon(
              icon,
              size: 16,
              color: Colors.teal,
            ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: valueStyle ??
                  TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String formatDateTime(String saleDate) {
    DateTime parsedDate = DateTime.parse(saleDate);
    String formattedDate = DateFormat('dd-MM-yyyy').format(parsedDate);
    String formattedTime = DateFormat('hh:mm a').format(parsedDate);
    return '$formattedDate। $formattedTime';
  }

  double calculateTotalProductPrice(List<Map<String, dynamic>> products) {
    return products.fold<double>(0.0, (double sum, product) {
      final salePrice = product['sale_price'] as num;
      final quantity = product['quantity'] ?? 1;
      return sum + (salePrice * quantity);
    });
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.brown, size: 30),
              SizedBox(width: 8),
              Text(
                'বিক্রয়ের রসিদ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.download, color: Colors.brown),
            onPressed: () async {
              final double totalProductPrice = calculateTotalProductPrice(selectedProducts);
              final List<Map<String, dynamic>> productsCopy =
              selectedProducts.map((product) {
                return Map<String, dynamic>.from(
                    product); 
              }).toList();
              await generateAndOpenSalePdf(
                customerName: customerName,
                customerPhone: customerPhone,
                totalAmount: totalAmount,
                cashPayment: cashPayment,
                remainingAmount: remainingAmount,
                presentAddress: presentAddress,
                totalProductPrice: totalProductPrice,
                permanentAddress: permanentAddress,
                saleDate: saleDate,
                selectedProducts: productsCopy,
              );
              showGlobalSnackBar(context, 'রসিদ সফলভাবে ডাউনলোড হয়েছে!');
            },
          ),
        ],
      ),
      content: SingleChildScrollView(
        
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(color: Colors.brown, thickness: 1.5),
            SizedBox(height: 2),
            buildReceiptRow(
              label: 'নাম:',
              value: customerName,
              valueStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
            buildReceiptRow(
              label: 'ফোন নম্বর:',
              value: customerPhone,
              valueStyle:
              TextStyle(color: Colors.brown, fontWeight: FontWeight.bold),
            ),
            buildReceiptRow(
              label: 'তারিখ:',
              value: convertToBengaliNumbers(formatDateTime(saleDate)),
              valueStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            buildReceiptRow(
              label: 'ঠিকানা:' ,
              value: presentAddress,
              valueStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2),
            Divider(color: Colors.black, thickness: 1),
            Column(
              children: [
                
                ...selectedProducts.map((product) {
                  final salePrice = product['sale_price'] as num;
                  final productName = product['name'];
                  final quantity = product['quantity'] ?? 1;
                  final totalPrice = salePrice * quantity;
                  return buildReceiptRow(
                    label: '$productName:',
                    value:
                    '${convertToBengaliNumbers(salePrice.toStringAsFixed(0))} x ${convertToBengaliNumbers(quantity.toString())} = ৳${convertToBengaliNumbers(totalPrice.toStringAsFixed(0))}',
                  );
                }).toList(),

                Divider(color: Colors.black, thickness: 1), 

                
                buildReceiptRow(
                  label: 'মোট:',
                  value: '৳${convertToBengaliNumbers(selectedProducts.fold<double>(0.0, (double sum, product) {
                    final salePrice = product['sale_price'] as num;
                    final quantity = product['quantity'] ?? 1;
                    return sum + (salePrice * quantity);
                  }).toStringAsFixed(0))}',
                ),

                buildReceiptRow(
                    label: (totalAmount - selectedProducts.fold<double>(0.0, (double sum, product) {
                      final salePrice = product['sale_price'] as num;
                      final quantity = product['quantity'] ?? 1;
                      return sum + (salePrice * quantity);
                    })) < 0
                        ? 'ডিস্কাউন্ট'  
                        : 'সার্ভিস চার্জ:',  
                    value: '৳${convertToBengaliNumbers(
                        (totalAmount - selectedProducts.fold<double>(0.0, (double sum, product) {
                          final salePrice = product['sale_price'] as num;
                          final quantity = product['quantity'] ?? 1;
                          return sum + (salePrice * quantity);
                        })).abs().toStringAsFixed(0))}',
                    valueStyle: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            buildReceiptRow(
              label: 'মোট বিক্রয়মূল্য:',
              value:
              '৳${convertToBengaliNumbers(totalAmount.toStringAsFixed(0))}',
            ),
            buildReceiptRow(
              label: 'নগদ পরিশোধ:',
              value:
              '৳${convertToBengaliNumbers(cashPayment.toStringAsFixed(0))}',
            ),
            buildReceiptRow(
              label: 'বর্তমান বাকি:',
              value:
              '৳${convertToBengaliNumbers(remainingAmount.toStringAsFixed(0))}',
              valueStyle:
              TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.brown,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                builder: (context) => AllTransactions(),
                ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: Text(
              'ঠিক আছে',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
