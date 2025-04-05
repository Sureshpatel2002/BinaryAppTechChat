import 'dart:io';
import 'package:flutter/material.dart';

class ImagePreviewScreen extends StatelessWidget {
  final File imageFile;
  final VoidCallback onSend;

  const ImagePreviewScreen({
    super.key,
    required this.imageFile,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Image'),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: onSend,
          )
        ],
      ),
      body: Center(
        child: Image.file(imageFile),
      ),
    );
  }
}
