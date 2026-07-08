import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../shared/widgets/custom_text.dart';
import '../../../../../shared/widgets/custom_snackbar_helper.dart';
import '../../../../../widgets/loading/loading_widgets.dart';
import '../../widgets/inputs/specialty_dropdown.dart';
import 'complete_doctor_profile_page.dart';

class DoctorSpecialtyScreen extends StatefulWidget {
  const DoctorSpecialtyScreen({super.key});

  @override
  State<DoctorSpecialtyScreen> createState() => _DoctorSpecialtyScreenState();
}

class _DoctorSpecialtyScreenState extends State<DoctorSpecialtyScreen> {
  String? _specialtyId;
  bool _isLoading = false;

  Future<void> _continue() async {
    if (_specialtyId == null) {
      CustomSnackBarHelper.show(
        context,
        message: 'Please select your specialization',
        isSuccess: false,
      );
      return;
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CompleteDoctorProfilePage(
          userId: userId,
          specialtyId: _specialtyId!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff8FBAC7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Gap(40),
              const CustomText(
                text: 'Almost there!',
                size: 27,
                
                weight: FontWeight.bold,
                color: Colors.white,
              ),
              const Gap(10),
              const CustomText(
                text: 'Select your specialization to continue',
                size: 18,
                
                weight: FontWeight.w500,
                color: Colors.white,
              ),
              const Gap(40),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SpecialtyDropdown(
                  selectedSpecialtyId: _specialtyId,
                  onChanged: (value) {
                    setState(() => _specialtyId = value);
                  },
                ),
              ),
              const Gap(30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xff8FBAC7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                      child: _isLoading
                          ? const AppPulseDot(
                              size: 20, color: Color(0xff8FBAC7),
                            )
                          : const CustomText(
                          text: 'Continue',
                          size: 17,
                          color: Color(0xff8FBAC7),
                          
                          weight: FontWeight.w600,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
