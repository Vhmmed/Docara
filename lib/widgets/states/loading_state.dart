import 'package:flutter/material.dart';
import '../loading/loading_widgets.dart';

class LoadingState extends StatelessWidget {
  final double? height;

  const LoadingState({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    final child = const Center(child: AppRingSpinner());
    if (height != null) {
      return SizedBox(height: height, child: child);
    }
    return child;
  }
}
