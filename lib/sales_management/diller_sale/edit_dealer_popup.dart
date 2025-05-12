import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditDealerInfoPopup extends StatefulWidget {
  final Map<String, dynamic> salesData;
  final String userId;      
  final String saleId;      
  final String dealerId;  
  final String fatherName;
  final String motherName;
  final Timestamp birthDate;
  final Timestamp time;
  final Function(Map<String, dynamic>) onDealerUpdated;

  EditDealerInfoPopup({
    required this.salesData,
    required this.userId,
    required this.saleId,
    required this.dealerId,
    required this.fatherName,
    required this.motherName,
    required this.birthDate,
    required this.time,
    required this.onDealerUpdated,
  });

  @override
  _EditDealerInfoPopupState createState() => _EditDealerInfoPopupState();
}

class _EditDealerInfoPopupState extends State<EditDealerInfoPopup> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController licenseController;
  late TextEditingController presentAddressController;
  late TextEditingController permanentAddressController;
  late TextEditingController nidController;
  late TextEditingController fatherNameController;
  late TextEditingController motherNameController;
  late List<TextEditingController> chassisControllers;  
  late List<String> originalChassisData;  
  late Timestamp birthDate;
  late Timestamp time;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.salesData['name']);
    phoneController = TextEditingController(text: widget.salesData['phone']);
    licenseController = TextEditingController(text: widget.salesData['license'] ?? '');
    presentAddressController = TextEditingController(text: widget.salesData['present_address'] ?? '');
    permanentAddressController = TextEditingController(text: widget.salesData['permanent_address'] ?? '');
    nidController = TextEditingController(text: widget.salesData['nid'] ?? '');
    fatherNameController = TextEditingController(text: widget.fatherName);
    motherNameController = TextEditingController(text: widget.motherName);
    chassisControllers = []; 
    originalChassisData = []; 

    final chassisData = widget.salesData['chassis'];
    if (chassisData is List) {
      
      for (var chassis in chassisData) {
        chassisControllers.add(TextEditingController(text: chassis ?? ''));
        originalChassisData.add(chassis ?? ''); 
      }
    }
    birthDate = widget.birthDate;
    time = widget.time;
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    licenseController.dispose();
    presentAddressController.dispose();
    permanentAddressController.dispose();
    nidController.dispose();
    fatherNameController.dispose();
    motherNameController.dispose();
    for (var controller in chassisControllers) {
      controller.dispose();
    }    super.dispose();
  }

  
  Future<void> _selectDate(BuildContext context, bool isBirthDate) async {
    DateTime initialDate = isBirthDate ? birthDate.toDate() : time.toDate();

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        if (isBirthDate) {
          birthDate = Timestamp.fromDate(pickedDate); 
        } else {
          
          DateTime oldDateTime = time.toDate();
          DateTime newDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            oldDateTime.hour,
            oldDateTime.minute,
            oldDateTime.second,
          );
          time = Timestamp.fromDate(newDateTime); 
        }
      });
    }
  }

  void saveChanges() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final String userId = widget.userId;
    final String saleId = widget.saleId;
    final String dealerId = widget.dealerId;
    final Timestamp oldTime = widget.time; 
    final Timestamp newTime = time; 

    
    if (oldTime.toDate().isAtSameMomentAs(newTime.toDate())) {
      print("Date unchanged, skipping total adjustments.");
    } else {
      
      String oldDailyPath = "${oldTime.toDate().year}-${oldTime.toDate().month}-${oldTime.toDate().day}";
      String oldMonthlyPath = "${oldTime.toDate().year}-${oldTime.toDate().month}";
      String oldYearlyPath = "${oldTime.toDate().year}";

      String newDailyPath = "${newTime.toDate().year}-${newTime.toDate().month}-${newTime.toDate().day}";
      String newMonthlyPath = "${newTime.toDate().year}-${newTime.toDate().month}";
      String newYearlyPath = "${newTime.toDate().year}";

      final double totalPrice = (widget.salesData['totalPrice'] as num?)?.toDouble() ?? 0.0;
      final double payment = (widget.salesData['payment'] as num?)?.toDouble() ?? 0.0;
      final double due = (widget.salesData['due'] as num?)?.toDouble() ?? 0.0;
      final double profit = (widget.salesData['profit'] as num?)?.toDouble() ?? 0.0;

      
      await firestore.runTransaction((transaction) async {
        
        await _updateTotals(transaction, userId, 'collection name', oldDailyPath, -payment, -totalPrice, -due, -profit);
        await _updateTotals(transaction, userId, 'collection name', oldMonthlyPath, 0, -totalPrice, 0, -profit);
        await _updateTotals(transaction, userId, 'collection name', oldYearlyPath, 0, -totalPrice, 0, -profit);
        await _updateTotals(transaction, userId, 'collection name', 'doc id/name', -payment, 0, -due, -profit);

        
        await _updateTotals(transaction, userId, 'collection name', newDailyPath, payment, totalPrice, due, profit);
        await _updateTotals(transaction, userId, 'collection name', newMonthlyPath, 0, totalPrice, 0, profit);
        await _updateTotals(transaction, userId, 'collection name', newYearlyPath, 0, totalPrice, 0, profit);
        await _updateTotals(transaction, userId, 'collection name', 'doc id/name', payment, 0, due, profit);
      });
    }

    
    List<String> updatedChassis = [];
    bool isChassisModified = false;

    
    for (int i = 0; i < chassisControllers.length; i++) {
      String chassisValue = chassisControllers[i].text.trim();
      if (chassisValue.isNotEmpty) {
        updatedChassis.add(chassisValue);
      } else {
        
        if (originalChassisData[i].isNotEmpty) {
          updatedChassis.add('');  
        }
      }

      
      if (chassisValue != originalChassisData[i]) {
        isChassisModified = true;
      }
    }

    
    if (isChassisModified) {
      await firestore.collection('collection name').doc(userId).collection('sales').doc(saleId).update({
        'name': nameController.text,
        'phone': phoneController.text,
        'license': licenseController.text,
        'present_address': presentAddressController.text,
        'permanent_address': permanentAddressController.text,
        'nid': nidController.text,
        'birthDate': birthDate,
        'time': newTime, 
        'chassis': updatedChassis.isNotEmpty ? updatedChassis : FieldValue.delete(), 
      });

      await firestore.collection('collection name').doc(userId).collection('dealers').doc(dealerId).update({
        'name': nameController.text,
        'phone': phoneController.text,
        'license': licenseController.text,
        'present_address': presentAddressController.text,
        'permanent_address': permanentAddressController.text,
        'nid': nidController.text,
        'father_name': fatherNameController.text,
        'mother_name': motherNameController.text,
        'birthDate': birthDate,
        'time': newTime, 
        if (updatedChassis.isNotEmpty) 'chassis': updatedChassis.isNotEmpty ? updatedChassis : FieldValue.delete(), 
      });
    } else {
      print("Chassis data is not modified, skipping update.");
    }

    
    widget.onDealerUpdated({
      'name': nameController.text,
      'phone': phoneController.text,
      'license': licenseController.text,
      'present_address': presentAddressController.text,
      'permanent_address': permanentAddressController.text,
      'nid': nidController.text,
      'father_name': fatherNameController.text,
      'mother_name': motherNameController.text,
      'birthDate': birthDate,
      'time': newTime,
      if (updatedChassis.isNotEmpty) 'chassis': updatedChassis.isNotEmpty ? updatedChassis : [],
    });

    Navigator.pop(context);
  }

  
  Future<void> _updateTotals(
      Transaction transaction,
      String userId,
      String collectionPath,
      String documentPath,
      double payment,
      double totalPrice,
      double due,
      double profit,
      ) async {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final DocumentReference<Map<String, dynamic>> docRef = db
        .collection('collection name')
        .doc(userId)
        .collection(collectionPath)
        .doc(documentPath);

    transaction.set(docRef, {
      'sale_total': FieldValue.increment(totalPrice),
      'field name': FieldValue.increment(profit),
      if (collectionPath == 'collection name') 'sale_paid': FieldValue.increment(payment),
      if (collectionPath == 'collection name' || (collectionPath == 'collection name' && documentPath == 'doc id/name'))
        'total_due': FieldValue.increment(due),
    }, SetOptions(merge: true)); 
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('কাস্টমার তথ্য এডিট'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            
            ListTile(
              title: Text('বিক্রয়ের তারিখ:\n${DateFormat('dd MMM yyyy').format(time.toDate())}'),
              trailing: Icon(Icons.calendar_month),
              onTap: () => _selectDate(context, false),
            ),

            
            ListTile(
              title: Text('জন্মতারিখ:\n${DateFormat('dd MMM yyyy').format(birthDate.toDate())}'),
              trailing: Icon(Icons.calendar_month_sharp),
              onTap: () => _selectDate(context, true),
            ),
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'ক্রেতার নাম')),
            TextField(controller: fatherNameController, decoration: InputDecoration(labelText: 'পিতার নাম')),
            TextField(controller: motherNameController, decoration: InputDecoration(labelText: 'মাতার নাম')),
            TextField(controller: phoneController, decoration: InputDecoration(labelText: 'ফোন নম্বর'), keyboardType: TextInputType.phone),
            TextField(controller: licenseController, decoration: InputDecoration(labelText: 'লাইসেন্স নম্বর')),
            TextField(controller: presentAddressController, decoration: InputDecoration(labelText: 'বর্তমান ঠিকানা')),
            TextField(controller: permanentAddressController, decoration: InputDecoration(labelText: 'স্থায়ী ঠিকানা')),
            TextField(controller: nidController, decoration: InputDecoration(labelText: 'এনআইডি'), keyboardType: TextInputType.number),
            for (int i = 0; i < chassisControllers.length; i++)
              TextField(
                controller: chassisControllers[i],
                decoration: InputDecoration(labelText: 'চেসিস নম্বর ${i + 1}'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('বাতিল')),
        ElevatedButton(onPressed: saveChanges, child: Text('সেভ করুন')),
      ],
    );
  }
}
