import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/onboarding_model.dart';

class OnboardingData {
  static List<OnboardingModel> getData() {
    return [
      OnboardingModel(
        title: 'Book Doctors Easily',
        description: 'Find and schedule appointments with verified healthcare professionals in seconds.',
        svgWidget:SvgPicture.asset('assets/images/calendar-02.svg',color: Colors.white,),
      ),
      OnboardingModel(
        title: 'Secure Video Consultations',
        description: 'Connect with doctors from anywhere through secure, high-quality video calls.',
        svgWidget: SvgPicture.asset('assets/images/video-01.svg',color: Colors.white,),
      ),
      OnboardingModel(
        title: 'Access Medical Records',
        description: 'Keep all your health records, prescriptions, and lab results in one safe place.',
        svgWidget: SvgPicture.asset('assets/images/document-validation.svg',color: Colors.white,),
      ),
    ];
  }
}