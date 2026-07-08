import 'package:flutter/material.dart';

class OnboardingModel {
  final String title;
  final String description;
  final Widget svgWidget;
  final Color ?color;

  OnboardingModel({
    required this.title,
    required this.description,
    this.color,
    required this.svgWidget,
  });
}