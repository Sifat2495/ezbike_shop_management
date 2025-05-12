import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class AddGuarantorPopup extends StatefulWidget {
  final Map<String, String>? initialData;

  AddGuarantorPopup({this.initialData});

  @override
  _AddGuarantorPopupState createState() => _AddGuarantorPopupState();
}

class _AddGuarantorPopupState extends State<AddGuarantorPopup> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _presentAddressController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _nidController = TextEditingController();
  DateTime? _selectedDate;
  bool _isPhoneValid = true;
  bool _isAnyFieldFilled = false;
  XFile? _selectedGuarantorImage;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _nameController.text = widget.initialData!['name'] ?? '';
      _phoneController.text = widget.initialData!['phone'] ?? '';
      _addressController.text = widget.initialData!['permanentAddress'] ?? '';
      _presentAddressController.text = widget.initialData!['presentAddress'] ?? '';
      _fatherNameController.text = widget.initialData!['father_name'] ?? '';
      _motherNameController.text = widget.initialData!['mother_name'] ?? '';
      _nidController.text = widget.initialData!['nid'] ?? '';
      _selectedDate = widget.initialData!['dob'] != 'Not Set'
          ? DateTime.parse(widget.initialData!['dob']!)
          : null;
      if (widget.initialData!['selectedImage'] != null &&
          widget.initialData!['selectedImage']!.isNotEmpty) {
        _selectedGuarantorImage = XFile(widget.initialData!['selectedImage']!);
      }
    }
    _checkIfAnyFieldFilled();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _presentAddressController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _nidController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();

    
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ছবি নির্বাচন করুন'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: Text('গ্যালারী'),
                leading: Icon(Icons.photo_library),
                onTap: () {
                  Navigator.of(context).pop(ImageSource.gallery);
                },
              ),
              ListTile(
                title: Text('ক্যামেরা'),
                leading: Icon(Icons.camera_alt),
                onTap: () {
                  Navigator.of(context).pop(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );

    
    if (source != null) {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 6, 
      );

      setState(() {
        _selectedGuarantorImage = image;
      });
    }
  }

  void _checkIfAnyFieldFilled() {
    setState(() {
      _isAnyFieldFilled = _nameController.text.isNotEmpty ||
          _phoneController.text.isNotEmpty ||
          _addressController.text.isNotEmpty ||
          _presentAddressController.text.isNotEmpty ||
          _fatherNameController.text.isNotEmpty ||
          _motherNameController.text.isNotEmpty ||
          _nidController.text.isNotEmpty ||
          _selectedDate != null;
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('জামিনদারের তথ্য',
              style: TextStyle(
                  fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold)),
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.pop(context, null),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                await _pickImage(); 
              },
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: screenWidth * 0.3,
                      height: screenWidth * 0.3,
                      color: Colors.grey[200],
                      child: _selectedGuarantorImage != null
                          ? Image.file(
                        File(_selectedGuarantorImage!.path),
                        fit: BoxFit.cover,
                      )
                          : Icon(Icons.person, size: screenWidth * 0.15),
                    ),
                  )
                  ,
                  
                  if (_selectedGuarantorImage != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedGuarantorImage = null; 
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: screenWidth * 0.05,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            TextButton(
              onPressed: _selectDate,
              child: Text(
                _selectedDate == null
                    ? 'জন্মতারিখ নির্বাচন'
                    : 'জন্মতারিখ: ${DateFormat('dd-MM-yyyy').format(_selectedDate!)}',
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'জামিনদারের নাম',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.01,
                  horizontal: screenWidth * 0.04,
                ),
              ),
              onChanged: (value) => _checkIfAnyFieldFilled(),
            ),
            SizedBox(height: screenHeight * 0.01),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              decoration: InputDecoration(
                labelText: 'মোবাইল নাম্বার',
                errorText: _isPhoneValid ? null : '১১ ডিজিটের নাম্বার দিন',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.01,
                  horizontal: screenWidth * 0.04,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _isPhoneValid = value.isEmpty || value.length == 11;
                });
                _checkIfAnyFieldFilled();
              },
            ),
            SizedBox(height: screenHeight * 0.01),
            TextFormField(
              controller: _fatherNameController,
              decoration: InputDecoration(
                labelText: 'পিতার নাম',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.01,
                  horizontal: screenWidth * 0.04,
                ),
              ),
              onChanged: (value) => _checkIfAnyFieldFilled(),
            ),
            SizedBox(height: screenHeight * 0.01),
            TextFormField(
              controller: _motherNameController,
              decoration: InputDecoration(
                labelText: 'মাতার নাম',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.01,
                  horizontal: screenWidth * 0.04,
                ),
              ),
              onChanged: (value) => _checkIfAnyFieldFilled(),
            ),
            SizedBox(height: screenHeight * 0.01),
            TextFormField(
              controller: _presentAddressController,
              decoration: InputDecoration(
                labelText: 'বর্তমান ঠিকানা',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.01,
                  horizontal: screenWidth * 0.04,
                ),
              ),
              onChanged: (value) => _checkIfAnyFieldFilled(),
            ),
            SizedBox(height: screenHeight * 0.01),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'স্থায়ী ঠিকানা',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.01,
                  horizontal: screenWidth * 0.04,
                ),
              ),
              onChanged: (value) => _checkIfAnyFieldFilled(),
            ),
            SizedBox(height: screenHeight * 0.01),
            TextFormField(
              controller: _nidController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'জাতীয় পরিচয়পত্র(NID)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.01,
                  horizontal: screenWidth * 0.04,
                ),
              ),
              onChanged: (value) => _checkIfAnyFieldFilled(),
            ),
          ],
        ),
      ),
      actions: [
        Center(
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: _isPhoneValid && _isAnyFieldFilled
                  ? Colors.green 
                  : Colors.grey.shade300, 
              foregroundColor: Colors.white, 
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), 
              ),
            ),
            onPressed: _isPhoneValid && _isAnyFieldFilled
                ? () {
              Navigator.pop(context, {
                'name': _nameController.text,
                'phone': _phoneController.text,
                'permanentAddress': _addressController.text,
                'presentAddress': _presentAddressController.text,
                'father_name': _fatherNameController.text,
                'mother_name': _motherNameController.text,
                'nid': _nidController.text,
                'dob': _selectedDate?.toIso8601String() ?? 'Not Set',
                'selectedImage': _selectedGuarantorImage?.path ?? '',
              });
            }
                : null,
            child:
            Text('যোগ করুন', style: TextStyle(fontSize: screenWidth * 0.045)),
          ),
        ),
      ],
    );
  }
}
