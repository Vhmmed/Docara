import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medical_booking_app/shared/widgets/custom_text.dart';
import 'package:medical_booking_app/widgets/loading/loading_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/widgets/custom_snackbar_helper.dart';

class WorkingHoursPage extends StatefulWidget {
  const WorkingHoursPage({super.key});

  @override
  State<WorkingHoursPage> createState() => _WorkingHoursPageState();
}

class _WorkingHoursPageState extends State<WorkingHoursPage> {
  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final Map<int, bool> _enabled = {};
  final Map<int, TextEditingController> _startCtrl = {};
  final Map<int, TextEditingController> _endCtrl = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 7; i++) {
      _enabled[i] = i < 5;
      _startCtrl[i] = TextEditingController(text: '09:00');
      _endCtrl[i] = TextEditingController(text: '17:00');
    }
    _fetch();
  }

  Future<void> _fetch() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final rows = await Supabase.instance.client
          .from('doctor_availability')
          .select('day_of_week, start_time, end_time')
          .eq('doctor_id', userId);

      if (rows is List) {
        for (final r in rows) {
          final day = r['day_of_week'] as int;
          _enabled[day] = true;
          _startCtrl[day]?.text = r['start_time'] as String? ?? '09:00';
          _endCtrl[day]?.text = r['end_time'] as String? ?? '17:00';
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _saving = true);
    try {
      // Delete existing and re-insert
      await Supabase.instance.client
          .from('doctor_availability')
          .delete()
          .eq('doctor_id', userId);

      for (int i = 0; i < 7; i++) {
        if (_enabled[i] != true) continue;
        await Supabase.instance.client.from('doctor_availability').insert({
          'doctor_id': userId,
          'day_of_week': i,
          'start_time': _startCtrl[i]!.text,
          'end_time': _endCtrl[i]!.text,
        });
      }

      if (!mounted) return;
      CustomSnackBarHelper.show(
        context,
        message: 'Working hours saved successfully',
        isSuccess: true,
      );
    } catch (e) {
      if (!mounted) return;
      CustomSnackBarHelper.show(
        context,
        message: 'Failed to save working hours',
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final c in _startCtrl.values) c.dispose();
    for (final c in _endCtrl.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const CustomText(
          text: 'Working Hours',
          size: 22,
          color: Colors.black,
          weight: FontWeight.w600,
          family: 'IBM Plex Sans',
        ),
      ),
      body: _loading
          ? const Center(child: AppRingSpinner())
          : Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: 7,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _buildDayRow(i),
            ),
          ),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildDayRow(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _buildDayCheckbox(index),
          if (_enabled[index] == true) ...[
            const Spacer(),
            _buildTimeField(
              controller: _startCtrl[index]!,
              label: 'Start',
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'to',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            _buildTimeField(
              controller: _endCtrl[index]!,
              label: 'End',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDayCheckbox(int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: _enabled[index] == true
            ? Colors.blue.shade50
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _enabled[index] == true
              ? Colors.blue.shade200
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _enabled[index],
            onChanged: (v) => setState(() => _enabled[index] = v ?? false),
            activeColor: Colors.blue.shade700,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Text(
            _days[index],
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: _enabled[index] == true
                  ? Colors.grey.shade800
                  : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeField({
    required TextEditingController controller,
    required String label,
  }) {
    return SizedBox(
      width: 85,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          hintText: label,
          hintStyle: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade400,
          ),
        ),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade800,
        ),
        textAlign: TextAlign.center,
        inputFormatters: [
          LengthLimitingTextInputFormatter(5),
          // Optional: Add time format filter (HH:MM)
          FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
        ],
        onChanged: (value) {
          // Auto-format time input (optional)
          if (value.length == 2 && !value.contains(':')) {
            controller.text = '$value:';
            controller.selection = TextSelection.fromPosition(
              TextPosition(offset: controller.text.length),
            );
          }
        },
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            disabledBackgroundColor: Colors.blue.shade200,
          ),
          child: _saving
              ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppPulseDot(size: 22, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                'Saving...',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.save_outlined, size: 22),
              const SizedBox(width: 10),
              Text(
                'Save Working Hours',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}