import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProfileImagePicker extends StatelessWidget {
  final String? imagePath;
  final String? imageUrl;
  final VoidCallback onTap;
  final double radius;

  const ProfileImagePicker({
    super.key,
    required this.imagePath,
    this.imageUrl,
    required this.onTap,
    this.radius = 60,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? provider;
    if (imagePath != null) {
      provider = FileImage(File(imagePath!));
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      provider = NetworkImage(imageUrl!);
    }

    final bool hasImage = provider != null;
    final double iconSize = radius * 0.67;
    final double overlaySize = radius * 0.45;

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: const Color(0xff8FBAC7).withOpacity(0.1),
            backgroundImage: provider,
            child: hasImage
                ? null
                : Icon(
                    CupertinoIcons.camera,
                    size: iconSize,
                    color: Color(0xff8FBAC7),
                  ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: EdgeInsets.all(overlaySize * 0.3),
                decoration: BoxDecoration(
                  color: const Color(0xff8FBAC7),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  CupertinoIcons.camera,
                  size: overlaySize * 0.6,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
