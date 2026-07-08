import 'package:flutter/material.dart';
import '../../core/constants/app_color.dart';
import '../../widgets/loading/loading_widgets.dart';
import 'custom_text.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.text,
    this.onTap,
    this.width,
    this.color,
    this.margin, this.height,
    this.isLoading = false,
  });
  final String text;
  final Function()? onTap;
  final double? width;
  final double? height;
  final Color? color;
  final EdgeInsets? margin;
  final bool isLoading;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: height ??  60,
        width: width,
        decoration: BoxDecoration(
          color: color ?? AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: isLoading
              ? const AppPulseDot(size: 20, color: Colors.white)
              : CustomText(
                  text: text,
                  color: Colors.white ,
                  size: 16,
                  weight: FontWeight.w700,
                ),
        ),
      ),
    );
  }
}
