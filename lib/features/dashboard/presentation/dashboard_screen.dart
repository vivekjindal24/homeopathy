import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/constants.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/clinic_app_bar.dart';
import '../../../shared/widgets/clinic_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/patient_avatar.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../appointments/presentation/providers/appointment_provider.dart';

/// Analytics/dashboard home screen for all roles.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(user, ref),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.card,
        onRefresh: () async {
          ref.invalidate(queueStreamProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            _GreetingCard(user: user),
            const SizedBox(height: AppSpacing.xl),
            _TodayStatsRow(),
            const SizedBox(height: AppSpacing.xl),
            _TodayQueuePreview(),
            const SizedBox(height: AppSpacing.xl),
            if (user?.role == UserRole.doctor ||
                user?.role == UserRole.staff) ...[
              _QuickActions(),
              const SizedBox(height: AppSpacing.xl),
            ],
            if (user?.role == UserRole.doctor) ...[
              _WeeklyChart(),
              const SizedBox(height: AppSpacing.xl),
            ],
          ],
        ),
      ),
    );
  }

  ClinicAppBar _buildAppBar(UserModel? user, WidgetRef ref) {
    return ClinicAppBar(
      title: AppConstants.clinicName,
      subtitle: AppConstants.clinicCity,
      showBack: false,
      actions: [
        IconButton(
          onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          icon: const Icon(Icons.logout_rounded, size: 22),
          tooltip: 'Sign Out',
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }
}

class _GreetingCard extends StatelessWidget {
  final UserModel? user;
  const _GreetingCard({this.user});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return ClinicCard(
      color: AppColors.surface,
      child: Row(
        children: [
          PatientAvatar(
            name: user?.fullName ?? 'User',
            imageUrl: user?.avatarUrl,
            radius: 30,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  user?.fullName.split(' ').first ?? 'Doctor',
                  style: AppTypography.headlineMedium,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    (user?.role.name ?? 'staff').toUpperCase(),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppFormatters.dateShort(DateTime.now()),
                style: AppTypography.monoSmall,
              ),
              Text(
                AppFormatters.time12(DateTime.now()),
                style: AppTypography.monoMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayStatsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(queueStreamProvider);

    return queueAsync.when(
      loading: () => const Row(
        children: [
          Expanded(child: MetricCardShimmer()),
          SizedBox(width: AppSpacing.md),
          Expanded(child: MetricCardShimmer()),
          SizedBox(width: AppSpacing.md),
          Expanded(child: MetricCardShimmer()),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (queue) {
        final total = queue.length;
        final completed = queue
            .where((a) => a.status == AppointmentStatus.completed)
            .length;
        final waiting = queue
            .where((a) =>
                a.status == AppointmentStatus.waiting ||
                a.status == AppointmentStatus.scheduled)
            .length;

        return Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Total Today',
                value: '$total',
                icon: Icons.calendar_today_rounded,
                accentColor: AppColors.secondary,
                onTap: () => context.go(AppRoutes.queue),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: MetricCard(
                label: 'Waiting',
                value: '$waiting',
                icon: Icons.hourglass_empty_rounded,
                accentColor: AppColors.warning,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: MetricCard(
                label: 'Completed',
                value: '$completed',
                icon: Icons.check_circle_outline_rounded,
                accentColor: AppColors.success,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TodayQueuePreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(queueStreamProvider);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Live Queue', style: AppTypography.headlineSmall),
            GestureDetector(
              onTap: () => context.go(AppRoutes.queue),
              child: Text(
                'View all',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        queueAsync.when(
          loading: () => const ShimmerList(count: 3),
          error: (e, _) => ErrorWidget(e),
          data: (queue) {
            final visible = queue
                .where((a) =>
                    a.status == AppointmentStatus.waiting ||
                    a.status == AppointmentStatus.scheduled ||
                    a.status == AppointmentStatus.inProgress)
                .take(3)
                .toList();

            if (visible.isEmpty) {
              return const EmptyState(
                icon: Icons.event_available_outlined,
                title: 'Queue is empty',
                subtitle: 'No pending appointments right now',
              );
            }

            return Column(
              children: visible.map((a) {
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text('#${a.queueNumber}',
                              style: AppTypography.monoSmall),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.patientName ?? '—',
                                style: AppTypography.titleMedium),
                            Text(AppFormatters.time12(a.scheduledAt),
                                style: AppTypography.bodySmall),
                          ],
                        ),
                      ),
                      StatusBadge.fromStatus(a.status),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTypography.headlineSmall),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _QuickActionBtn(
              icon: Icons.person_add_rounded,
              label: 'New Patient',
              onTap: () => context.go(AppRoutes.patientNew),
            ),
            const SizedBox(width: AppSpacing.md),
            _QuickActionBtn(
              icon: Icons.calendar_today_rounded,
              label: 'Book Appt',
              onTap: () => context.go(AppRoutes.appointmentBooking),
            ),
            const SizedBox(width: AppSpacing.md),
            _QuickActionBtn(
              icon: Icons.people_rounded,
              label: 'Patients',
              onTap: () => context.go(AppRoutes.patientList),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: AppSpacing.iconXl),
              const SizedBox(height: AppSpacing.sm),
              Text(label,
                  style: AppTypography.labelSmall,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Static sample data — replace with real RPC call
    final spots = [
      const FlSpot(0, 4),
      const FlSpot(1, 7),
      const FlSpot(2, 5),
      const FlSpot(3, 9),
      const FlSpot(4, 6),
      const FlSpot(5, 11),
      const FlSpot(6, 8),
    ];

    return ClinicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('This Week', style: AppTypography.headlineSmall),
              Text('Appointments',
                  style: AppTypography.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Text(
                          days[value.toInt()],
                          style: AppTypography.labelSmall,
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

