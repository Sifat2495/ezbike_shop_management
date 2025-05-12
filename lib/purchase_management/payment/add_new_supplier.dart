import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../widgets/all_common_functions.dart'; 

class AddSupplierPage extends StatefulWidget {
  @override
  _AddSupplierPageState createState() => _AddSupplierPageState();
}

class _AddSupplierPageState extends State<AddSupplierPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _transactionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  File? _selectedImage;
  String? _image;

  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  
  Future<void> _pickImage() async {
    
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose image source'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(ImageSource.camera),
            child: Text('Camera'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
            child: Text('Gallery'),
          ),
        ],
      ),
    );

    if (source != null) {
      
      final pickedFile = await ImagePicker().pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    }
  }

  void _saveSupplier() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      showGlobalSnackBar(context, 'Please log in to add supplier');
      return;
    }

    if (_formKey.currentState!.validate()) {
      showLoadingDialog(context,
          message: 'Saving supplier...'); 

      final String name = _nameController.text.trim();
      final String phone = _phoneController.text.trim();

      
      
      
      
      
      
      

      
      final phoneCheck = await FirebaseFirestore.instance
          .collection('collection name')
          .doc(user.uid)
          .collection('suppliers')
          .where('phone', isEqualTo: phone)
          .get();

      if (phoneCheck.docs.isNotEmpty) {
        hideLoadingDialog(context); 
        showGlobalSnackBar(
            context, 'এই ফোন নম্বরের একটি সাপ্লায়ার যুক্ত করা আছে');
        return;
      }

      
      if (_selectedImage != null) {
        final imageFile = File(_selectedImage!.path);
        final imageBytes = await imageFile.readAsBytes();

        
        var result = await FlutterImageCompress.compressWithList(
          imageBytes,
          minWidth: 800, 
          minHeight: 600, 
          quality: 60, 
        );

        
        final compressedImage = File('${imageFile.path}_compressed.jpg')
          ..writeAsBytesSync(result);

        
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('collection name/${user.uid}/supplier_images/$name$phone.jpg');
        await storageRef.putFile(compressedImage);
        _image = await storageRef.getDownloadURL();
      } else {
        _image = ''; 
      }

      double supplierDue = 0.0;
      if (_transactionController.text.isNotEmpty) {
        try {
          supplierDue = double.parse(_transactionController.text);
        } catch (e) {
          hideLoadingDialog(context); 
          showGlobalSnackBar(context, 'লেনদেনের জন্য সঠিক পরিমাণ দিন');
          return;
        }
      }

      final Timestamp transactionDate = Timestamp.fromDate(_selectedDate);

      final supplierData = {
        'name': name,
        'phone': phone,
        'image': _image,
        'supplier_due': supplierDue,
        'time': transactionDate,
        'sms_supplier': true,
      };

      try {
        await FirebaseFirestore.instance
            .collection('collection name')
            .doc(user.uid)
            .collection('suppliers')
            .add(supplierData);

        
        final yearlyTotalsRef = FirebaseFirestore.instance
            .collection('collection name')
            .doc(user.uid)
            .collection('collection name')
            .doc('doc id/name');

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(yearlyTotalsRef);
          if (!snapshot.exists) {
            
            transaction.set(yearlyTotalsRef, {'supplier_due': supplierDue});
          } else {
            
            final currentSupplierDue = snapshot.data()?['supplier_due'] ?? 0.0;
            transaction.update(
              yearlyTotalsRef,
              {'supplier_due': currentSupplierDue + supplierDue},
            );
          }
        });

        final supplierDocId = await _getSupplierDocId(user.uid, phone);
        if (supplierDocId != null) {
          await FirebaseFirestore.instance
              .collection('collection name')
              .doc(user.uid)
              .collection('suppliers')
              .doc(supplierDocId)
              .collection('history')
              .add({
            'payment': 0,
            'reason': 'add supplier',
            'due': supplierDue,
            'time': transactionDate,
          });
        }

        hideLoadingDialog(context);
        showGlobalSnackBar(context,'সাপ্লায়ার সফলভাবে যুক্ত হয়েছে');

        _formKey.currentState!.reset();
        setState(() {
          _selectedDate = DateTime.now();
          _selectedImage = null;
        });
        Navigator.pop(context);
      } catch (e) {
        hideLoadingDialog(context); 
        showGlobalSnackBar(context,'ডাটা সংরক্ষণে সমস্যা হয়েছে: $e');
      }
    }
  }

  Future<String?> _getSupplierDocId(String userId, String phone) async {
    final QuerySnapshot supplierSnapshot = await FirebaseFirestore.instance
        .collection('collection name')
        .doc(userId)
        .collection('suppliers')
        .where('phone', isEqualTo: phone)
        .get();

    if (supplierSnapshot.docs.isNotEmpty) {
      return supplierSnapshot.docs.first.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        title: Center(
          child: Text(
            'সাপ্লায়ার যুক্ত করুন',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18, 
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                Text(
                  "লেনদেনের তারিখ",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${_selectedDate.toLocal()}".split(' ')[0],
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        Icon(Icons.calendar_today, color: Colors.black54),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10),

                
                Text("সাপ্লায়ারের ছবি",
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 100, 
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      image: _selectedImage == null
                          ? DecorationImage(
                        image: AssetImage('assets/error.jpg'),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: _selectedImage == null
                        ? Center(
                        child: Text('ছবি নির্বাচন করুন',
                            style: TextStyle(color: Colors.black)))
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 100, 
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),

                
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'নাম',
                    border: OutlineInputBorder(),
                    isDense: true, 
                    contentPadding: EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal:
                        12.0), 
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'এখানে নাম লিখুন';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),

                
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'ফোন নম্বর',
                    border: OutlineInputBorder(),
                    isDense: true, 
                    contentPadding: EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal:
                        12.0), 
                  ),

                  inputFormatters: [
                    LengthLimitingTextInputFormatter(
                        11), 
                    FilteringTextInputFormatter.digitsOnly, 
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'এখানে ফোন নম্বর লিখুন';
                    } else if (value.length != 11) {
                      return 'ফোন নম্বর অবশ্যই ১১ সংখ্যার হতে হবে';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),

                
                TextFormField(
                  controller: _transactionController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'আগের লেনদেন(টাকা)',
                    border: OutlineInputBorder(),
                    isDense: true, 
                    contentPadding: EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal:
                        12.0), 
                  ),
                ),
                SizedBox(height: 10),

                
                Center(
                  child: ElevatedButton(
                    onPressed: _saveSupplier,
                    style: ElevatedButton.styleFrom(
                      padding:
                      EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                      backgroundColor: Colors.blue,
                    ),
                    child: Text(
                      'সেভ করুন',
                      style: TextStyle(fontSize: 18, color: Colors.white),
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
