import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../controllers/add_guarantor_popup.dart';
import '../controllers/confirmation_popup.dart';
import '../controllers/phone_validation_controller.dart';
import 'sale_product_selection.dart';
import '../../widgets/all_common_functions.dart';

class SaleStockPage extends StatefulWidget {
  const SaleStockPage({super.key});

  @override
  _SaleStockPageState createState() => _SaleStockPageState();
}

class _SaleStockPageState extends State<SaleStockPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _motherNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  List<TextEditingController> _phoneControllers = [TextEditingController()];
  final TextEditingController _presentAddressController = TextEditingController();
  final TextEditingController _permanentAddressController = TextEditingController();
  final TextEditingController _nidController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _batteryController = TextEditingController();
  List<TextEditingController> _chassisControllers = [TextEditingController()];
  final _formKey = GlobalKey<FormState>();
  bool _isPhoneValid = true;
  final bool _isCustomerSelected = false; 
  XFile? _selectedCustomerImage;
  final List<Map<String, String>> _guarantorNames =
      []; 
  final List<Map<String, dynamic>> _selectedProducts = []; 
  DateTime _selectedDate = DateTime.now();
  DateTime _birthDate = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _licenseController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _phoneController.dispose();
    _presentAddressController.dispose();
    _permanentAddressController.dispose();
    _nidController.dispose();
    _colorController.dispose();
    _batteryController.dispose();
    for (var controller in _chassisControllers) {
      controller.dispose();
    }
    for (var controller in _phoneControllers) {
      controller.dispose();
    }
    _birthDate = DateTime.now();
    _selectedDate = DateTime.now();
    _selectedProducts.clear();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _addChassisField() {
    setState(() {
      _chassisControllers.add(TextEditingController());
    });
  }

  void _removeChassisField(int index) {
    setState(() {
      _chassisControllers[index].dispose(); 
      _chassisControllers.removeAt(index); 
    });
  }

  void _addPhoneField() {
    setState(() {
      _phoneControllers.add(TextEditingController());
    });
  }

  void _removePhoneField(int index) {
    setState(() {
      _phoneControllers[index].dispose(); 
      _phoneControllers.removeAt(index); 
    });
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
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
        _selectedCustomerImage = image;
      });
    }
  }

  
  Future<void> _addGuarantor() async {
    final result = await showDialog(
      context: context,
      builder: (context) => AddGuarantorPopup(),
    );

    
    if (result != null) {
      setState(() {
        _guarantorNames.add({
          'name': result['name'] ?? '',
          'phone': result['phone'] ?? '',
          'permanentAddress': result['permanentAddress'] ?? '',
          'presentAddress': result['presentAddress'] ?? '',
          'fatherName': result['father_name'] ?? '',
          'motherName': result['mother_name'] ?? '',
          'nid': result['nid'] ?? '',
          'dob': result['dob'] ?? 'Not Set',
          'selectedImage': result['selectedImage'] ?? '', 
        });
      });
    }
  }

  
  Future<void> _editGuarantor(int index) async {
    final result = await showDialog(
      context: context,
      builder: (context) => AddGuarantorPopup(
        initialData: _guarantorNames[index],
      ),
    );
    if (result != null) {
      setState(() {
        _guarantorNames[index] = result;
      });
    }
  }

  
  void _removeGuarantor(int index) {
    setState(() {
      _guarantorNames.removeAt(index);
    });
  }

  
  Future<void> _editProduct(int index) async {
    final result = await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13), 
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
              13), 
          child: SizedBox(
            width:
                MediaQuery.of(context).size.width * 0.8, 
            height: MediaQuery.of(context).size.height *
                0.8, 
            child: ProductSelectionPage(),
          ),
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedProducts[index] = result;
      });
    }
  }

  
  void _removeProduct(int index) {
    setState(() {
      _selectedProducts.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final DateFormat dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('পণ্য বিক্রয়'),
        backgroundColor: Colors.green,
        centerTitle: true,
        titleTextStyle: TextStyle(fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 20.0, 
        ),
      ),

      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.03,
            vertical: screenHeight * 0.01,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _selectedCustomerImage == null
                      ? ElevatedButton(
              onPressed: _pickImage,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.01,
                              horizontal: screenWidth * 0.05,
                            ),
                            shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), 
                            ),
                          ),
                          child: Text(
                            'ছবি নির্বাচন',
                            style: TextStyle(fontSize: screenWidth * 0.045),
                          ),
                        )
                      : Stack(
                          children: [
                            Container(
                              margin: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.01),
                              height: screenHeight * 0.2,
                              width: screenWidth * 0.4,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Image.file(
                                File(_selectedCustomerImage!.path),
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 5,
                              right: 5,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCustomerImage = null;
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
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "জন্মতারিখ",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _selectBirthDate(context),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dateFormat.format(_birthDate),
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.black),
                                    ),
                                    Icon(Icons.calendar_month,
                                        color: Colors.black54),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "লেন্দেনের তারিখ",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _selectDate(context),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dateFormat.format(_selectedDate),
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.black),
                                    ),
                                    Icon(Icons.calendar_today,
                                        color: Colors.black54),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'নাম',
                      labelStyle: TextStyle(fontSize: screenWidth * 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      isDense: true, 
                      contentPadding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.011,
                        horizontal: screenWidth * 0.04,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  TextFormField(
                    controller: _fatherNameController,
                    decoration: InputDecoration(
                      labelText: 'পিতার নাম',
                      labelStyle: TextStyle(fontSize: screenWidth * 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      isDense: true, 
                      contentPadding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.011,
                        horizontal: screenWidth * 0.04,
                      ), 
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  TextFormField(
                    controller: _motherNameController,
                    decoration: InputDecoration(
                      labelText: 'মাতার নাম',
                      labelStyle: TextStyle(fontSize: screenWidth * 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      isDense: true, 
                      contentPadding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.011,
                        horizontal: screenWidth * 0.04,
                      ), 
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'ফোন',
                      labelStyle: TextStyle(fontSize: screenWidth * 0.04),
                      errorText: _isPhoneValid
                          ? null
                          : 'এই নম্বরের কাস্টমার যুক্ত করা আছে।',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      isDense: true, 
                      contentPadding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.011,
                        horizontal: screenWidth * 0.04,
                      ),
                      suffix: Text(
                        '${_phoneController.text.length}/11',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    maxLength: 11,
                    buildCounter: (context,
                        {required currentLength,
                          required isFocused,
                          maxLength}) =>
                    null,
                    onChanged: (value) {
                      if (!_isCustomerSelected && value.length == 11) {
                        PhoneValidationController()
                            .validatePhoneAfter11Digits(value, (isValid) {
                          setState(() {
                            _isPhoneValid = isValid;
                          });
                        });
                      } else {
                        setState(() {
                          _isPhoneValid = true;
                        });
                      }
                    },
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Column(
                    children: _phoneControllers.asMap().entries.map((entry) {
                      int index = entry.key;
                      TextEditingController controller = entry.value;
                      return Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controller,
                              decoration: InputDecoration(
                                labelText: 'ফোন নাম্বার',
                                labelStyle:
                                TextStyle(fontSize: screenWidth * 0.04),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                isDense: true, 
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.011,
                                  horizontal: screenWidth * 0.04,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              index == 0
                                  ? Icons.add
                                  : Icons
                                  .delete_forever, 
                            ),
                            onPressed: () {
                              if (index == 0) {
                                _addPhoneField(); 
                              } else {
                                _removePhoneField(
                                    index); 
                              }
                            },
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  TextFormField(
                    controller: _presentAddressController,
                    decoration: InputDecoration(
                      labelText: 'বর্তমান ঠিকানা',
                      labelStyle: TextStyle(fontSize: screenWidth * 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      isDense: true, 
                      contentPadding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.011,
                        horizontal: screenWidth * 0.04,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  TextFormField(
                    controller: _permanentAddressController,
                    decoration: InputDecoration(
                      labelText: 'স্থায়ী ঠিকানা',
                      labelStyle: TextStyle(fontSize: screenWidth * 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      isDense: true, 
                      contentPadding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.011,
                        horizontal: screenWidth * 0.04,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  TextFormField(
                    controller: _licenseController,
                    decoration: InputDecoration(
                      labelText: 'লাইসেন্স',
                      labelStyle: TextStyle(fontSize: screenWidth * 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      isDense: true, 
                      contentPadding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.011,
                        horizontal: screenWidth * 0.04,
                      ), 
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  TextFormField(
                    controller: _nidController,
                    decoration: InputDecoration(
                      labelText: 'জাতীয় পরিচয়পত্র(NID)',
                      labelStyle: TextStyle(fontSize: screenWidth * 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      isDense: true, 
                      contentPadding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.011,
                        horizontal: screenWidth * 0.04,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Column(
                    children: _chassisControllers.asMap().entries.map((entry) {
                      int index = entry.key;
                      TextEditingController controller = entry.value;
                      return Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controller,
                              decoration: InputDecoration(
                                labelText: 'অটোর চেসিস নম্বর(যদি থাকে)',
                                labelStyle:
                                TextStyle(fontSize: screenWidth * 0.04),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                isDense: true, 
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.011,
                                  horizontal: screenWidth * 0.04,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              index == 0
                                  ? Icons.add
                                  : Icons
                                  .delete_forever, 
                            ),
                            onPressed: () {
                              if (index == 0) {
                                _addChassisField(); 
                              } else {
                                _removeChassisField(
                                    index); 
                              }
                            },
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  TextFormField(
                    controller: _colorController,
                    decoration: InputDecoration(
                      labelText: 'গাড়ির রং',
                      labelStyle: TextStyle(fontSize: screenWidth * 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      isDense: true, 
                      contentPadding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.011,
                        horizontal: screenWidth * 0.04,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  TextFormField(
                    controller: _batteryController,
                    decoration: InputDecoration(
                      labelText: 'ব্যাটারি মডেল',
                      labelStyle: TextStyle(fontSize: screenWidth * 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      isDense: true, 
                      contentPadding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.011,
                        horizontal: screenWidth * 0.04,
                      ),
                    ),
                  ),
                  if (_guarantorNames
                      .isNotEmpty) 
                    Column(
                      children: _guarantorNames.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, String> guarantor =
                            entry.value; 
                        
                        String imageUrl = guarantor['selectedImage'] ??
                            ''; 

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            
                            imageUrl.isNotEmpty
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(imageUrl),
                                width: screenWidth *
                                    0.1, 
                                height: screenWidth * 0.1,
                                fit: BoxFit.cover,
                              ),
                            )
                                : Icon(
                              Icons
                                  .person, 
                              size: screenWidth * 0.1,
                            ),

                            
                            Expanded(
                              child: Text(
                                'জামিনদার ${index + 1}: ${guarantor['name']}',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () => _editGuarantor(index),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => _removeGuarantor(index),
                                ),
                              ],
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  Divider(
                    thickness: 2.0, 
                    color: Colors.grey, 
                  ),
                  if (_selectedProducts
                      .isNotEmpty) 
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.0001,
                        horizontal: screenWidth * 0.04,
                      ),
                      child: Text(
                        'প্রোডাক্ট',
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                          decoration:
                          TextDecoration.underline, 
                        ),
                      ),
                    ),
                  Column(
                    children: _selectedProducts.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, dynamic> product = entry.value;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${index + 1}. ${product['name']} - মূল্য: ৳${convertToBengaliNumbers(double.parse(product['sale_price'].toString()).toStringAsFixed(0))}',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.refresh),
                                onPressed: () => _editProduct(index),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _removeProduct(index),
                              ),
                            ],
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: screenWidth *
                            0.4, 
                        child: ElevatedButton.icon(
                          onPressed:
                          _guarantorNames.length < 3 ? _addGuarantor : null,
                          icon:
                          Icon(Icons.person_add, size: screenWidth * 0.05),
                          label: Text(
                            'জামিনদার',
                            style: TextStyle(fontSize: screenWidth * 0.04),
                          ),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  8), 
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: screenWidth *
                            0.4, 
                        child: ElevatedButton.icon(
                          onPressed: _selectedProducts.length < 10
                              ? () async {
                            final result = await showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      13), 
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      13), 
                                  child: SizedBox(
                                    width: screenWidth *
                                        0.8, 
                                    height: screenHeight *
                                        0.8, 
                                    child: ProductSelectionPage(),
                                  ),
                                ),
                              ),
                            );
                            if (result != null) {
                              setState(() {
                                _selectedProducts
                                    .add(result); 
                              });
                            }
                          }
                              : null,
                          icon: Icon(Icons.battery_charging_full,
                              size: screenWidth * 0.05),
                          label: Text(
                            'প্রোডাক্ট',
                            style: TextStyle(fontSize: screenWidth * 0.04),
                          ),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  8), 
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  ElevatedButton(
                    onPressed: (_phoneController.text.length == 11 &&
                        _selectedProducts.isNotEmpty)
                        ? () async {
                      
                      Map<String, int> aggregatedProducts = {};
                      for (var product in _selectedProducts) {
                        String productName = product['name'];
                        if (aggregatedProducts.containsKey(productName)) {
                          aggregatedProducts[productName] =
                              aggregatedProducts[productName]! + 1;
                        } else {
                          aggregatedProducts[productName] = 1;
                        }
                      }

                      
                      List<Map<String, dynamic>> aggregatedProductList =
                      aggregatedProducts.entries.map((entry) {
                        String productName = entry.key;
                        int quantity = entry.value;
                        double salePrice = _selectedProducts.firstWhere(
                                (product) =>
                            product['name'] ==
                                productName)['sale_price'];
                        double purchasePrice =
                        _selectedProducts.firstWhere((product) =>
                        product['name'] ==
                            productName)['purchase_price'];
                        var stockValue = _selectedProducts.firstWhere(
                                (product) =>
                            product['name'] == productName)['collection name'];
                        double stock = stockValue is int
                            ? stockValue.toDouble()
                            : stockValue;
                        return {
                          'name': productName,
                          'quantity': quantity,
                          'sale_price': salePrice,
                          'purchase_price': purchasePrice,
                          'collection name': stock,
                        };
                      }).toList();

                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConfirmationPopup(
                            name: _nameController.text,
                            license: _licenseController.text,
                            fatherName: _fatherNameController.text,
                            motherName: _motherNameController.text,
                            phone: _phoneController.text,
                            presentAddress: _presentAddressController.text,
                            permanentAddress: _permanentAddressController.text,
                            nid: _nidController.text,
                            color: _colorController.text,
                            battery: _batteryController.text,
                            chassis: _chassisControllers
                                .map((controller) => controller.text)
                                .toList(),
                            phones: _phoneControllers
                                .map((controller) => controller.text)
                                .toList(),
                            guarantors: _guarantorNames,
                            products: aggregatedProductList,
                            imagePath: _selectedCustomerImage?.path ?? '',
                            birthDate: _birthDate,
                            time: _selectedDate,
                          ),
                        ),
                      );

                      if (result == 'sale_completed') {
                        
                        setState(() {
                          _nameController.clear();
                          _licenseController.clear();
                          _birthDate = DateTime.now();
                          _selectedDate = DateTime.now();
                          _fatherNameController.clear();
                          _motherNameController.clear();
                          _phoneController.clear();
                          _presentAddressController.clear();
                          _permanentAddressController.clear();
                          _nidController.clear();
                          _colorController.clear();
                          _batteryController.clear();
                          _chassisControllers = [TextEditingController()];
                          _phoneControllers = [TextEditingController()];
                          _guarantorNames.clear();
                          _selectedProducts.clear();
                          _selectedCustomerImage = null;
                        });
                      }
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_isPhoneValid &&
                          _phoneController.text.length == 11 &&
                          _selectedProducts.isNotEmpty)
                          ? Colors.green
                          : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.01,
                        horizontal: screenWidth * 0.1,
                      ),
                    ),
                    child: Text(
                      'বিক্রি প্রক্রিয়া',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
