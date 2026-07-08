import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/custom_snackbar_helper.dart';
import '../../domain/entities/medical_record_entity.dart';
import '../cubits/create_record_cubit.dart';
import '../cubits/create_record_state.dart';
import '../widgets/forms/follow_up_date_field.dart';
import '../widgets/forms/labeled_text_field.dart';
import '../widgets/forms/submit_button.dart';

class AddConsultationNotesPage extends StatefulWidget {
  final String patientId;
  final String patientName;
  final int? age;
  final String? gender;

  const AddConsultationNotesPage({
    super.key,
    required this.patientId,
    required this.patientName,
    this.age,
    this.gender,
  });

  @override
  State<AddConsultationNotesPage> createState() =>
      _AddConsultationNotesPageState();
}

class _AddConsultationNotesPageState extends State<AddConsultationNotesPage> {
  late final CreateRecordCubit _cubit;
  final _formKey = GlobalKey<FormState>();
  final _complaintsCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _prescriptionCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  DateTime? _followUpDate;

  @override
  void initState() {
    super.initState();
    _cubit = sl<CreateRecordCubit>();
  }

  @override
  void dispose() {
    _cubit.close();
    _complaintsCtrl.dispose();
    _diagnosisCtrl.dispose();
    _prescriptionCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Consultation Notes')),
      body: BlocListener<CreateRecordCubit, CreateRecordState>(
        bloc: _cubit,
        listener: (context, state) {
          if (state is CreateRecordSuccess) {
            CustomSnackBarHelper.show(context,
                message: 'Notes saved successfully', isSuccess: true);
            Navigator.pop(context, true);
          } else if (state is CreateRecordError) {
            CustomSnackBarHelper.show(context,
                message: state.message, isSuccess: false);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient info header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        widget.patientName.isNotEmpty
                            ? widget.patientName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.patientName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (widget.age != null || widget.gender != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              [
                                if (widget.age != null) '${widget.age} years',
                                if (widget.gender != null) widget.gender,
                              ].join(' \u2022 '),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        Text(
                          'Patient ID: #${widget.patientId.length >= 8 ? widget.patientId.substring(0, 8).toUpperCase() : widget.patientId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Gap(24),
                LabeledTextField(
                  icon: Icons.healing,
                  label: 'Chief Complaints & Symptoms',
                  hintText: 'Describe the patient\'s complaints...',
                  controller: _complaintsCtrl,
                  maxLines: 4,
                  validator: (v) => (v == null || v.trim().isEmpty) &&
                          _diagnosisCtrl.text.trim().isEmpty
                      ? 'Fill at least complaints or diagnosis'
                      : null,
                ),
                const Gap(20),
                LabeledTextField(
                  icon: Icons.assignment,
                  label: 'Diagnosis',
                  hintText: 'Enter diagnosis...',
                  controller: _diagnosisCtrl,
                  maxLines: 4,
                ),
                const Gap(20),
                LabeledTextField(
                  icon: Icons.medication,
                  label: 'Prescription',
                  hintText: 'Enter prescription details...',
                  controller: _prescriptionCtrl,
                  maxLines: 4,
                ),
                const Gap(20),
                FollowUpDateField(
                  selectedDate: _followUpDate,
                  onDateSelected: (d) => setState(() => _followUpDate = d),
                ),
                const Gap(20),
                LabeledTextField(
                  icon: Icons.info_outline,
                  label: 'Additional Instructions',
                  hintText: 'Any additional instructions...',
                  controller: _instructionsCtrl,
                  maxLines: 3,
                ),
                const Gap(32),
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: BlocBuilder<CreateRecordCubit, CreateRecordState>(
                      bloc: _cubit,
                      builder: (context, state) {
                        return SubmitButton(
                          submitting: state is CreateRecordSubmitting,
                          label: 'Save Consultation',
                          onPressed: _submit,
                        );
                      },
                    ),
                  ),
                ),
                const Gap(20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final doctorId = Supabase.instance.client.auth.currentUser?.id;
    final complaints = _complaintsCtrl.text.trim();
    final diagnosis = _diagnosisCtrl.text.trim();

    await _cubit.submit(
      patientId: widget.patientId,
      doctorId: doctorId,
      recordType: RecordType.report,
      title: diagnosis.isNotEmpty ? diagnosis : 'Consultation',
      chiefComplaints: complaints.isNotEmpty ? complaints : null,
      diagnosis: diagnosis.isNotEmpty ? diagnosis : null,
      prescription: _prescriptionCtrl.text.trim().isNotEmpty
          ? _prescriptionCtrl.text.trim()
          : null,
      followUpDate: _followUpDate,
      additionalInstructions: _instructionsCtrl.text.trim().isNotEmpty
          ? _instructionsCtrl.text.trim()
          : null,
    );
  }
}
