import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_color.dart';

class CustomTextFormField extends StatefulWidget {
  const CustomTextFormField({
    super.key,
    required this.hint,
    required this.isPassword,
    required this.controller,
    this.color,
    this.textColor,
    this.borderColor,
    this.errorColor,
    this.textErrorColor,
    this.prefixIcon,
    this.hintStyle,
    this.borderRadius,
    this.onTap, this.suffixIcon,  this.readOnly, this.keyboardType,
    this.validator,
    this.maxLines,
  });

  final String hint;
  final bool isPassword;
  final bool? readOnly;
  final TextEditingController controller;
  final Color? color;
  final Color? textColor;
  final Color? borderColor;
  final Color? errorColor;
  final Color? textErrorColor;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextStyle? hintStyle;
  final double? borderRadius;
  final Function()? onTap;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final int? maxLines;


  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late bool _obscureTest;
  late bool isOpen = false;

  @override
  void initState() {
    _obscureTest = widget.isPassword;
    super.initState();
  }

  void _togglePasswordView() {
    setState(() {
      _obscureTest = !_obscureTest;
      isOpen = !isOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      cursorColor: AppColors.primary,
      readOnly: widget.readOnly ?? false,
      onTap: widget.onTap,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines ?? 1,
      validator: widget.validator ?? (v) {
        if (v == null || v.isEmpty) {
          return '${widget.hint} is required';
        }
        return null;
      },
      obscureText: _obscureTest,
      decoration: InputDecoration(
        errorStyle: TextStyle(
          color: widget.textErrorColor ?? Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: widget.errorColor ?? Colors.red.withOpacity(0.8),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 15),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red.withOpacity(0.8), width: 2),
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 15),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 15),
          borderSide: BorderSide(
            color: widget.borderColor ?? Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 15),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        hintText: widget.hint,
        hintStyle: widget.hintStyle ?? TextStyle(
          color: widget.textColor ?? Colors.grey[400],
          fontSize: 14,
          
        ),
        fillColor: widget.color ?? Colors.grey.shade100,
        filled: true,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.isPassword
            ? GestureDetector(
          onTap: () => _togglePasswordView(),
          child: Icon(
            isOpen ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
            color: AppColors.primary,
          ),
        )
            : widget.suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}