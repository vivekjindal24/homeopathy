import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/constants.dart';
import '../../../../shared/models/appointment_model.dart';
import '../../../../shared/widgets/clinic_app_bar.dart';
import '../../../../shared/widgets/clinic_button.dart';
import '../../../../shared/widgets/clinic_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../core/router/app_router.dart';
import '../../data/appointment_repository.dart';
import '../providers/appointment_provider.dart';

/// Full appointment detail with status management and navigation to
/// vitals / prescription sub-screens.
class AppointmentDetailScreen extends ConsumerWidget {
  final String appointmentId;
  const AppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apptAsync = ref.watch(appointmentDetailProvider(appointmentId));

    return apptAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(appointmentDetailProvider(appointmentId)),
        ),
      ),
      data: (appt) => _ApptContent(appointment: appt),
    );
  }
}

class _ApptContent extends ConsumerWidget {
  final AppointmentModel appointment;
  const _ApptContent({required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = appointment;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ClinicAppBar(
        title: a.patientName ?? 'Appointment',
        subtitle: 'Queue #${a.queueNumber} · ${AppFormatters.time12(a.scheduledAt)}',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: StatusBadge.fromStatus(a.status),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient info
            ClinicCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Patient', style: AppTypography.headlineSmall),
                  const Divider(height: AppSpacing.xl),
                  CardRow(label: 'Name', value: a.patientName ?? '--'),
                  CardRow(label: 'Patient Code', value: a.patientCode ?? '--'),
                  CardRow(
                    label: 'Scheduled',
                    value: AppFormatters.dateTime(a.scheduledAt),
                  ),
                  CardRow(label: 'Doctor', value: a.doctorName ?? '--'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Status actions
            _StatusActions(appointment: a),
            const SizedBox(height: AppSpacing.lg),

            // Quick-action cards
            Text('Actions', style: AppTypography.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            _ActionGrid(appointment: a),
          ],
        ),
      ),
    );
  }
}

class _StatusActions extends ConsumerWidget {
  final AppointmentModel appointment;
  const _StatusActions({required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = appointment;
    final repo = ref.read(appointmentRepositoryProvider);

    Future<void> setStatus(AppointmentStatus status) async {
      try {
        await repo.updateStatus(a.id, status);
        ref.invalidate(appointmentDetailProvider(a.id));
        ref.invalidate(queueStreamProvider);
        if (context.mounted) {
          context.showSnackBar('Status updated to ${status.displayName}');
        }
      } catch (e) {
        if (context.mounted) context.showErrorSnackBar(e.toString());
      }
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (a.status == AppointmentStatus.scheduled ||
            a.status == AppointmentStatus.waiting)
          ClinicButton(
            label: 'Mark In Progress',
            isFullWidth: false,
            width: 160,
            height: 40,
            prefixIcon: Icons.play_arrow_rounded,
            onPressed: () => setStatus(AppointmentStatus.inProgress),
          ),
        if (a.status == AppointmentStatus.inProgress)
          ClinicButton(
            label: 'Mark Completed',
            isFullWidth: false,
            width: 160,
            height: 40,
            prefixIcon: Icons.check_rounded,
            onPressed: () => setStatus(AppointmentStatus.completed),
          ),
        if (a.status != AppointmentStatus.cancelled &&
            a.status != AppointmentStatus.completed)
          ClinicButton(
            label: 'Cancel',
            isFullWidth: false,
            width: 100,
            height: 40,
            variant: ClinicButtonVariant.danger,
            onPressed: () => setStatus(AppointmentStatus.cancelled),
          ),
      ],
    );
  }
}

class _ActionGrid extends StatelessWidget {
  final AppointmentModel appointment;
  const _ActionGrid({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        _ActionCard(
          icon: Icons.monitor_heart_outlined,
          label: 'Record Vitals',
          color: AppColors.secondary,
          onTap: () {
            context.push('/vitals/${a.id}?patientId=${a.patientId}');
          },
        ),
        _ActionCard(
          icon: Icons.edit_document,
          label: 'Write Prescription',
          color: AppColors.primary,
          onTap: () =>
              context.push(AppRoutes.prescriptionWriterPath(a.id)),
        ),
        _ActionCard(
          icon: Icons.science_outlined,
          label: 'Lab Reports',
          color: AppColors.warning,
          onTap: () =>
              context.push(AppRoutes.labReportsPath(a.patientId)),
        ),
        _ActionCard(
          icon: Icons.photo_library_outlined,
          label: 'Patient Media',
          color: AppColors.success,
          onTap: () =>
              context.push(AppRoutes.patientMediaPath(a.patientId)),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClinicCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(label,
              style: AppTypography.titleSmall,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

