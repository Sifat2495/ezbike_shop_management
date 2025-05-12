import 'dart:io';
import 'package:bebshar_poristhiti_stock/widgets/all_common_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import '../models/employee_model.dart';
import '../services/dialogs.dart';
import '../services/employee_service.dart';
import 'package:flutter/services.dart'; 


Future<String?> getCurrentUserId() async {
  return FirebaseAuth.instance.currentUser?.uid;
}

class EmployeeDetailScreen extends StatefulWidget {
  final Employee employee;

  EmployeeDetailScreen({Key? key, required this.employee}) : super(key: key);

  @override
  _EmployeeDetailScreenState createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final EmployeeService _employeeService =
  EmployeeService(); 

  bool _isLoading = false; 

  
  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      final Uri url = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'Could not launch $url';
      }
    } else {
      showGlobalSnackBar(context,'মোবাইল নাম্বার যোগ করা নেই');
    }
  }

  Future<void> _updateImage(BuildContext context) async {
    final ImageSource? source = await DialogUtil.showImageSourceDialog(context);

    if (source != null) {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 10, 
      );

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);

        try {
          
          Uint8List? compressedImageBytes = await FlutterImageCompress.compressWithFile(
            imageFile.path,
            minWidth: 800, 
            minHeight: 800, 
            quality: 50, 
          );

          
          if (compressedImageBytes != null && compressedImageBytes.isNotEmpty) {
            
            File compressedImageFile = File('${imageFile.parent.path}/compressed_${imageFile.uri.pathSegments.last}');
            await compressedImageFile.writeAsBytes(compressedImageBytes);

            
            if (widget.employee.imageUrl != null && widget.employee.imageUrl!.isNotEmpty) {
              String oldImageUrl = widget.employee.imageUrl!;
              Reference oldImageRef = _storage.refFromURL(oldImageUrl);
              await oldImageRef.delete();
            }

            
            String fileName = path.basename(compressedImageFile.path);
            Reference storageReference = _storage.ref().child('collection name/${_employeeService.userId}/employee_images/$fileName');
            UploadTask uploadTask = storageReference.putFile(compressedImageFile);
            TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});

            
            String newImageUrl = await taskSnapshot.ref.getDownloadURL();
            await _employeeService.updateEmployeeImageUrl(
              widget.employee.id,
              newImageUrl,
            );

            
            setState(() {
              widget.employee.imageUrl = newImageUrl;
            });
          }
        } catch (e) {
          showGlobalSnackBar(context,'ছবি আপলোড করতে সমস্যা হয়েছে: $e');
        }
      }
    }
  }

  
  Future<void> _editEmployeeDetails() async {
    if (_isLoading) return; 

    setState(() {
      _isLoading = true; 
    });

    try {
      
      await _employeeService.updateEmployee(widget.employee);

      
      showGlobalSnackBar(context,'তথ্য সফলভাবে আপডেট হয়েছে');
      } catch (e) {
      
      showGlobalSnackBar(context,'তথ্য আপডেট করতে সমস্যা হয়েছে: $e');
      } finally {
      setState(() {
        _isLoading = false; 
      });
    }
  }

  
  Future<void> _showEditDialog() async {
    TextEditingController nameController =
    TextEditingController(text: widget.employee.name);
    TextEditingController phoneController =
    TextEditingController(text: widget.employee.phoneNumber);
    TextEditingController addressController =
    TextEditingController(text: widget.employee.address);
    TextEditingController nidController =
    TextEditingController(text: widget.employee.nid);
    TextEditingController positionController =
    TextEditingController(text: widget.employee.position);
    TextEditingController emergencyContactController =
    TextEditingController(text: widget.employee.emergencyContact);
    TextEditingController salaryController =
    TextEditingController(text: widget.employee.salary?.toString() ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("কর্মচারীর তথ্য আপডেট করুন"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: "নাম"),
                ),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.number, 
                  decoration: InputDecoration(labelText: "মোবাইল নাম্বার"),
                  inputFormatters: [
                    FilteringTextInputFormatter
                        .digitsOnly, 
                    LengthLimitingTextInputFormatter(
                        11), 
                  ],
                ),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(labelText: "ঠিকানা"),
                ),
                TextField(
                  controller: nidController,
                  keyboardType: TextInputType.number,
                  decoration:
                  InputDecoration(labelText: "জাতীয় পরিচয়পত্রের নাম্বার"),
                ),
                TextField(
                  controller: positionController,
                  decoration: InputDecoration(labelText: "পদবী"),
                ),
                TextField(
                  controller: emergencyContactController,
                  keyboardType: TextInputType.number,
                  decoration:
                  InputDecoration(labelText: "জরুরী যোগাযোগ নাম্বার"),
                ),
                TextField(
                  controller: salaryController,
                  keyboardType: TextInputType.number, 
                  decoration: InputDecoration(labelText: "বেতন"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
              },
              child: Text("বাদ দিন"),
            ),
            TextButton(
              onPressed: () {
                double? updatedSalary = double.tryParse(salaryController.text);

                
                if (updatedSalary == null) {
                  showGlobalSnackBar(context,'বেতনের সঠিক পরিমাণ দিন');
                  return;
                }

                
                setState(() {
                  widget.employee.name = nameController.text;
                  widget.employee.phoneNumber = phoneController.text;
                  widget.employee.address = addressController.text;
                  widget.employee.nid = nidController.text;
                  widget.employee.position = positionController.text;
                  widget.employee.emergencyContact =
                      emergencyContactController.text;
                  widget.employee.salary =
                      updatedSalary; 
                });

                _editEmployeeDetails();
                Navigator.of(context).pop(); 
              },
              child: Text("সেভ করুন"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('কর্মচারীর তথ্য'),
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => DialogUtil.showImageDialog(
                        context, widget.employee.imageUrl),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: widget.employee.imageUrl != null &&
                          widget.employee.imageUrl!.isNotEmpty
                          ? NetworkImage(widget.employee.imageUrl!)
                          : AssetImage('assets/placeholder.png')
                      as ImageProvider,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: () => _updateImage(context),
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.grey[300],
                        child: Icon(Icons.edit, size: 15, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text('নাম: ${widget.employee.name}',
                style: TextStyle(fontSize: 18)),
            Row(
              children: [
                Text('মোবাইল নাম্বার: ${widget.employee.phoneNumber}',
                    style: TextStyle(fontSize: 18)),
                IconButton(
                  icon: Icon(Icons.phone, color: Colors.blue),
                  onPressed: () => _makePhoneCall(widget.employee.phoneNumber),
                ),
              ],
            ),
            Row(
              children: [
                Text('জরুরী যোগাযোগ: ${widget.employee.emergencyContact}',
                    style: TextStyle(fontSize: 18)),
                IconButton(
                  icon: Icon(Icons.phone, color: Colors.red),
                  onPressed: () =>
                      _makePhoneCall(widget.employee.emergencyContact),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text('জাতীয় পরিচয়পত্র: ${widget.employee.nid}',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Text(
              'ঠিকানা: ${widget.employee.address}',
              style: TextStyle(fontSize: 18),
              maxLines: 3, 
              overflow:
              TextOverflow.ellipsis, 
            ),
            SizedBox(height: 20),
            Text('পদবী: ${widget.employee.position}',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Text(
              'বেতন: ${widget.employee.salary != null ? convertToBengaliNumbers(widget.employee.salary.toString()) : ''}',
              style: TextStyle(fontSize: 18),
            ),

            
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showEditDialog, 
              child: Text('তথ্য আপডেট করুন'),
            ),
          ],
        ),
      ),
    );
  }
}
