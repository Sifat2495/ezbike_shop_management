import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class GuarantorEdit extends StatefulWidget {
  final Map<String, dynamic> guarantor;
  final String userId;
  final Function(Map<String, dynamic>) onSave;

  GuarantorEdit({required this.guarantor, required this.onSave, required this.userId});

  @override
  _GuarantorEditState createState() => _GuarantorEditState();
}

class _GuarantorEditState extends State<GuarantorEdit> {
  late TextEditingController nameController;
  late TextEditingController fatherNameController;
  late TextEditingController motherNameController;
  late TextEditingController nidController;
  late TextEditingController phoneController;
  late TextEditingController dobController;
  late TextEditingController presentAddressController;
  late TextEditingController permanentAddressController;

  String? selectedImage; 

  @override
  void initState() {
    super.initState();

    String? initialDob = widget.guarantor['dob'];
    DateTime dobDate;

    try {
      dobDate = initialDob != null && initialDob.isNotEmpty
          ? DateTime.parse(initialDob)
          : DateTime.now();
    } catch (e) {
      dobDate = DateTime.now(); 
    }

    dobController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(dobDate),
    );

    nameController = TextEditingController(text: widget.guarantor['name'] ?? '');
    fatherNameController = TextEditingController(text: widget.guarantor['fatherName'] ?? '');
    motherNameController = TextEditingController(text: widget.guarantor['motherName'] ?? '');
    nidController = TextEditingController(text: widget.guarantor['nid'] ?? '');
    phoneController = TextEditingController(text: widget.guarantor['phone'] ?? '');
    presentAddressController = TextEditingController(text: widget.guarantor['presentAddress'] ?? '');
    permanentAddressController = TextEditingController(text: widget.guarantor['permanentAddress'] ?? '');
    selectedImage = widget.guarantor['selectedImage'];
  }

  Future<void> _selectDate() async {
    DateTime initialDate;
    try {
      initialDate = DateTime.tryParse(dobController.text) ?? DateTime.now();
    } catch (e) {
      initialDate = DateTime.now();
    }

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        dobController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 7,
    );

    if (image != null) {
      setState(() {
        selectedImage = image.path; 
      });
    }
  }

  Future<String?> _uploadImageToFirebase(File imageFile, String? oldImageUrl) async {
    String userId = widget.userId;
    Map<String, dynamic> guarantor = widget.guarantor; 

    try {
      FirebaseStorage storage = FirebaseStorage.instance;

      
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        try {
          
          Reference oldRef = storage.refFromURL(oldImageUrl);
          await oldRef.delete();
          print("✅ Old image deleted successfully.");
        } catch (e) {
          print("⚠️ Error deleting old image: $e");
        }
      }

      
      String name = guarantor['name'] ?? 'unknown';
      String phone = guarantor['phone'] ?? 'unknown';

      
      String fileName = "collection name/$userId/collection name/${name}_${phone}_${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference storageRef = storage.ref().child(fileName);

      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("🔥 Error uploading image: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            
            if (selectedImage != null && selectedImage!.isNotEmpty) ...[
              GestureDetector(
                onTap: _pickImage,
                child: selectedImage!.startsWith('http')
                    ? Image.network(
                  selectedImage!,
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                )
                    : Image.file(
                  File(selectedImage!),
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                ),
              ),
              TextButton(
                onPressed: _pickImage,
                child: Text("Change Image"),
              ),
            ] else ...[
              
              GestureDetector(
                onTap: _pickImage,
                child: Icon(
                  Icons.broken_image,
                  size: 80,
                  color: Colors.grey, 
                ),
              ),
              TextButton(
                onPressed: _pickImage,
                child: Text("Choose Image"),
              ),
            ],
            SizedBox(height: 10),

            TextField(
              controller: dobController,
              decoration: InputDecoration(labelText: "জন্মতারিখ"),
              readOnly: true,
              onTap: _selectDate,
            ),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "নাম"),
            ),
            TextField(
              controller: fatherNameController,
              decoration: InputDecoration(labelText: "পিতা"),
            ),
            TextField(
              controller: motherNameController,
              decoration: InputDecoration(labelText: "মাতা"),
            ),
            TextField(
              controller: nidController,
              decoration: InputDecoration(labelText: "NID"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(labelText: "ফোন"),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: presentAddressController,
              decoration: InputDecoration(labelText: "বর্তমান ঠিকানা"),
            ),
            TextField(
              controller: permanentAddressController,
              decoration: InputDecoration(labelText: "স্থায়ী ঠিকানা"),
            ),
            SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('বাতিল'),
                ),
                SizedBox(width: 10), 

                ElevatedButton(
                  onPressed: () async {
                    String? imageUrl = selectedImage;

                    
                    if (selectedImage != null && !selectedImage!.startsWith("http")) {
                      File imageFile = File(selectedImage!);
                      imageUrl = await _uploadImageToFirebase(imageFile, widget.guarantor['selectedImage']);
                    } else {
                      
                      imageUrl = widget.guarantor['selectedImage'];
                    }

                    
                    final Map<String, dynamic> updatedGuarantor = {}; 

                    
                    if (nameController.text != widget.guarantor['name']) {
                      updatedGuarantor['name'] = nameController.text.isEmpty ? null : nameController.text;
                    }
                    if (fatherNameController.text != widget.guarantor['fatherName']) {
                      updatedGuarantor['fatherName'] = fatherNameController.text.isEmpty ? null : fatherNameController.text;
                    }
                    if (motherNameController.text != widget.guarantor['motherName']) {
                      updatedGuarantor['motherName'] = motherNameController.text.isEmpty ? null : motherNameController.text;
                    }
                    if (nidController.text != widget.guarantor['nid']) {
                      updatedGuarantor['nid'] = nidController.text.isEmpty ? null : nidController.text;
                    }
                    if (phoneController.text != widget.guarantor['phone']) {
                      updatedGuarantor['phone'] = phoneController.text.isEmpty ? null : phoneController.text;
                    }
                    if (dobController.text != widget.guarantor['dob']) {
                      updatedGuarantor['dob'] = dobController.text.isEmpty ? null : dobController.text;
                    }
                    if (presentAddressController.text != widget.guarantor['presentAddress']) {
                      updatedGuarantor['presentAddress'] = presentAddressController.text.isEmpty ? null : presentAddressController.text;
                    }
                    if (permanentAddressController.text != widget.guarantor['permanentAddress']) {
                      updatedGuarantor['permanentAddress'] = permanentAddressController.text.isEmpty ? null : permanentAddressController.text;
                    }
                    if (imageUrl != widget.guarantor['selectedImage']) {
                      updatedGuarantor['selectedImage'] = imageUrl;
                    }

                    
                    if (updatedGuarantor.isNotEmpty) {
                      widget.onSave(updatedGuarantor);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('কোনো পরিবর্তন করা হয়নি।')),
                      );
                    }
                  },
                  child: Text("💾 সেভ করুন", style: TextStyle(color: Colors.teal[900])),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
