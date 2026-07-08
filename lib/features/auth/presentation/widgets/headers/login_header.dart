import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:medical_booking_app/features/auth/data/models/role_model.dart';

class LoginHeader extends StatelessWidget {
  final RoleModel role;
  const LoginHeader({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          role.iconPath,
          width: 45,
          height: 45,
        ),
        const Gap(12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back!',
              style: TextStyle(
                fontSize: 20,
                
                fontWeight: FontWeight.bold,
                color: role.color,
              ),
            ),
            Text(
              'Sign in to continue as a ${role.id}',
              style: TextStyle(
                fontSize: 13,
                
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
