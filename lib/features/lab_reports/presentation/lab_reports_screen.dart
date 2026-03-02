import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/clinic_app_bar.dart';
import '../../../shared/widgets/clinic_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final _labReportsProvider =
    FutureProvider.family<List<LabReportModel>, String>((ref, patientId) async {
  final client = Supabase.instance.client;
  final data = await client
      .from(AppConstants.tableLabReports)
      .select()
      .eq('patient_id', patientId)
      .order('report_date', ascending: false);
  return (data as List).map((e) => LabReportModel.fromJson(e)).toList();
});

/// Lab reports list + upload screen for a patient.
class LabReportsScreen extends ConsumerWidget {
  final String patientId;
  const LabReportsScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(_labReportsProvider(patientId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ClinicAppBar(
        title: 'Lab Reports',
        actions: [
          IconButton(
            onPressed: () => _uploadReport(context, ref),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Icon(Icons.upload_rounded,
                  color: AppColors.textInverse, size: 20),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: reportsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.pagePadding),
          child: ShimmerList(),
        ),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (reports) {
          if (reports.isEmpty) {
            return EmptyState(
              icon: Icons.science_outlined,
              title: 'No lab reports',
              subtitle: 'Upload reports using the button above',
              actionLabel: 'Upload Report',
              onAction: () => _uploadReport(context, ref),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            itemCount: reports.length,
            itemBuilder: (_, i) =>
                _ReportTile(report: reports[i], patientId: patientId),
          );
        },
      ),
    );
  }

  Future<void> _uploadReport(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      final file = File(image.path);
      final ext = image.path.split('.').last;
      final path = '${patientId}/${const Uuid().v4()}.$ext';

      final storageService = ref.read(storageServiceProvider);
      final storedPath = await storageService.uploadFile(
        bucket: AppConstants.bucketLabReports,
        file: file,
        customPath: path,
      );

      final userId = ref.read(currentUserProvider)?.id ?? '';
      await Supabase.instance.client.from(AppConstants.tableLabReports).insert({
        'patient_id': patientId,
        'report_type': 'general',
        'file_url': storedPath,
        'file_name': image.name,
        'uploaded_by': userId,
        'report_date': DateTime.now().toIso8601String().split('T').first,
      });

      ref.invalidate(_labReportsProvider(patientId));
      if (context.mounted) {
        context.showSnackBar('Report uploaded successfully!');
      }
    } catch (e) {
      if (context.mounted) context.showErrorSnackBar(e.toString());
    }
  }
}

class _ReportTile extends StatelessWidget {
  final LabReportModel report;
  final String patientId;

  const _ReportTile({required this.report, required this.patientId});

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
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            report.isPdf
                ? Icons.picture_as_pdf_outlined
                : Icons.image_outlined,
            color: AppColors.warning,
          ),
        ),
        title: Text(report.fileName, style: AppTypography.titleMedium),
        subtitle: Text(
          '${report.reportType.snakeToTitle} · ${AppFormatters.dateShort(report.reportDate)}',
          style: AppTypography.bodySmall,
        ),
        trailing: const Icon(Icons.open_in_new_rounded,
            size: 18, color: AppColors.textSecondary),
        onTap: () => _openReport(context, report),
      ),
    );
  }

  void _openReport(BuildContext context, LabReportModel report) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(report.fileName),
        ),
        body: PhotoView(
          imageProvider: NetworkImage(report.fileUrl),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
        ),
      ),
    ));
  }
}


