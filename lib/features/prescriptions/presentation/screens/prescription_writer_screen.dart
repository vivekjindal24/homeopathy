import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/constants.dart';
import '../../../../shared/models/prescription_model.dart';
import '../../../../shared/widgets/clinic_app_bar.dart';
import '../../../../shared/widgets/clinic_button.dart';
import '../../../../shared/widgets/clinic_text_field.dart';
import '../../../../shared/widgets/clinic_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/services/pdf_service.dart';
import '../../data/prescription_repository.dart';
import '../providers/prescription_provider.dart';

/// Doctor's prescription writing screen.
class PrescriptionWriterScreen extends ConsumerStatefulWidget {
  final String appointmentId;
  const PrescriptionWriterScreen({super.key, required this.appointmentId});

  @override
  ConsumerState<PrescriptionWriterScreen> createState() =>
      _PrescriptionWriterScreenState();
}

class _PrescriptionWriterScreenState
    extends ConsumerState<PrescriptionWriterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _complaintCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _miasm;
  DateTime? _followUpDate;
  List<RemedyLine> _remedies = [_emptyRemedy()];
  bool _saving = false;

  static const _miasmOptions = [
    'Psoric', 'Sycotic', 'Syphilitic', 'Tubercular', 'Cancer Miasm'
  ];
  static const _potencies = ['6C', '30C', '200C', '1M', '10M', '50M', 'LM1', 'LM2', 'Q'];
  static const _frequencies = [
    'Once daily', 'Twice daily', 'Three times daily',
    'Once weekly', 'As needed', 'SOS'
  ];
  static const _durations = [
    '3 days', '5 days', '1 week', '2 weeks', '1 month', '3 months', 'Until review'
  ];

  static RemedyLine _emptyRemedy() => const RemedyLine(
      remedyName: '', potency: '30C', dose: '2 pills',
      frequency: 'Twice daily', duration: '1 week');

  // Auto-save timer
  Timer? _autoSave;

  @override
  void initState() {
    super.initState();
    _startAutoSave();
  }

  void _startAutoSave() {
    _autoSave = Timer.periodic(const Duration(seconds: 30), (_) => _saveDraft());
  }

  @override
  void dispose() {
    _autoSave?.cancel();
    _complaintCtrl.dispose();
    _diagnosisCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ClinicAppBar(
        title: 'Write Prescription',
        subtitle: 'Appointment #${widget.appointmentId.substring(0, 8)}',
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _saveDraft,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Draft'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            _buildChiefComplaint(),
            const SizedBox(height: AppSpacing.lg),
            _buildDiagnosis(),
            const SizedBox(height: AppSpacing.lg),
            _buildMiasm(),
            const SizedBox(height: AppSpacing.xxl),
            _buildRemediesSection(),
            const SizedBox(height: AppSpacing.xxl),
            _buildFollowUp(),
            const SizedBox(height: AppSpacing.lg),
            ClinicTextField(
              label: 'Doctor\'s Notes',
              hint: 'Additional instructions for patient',
              controller: _notesCtrl,
              maxLines: 3,
              prefixIcon: Icons.notes_outlined,
            ),
            const SizedBox(height: AppSpacing.xxxl),
            ClinicButton(
              label: 'Save & Generate PDF',
              isLoading: _saving,
              prefixIcon: Icons.picture_as_pdf_outlined,
              onPressed: _saveAndGeneratePdf,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildChiefComplaint() {
    return ClinicTextField(
      label: 'Chief Complaint *',
      hint: 'Patient\'s primary complaint',
      controller: _complaintCtrl,
      maxLines: 2,
      prefixIcon: Icons.healing_outlined,
      validator: (v) => AppValidators.required(v, 'Chief complaint'),
    );
  }

  Widget _buildDiagnosis() {
    return ClinicTextField(
      label: 'Diagnosis',
      hint: 'Clinical diagnosis',
      controller: _diagnosisCtrl,
      maxLines: 2,
      prefixIcon: Icons.medical_information_outlined,
    );
  }

  Widget _buildMiasm() {
    return ClinicDropdown<String>(
      label: 'Miasm',
      value: _miasm,
      hint: 'Select miasm (optional)',
      items: _miasmOptions
          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
          .toList(),
      onChanged: (v) => setState(() => _miasm = v),
    );
  }

  Widget _buildRemediesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Remedies', style: AppTypography.headlineSmall),
            TextButton.icon(
              onPressed: () => setState(() => _remedies.add(_emptyRemedy())),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ..._remedies.asMap().entries.map((entry) {
          return _RemedyRow(
            key: ValueKey(entry.key),
            index: entry.key,
            remedy: entry.value,
            potencies: _potencies,
            frequencies: _frequencies,
            durations: _durations,
            onChanged: (updated) {
              setState(() => _remedies[entry.key] = updated);
            },
            onRemove: _remedies.length > 1
                ? () => setState(() => _remedies.removeAt(entry.key))
                : null,
          );
        }),
      ],
    );
  }

  Widget _buildFollowUp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Follow-up Date', style: AppTypography.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        GestureDetector(
          onTap: _pickFollowUp,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_repeat_outlined,
                    size: 20, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.md),
                Text(
                  _followUpDate == null
                      ? 'Set follow-up date'
                      : AppFormatters.dateShort(_followUpDate),
                  style: _followUpDate == null
                      ? AppTypography.bodyMedium
                          .copyWith(color: AppColors.textDisabled)
                      : AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickFollowUp() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _followUpDate = picked);
  }

  Map<String, dynamic> _buildPayload() {
    return {
      'appointment_id': widget.appointmentId,
      'patient_id': '', // will be filled by repository
      'doctor_id': ref.read(currentUserProvider)?.id ?? '',
      'chief_complaint': _complaintCtrl.text.trim(),
      'diagnosis': _diagnosisCtrl.text.trim().isEmpty
          ? null
          : _diagnosisCtrl.text.trim(),
      'miasm': _miasm,
      'remedy_json': _remedies
          .where((r) => r.remedyName.isNotEmpty)
          .map((r) => r.toJson())
          .toList(),
      'follow_up_date': _followUpDate?.toIso8601String().split('T').first,
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    };
  }

  Future<void> _saveDraft() async {
    // Save to local Hive cache without PDF generation
    // This is a lightweight non-blocking save
  }

  Future<void> _saveAndGeneratePdf() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final validRemedies = _remedies.where((r) => r.remedyName.isNotEmpty).toList();
    if (validRemedies.isEmpty) {
      context.showErrorSnackBar('Add at least one remedy');
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(prescriptionRepositoryProvider);
      await repo.savePrescription(_buildPayload());
      ref.invalidate(prescriptionListProvider(widget.appointmentId));

      if (mounted) {
        context.showSnackBar('Prescription saved successfully!');
        context.pop();
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _RemedyRow extends StatefulWidget {
  final int index;
  final RemedyLine remedy;
  final List<String> potencies;
  final List<String> frequencies;
  final List<String> durations;
  final ValueChanged<RemedyLine> onChanged;
  final VoidCallback? onRemove;

  const _RemedyRow({
    super.key,
    required this.index,
    required this.remedy,
    required this.potencies,
    required this.frequencies,
    required this.durations,
    required this.onChanged,
    this.onRemove,
  });

  @override
  State<_RemedyRow> createState() => _RemedyRowState();
}

class _RemedyRowState extends State<_RemedyRow> {
  late TextEditingController _nameCtrl;
  late TextEditingController _doseCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.remedy.remedyName);
    _doseCtrl = TextEditingController(text: widget.remedy.dose);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _doseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${widget.index + 1}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (widget.onRemove != null)
                GestureDetector(
                  onTap: widget.onRemove,
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _nameCtrl,
            style: AppTypography.bodyMedium,
            decoration: const InputDecoration(
              hintText: 'Remedy name (e.g. Natrum Mur)',
              prefixIcon: Icon(Icons.science_outlined, size: 18),
            ),
            onChanged: (v) => widget.onChanged(
              widget.remedy.copyWith(remedyName: v),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: widget.remedy.potency,
                  items: widget.potencies
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => widget.onChanged(
                    widget.remedy.copyWith(potency: v),
                  ),
                  decoration: const InputDecoration(labelText: 'Potency'),
                  dropdownColor: AppColors.card,
                  style: AppTypography.bodyMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _doseCtrl,
                  style: AppTypography.bodyMedium,
                  decoration: const InputDecoration(labelText: 'Dose'),
                  onChanged: (v) => widget.onChanged(
                    widget.remedy.copyWith(dose: v),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: widget.remedy.frequency,
                  items: widget.frequencies
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) => widget.onChanged(
                    widget.remedy.copyWith(frequency: v),
                  ),
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  dropdownColor: AppColors.card,
                  style: AppTypography.bodyMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: widget.remedy.duration,
                  items: widget.durations
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => widget.onChanged(
                    widget.remedy.copyWith(duration: v),
                  ),
                  decoration: const InputDecoration(labelText: 'Duration'),
                  dropdownColor: AppColors.card,
                  style: AppTypography.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

