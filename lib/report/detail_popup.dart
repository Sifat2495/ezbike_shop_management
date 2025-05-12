import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../purchase_management/stock_purchase/supplier_pdf_generator.dart';
import '../sales_management/stock_sale/pdf_generator.dart';

class DetailPopup extends StatelessWidget {
  final Map<String, dynamic> reportData;
  final bool isPurchase;

  const DetailPopup({Key? key, required this.reportData, required this.isPurchase})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double totalPrice = _calculateTotalPrice(reportData['products'] ?? [], isPurchase);

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('বিস্তারিত তথ্য', style: TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            icon: Icon(Icons.download, color: Colors.teal),
            onPressed: () async {
              await _downloadReceipt();
            },
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            _buildDataRow('নাম', reportData['name'] ?? 'নেই'),
            _buildDataRow('ফোন', reportData['phone'] ?? 'নেই'),
            _buildDataRow('মোট মূল্য', '৳ ${totalPrice.toStringAsFixed(0)}'),
            _buildDataRow('ডিসকাউন্ট', '৳ ${(totalPrice - (reportData['totalPrice'] ?? 0)).toStringAsFixed(0)}'),
            _buildDataRow('মূল্য', '৳ ${((reportData['totalPrice'] ?? 0)).toStringAsFixed(0)}'),
            if (isPurchase) ...[
              _buildDataRow('পূর্বের বাকী', '৳ ${reportData['previousDue'].toStringAsFixed(0) ?? 0}'),
              _buildDataRow('বাকীসহ মোট', '৳ ${reportData['priceWithDue'].toStringAsFixed(0) ?? 0}'),
            ],
            _buildDataRow('নগদ', '৳ ${reportData['payment'].toStringAsFixed(0) ?? 0}'),
            _buildDataRow('লেনদেনের পর বাকি', '৳ ${reportData['due'].toStringAsFixed(0) ?? 0}'),
            _buildDataRow(
              'তারিখ',
              reportData['time'] != null
                  ? DateFormat('dd-MM-yyyy, hh:mm a').format(reportData['time'].toDate())
                  : 'নেই',
            ),
            SizedBox(height: 16),
            Text(
              'পণ্যসমূহ:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            
            ..._buildProductList(reportData['products'] ?? []),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('বন্ধ করুন', style: TextStyle(color: Colors.teal)),
        ),
      ],
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  List<Widget> _buildProductList(List<dynamic> products) {
    if (products.isEmpty) {
      return [Text('কোন পণ্য নেই।')];
    }
    return products.asMap().entries.map((entry) {
      int index = entry.key + 1;
      Map<String, dynamic> product = entry.value;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black, fontSize: 14),
                          children: [
                            TextSpan(
                              text: '$index: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: '${product['name'] ?? 'N/A'}',
                            ),
                          ],
                        ),
                        overflow: TextOverflow.visible,
                        softWrap: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${(product[isPurchase ? 'purchase_stock' : 'quantity'] ?? 0).toInt()}',
                        style: TextStyle(color: Colors.black, fontSize: 14),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.visible,
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Future<void> _downloadReceipt() async {
    
    final isSale = reportData['type'] == 'sale';

    
    final Name = reportData['name'] ?? 'Unknown';
    final Phone = reportData['phone'] ?? 'Unknown';
    final totalPrice = _calculateTotalPrice(reportData['products'] ?? [], isPurchase);
    final totalAmount = reportData['totalPrice'] ?? 0.0;
    final cashPayment = reportData['payment'] ?? 0.0;
    final selectedPreviousTransaction = reportData['previousDue'] ?? 0.0;
    final remainingAmount = reportData['due'] ?? 0.0;
    final presentAddress = reportData['address'] ?? 'Unknown';
    final Date = reportData['time']?.toDate().toIso8601String() ?? '';
    final selectedProducts = (reportData['products'] ?? [])
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
        .toList();
    final quantityMap = _buildQuantityMap(reportData['products'] ?? []);

    if (isPurchase) {
      await generateAndOpenPurchasePdf(
        supplierName: Name,
        supplierPhone: Phone,
        totalAmount: totalAmount,
        cashPayment: cashPayment,
        remainingAmount: remainingAmount,
        selectedPreviousTransaction: selectedPreviousTransaction,
        purchaseDate: Date,
        selectedProducts: selectedProducts,
      );
    } else {
      await generateAndOpenSalePdf(
        customerName: Name,
        customerPhone: Phone,
        totalAmount: totalAmount,
        cashPayment: cashPayment,
        remainingAmount: remainingAmount,
        presentAddress: presentAddress,
        permanentAddress: '',
        saleDate: Date,
        selectedProducts: selectedProducts,
        totalProductPrice: totalPrice,
      );
    }
  }

  Map<String, int> _buildQuantityMap(List<dynamic> products) {
    Map<String, int> quantityMap = {};
    for (var product in products) {
      String name = product['name'] ?? 'Unknown';
      int quantity = isPurchase
          ? (product['purchase_stock'] ?? 0).toInt()
          : (product['quantity'] ?? 0).toInt();
      quantityMap[name] = quantity;
    }
    return quantityMap;
  }

  double _calculateTotalPrice(List<dynamic> products, bool isPurchase) {
    double totalPrice = 0.0;
    for (var product in products) {
      if (isPurchase) {
        
        totalPrice += (product['purchase_price'] ?? 0) * (product['purchase_stock'] ?? 0);
      } else {
        
        totalPrice += (product['sale_price'] ?? 0) * (product['quantity'] ?? 0);
      }
    }
    return totalPrice;
  }
}
