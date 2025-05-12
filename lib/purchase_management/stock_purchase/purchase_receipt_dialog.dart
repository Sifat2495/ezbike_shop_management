import 'package:bebshar_poristhiti_stock/purchase_management/stock_purchase/supplier_pdf_generator.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../widgets/all_common_functions.dart';

class ReceiptDialog extends StatelessWidget {
  final String supplierName;
  final String supplierPhone;
  final double totalAmount;
  final double cashPayment;
  final double remainingAmount;
  final double selectedPreviousTransaction;
  final double grandTotal;
  final String purchaseDate;
  final List<Map<String, dynamic>> selectedProducts;
  final Function resetStateCallback;

  ReceiptDialog({
    required this.supplierName,
    required this.supplierPhone,
    required this.totalAmount,
    required this.cashPayment,
    required this.remainingAmount,
    required this.selectedPreviousTransaction,
    required this.grandTotal,
    required this.purchaseDate,
    required this.selectedProducts,
    required this.resetStateCallback,
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
                color: Colors.grey[600],
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

  String formatDateTime(String purchaseDate) {
    
    DateTime parsedDate = DateTime.parse(purchaseDate);

    
    String formattedDate =
    DateFormat('dd-MM-yyyy').format(parsedDate); 
    String formattedTime =
    DateFormat('hh:mm a').format(parsedDate); 

    return '$formattedDate;$formattedTime';
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
                'ক্রয়ের রসিদ',
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
              final List<Map<String, dynamic>> productsCopy =
              selectedProducts.map((product) {
                return Map<String, dynamic>.from(
                    product); 
              }).toList();
              await generateAndOpenPurchasePdf(
                supplierName: supplierName,
                supplierPhone: supplierPhone,
                totalAmount: totalAmount,
                cashPayment: cashPayment,
                remainingAmount: remainingAmount,
                purchaseDate: purchaseDate,
                selectedPreviousTransaction: selectedPreviousTransaction,
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
              value: supplierName,
              valueStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
            buildReceiptRow(
              label: 'ফোন নম্বর:',
              value: supplierPhone,
              valueStyle:
              TextStyle(color: Colors.brown, fontWeight: FontWeight.bold),
            ),
            buildReceiptRow(
              label: 'তারিখ:',
              value: convertToBengaliNumbers(formatDateTime(purchaseDate)),
              valueStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2),
            Divider(color: Colors.grey[300], thickness: 1),
            Column(
              children: selectedProducts.map((product) {
                final purchasePrice = product['purchase_price'];
                final purchaseStock = product['purchase_stock'];
                final totalPrice = purchasePrice * purchaseStock;
                return buildReceiptRow(
                  label: '${product['name']}:',
                  value:
                  '${convertToBengaliNumbers(product['purchase_price'].toStringAsFixed(0))} x ${convertToBengaliNumbers(product['purchase_stock'].toString())} = ৳${convertToBengaliNumbers(totalPrice.toStringAsFixed(0))}',
                );
              }).toList(),
            ),
            Divider(color: Colors.grey[300], thickness: 1),
            buildReceiptRow(
              label: 'মোট ক্রয়মূল্য:',
              value:
              '${convertToBengaliNumbers(totalAmount.toStringAsFixed(0))} টাকা',
              
            ),
            buildReceiptRow(
              label: 'আগের দেনা:',
              value:
              '${convertToBengaliNumbers(selectedPreviousTransaction.toStringAsFixed(0))} টাকা',
              
            ),
            Divider(color: Colors.grey[300], thickness: 1),
            buildReceiptRow(
              label: 'দেনা সহ মোট:',
              value:
              '${convertToBengaliNumbers(grandTotal.toStringAsFixed(0))} টাকা',
              
            ),
            buildReceiptRow(
              label: 'নগদ পরিশোধ:',
              value:
              '${convertToBengaliNumbers(cashPayment.toStringAsFixed(0))} টাকা',
              
            ),
            Divider(color: Colors.grey[300], thickness: 1),
            buildReceiptRow(
              label: 'বর্তমান দেনা:',
              value:
              '${convertToBengaliNumbers(remainingAmount.toStringAsFixed(0))} টাকা',
              
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
            resetStateCallback();
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
