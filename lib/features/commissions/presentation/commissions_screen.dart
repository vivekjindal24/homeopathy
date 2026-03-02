import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/clinic_app_bar.dart';
import '../../../shared/widgets/clinic_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../shared/models/user_model.dart';
import '../data/commission_repository.dart';

final _commissionsProvider =
    FutureProvider<List<CommissionModel>>((ref) async {
  return ref.watch(commissionRepositoryProvider).fetchAll();
});

/// Commission tracking screen — full view for doctor, own-only for staff.
class CommissionsScreen extends ConsumerWidget {
  const CommissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final commissionsAsync = ref.watch(_commissionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ClinicAppBar(
        title: 'Commissions',
        subtitle: 'Lab & referral earnings',
        showBack: false,
      ),
      body: commissionsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.pagePadding),
          child: ShimmerList(count: 4),
        ),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(_commissionsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.monetization_on_outlined,
              title: 'No commissions yet',
              subtitle: 'Commissions will appear here once patients are referred',
            );
          }

          final pending = list.where((c) => !c.isPaid).toList();
          final paid = list.where((c) => c.isPaid).toList();
          final pendingTotal = pending.fold(0.0, (s, c) => s + c.amount);
          final paidTotal = paid.fold(0.0, (s, c) => s + c.amount);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              // Summary
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'Pending',
                      amount: pendingTotal,
                      color: AppColors.warning,
                      icon: Icons.pending_outlined,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Paid Out',
                      amount: paidTotal,
                      color: AppColors.success,
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              if (pending.isNotEmpty) ...[
                Text('Pending', style: AppTypography.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                ...pending.map((c) => _CommissionTile(
                      commission: c,
                      canMarkPaid:
                          user?.role == UserRole.doctor,
                      onMarkPaid: () async {
                        await ref
                            .read(commissionRepositoryProvider)
                            .markPaid(c.id);
                        ref.invalidate(_commissionsProvider);
                      },
                    )),
                const SizedBox(height: AppSpacing.xl),
              ],
              if (paid.isNotEmpty) ...[
                Text('Paid', style: AppTypography.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                ...paid.map((c) => _CommissionTile(commission: c)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(AppFormatters.currency(amount),
              style: AppTypography.headlineMedium.copyWith(color: color)),
          Text(label, style: AppTypography.labelSmall),
        ],
      ),
    );
  }
}

class _CommissionTile extends StatelessWidget {
  final CommissionModel commission;
  final bool canMarkPaid;
  final VoidCallback? onMarkPaid;

  const _CommissionTile({
    required this.commission,
    this.canMarkPaid = false,
    this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    final c = commission;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.patientName ?? 'Patient',
                    style: AppTypography.titleLarge),
                if (c.staffName != null)
                  Text('Staff: ${c.staffName}',
                      style: AppTypography.bodySmall),
                Text(AppFormatters.dateShort(c.createdAt),
                    style: AppTypography.labelSmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppFormatters.currency(c.amount),
                style: AppTypography.headlineSmall.copyWith(
                  color: c.isPaid ? AppColors.success : AppColors.warning,
                ),
              ),
              Text('${c.percentage}%', style: AppTypography.labelSmall),
              const SizedBox(height: AppSpacing.xs),
              StatusBadge(
                label: c.isPaid ? 'PAID' : 'PENDING',
                color: c.isPaid ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
          if (canMarkPaid && !c.isPaid && onMarkPaid != null) ...[
            const SizedBox(width: AppSpacing.md),
            IconButton(
              onPressed: onMarkPaid,
              icon: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success),
              tooltip: 'Mark as paid',
            ),
          ],
        ],
      ),
    );
  }
}

