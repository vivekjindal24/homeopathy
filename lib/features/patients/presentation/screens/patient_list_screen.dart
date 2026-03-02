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
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/patient_avatar.dart';
import '../providers/patient_provider.dart';

/// Screen showing a searchable, paginated list of all patients.
class PatientListScreen extends ConsumerStatefulWidget {
  const PatientListScreen({super.key});

  @override
  ConsumerState<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends ConsumerState<PatientListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(patientListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ClinicAppBar(
        title: 'Patients',
        subtitle: 'All registered patients',
        showBack: false,
        actions: [
          IconButton(
            onPressed: () => context.go(AppRoutes.patientNew),
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
      body: Column(
        children: [
          _buildSearchBar(state.searchQuery),
          Expanded(
            child: _buildContent(state),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(String currentQuery) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.md,
      ),
      child: TextField(
        controller: _searchController,
        style: AppTypography.bodyMedium,
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          hintText: 'Search by name, code, or phone…',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: currentQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    ref.read(patientListProvider.notifier).clearSearch();
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                )
              : null,
        ),
        onChanged: (q) =>
            ref.read(patientListProvider.notifier).search(q),
      ),
    );
  }

  Widget _buildContent(patientListState) {
    if (patientListState.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
        child: ShimmerList(count: 6),
      );
    }

    if (patientListState.error != null && patientListState.patients.isEmpty) {
      return ErrorState(
        message: patientListState.error!,
        onRetry: () =>
            ref.read(patientListProvider.notifier).loadPatients(refresh: true),
      );
    }

    if (patientListState.patients.isEmpty) {
      return EmptyState(
        icon: Icons.person_search_rounded,
        title: patientListState.searchQuery.isEmpty
            ? 'No patients yet'
            : 'No results found',
        subtitle: patientListState.searchQuery.isEmpty
            ? 'Register your first patient using the + button'
            : 'Try a different name, code or phone number',
        actionLabel: patientListState.searchQuery.isEmpty
            ? 'Register Patient'
            : null,
        onAction: patientListState.searchQuery.isEmpty
            ? () => context.go(AppRoutes.patientNew)
            : null,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      onRefresh: () =>
          ref.read(patientListProvider.notifier).loadPatients(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.sm,
        ),
        itemCount: patientListState.patients.length +
            (patientListState.isLoadingMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i == patientListState.patients.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }
          return _PatientListTile(
            patient: patientListState.patients[i],
          );
        },
      ),
    );
  }
}

class _PatientListTile extends StatelessWidget {
  final PatientModel patient;
  const _PatientListTile({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        leading: PatientAvatar(
          imageUrl: patient.avatarUrl,
          name: patient.fullName,
          radius: 24,
        ),
        title: Text(patient.fullName, style: AppTypography.titleLarge),
        subtitle: Row(
          children: [
            Text(
              patient.patientCode,
              style: AppTypography.monoSmall,
            ),
            if (patient.phone != null) ...[
              Text(' · ', style: AppTypography.bodySmall),
              Text(
                AppFormatters.phone(patient.phone),
                style: AppTypography.bodySmall,
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (patient.dateOfBirth != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Text(
                  AppFormatters.age(patient.dateOfBirth),
                  style: AppTypography.labelSmall,
                ),
              ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
        onTap: () => context.go(
          AppRoutes.patientDetailPath(patient.id),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }
}

