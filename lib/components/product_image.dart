import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'snackbar.dart';

class ProductImage extends StatefulWidget {
  final Function(String? imagePath) onFileChanged;
  final String? imageUrl;
  final Function(bool isLoading) onLoadingChanged;

  const ProductImage({
    required this.onFileChanged,
    this.imageUrl,
    required this.onLoadingChanged,
    super.key,
  });

  @override
  State<ProductImage> createState() => _ProductImageState();
}

class _ProductImageState extends State<ProductImage> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 2),
          ),
          child: widget.imageUrl == null || widget.imageUrl!.isEmpty
              ? const Icon(
                  Icons.sell,
                  color: Colors.black54,
                  size: 50,
                )
              : ClipOval(
                  child: widget.imageUrl!.startsWith('http')
                      ? Image.network(
                          widget.imageUrl!,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.camera_alt,
                              color: Colors.grey,
                              size: 50,
                            );
                          },
                        )
                      : Image.file(
                          File(widget.imageUrl!),
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.camera_alt,
                              color: Colors.grey,
                              size: 50,
                            );
                          },
                        ),
                ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: InkWell(
            onTap: selectPhoto,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: const Icon(
                Icons.add_a_photo,
                size: 25,
                color: Colors.black54,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> selectPhoto() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => BottomSheet(
        builder: (context) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
        onClosing: () {},
      ),
    );
  }

  Future<void> pickImage(ImageSource source) async {
    widget.onLoadingChanged(true);
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) {
        widget.onLoadingChanged(false);
        return;
      }

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      );

      if (croppedFile == null) {
        widget.onLoadingChanged(false);
        return;
      }

      widget.onFileChanged(croppedFile.path);
    } catch (e) {
      if (!mounted) return;
      errorSnackbar(context, "Failed to select image. Please try again.");
    } finally {
      widget.onLoadingChanged(false);
    }
  }
}
