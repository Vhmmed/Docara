import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:medical_booking_app/shared/widgets/custom_text.dart';

import '../../../auth/presentation/pages/auth/login_page.dart';
import '../../data/role_data/role_data.dart';
import '../widgets/nav/rolecard/role_card.dart';

class RoleSelection extends StatelessWidget {
  const RoleSelection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff8FBAC7),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Gap(100),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Color(0xff8FBAC7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset('assets/LogoApp/last2.png')),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: Text(
                    'Welcome to Docara!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Select your role to continue',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    
                    fontWeight: FontWeight.w500),
              ),
            ),
            Gap(50),
            Column(
              children: roles.map((role) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: RoleCard(
                    title: role['title'] as String,
                    description: role['desc'] as String,
                    icon: role['icon'] as String,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LoginPage(
                            roleId: role['id'] as String,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
            Gap(20),
            CustomText(
              text: 'By continuing, you agree to our Terms of Service',
              color: Colors.white,
              size: 13,
            ),
          ],
        ),
      ),
    );
  }
}
