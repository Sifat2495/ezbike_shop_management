import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProductPaymentEditPopup extends StatefulWidget {
  final String customerId;
  final List<Map<String, dynamic>> products;
  final Map<String, dynamic> salesData;
  final ValueChanged<Map<String, dynamic>> onUpdate;

  const ProductPaymentEditPopup({
    Key? key,
    required this.customerId,
    required this.products,
    required this.salesData,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _ProductPaymentEditPopupState createState() =>
      _ProductPaymentEditPopupState();
}

class _ProductPaymentEditPopupState extends State<ProductPaymentEditPopup> {
  final TextEditingController _downPaymentController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  double _totalPrice = 0.0;
  double _remainingAmount = 0.0;
  final Map<String, TextEditingController> _quantityControllers = {};
  final Map<String, TextEditingController> _priceControllers = {};

  @override
  void initState() {
    super.initState();
    double initialPayment = (widget.salesData['payment'] ?? 0).toDouble();
    _downPaymentController.text = initialPayment.toStringAsFixed(0);
    double initialMonth = (widget.salesData['months'] ?? 0).toDouble();
    _monthController.text = initialMonth.toStringAsFixed(0);
    _downPaymentController.addListener(_calculateRemainingAmount);

    widget.products.forEach((product) {
      String productName = product['name'];
      int quantity = product['quantity'] ?? 1;
      double price = (product['sale_price'] ?? 0).toDouble();
      double totalProductPrice = product['total_price'] ?? (price * quantity);

      _quantityControllers[productName] = TextEditingController(text: '$quantity');
      _priceControllers[productName] = TextEditingController(text: totalProductPrice.toStringAsFixed(0));

      _quantityControllers[productName]!.addListener(() {
        _updatePriceBasedOnQuantity(productName);
        _updateTotalPrice();
      });

      _priceControllers[productName]!.addListener(() {
        _updateTotalPrice();
      });
    });

    _updateTotalPrice();
  }

  Future<void> updateFirestoreOnEdit(Map<String, dynamic> updatedSalesData) async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    WriteBatch batch = FirebaseFirestore.instance.batch();
    DateTime saleDate = (updatedSalesData['time'] as Timestamp).toDate();
    String formattedDate = '${saleDate.year}-${saleDate.month}-${saleDate.day}';

    double newTotalPrice = updatedSalesData['totalPrice'];
    double newPayment = updatedSalesData['payment'];
    double newDue = updatedSalesData['due'];
    double oldDue = widget.salesData['due'] ?? 0.0;
    double dueDifference = newDue - oldDue; 

    List<Map<String, dynamic>> updatedProducts = List<Map<String, dynamic>>.from(updatedSalesData['products']);

    final CollectionReference stockRef = FirebaseFirestore.instance
        .collection('collection name')
        .doc(userId)
        .collection('collection name');

    final DocumentReference customerRef = FirebaseFirestore.instance
        .collection('collection name')
        .doc(userId)
        .collection('collection name')
        .doc(widget.customerId);

    final CollectionReference lossProfitCollection = FirebaseFirestore.instance
        .collection('collection name')
        .doc(userId)
        .collection('collection name');

    final DocumentReference dailyTotalsRef = FirebaseFirestore.instance
        .collection('collection name')
        .doc(userId)
        .collection('collection name')
        .doc(formattedDate);

    final DocumentReference monthlyTotalsRef = FirebaseFirestore.instance
        .collection('collection name')
        .doc(userId)
        .collection('collection name')
        .doc('${saleDate.year}-${saleDate.month}');

    final DocumentReference yearlyTotalsRef = FirebaseFirestore.instance
        .collection('collection name')
        .doc(userId)
        .collection('collection name')
        .doc('${saleDate.year}');

    final DocumentReference allTimeDocRef = FirebaseFirestore.instance
        .collection('collection name')
        .doc(userId)
        .collection('collection name')
        .doc('doc id/name');

    final DocumentSnapshot dailyTotalsDoc = await dailyTotalsRef.get();
    double existingDailyProfit = (dailyTotalsDoc.exists && dailyTotalsDoc['field name'] != null)
        ? (dailyTotalsDoc['field name'] as num).toDouble()
        : 0.0;
    double existingDailySale = (dailyTotalsDoc.exists && dailyTotalsDoc['sale_total'] != null)
        ? (dailyTotalsDoc['sale_total'] as num).toDouble()
        : 0.0;
    double existingDailyPaid = (dailyTotalsDoc.exists && dailyTotalsDoc['sale_paid'] != null)
        ? (dailyTotalsDoc['sale_paid'] as num).toDouble()
        : 0.0;
    double existingDailyDue = (dailyTotalsDoc.exists && dailyTotalsDoc['total_due'] != null)
        ? (dailyTotalsDoc['total_due'] as num).toDouble()
        : 0.0;

    final DocumentSnapshot monthlyTotalsDoc = await monthlyTotalsRef.get();
    double existingMonthlySale = (monthlyTotalsDoc.exists && monthlyTotalsDoc['sale_total'] != null)
        ? (monthlyTotalsDoc['sale_total'] as num).toDouble()
        : 0.0;
    double existingMonthlyProfit = (monthlyTotalsDoc.exists && monthlyTotalsDoc['field name'] != null)
        ? (monthlyTotalsDoc['field name'] as num).toDouble()
        : 0.0;

    final DocumentSnapshot yearlyTotalsDoc = await yearlyTotalsRef.get();
    double existingYearlySale = (yearlyTotalsDoc.exists && yearlyTotalsDoc['sale_total'] != null)
        ? (yearlyTotalsDoc['sale_total'] as num).toDouble()
        : 0.0;
    double existingYearlyProfit = (yearlyTotalsDoc.exists && yearlyTotalsDoc['field name'] != null)
        ? (yearlyTotalsDoc['field name'] as num).toDouble()
        : 0.0;

    final DocumentSnapshot allTimeDoc = await allTimeDocRef.get();
    double existingAllTimeDue = (allTimeDoc.exists && allTimeDoc['total_due'] != null)
        ? (allTimeDoc['total_due'] as num).toDouble()
        : 0.0;
    double existingAllTimeProfit = (allTimeDoc.exists && allTimeDoc['field name'] != null)
        ? (allTimeDoc['field name'] as num).toDouble()
        : 0.0;

    
    final DocumentSnapshot customerDoc = await customerRef.get();
    double existingCustomerDue = (customerDoc.exists && customerDoc['customer_due'] != null)
        ? (customerDoc['customer_due'] as num).toDouble()
        : 0.0;

    double updatedCustomerDue = existingCustomerDue + dueDifference; 
    double updatedAllTimeDue = existingAllTimeDue + dueDifference; 
    double totalDailyProfit = 0.0; 
    double oldTotalProfit = 0.0; 

    for (var product in updatedProducts) {
      String productName = product['name'];
      int newQuantity = product['quantity'];
      double salePrice = product['sale_price'];
      double totalPrice = double.tryParse(_priceControllers[productName]!.text) ?? (salePrice * newQuantity);

      int oldQuantity = widget.products
          .firstWhere((p) => p['name'] == productName, orElse: () => {'quantity': newQuantity})['quantity'];
      double oldPTotalPrice = widget.products
          .firstWhere((p) => p['name'] == productName, orElse: () => {'total_price': totalPrice})['total_price'];

      int quantityDifference = oldQuantity - newQuantity; 

      final QuerySnapshot stockQuery = await stockRef.where('name', isEqualTo: productName).limit(1).get();

      if (stockQuery.docs.isNotEmpty) {
        final DocumentReference productRef = stockQuery.docs.first.reference;
        final Map<String, dynamic> stockData = stockQuery.docs.first.data() as Map<String, dynamic>;

        int existingStock = (stockData['collection name'] ?? 0).toInt();
        int updatedStock = existingStock + quantityDifference;
        double purchasePrice = (stockData['purchase_price'] ?? 0.0).toDouble();


        batch.update(productRef, {
          'collection name': updatedStock,
        });

        final QuerySnapshot existingDocs = await lossProfitCollection
            .where('name', isEqualTo: productName)
            .limit(1)
            .get();

        if (existingDocs.docs.isNotEmpty) {
          final DocumentReference docRef = existingDocs.docs.first.reference;
          final Map<String, dynamic> existingData = existingDocs.docs.first.data() as Map<String, dynamic>;

          double oldSaleTotal = (existingData['sale_netTotal'] ?? 0).toDouble();
          double oldProfit = (existingData['field name'] ?? 0.0).toDouble();
          double oldProfitPerProduct = oldPTotalPrice - (purchasePrice * oldQuantity);
          double profitPerProduct = oldProfit - oldProfitPerProduct + totalPrice- (purchasePrice * newQuantity);
          double newProfitPerProduct = totalPrice - (purchasePrice * newQuantity);
          

          batch.update(docRef, {
            'sale_stock': (existingData['sale_stock'] ?? 0.0) - quantityDifference,
            'sale_netTotal': oldSaleTotal - (oldPTotalPrice - totalPrice),
            'field name': profitPerProduct,
          });
          totalDailyProfit += newProfitPerProduct;
          oldTotalProfit += oldProfitPerProduct;
          } else {
          double newProfit = totalPrice - (purchasePrice * newQuantity);
          batch.set(lossProfitCollection.doc(), {
            'name': productName,
            'sale_stock': newQuantity,
            'sale_netTotal': totalPrice,
            'field name': newProfit,
          });
          totalDailyProfit += newProfit; 
        }
      }
      double updatedDailyProfit = existingDailyProfit - oldTotalProfit + totalDailyProfit;
      batch.set(dailyTotalsRef, {
        'sale_total': existingDailySale +(newTotalPrice - widget.salesData['totalPrice']),
        'sale_paid': existingDailyPaid + (newPayment - widget.salesData['payment']),
        'total_due': existingDailyDue + (newDue - widget.salesData['due']),
        'field name': updatedDailyProfit,
      }, SetOptions(merge: true));

      batch.set(monthlyTotalsRef, {
        'sale_total': existingMonthlySale + (newTotalPrice - widget.salesData['totalPrice']),
        'field name': existingMonthlyProfit - oldTotalProfit + totalDailyProfit,
      }, SetOptions(merge: true));

      batch.set(yearlyTotalsRef, {
        'sale_total': existingYearlySale + (newTotalPrice - widget.salesData['totalPrice']),
        'field name': existingYearlyProfit - oldTotalProfit + totalDailyProfit,
      }, SetOptions(merge: true));

      batch.set(allTimeDocRef, {
        'total_due': updatedAllTimeDue,
        'field name': existingAllTimeProfit - oldTotalProfit + totalDailyProfit,
      }, SetOptions(merge: true));

    }

    
    batch.update(customerRef, {
      'customer_due': updatedCustomerDue,
    });

    await batch.commit();
  }

  void _updatePriceBasedOnQuantity(String productName) {
    int quantity = int.tryParse(_quantityControllers[productName]!.text) ?? 1;
    double price = (widget.products.firstWhere((p) => p['name'] == productName)['sale_price'] ?? 0).toDouble();
    double newTotalPrice = price * quantity;

    if (_priceControllers[productName]!.text != newTotalPrice.toStringAsFixed(0)) {
      _priceControllers[productName]!.text = newTotalPrice.toStringAsFixed(0);
    }
  }

  void _calculateRemainingAmount() {
    double downPayment = double.tryParse(_downPaymentController.text) ?? 0.0;
    setState(() {
      _remainingAmount = _totalPrice - downPayment;
    });
  }

  void _updateTotalPrice() {
    double totalPrice = 0.0;
    _priceControllers.forEach((productName, controller) {
      double price = double.tryParse(controller.text) ?? 0.0;
      totalPrice += price;
    });

    setState(() {
      _totalPrice = totalPrice;
    });

    _calculateRemainingAmount();
  }

  @override
  void dispose() {
    _downPaymentController.removeListener(_calculateRemainingAmount);
    _downPaymentController.dispose();
    _quantityControllers.forEach((_, controller) => controller.dispose());
    _priceControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('বিক্রয় এডিট করুন'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('প্রোডাক্ট', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Table(
              columnWidths: {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 5),
                      child: Text('নাম', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 5),
                      child: Text('পরিমাণ', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 5),
                      child: Text('মূল্য', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                    ),
                  ],
                ),
                ...widget.products.map((product) {
                  String productName = product['name'];
                  return TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 5),
                        child: Text(productName),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 5),
                        child: TextField(
                          controller: _quantityControllers[productName],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8)),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 5),
                        child: TextField(
                          controller: _priceControllers[productName],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8)),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
            SizedBox(height: 10),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('মোট মূল্য:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('৳${_totalPrice.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('নগদ পরিশোধ:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _downPaymentController,
                    decoration: InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8)),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('বাকি:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('৳${_remainingAmount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('নির্ধারিত মাস:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _monthController,
                    decoration: InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8)),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
        ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            double downPayment = double.tryParse(_downPaymentController.text) ?? 0.0;
            double remaining = _remainingAmount;

            List<Map<String, dynamic>> updatedProducts = widget.products.map((product) {
              String productName = product['name'];
              int quantity = int.tryParse(_quantityControllers[productName]!.text) ?? 1;
              double salePrice = (product['sale_price'] ?? 0).toDouble();
              double totalPrice = double.tryParse(_priceControllers[productName]!.text) ?? (salePrice * quantity);

              return {
                'name': productName,
                'quantity': quantity,
                'sale_price': salePrice,
                'total_price': totalPrice,
              };
            }).toList();

            Map<String, dynamic> updatedSalesData = {
              ...widget.salesData,
              'payment': downPayment,
              'due': remaining,
              'totalPrice': _totalPrice,
              'products': updatedProducts,
              'months': double.tryParse(_monthController.text) ?? 0.0,
            };

            await updateFirestoreOnEdit(updatedSalesData);
            widget.onUpdate(updatedSalesData); 
            Navigator.of(context).pop(updatedSalesData);
          },
          child: Text('সেভ করুন'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('বাতিল করুন'),
        ),
      ],
    );
  }
}
