import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/models/appointment_model.dart';
import '../../../../shared/widgets/clinic_app_bar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../core/router/app_router.dart';
import '../providers/appointment_provider.dart';

/// Real-time today's queue screen.
class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(queueStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ClinicAppBar(
        title: 'Today\'s Queue',
        subtitle: AppFormatters.dateLong(DateTime.now()),
        showBack: false,
        actions: [
          IconButton(
            onPressed: () => context.go(AppRoutes.appointmentBooking),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Icon(Icons.add_rounded,
                  color: AppColors.textInverse, size: 20),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: queueAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) =>
            ErrorState(message: e.toString()),
        data: (queue) {
          if (queue.isEmpty) {
            return const EmptyState(
              icon: Icons.event_available_outlined,
              title: 'No appointments today',
              subtitle: 'Book an appointment to get started',
            );
          }
          return _QueueList(queue: queue);
        },
      ),
    );
  }
}

class _QueueList extends ConsumerWidget {
  final List<AppointmentModel> queue;
  const _QueueList({required this.queue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Group by status
    final active = queue.where((a) =>
        a.status == AppointmentStatus.inProgress).toList();
    final waiting = queue.where((a) =>
        a.status == AppointmentStatus.waiting ||
        a.status == AppointmentStatus.scheduled).toList();
    final done = queue.where((a) =>
        a.status == AppointmentStatus.completed ||
        a.status == AppointmentStatus.cancelled).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        // Stats row
        _StatsRow(queue: queue),
        const SizedBox(height: AppSpacing.lg),

        if (active.isNotEmpty) ...[
          _SectionLabel(label: 'In Progress', count: active.length),
          const SizedBox(height: AppSpacing.sm),
          ...active.map((a) => _QueueCard(appointment: a)),
          const SizedBox(height: AppSpacing.lg),
        ],

        if (waiting.isNotEmpty) ...[
          _SectionLabel(label: 'Waiting', count: waiting.length),
          const SizedBox(height: AppSpacing.sm),
          ...waiting.map((a) => _QueueCard(appointment: a)),
          const SizedBox(height: AppSpacing.lg),
        ],

        if (done.isNotEmpty) ...[
          _SectionLabel(label: 'Completed / Cancelled', count: done.length),
          const SizedBox(height: AppSpacing.sm),
          ...done.map((a) => _QueueCard(appointment: a, dimmed: true)),
        ],
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<AppointmentModel> queue;
  const _StatsRow({required this.queue});

  @override
  Widget build(BuildContext context) {
    final total = queue.length;
    final completed =
        queue.where((a) => a.status == AppointmentStatus.completed).length;
    final waiting = queue
        .where((a) =>
            a.status == AppointmentStatus.waiting ||
            a.status == AppointmentStatus.scheduled)
        .length;

    return Row(
      children: [
        _StatChip(value: '$total', label: 'Total', color: AppColors.secondary),
        const SizedBox(width: AppSpacing.sm),
        _StatChip(value: '$waiting', label: 'Waiting', color: AppColors.warning),
        const SizedBox(width: AppSpacing.sm),
        _StatChip(value: '$completed', label: 'Done', color: AppColors.success),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatChip({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value,
                style: AppTypography.headlineMedium.copyWith(color: color)),
            Text(label, style: AppTypography.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final int count;
  const _SectionLabel({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: AppTypography.headlineSmall),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: Text('$count', style: AppTypography.labelSmall),
        ),
      ],
    );
  }
}

class _QueueCard extends ConsumerWidget {
  final AppointmentModel appointment;
  final bool dimmed;
  const _QueueCard({required this.appointment, this.dimmed = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = appointment;
    return AnimatedOpacity(
      opacity: dimmed ? 0.5 : 1,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: a.status == AppointmentStatus.inProgress
                ? AppColors.primary.withOpacity(0.5)
                : AppColors.border,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Center(
              child: Text(
                '#${a.queueNumber}',
                style: AppTypography.monoMedium,
              ),
            ),
          ),
          title: Text(a.patientName ?? 'Unknown', style: AppTypography.titleLarge),
          subtitle: Text(
            '${AppFormatters.time12(a.scheduledAt)} · ${a.patientCode ?? ''}',
            style: AppTypography.bodySmall,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusBadge.fromStatus(a.status),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary, size: 20),
            ],
          ),
          onTap: () => context.push(AppRoutes.appointmentDetailPath(a.id)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
    );
  }
}

