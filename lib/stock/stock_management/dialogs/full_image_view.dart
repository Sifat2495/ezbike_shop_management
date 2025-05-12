import 'package:flutter/material.dart';
import 'dart:io';
import '../../../widgets/all_common_functions.dart';
import '../../../widgets/image_upload_service.dart';

class FullImageView extends StatefulWidget {
  final List<String> photoUrls;
  final int initialIndex;
  final Function(int index, String action, [String? newImageUrl]) onImageChange;
  final String userId;
  final String stockId;

  const FullImageView({
    required this.photoUrls,
    required this.initialIndex,
    required this.onImageChange,
    required this.userId,
    required this.stockId,
    Key? key,
  }) : super(key: key);

  @override
  State<FullImageView> createState() => _FullImageViewState();
}

class _FullImageViewState extends State<FullImageView> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.photoUrls.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final imageUrl = widget.photoUrls[index];
            return InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  );
                },
              ),
            );
          },
        ),
        Positioned(
          top: 10,
          right: 20,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.zero,
              backgroundColor: Colors.white,
              elevation: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Icon(Icons.close, color: Colors.red, size: 30),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              '${_currentIndex + 1} / ${widget.photoUrls.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          right: 20,
          child: SizedBox(
            width: 40,
            height: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.zero,
                backgroundColor: Colors.white,
                elevation: 10,
              ),
              onPressed: () => _deleteImage(context),
              child:
              const Icon(Icons.delete_forever, color: Colors.red, size: 30),
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          right: 70,
          child: SizedBox(
            width: 40,
            height: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.zero,
                backgroundColor: Colors.white,
                elevation: 10,
              ),
              onPressed: () => _replaceImage(context),
              child: const Icon(Icons.update, color: Colors.blue, size: 30),
            ),
          ),
        ),
      ],
    );
  }

  void _deleteImage(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: const Text("Are you sure you want to delete this image?"),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                final String photoUrl = widget.photoUrls[_currentIndex];
                try {
                  await FirebasePhotoService().deletePhoto(
                    documentPath:
                    'collection name/${widget.userId}/collection name/${widget.stockId}',
                    fieldName: 'field name',
                    photoUrl: photoUrl,
                  );
                  widget.onImageChange(
                      _currentIndex, 'delete');
                } catch (e) {
                  showGlobalSnackBar(context,'Failed to delete image: $e');
                  }
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void _replaceImage(BuildContext context) async {
    final File? newImageFile = await FirebasePhotoService.pickPhoto(context);
    if (newImageFile == null) return;

    final String oldPhotoUrl = widget.photoUrls[_currentIndex];
    try {
       await FirebasePhotoService().deletePhoto(
        documentPath: 'collection name/${widget.userId}/collection name/${widget.stockId}',
        fieldName: 'field name',
        photoUrl: oldPhotoUrl,
      );

      final List<String> uploadedUrls =
      await FirebasePhotoService().uploadPhotos(
        photos: [newImageFile],
        documentPath: 'collection name/${widget.userId}/collection name/${widget.stockId}',
        fieldName: 'field name',
      );

      if (uploadedUrls.isNotEmpty) {
        widget.onImageChange(_currentIndex, 'update', uploadedUrls.first);
        Navigator.of(context).pop();
      }
    } catch (e) {
      showGlobalSnackBar(context,'Failed to replace image: $e');
      }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
