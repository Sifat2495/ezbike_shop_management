import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart'; 
import 'dart:io';
import '../models/employee_model.dart';
import '../services/employee_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class AddEmployeeScreen extends StatefulWidget {
  @override
  _AddEmployeeScreenState createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _positionController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _nidController = TextEditingController();
  final _salaryController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  File? _selectedImage; 

  final EmployeeService employeeService = EmployeeService();

  Future<void> _pickImage() async {
    
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.all(0), 
        content: Padding(
          padding: EdgeInsets.symmetric(vertical: 20), 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                child: Flexible(
                  flex: 1,
                  child: Icon(
                    Icons.image,
                    size: MediaQuery.of(context).size.width * 0.2, 
                    color: Colors.blue,
                  ),
                ),
              ),
              SizedBox(width: 40),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
                child: Flexible(
                  flex: 1,
                  child: Icon(
                    Icons.camera_alt,
                    size: MediaQuery.of(context).size.width * 0.2, 
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
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

  Future<File?> _compressImage(File imageFile) async {
    
    final compressedImage = await FlutterImageCompress.compressWithFile(
      imageFile.path,
      minWidth: 600,
      minHeight: 600,
      quality: 60, 
      rotate: 0,
    );

    if (compressedImage != null) {
      return File(imageFile.path)..writeAsBytesSync(compressedImage);
    }
    return null;
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('কর্মচারী যুক্ত করুন'),
        automaticallyImplyLeading: false, 
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'নাম'),
                ),
                TextFormField(
                  controller: _phoneNumberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  decoration: InputDecoration(labelText: 'মোবাইল নাম্বার'),
                  
                  
                  
                  
                  
                  
                  
                  
                ),
                TextFormField(
                  controller: _emergencyContactController,
                  keyboardType: TextInputType.phone,
                  decoration:
                  InputDecoration(labelText: 'জরুরী যোগাযোগ নাম্বার'),
                ),
                TextFormField(
                  controller: _positionController,
                  decoration: InputDecoration(labelText: 'পদবী'),
                ),
                TextFormField(
                  controller: _nidController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration:
                  InputDecoration(labelText: 'জাতীয় পরিচয়পত্রের নাম্বার'),
                ),
                TextFormField(
                  controller: _salaryController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'বেতন'),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                  ],
                ),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: 'ঠিকানা'),
                ),
                SizedBox(height: 0),
                _selectedImage == null
                    ? Text("") 
                    : Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Image.file(_selectedImage!, height: 100),
                    Padding(
                      padding: EdgeInsets.all(
                          4), 
                      child: Container(
                        width: 24, 
                        height: 24, 
                        decoration: BoxDecoration(
                          color: Colors
                              .white, 
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(
                              4), 
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          padding:
                          EdgeInsets.zero, 
                          iconSize: 16, 
                          icon: Icon(Icons.clear, color: Colors.red),
                          onPressed:
                          _clearImage, 
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text('ছবি আপলোড করুন'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      String? imageUrl;
                      if (_selectedImage != null) {
                        final compressedImage = await _compressImage(_selectedImage!);

                        final fileName = path.basename(compressedImage!.path);
                        final storageRef = FirebaseStorage.instance
                            .ref()
                            .child('collection name/${employeeService.userId}/employee_images/$fileName');
                        await storageRef.putFile(_selectedImage!);
                        imageUrl = await storageRef.getDownloadURL();
                      }

                      final employee = Employee(
                        id: FirebaseFirestore.instance
                            .collection('collection name')
                            .doc(employeeService.userId)
                            .collection('collection name')
                            .doc()
                            .id, 
                        name: _nameController.text,
                        position: _positionController.text,
                        phoneNumber: _phoneNumberController.text,
                        nid: _nidController.text,
                        salary: double.tryParse(_salaryController.text),
                        address: _addressController.text,
                        emergencyContact: _emergencyContactController.text,
                        imageUrl: imageUrl, 
                      );

                      await employeeService.addEmployee(employee);

                      Navigator.of(context).pop();
                    }
                  },
                  child: Text('সেভ করুন'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _phoneNumberController.dispose();
    _nidController.dispose();
    _salaryController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }
}
