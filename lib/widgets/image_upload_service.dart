import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class FirebasePhotoService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  
  Future<List<String>> uploadPhotos({
    required List<File> photos,
    required String documentPath,
    required String fieldName,
  }) async {
    List<String> photoUrls = [];
    try {
      
      final documentRef = _firestore.doc(documentPath);
      final documentSnapshot = await documentRef.get();
      if (!documentSnapshot.exists) {
        await documentRef.set({fieldName: []});
      }

      
      final uploadTasks = photos.map((photo) async {
        
        Uint8List imageBytes = await photo.readAsBytes();

        
        var result = await FlutterImageCompress.compressWithList(
          imageBytes,
          minWidth: 600, 
          quality: 50, 
        );

        
        if (result.isEmpty) throw Exception("Failed to compress image");

        
        final compressedFile = await _saveToTemporaryFile(result);

        
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        String filePath = '$documentPath/$fileName';
        final ref = _storage.ref(filePath);
        await ref.putFile(compressedFile);

        
        String downloadUrl = await ref.getDownloadURL();

        
        await compressedFile.delete();

        return downloadUrl;
      });

      
      photoUrls = await Future.wait(uploadTasks);

      
      await documentRef.update({
        fieldName: FieldValue.arrayUnion(photoUrls),
      });
    } catch (e) {
      throw Exception("Failed to upload photos: $e");
    }

    return photoUrls;
  }


  Future<File> _saveToTemporaryFile(List<int> bytes) async {
    final tempDir = await Directory.systemTemp.createTemp();
    final tempFile = File('${tempDir.path}/image_${DateTime.now().millisecondsSinceEpoch}.jpg');
    return tempFile.writeAsBytes(bytes);
  }

  
  Future<void> updatePhotos({
    required List<File?> photos,
    required String folder,
    required String documentPath,
    required String fieldName,
  }) async {
    try {
      final List<File> newPhotos = photos.whereType<File>().toList();

      
      final documentSnapshot =
      await FirebaseFirestore.instance.doc(documentPath).get();
      List<String> existingPhotoUrls = [];
      if (documentSnapshot.exists) {
        existingPhotoUrls =
        List<String>.from(documentSnapshot.get(fieldName) ?? []);
      }

      
      for (String photoUrl in existingPhotoUrls) {
        try {
          final ref = FirebaseStorage.instance.refFromURL(photoUrl);
          await ref.delete();
        } catch (e) {
          print("Failed to delete photo: $photoUrl, error: $e");
        }
      }

      
      List<String> uploadedUrls = [];
      for (File photo in newPhotos) {
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final storagePath = "$folder/$fileName.jpg";
        final uploadTask =
        await FirebaseStorage.instance.ref(storagePath).putFile(photo);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        uploadedUrls.add(downloadUrl);
      }

      
      await FirebaseFirestore.instance.doc(documentPath).update({
        fieldName: uploadedUrls,
      });
    } catch (e) {
      throw Exception("Failed to update photos: $e");
    }
  }

  
  Future<void> deletePhoto({
    required String documentPath,
    required String fieldName,
    required String photoUrl,
  }) async {
    try {
      
      await _firestore.doc(documentPath).update({
        fieldName: FieldValue.arrayRemove([photoUrl]),
      });

      
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();
    } catch (e) {
      throw Exception("Failed to delete photo: $e");
    }
  }

  
  Future<List<String>> fetchPhotoUrls({
    required String documentPath,
    required String fieldName,
  }) async {
    try {
      DocumentSnapshot snapshot = await _firestore.doc(documentPath).get();
      if (snapshot.exists) {
        return List<String>.from(snapshot.get(fieldName) ?? []);
      } else {
        throw Exception("Document not found");
      }
    } catch (e) {
      throw Exception("Failed to fetch photo URLs: $e");
    }
  }

  
  Future<List<String>> getImages({
    required String documentPath,
    required String fieldName,
  }) async {
    List<String> photoUrls = await fetchPhotoUrls(
      documentPath: documentPath,
      fieldName: fieldName,
    );
    return photoUrls;
  }

  static Widget getImagePreview({
    required List<dynamic> images, 
    double imageHeight = 100,
    double imageWidth = 100,
    required Function(dynamic image) onRemoveImage, 
  }) {
    if (images.isEmpty)
      return const SizedBox(); 

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var image in images)
          Stack(
            clipBehavior: Clip.none,
            children: [
              
              Container(
                margin: const EdgeInsets.only(right: 10),
                height: imageHeight,
                width: imageWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image:
                    image is File ? FileImage(image) : NetworkImage(image),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              
              Positioned(
                top: -5,
                right: -5,
                child: GestureDetector(
                  onTap: () =>
                      onRemoveImage(image), 
                  child: const Icon(
                    Icons.cancel,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  static Future<File?> pickPhoto(BuildContext context) async {
    final pickedSource = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        var screenWidth = MediaQuery.of(context).size.width;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), 
          ),
          title: Center(
            child: Text(
              'Choose an Option',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          content: SizedBox(
            width: screenWidth * 0.6, 
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop(ImageSource.gallery);
                      },
                      child: Column(
                        children: [
                          Icon(
                            Icons.image,
                            size: screenWidth * 0.15,
                            color: Colors.blue,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Gallery',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                    
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop(ImageSource.camera);
                      },
                      child: Column(
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: screenWidth * 0.15,
                            color: Colors.green,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Camera',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (pickedSource == null) return null; 

    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: pickedSource);

    if (pickedFile != null) {
      return File(pickedFile.path); 
    }
    return null; 
  }

}

