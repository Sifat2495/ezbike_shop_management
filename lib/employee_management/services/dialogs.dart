
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DialogUtil {
  
  static Future<ImageSource?> showImageSourceDialog(
      BuildContext context) async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ছবি সিলেক্ট করুন'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(ImageSource.camera),
              child: Text('ক্যামেরা'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
              child: Text('গ্যালারী'),
            ),
          ],
        );
      },
    );
  }

  
  static void showImageDialog(BuildContext context, String? imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: AspectRatio(
          aspectRatio: 1,
          child: imageUrl != null && imageUrl.isNotEmpty
              ? Image.network(imageUrl, fit: BoxFit.cover)
              : Image.asset('assets/placeholder.png', fit: BoxFit.cover),
        ),
      ),
    );
  }
}
