import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../widgets/image_upload_service.dart';
import '../../../widgets/all_common_functions.dart';
import '../../product/product_model.dart';
import 'firestore_service.dart';
import 'full_image_view.dart';

Future<void> showProductDetailsDialogStock(BuildContext context,
    Product product, String documentId, String currentUserId) async {
  final fetchedProduct = await fetchProductDetails(documentId);

  if (fetchedProduct != null) {
    List<String> photoUrls = List<String>.from(fetchedProduct.photoUrls);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: _buildDialogTitle(fetchedProduct.name),
              content: _buildDialogContent(
                context,
                fetchedProduct,
                documentId,
                currentUserId,
                photoUrls,
                setState,
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          
                          final phone = fetchedProduct.supplierPhone;
                          if (phone != null && phone.isNotEmpty) {
                            launchUrl(Uri.parse('tel:$phone'));
                          } else {
                            showGlobalSnackBar(context,'সাপ্লাইয়ারের ফোন নাম্বার পাওয়া যায়নি।');
                            }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.phone,
                          size: 10,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'সাপ্লায়ার',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'বন্ধ করুন',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

Widget _buildDialogTitle(String title) {
  return Container(
    padding: const EdgeInsets.all(8.0),
    decoration: BoxDecoration(
      color: Colors.teal.withOpacity(0.8),
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2)),
      ],
    ),
    child: Text(
      title,
      textAlign: TextAlign.center,
      style: const TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
    ),
  );
}

Widget _buildDialogContent(
    BuildContext context,
    Product product,
    String documentId,
    String currentUserId,
    List<String> photoUrls,
    void Function(void Function()) setState) {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageGallery(
            context, photoUrls, documentId, currentUserId, setState),
        const SizedBox(height: 16),
        _buildProductDetails(product),
      ],
    ),
  );
}

Widget _buildImageGallery(
    BuildContext context,
    List<String> photoUrls,
    String documentId,
    String currentUserId,
    void Function(void Function()) setState) {
  final String documentPath = 'collection name/$currentUserId/collection name/$documentId';

  assert(currentUserId.isNotEmpty, 'currentUserId is empty');
  assert(documentId.isNotEmpty, 'documentId is empty');
  print('Document Path: $documentPath');

  if (photoUrls.isEmpty) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () async {
            File? selectedImage = await FirebasePhotoService.pickPhoto(context);
            if (selectedImage != null) {
              List<String> newImageUrls =
              await FirebasePhotoService().uploadPhotos(
                photos: [selectedImage],
                documentPath: documentPath,
                fieldName: 'field name',
              );
              setState(() {
                photoUrls.addAll(newImageUrls);
              });
              updateProductImages(documentId, photoUrls);
            }
          },
          child: _buildImagePlaceholder(),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () async {
            File? selectedImage = await FirebasePhotoService.pickPhoto(context);
            if (selectedImage != null) {
              List<String> newImageUrls =
              await FirebasePhotoService().uploadPhotos(
                photos: [selectedImage],
                documentPath: documentPath,
                fieldName: 'field name',
              );
              setState(() {
                photoUrls.addAll(newImageUrls);
              });
              updateProductImages(documentId, photoUrls);
            }
          },
          child: _buildImagePlaceholder(),
        ),
      ],
    );
  } else if (photoUrls.length == 1) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => _showFullImageDialog(
            context,
            photoUrls,
            0,
            documentId,
            currentUserId,
            setState,
          ),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(photoUrls[0]),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () async {
            File? selectedImage = await FirebasePhotoService.pickPhoto(context);
            if (selectedImage != null) {
              List<String> newImageUrls =
              await FirebasePhotoService().uploadPhotos(
                photos: [selectedImage],
                documentPath: documentPath,
                fieldName: 'field name',
              );
              setState(() {
                photoUrls.addAll(newImageUrls);
              });
              updateProductImages(documentId, photoUrls);
            }
          },
          child: _buildImagePlaceholder(),
        ),
      ],
    );
  } else {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: photoUrls.map((url) {
          return GestureDetector(
            onTap: () => _showFullImageDialog(
              context,
              photoUrls,
              photoUrls.indexOf(url),
              documentId,
              currentUserId,
              setState,
            ),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(url),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

Widget _buildImagePlaceholder() {
  return Container(
    margin: const EdgeInsets.only(right: 8),
    height: 100,
    width: 100,
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: BorderRadius.circular(8),
    ),
    child: Center(
      child: Icon(Icons.add_a_photo, size: 40, color: Colors.teal),
    ),
  );
}

Widget _buildProductDetails(Product product) {
  return Column(
    children: [
      _buildDetailRow(
          Icons.qr_code_2_outlined, 'barcode:', '${product.barcode}'),
      _buildDetailRow(Icons.price_change, 'ক্রয় মূল্য:',
          '${convertToBengaliNumbers(product.purchasePrice.toString())}৳'),
      _buildDetailRow(Icons.sell, 'বিক্রয় মূল্য:',
          '${convertToBengaliNumbers(product.salePrice.toString())}৳'),
      _buildDetailRow(Icons.inventory, 'স্টক:',
          convertToBengaliNumbers(product.stock.toString())),
      _buildDetailRow(
          Icons.inventory, 'সাপ্লায়ার:', (product.supplierName.toString())),
      _buildDetailRow(Icons.phone, 'সাপ্লায়ার ফোন:',
          convertToBengaliNumbers(product.supplierPhone.toString())),
      _buildDetailRow(
        Icons.monetization_on,
        'স্টকের মূল্য:',
        '${convertToBengaliNumbers((product.purchasePrice * product.stock).toStringAsFixed(2))}৳',
      ),
    ],
  );
}

Widget _buildDetailRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(icon, color: Colors.teal, size: 20),
          ],
        ),
        const SizedBox(width: 4),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

void _showFullImageDialog(
    BuildContext context,
    List<String> photoUrls,
    int initialIndex,
    String documentId,
    String currentUserId,
    void Function(void Function()) setState) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.grey[800],
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: FullImageView(
            photoUrls: photoUrls,
            initialIndex: initialIndex,
            userId: currentUserId,
            stockId: documentId,
            onImageChange: (index, action, [newImageUrl]) {
              if (action == 'delete') {
                setState(() {
                  photoUrls.removeAt(index);
                });
                updateProductImages(documentId, photoUrls);
              } else if (action == 'update' && newImageUrl != null) {
                setState(() {
                  photoUrls[index] = newImageUrl;
                });
                updateProductImages(documentId, photoUrls);
              }
            },
          ),
        ),
      );
    },
  );
}
