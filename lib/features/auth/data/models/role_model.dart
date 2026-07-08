import 'package:flutter/material.dart';

class RoleModel {
  final String id;
  final String title;
  final String iconPath;
  final Color? color;

  RoleModel({
    required this.id,
    required this.title,
    required this.iconPath,
    this.color,
  });

  static List<RoleModel> getRoles() {
    return [
      RoleModel(
          id: 'admin',
          title: 'Access the platform control panel',
          iconPath: 'assets/images/security.svg',
          color: Color(0xff8FBAC7)),
      RoleModel(
          id: 'doctor',
          title: 'Sign in to continue your care',
          iconPath: 'assets/images/stethoscope.svg',
          color: Color(0xff8FBAC7)),
      RoleModel(
          id: 'patient',
          title: 'Sign in to continue your care',
          iconPath: 'assets/images/user.svg',
          color: Color(0xff8FBAC7)),
    ];
  }

  static RoleModel getRoleById(String id) {
    return getRoles().firstWhere(
      (role) => role.id.toLowerCase() == id.toLowerCase(),
      orElse: () => getRoles()[0],
    );
  }
}
