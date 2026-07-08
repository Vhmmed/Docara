import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:medical_booking_app/shared/widgets/custom_text.dart';
import 'package:medical_booking_app/widgets/loading/loading_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SpecialtyDropdown extends StatefulWidget {
  final String? selectedSpecialtyId;
  final ValueChanged<String?> onChanged;
  const SpecialtyDropdown({
    super.key,
    required this.selectedSpecialtyId,
    required this.onChanged,
  });

  @override
  State<SpecialtyDropdown> createState() => _SpecialtyDropdownState();
}

class _SpecialtyDropdownState extends State<SpecialtyDropdown> {
  List<Map<String, dynamic>> _specialties = [];
  bool _loading = false;
  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _fetchSpecialties();
    }
  }

  Future<void> _fetchSpecialties() async {
    setState(() => _loading = true);
    try {
      final data = await Supabase.instance.client
          .from('specialties')
          .select('id, name')
          .order('name');
      if (!mounted) return;
      setState(() {
        _specialties = (data as List).map((e) => e as Map<String, dynamic>).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CustomText(
          text: 'Specialization',
          size: 15,
          
          weight: FontWeight.w600,
          color: Colors.black87,
        ),
        const Gap(8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: _loading
          ? const SizedBox(
                height: 48,
                child: Center(child: AppRingSpinner(size: 20)),
              )
              : DropdownButtonFormField<String>(
                  value: widget.selectedSpecialtyId,
                  hint: CustomText(
                    text: _specialties.isEmpty
                        ? 'No specialties available'
                        : 'Select your specialization',
                    size: 14,
                    color: Colors.grey,
                    
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  items: _specialties.map((specialty) {
                    return DropdownMenuItem<String>(
                      value: specialty['id'] as String,
                      child: CustomText(
                        text: specialty['name'] as String,
                        size: 14,
                        color: Colors.black87,
                        
                      ),
                    );
                  }).toList(),
                  onChanged: _specialties.isEmpty ? null : widget.onChanged,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your specialization';
                    }
                    return null;
                  },
                  dropdownColor: Colors.white,
                  icon: Icon(
                    CupertinoIcons.chevron_down,
                    color: Colors.grey[500],
                    size: 20,
                  ),
                  style: const TextStyle(
                    
                    fontSize: 14,
                  ),
                ),
        ),
      ],
    );
  }
}
