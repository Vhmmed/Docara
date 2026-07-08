import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../shared/widgets/custom_text.dart';
import '../../../../widgets/loading/loading_widgets.dart';
import '../../../../widgets/states/empty_state.dart';
import '../../../../widgets/states/error_state.dart';
import '../../domain/entities/medical_record_entity.dart';
import '../cubits/medical_records_cubit.dart';
import '../cubits/medical_records_state.dart';
import '../widgets/cards/medical_record_card.dart';
import '../widgets/sheets/medical_record_detail_sheet.dart';

class PatientRecordsPage extends StatefulWidget {
  const PatientRecordsPage({super.key});

  @override
  State<PatientRecordsPage> createState() => _PatientRecordsPageState();
}

class _PatientRecordsPageState extends State<PatientRecordsPage> {
  late final MedicalRecordsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<MedicalRecordsCubit>()..loadPatientInfo(_currentUserId());
  }

  String _currentUserId() =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

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
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const CustomText(
          text: 'Medical Records',
          size: 23,
          color: Colors.black,
          weight: FontWeight.w500,
          family: 'IBM Plex Sans ',
        ),
      ),
      body: BlocBuilder<MedicalRecordsCubit, MedicalRecordsState>(
        bloc: _cubit,
        builder: (context, state) {
          return switch (state) {
            MedicalRecordsInitial() ||
            MedicalRecordsLoading() =>
              const Center(child: AppRingSpinner()),
            MedicalRecordsError(message: final msg) => ErrorState(
                message: msg,
                onRetry: () => _cubit.loadPatientInfo(_currentUserId()),
              ),
            PatientInfoLoaded(records: final records) => records.isEmpty
                ? const EmptyState(
                    icon: Icons.folder_open, message: 'No medical records yet')
                : _buildRecordList(records),
          };
        },
      ),
    );
  }

  Widget _buildRecordList(List<MedicalRecordEntity> records) {
    return RefreshIndicator(
      onRefresh: () => _cubit.loadPatientInfo(_currentUserId()),
      color: AppColors.primary,
      backgroundColor: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: records.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final record = records[index];
          return MedicalRecordCard(
            record: record,
            onTap: () => _showRecordDetail(record),
          );
        },
      ),
    );
  }

  void _showRecordDetail(MedicalRecordEntity record) {
    showModalBottomSheet(
      context: context,
      builder: (_) => MedicalRecordDetailSheet(record: record),
    );
  }
}
