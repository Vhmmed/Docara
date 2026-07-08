import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/custom_text.dart';
import '../../../../widgets/loading/loading_widgets.dart';
import '../../../../widgets/states/error_state.dart';
import '../../domain/entities/medical_record_entity.dart';
import '../../domain/entities/patient_summary_entity.dart';
import '../cubits/medical_records_cubit.dart';
import '../cubits/medical_records_state.dart';
import '../widgets/cards/info_summary_card.dart';
import '../widgets/cards/medical_record_card.dart';
import '../widgets/sheets/medical_record_detail_sheet.dart';
import '../widgets/cards/patient_summary_header.dart';
import '../widgets/misc/tag_chip.dart';
import '../widgets/cards/visit_history_card.dart';
import 'add_consultation_notes_page.dart';

class PatientInfoPage extends StatefulWidget {
  final String patientId;

  const PatientInfoPage({super.key, required this.patientId});

  @override
  State<PatientInfoPage> createState() => _PatientInfoPageState();
}

class _PatientInfoPageState extends State<PatientInfoPage> {
  late final MedicalRecordsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<MedicalRecordsCubit>()..loadPatientInfo(widget.patientId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          scrolledUnderElevation: 0,
          centerTitle: true,
          backgroundColor: Colors.white,
          title: const CustomText(
            text: 'Patient Info',
            size: 23,
            color: Colors.black,
            weight: FontWeight.w500,
          )),
      body: BlocBuilder<MedicalRecordsCubit, MedicalRecordsState>(
        bloc: _cubit,
        builder: (context, state) {
          return switch (state) {
            MedicalRecordsInitial() ||
            MedicalRecordsLoading() =>
              const Center(child: AppRingSpinner()),
            MedicalRecordsError(message: final msg) => ErrorState(
                message: msg,
                onRetry: () => _cubit.loadPatientInfo(widget.patientId),
              ),
            PatientInfoLoaded(summary: final s, records: final r) =>
              _buildContent(s, r),
          };
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: BlocBuilder<MedicalRecordsCubit, MedicalRecordsState>(
          bloc: _cubit,
          builder: (context, state) {
            final summary = switch (state) {
              PatientInfoLoaded(summary: final s) => s,
              _ => null,
            };
            return FilledButton.icon(
              onPressed: summary == null
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddConsultationNotesPage(
                            patientId: summary.patientId,
                            patientName: summary.fullName,
                            age: summary.age,
                            gender: summary.gender,
                          ),
                        ),
                      ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Consultation Notes'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
      PatientSummaryEntity summary, List<MedicalRecordEntity> records) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PatientSummaryHeader(
            fullName: summary.fullName,
            avatarUrl: summary.avatarUrl,
            age: summary.age,
            gender: summary.gender,
            patientId: summary.patientId,
          ),
          const Gap(20),
          Row(
            children: [
              if (summary.bloodType != null)
                InfoSummaryCard(
                  icon: Icons.bloodtype,
                  label: 'Blood Type',
                  value: summary.bloodType!,
                  iconColor: Colors.red,
                )
              else
                InfoSummaryCard(
                  icon: Icons.bloodtype,
                  label: 'Blood Type',
                  value: '—',
                  iconColor: Colors.grey,
                ),
              const Gap(12),
              InfoSummaryCard(
                icon: Icons.monitor_heart_outlined,
                label: 'Total Visits',
                value: '${summary.totalVisits}',
                iconColor: Colors.blue,
              ),
            ],
          ),
          if (summary.allergies.isNotEmpty) ...[
            const Gap(24),
            _sectionTitle(Icons.warning_amber_rounded, 'Allergies', Colors.red),
            const Gap(10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: summary.allergies
                  .map((a) => TagChip(
                        label: a,
                        icon: Icons.medical_information,
                        color: Colors.red,
                      ))
                  .toList(),
            ),
          ],
          if (summary.medicalConditions.isNotEmpty) ...[
            const Gap(24),
            _sectionTitle(Icons.healing, 'Medical Conditions', Colors.grey),
            const Gap(10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: summary.medicalConditions
                  .map((c) => TagChip(
                        label: c,
                        icon: Icons.check_circle_outline,
                        color: Colors.grey.shade700,
                      ))
                  .toList(),
            ),
          ],
          const Gap(24),
          VisitHistoryCard(
            totalVisits: summary.totalVisits,
            visitsThisYear: summary.visitsThisYear,
            visitsThisMonth: summary.visitsThisMonth,
            lastVisitDate: summary.lastVisitDate,
          ),
          const Gap(28),
          _sectionTitle(Icons.history, 'Recent Records', Colors.blue),
          const Gap(12),
          if (records.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No records yet',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              ),
            )
          else
            ...records.take(5).map((record) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MedicalRecordCard(
                    record: record,
                    onTap: () => _showRecordDetail(record),
                  ),
                )),
          const Gap(80),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showRecordDetail(MedicalRecordEntity record) {
    showModalBottomSheet(
      context: context,
      builder: (_) => MedicalRecordDetailSheet(record: record),
    );
  }
}
