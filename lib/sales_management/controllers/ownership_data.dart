import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/all_common_functions.dart';
import '../stock_sale/ownership_form.dart';

class OwnershipTransferFormPage extends StatefulWidget {
  final String? customerName;
  final String? fatherName;
  final String? motherName;
  final String? presentAddress;
  final String? permanentAddress;
  final String? phone;
  final DateTime? saleDate;
  final double? totalPrice;
  final double? advance;
  final double? due;
  final String? chassis;
  final String? nid;

  OwnershipTransferFormPage({
    this.customerName,
    this.fatherName,
    this.motherName,
    this.presentAddress,
    this.permanentAddress,
    this.phone,
    this.saleDate,
    this.totalPrice,
    this.advance,
    this.due,
    this.chassis,
    this.nid,
  });

  @override
  _OwnershipTransferFormPageState createState() =>
      _OwnershipTransferFormPageState();
}

class _OwnershipTransferFormPageState extends State<OwnershipTransferFormPage> {
  final _formKey = GlobalKey<FormState>();

  late String? customerName;
  late String? fatherName;
  late String? motherName;
  late String? presentAddress;
  late String? permanentAddress;
  late String? phone;
  late DateTime? saleDate;
  late double? totalPrice;
  late double? advance;
  late double? due;
  late String? chassis;
  late String? nid;
  late String? brand;
  late String? model;
  late String? color;
  late String? batteryName;

  @override
  void initState() {
    super.initState();

    customerName = widget.customerName;
    fatherName = widget.fatherName;
    motherName = widget.motherName;
    presentAddress = widget.presentAddress;
    permanentAddress = widget.permanentAddress;
    phone = widget.phone;
    saleDate = widget.saleDate;
    totalPrice = widget.totalPrice;
    advance = widget.advance;
    due = widget.due;
    chassis = widget.chassis;
    nid = widget.nid;
    brand = null;
    model = null;
    color = null;
    batteryName = null;
  }

  void _submitForm() {
    generateAndOpenOwnershipTransferPdf(
      customerName: customerName ?? '',
      fatherName: fatherName ?? '',
      motherName: motherName ?? '',
      presentAddress: presentAddress ?? '',
      permanentAddress: permanentAddress ?? '',
      phone: phone ?? '',
      saleDate: saleDate?.toString() ?? '',
      totalPrice: totalPrice ?? 0.0,
      advance: advance ?? 0.0,
      due: due ?? 0.0,
      chassis: chassis ?? '',
      brand: brand ?? '',
      model: model ?? '',
      color: color ?? '',
      batteryName: batteryName ?? '',
    );
    showGlobalSnackBar(context, 'Ownership Transfer PDF generated successfully');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('মালিকানা পেপার'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: customerName,
                  decoration: InputDecoration(labelText: 'ক্রেতার নাম'),
                  onChanged: (value) => setState(() => customerName = value),
                ),
                TextFormField(
                  initialValue: fatherName,
                  decoration: InputDecoration(labelText: 'পিতার নাম'),
                  onChanged: (value) => setState(() => fatherName = value),
                ),
                TextFormField(
                  initialValue: motherName,
                  decoration: InputDecoration(labelText: 'মাতার নাম'),
                  onChanged: (value) => setState(() => motherName = value),
                ),
                TextFormField(
                  initialValue: nid,
                  decoration: InputDecoration(labelText: 'জাতীয় পরিচয়পত্র(NID)'),
                  onChanged: (value) => setState(() => nid = value),
                ),
                TextFormField(
                  initialValue: phone,
                  decoration: InputDecoration(labelText: 'মোবাইল নাম্বার'),
                  onChanged: (value) => setState(() => phone = value),
                ),
                TextFormField(
                  initialValue: presentAddress,
                  decoration: InputDecoration(labelText: 'বর্তমান ঠিকানা'),
                  onChanged: (value) => setState(() => presentAddress = value),
                ),
                TextFormField(
                  initialValue: permanentAddress,
                  decoration: InputDecoration(labelText: 'স্থায়ী ঠিকানা'),
                  onChanged: (value) => setState(() => permanentAddress = value),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: saleDate != null
                            ? DateFormat('dd MMM yyyy').format(saleDate!)
                            : '',
                        decoration: InputDecoration(labelText: 'বিক্রয়ের তারিখ'),
                        readOnly: true,
                        onTap: () async {
                          DateTime? selectedDate = await showDatePicker(
                            context: context,
                            initialDate: saleDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (selectedDate != null && selectedDate != saleDate) {
                            setState(() {
                              saleDate = selectedDate;
                            });
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: chassis,
                        decoration: InputDecoration(labelText: 'অটোর চেসিস নম্বর'),
                        onChanged: (value) => setState(() => chassis = value),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: totalPrice?.toStringAsFixed(0) ?? '',
                        decoration: InputDecoration(labelText: 'মোট মূল্য'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => setState(
                                () => totalPrice = double.tryParse(value)),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: advance?.toStringAsFixed(0) ?? '',
                        decoration: InputDecoration(labelText: 'নগদ পরিশোধ'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => setState(
                                () => advance = double.tryParse(value)),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: due?.toStringAsFixed(0) ?? '',
                        decoration: InputDecoration(labelText: 'কমিশন'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => setState(
                                () => due = double.tryParse(value)),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: brand,
                        decoration: InputDecoration(labelText: 'ব্র্যান্ড'),
                        onChanged: (value) => setState(() => brand = value),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: model,
                        decoration: InputDecoration(labelText: 'মডেল'),
                        onChanged: (value) => setState(() => model = value),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: color,
                        decoration: InputDecoration(labelText: 'কালার'),
                        onChanged: (value) => setState(() => color = value),
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  initialValue: batteryName,
                  decoration: InputDecoration(labelText: 'ব্যাটারির নাম'),
                  onChanged: (value) => setState(() => batteryName = value),
                ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      _submitForm();
                    },
                    child: Text('Generate PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
