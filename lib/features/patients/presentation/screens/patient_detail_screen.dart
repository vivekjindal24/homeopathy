import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/patient_model.dart';
import '../../../../shared/widgets/clinic_app_bar.dart';
import '../../../../shared/widgets/clinic_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/patient_avatar.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/patient_repository.dart';
import '../providers/patient_provider.dart';

/// Full patient profile with tabbed content.
class PatientDetailScreen extends ConsumerWidget {
  final String patientId;
  const PatientDetailScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(patientDetailProvider(patientId));

    return patientAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(patientDetailProvider(patientId)),
        ),
      ),
      data: (patient) => _PatientDetailContent(patient: patient),
    );
  }
}

class _PatientDetailContent extends ConsumerStatefulWidget {
  final PatientModel patient;
  const _PatientDetailContent({required this.patient});

  @override
  ConsumerState<_PatientDetailContent> createState() =>
      _PatientDetailContentState();
}

class _PatientDetailContentState
    extends ConsumerState<_PatientDetailContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ClinicAppBar(
        title: p.fullName,
        subtitle: p.patientCode,
        actions: [
          IconButton(
            onPressed: () => context.go(AppRoutes.appointmentBooking,
                extra: p.id),
            icon: const Icon(Icons.calendar_today_outlined, size: 20),
            tooltip: 'Book Appointment',
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Appointments'),
            Tab(text: 'Reports'),
            Tab(text: 'Media'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _OverviewTab(patient: p),
          _AppointmentsTab(patientId: p.id),
          _ReportsTab(patientId: p.id),
          _MediaTab(patientId: p.id),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final PatientModel patient;
  const _OverviewTab({required this.patient});

  @override
  Widget build(BuildContext context) {
    final p = patient;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        children: [
          // Header card
          ClinicCard(
            child: Row(
              children: [
                PatientAvatar(
                    name: p.fullName, imageUrl: p.avatarUrl, radius: 36),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.fullName, style: AppTypography.headlineMedium),
                      const SizedBox(height: 4),
                      Text(p.patientCode,
                          style: AppTypography.monoMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          if (p.dateOfBirth != null)
                            _chip(AppFormatters.age(p.dateOfBirth)),
                          const SizedBox(width: AppSpacing.sm),
                          _chip(p.gender.capitalize),
                          if (p.bloodGroup != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            _chip(p.bloodGroup!, color: AppColors.error),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Contact
          ClinicCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Contact', style: AppTypography.headlineSmall),
                const Divider(height: AppSpacing.xl),
                if (p.phone != null)
                  CardRow(label: 'Phone', value: AppFormatters.phone(p.phone)),
                if (p.email != null)
                  CardRow(label: 'Email', value: p.email!),
                if (p.address != null)
                  CardRow(label: 'Address', value: p.address!),
                if (p.referredBy != null)
                  CardRow(label: 'Referred By', value: p.referredBy!),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Medical
          ClinicCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Medical History', style: AppTypography.headlineSmall),
                const Divider(height: AppSpacing.xl),
                if (p.chiefComplaint != null)
                  CardRow(label: 'Chief Complaint', value: p.chiefComplaint!),
                if (p.allergies != null && p.allergies!.isNotEmpty)
                  CardRow(
                    label: 'Allergies',
                    value: p.allergies!,
                    valueColor: AppColors.warning,
                  ),
                if (p.medicalHistory != null)
                  CardRow(label: 'Past History', value: p.medicalHistory!),
                if (p.currentMedications != null)
                  CardRow(label: 'Medications', value: p.currentMedications!),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Registered: ${AppFormatters.dateShort(p.createdAt)}',
            style: AppTypography.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color ?? AppColors.primary,
        ),
      ),
    );
  }
}

class _AppointmentsTab extends StatelessWidget {
  final String patientId;
  const _AppointmentsTab({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.calendar_month_outlined,
      title: 'No appointments yet',
      subtitle: 'Appointments will appear here once booked',
      actionLabel: 'Book Appointment',
      onAction: () => context.push(AppRoutes.appointmentBooking, extra: patientId),
    );
  }
}

class _ReportsTab extends StatelessWidget {
  final String patientId;
  const _ReportsTab({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () => context.push(AppRoutes.labReportsPath(patientId)),
        icon: const Icon(Icons.science_outlined),
        label: const Text('View Lab Reports'),
      ),
    );
  }
}

class _MediaTab extends StatelessWidget {
  final String patientId;
  const _MediaTab({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () => context.push(AppRoutes.patientMediaPath(patientId)),
        icon: const Icon(Icons.photo_library_outlined),
        label: const Text('View Media'),
      ),
    );
  }
}

extension StringCapitalize on String {
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

