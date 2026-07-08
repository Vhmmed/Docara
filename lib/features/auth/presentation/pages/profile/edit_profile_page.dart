import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../shared/widgets/custom_snackbar_helper.dart';
import '../../../../../widgets/loading/loading_widgets.dart';
import '../../cubits/profile_cubit.dart';
import '../../widgets/inputs/blood_type_selector.dart';
import '../../widgets/inputs/chip_input.dart';

class EditProfilePage extends StatefulWidget {
  final String roleId;

  const EditProfilePage({super.key, required this.roleId});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final ProfileCubit _cubit;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  DateTime? _dateOfBirth;
  String? _gender;
  String? _bloodType;
  List<String> _allergies = [];
  List<String> _medicalConditions = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _cubit = sl<ProfileCubit>();
    final state = _cubit.state;
    if (state is ProfileLoaded) {
      final p = state.profile;
      _nameCtrl.text = p.fullName ?? '';
      _phoneCtrl.text = p.phone ?? '';
      _dateOfBirth = p.dateOfBirth;
      _gender = p.gender;
      _bloodType = p.bloodType;
      _allergies = List.from(p.allergies);
      _medicalConditions = List.from(p.medicalConditions);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool get _isPatient => widget.roleId == 'patient';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _cubit.updateProfile(
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        dateOfBirth: _dateOfBirth,
        gender: _gender,
        bloodType: _isPatient ? _bloodType : null,
        allergies: _isPatient ? _allergies : null,
        medicalConditions: _isPatient ? _medicalConditions : null,
      );
      if (!mounted) return;
      CustomSnackBarHelper.show(
        context,
        message: 'Profile updated successfully',
        isSuccess: true,
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      CustomSnackBarHelper.show(
        context,
        message: 'Failed to update profile',
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),
              const Gap(24),
              _buildNameField(),
              const Gap(16),
              _buildPhoneField(),
              const Gap(16),
              _buildDateOfBirthField(),
              const Gap(16),
              _buildGenderDropdown(),
              if (_isPatient) ...[
                const Gap(24),
                _buildSectionTitle('Medical Information'),
                const Gap(16),
                _buildBloodTypeSelector(),
                const Gap(20),
                _buildAllergiesSection(),
                const Gap(20),
                _buildMedicalConditionsSection(),
              ],
              const Gap(32),
              _buildSaveButton(),
              const Gap(12),
              Center(
                child: Text(
                  'All information is secure and private',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
              const Gap(8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.purple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: Colors.blue.shade700,
              size: 28,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personal Information',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Gap(2),
                Text(
                  'Update your personal details',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isPatient ? 'Patient' : 'Doctor',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameCtrl,
      decoration: InputDecoration(
        labelText: 'Full Name',
        prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        labelStyle: TextStyle(color: Colors.grey.shade600),
      ),
      style: TextStyle(fontSize: 15),
      validator: (v) =>
      v == null || v.trim().isEmpty ? 'Required' : null,
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneCtrl,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        labelStyle: TextStyle(color: Colors.grey.shade600),
      ),
      keyboardType: TextInputType.phone,
      style: TextStyle(fontSize: 15),
    );
  }

  Widget _buildDateOfBirthField() {
    return InkWell(
      onTap: _pickDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date of Birth',
          prefixIcon: Icon(Icons.calendar_today_rounded, color: Colors.grey.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          labelStyle: TextStyle(color: Colors.grey.shade600),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _dateOfBirth != null
                  ? DateFormat('dd MMM yyyy').format(_dateOfBirth!)
                  : 'Tap to select',
              style: TextStyle(
                fontSize: 15,
                color: _dateOfBirth != null
                    ? Colors.grey.shade800
                    : Colors.grey.shade500,
              ),
            ),
            if (_dateOfBirth != null)
              Icon(Icons.check_circle_outline_rounded,
                  color: Colors.green.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _gender,
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: Icon(Icons.transgender_rounded, color: Colors.grey.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        labelStyle: TextStyle(color: Colors.grey.shade600),
      ),
      items: const [
        DropdownMenuItem(
          value: 'Male',
          child: Row(
            children: [
              Icon(Icons.male_rounded, size: 20),
              Gap(10),
              Text('Male'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 'Female',
          child: Row(
            children: [
              Icon(Icons.female_rounded, size: 20),
              Gap(10),
              Text('Female'),
            ],
          ),
        ),
      ],
      onChanged: (v) => setState(() => _gender = v),
      icon: Icon(Icons.arrow_drop_down_rounded, color: Colors.grey.shade600),
      dropdownColor: Colors.white,
      elevation: 0,
      selectedItemBuilder: (context) {
        return const [
          Text('Male'),
          Text('Female'),
        ];
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.purple.shade700],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Gap(10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildBloodTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bloodtype_rounded, color: Colors.red.shade400, size: 22),
              const Gap(10),
              Text(
                'Blood Type',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const Gap(8),
          BloodTypeSelector(
            value: _bloodType,
            onChanged: (v) => setState(() => _bloodType = v),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergiesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade400, size: 22),
              const Gap(10),
              Text(
                'Allergies',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const Gap(12),
          ChipInput(
            initialValues: _allergies,
            onChanged: (v) => _allergies = v,
            hintText: 'Add allergy...',
          ),
          const Gap(8),
          Text(
            '⚠️ Please confirm this information with your doctor',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalConditionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_information_rounded, color: Colors.purple.shade400, size: 22),
              const Gap(10),
              Text(
                'Medical Conditions',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const Gap(12),
          ChipInput(
            initialValues: _medicalConditions,
            onChanged: (v) => _medicalConditions = v,
            hintText: 'Add condition...',
          ),
          const Gap(8),
          Text(
            '⚠️ Please confirm this information with your doctor',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: _saving ? null : _save,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          disabledBackgroundColor: Colors.blue.shade200,
        ),
        child: _saving
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppPulseDot(size: 22, color: Colors.white),
            const Gap(12),
            Text(
              'Saving...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save_outlined, size: 22),
            const Gap(10),
            Text(
              'Save Changes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}