import 'package:flutter/material.dart';

class CustomText extends StatelessWidget {
  const CustomText({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.weight,
    this.maxLines,
    this.overflow,
    this.align, this.family,
  });

  final String text;
  final Color? color;
  final double? size;
  final FontWeight? weight;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? align;
  final String? family;


  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines ?? 2,
      overflow: overflow ?? TextOverflow.ellipsis,
      textAlign: align,
      textScaler: TextScaler.linear(1.0),
      style: TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color,
        fontFamily: family,
      ),
    );
  }
}
