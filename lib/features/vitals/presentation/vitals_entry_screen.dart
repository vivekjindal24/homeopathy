import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/models/vitals_model.dart';
import '../../../shared/widgets/clinic_app_bar.dart';
import '../../../shared/widgets/clinic_button.dart';
import '../../../shared/widgets/clinic_text_field.dart';
import '../../../shared/widgets/clinic_card.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/vitals_repository.dart';

/// Screen for recording patient vitals at the time of an appointment.
class VitalsEntryScreen extends ConsumerStatefulWidget {
  final String appointmentId;
  final String patientId;
  const VitalsEntryScreen({
    super.key,
    required this.appointmentId,
    required this.patientId,
  });

  @override
  ConsumerState<VitalsEntryScreen> createState() => _VitalsEntryScreenState();
}

class _VitalsEntryScreenState extends ConsumerState<VitalsEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _bpSysCtrl = TextEditingController();
  final _bpDiaCtrl = TextEditingController();
  final _pulseCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _spo2Ctrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    try {
      final vitals = await ref
          .read(vitalsRepositoryProvider)
          .fetchByAppointment(widget.appointmentId);
      if (vitals != null && mounted) {
        _weightCtrl.text = vitals.weight?.toString() ?? '';
        _heightCtrl.text = vitals.height?.toString() ?? '';
        _bpSysCtrl.text = vitals.bpSystolic?.toString() ?? '';
        _bpDiaCtrl.text = vitals.bpDiastolic?.toString() ?? '';
        _pulseCtrl.text = vitals.pulse?.toString() ?? '';
        _tempCtrl.text = vitals.temperature?.toString() ?? '';
        _spo2Ctrl.text = vitals.spo2?.toString() ?? '';
        setState(() {});
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _bpSysCtrl.dispose();
    _bpDiaCtrl.dispose();
    _pulseCtrl.dispose();
    _tempCtrl.dispose();
    _spo2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const ClinicAppBar(title: 'Record Vitals'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            _buildVitalRow(
              icon: Icons.monitor_weight_outlined,
              label: 'Weight',
              unit: 'kg',
              controller: _weightCtrl,
              color: AppColors.secondary,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildVitalRow(
              icon: Icons.height_rounded,
              label: 'Height',
              unit: 'cm',
              controller: _heightCtrl,
              color: AppColors.secondary,
            ),
            const SizedBox(height: AppSpacing.md),
            ClinicCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.favorite_outlined,
                          color: AppColors.error, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Blood Pressure', style: AppTypography.titleMedium),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: ClinicTextField(
                          label: 'Systolic (mmHg)',
                          hint: '120',
                          controller: _bpSysCtrl,
                          keyboardType: TextInputType.number,
                          validator: _bpSysCtrl.text.isEmpty
                              ? null
                              : AppValidators.bpSystolic,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ClinicTextField(
                          label: 'Diastolic (mmHg)',
                          hint: '80',
                          controller: _bpDiaCtrl,
                          keyboardType: TextInputType.number,
                          validator: _bpDiaCtrl.text.isEmpty
                              ? null
                              : AppValidators.bpDiastolic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildVitalRow(
              icon: Icons.favorite_border_outlined,
              label: 'Pulse Rate',
              unit: 'bpm',
              controller: _pulseCtrl,
              color: AppColors.error,
              normalMin: AppConstants.pulseMin.toDouble(),
              normalMax: AppConstants.pulseMax.toDouble(),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildVitalRow(
              icon: Icons.thermostat_outlined,
              label: 'Temperature',
              unit: '°C',
              controller: _tempCtrl,
              color: AppColors.warning,
              normalMin: AppConstants.temperatureMin,
              normalMax: AppConstants.temperatureMax,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildVitalRow(
              icon: Icons.air_outlined,
              label: 'SpO2',
              unit: '%',
              controller: _spo2Ctrl,
              color: AppColors.primary,
              normalMin: AppConstants.spo2Min.toDouble(),
              normalMax: 100,
              validator: _spo2Ctrl.text.isEmpty ? null : AppValidators.spo2,
            ),
            const SizedBox(height: AppSpacing.xxxl),
            ClinicButton(
              label: 'Save Vitals',
              isLoading: _saving,
              prefixIcon: Icons.save_outlined,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalRow({
    required IconData icon,
    required String label,
    required String unit,
    required TextEditingController controller,
    required Color color,
    double? normalMin,
    double? normalMax,
    String? Function(String?)? validator,
  }) {
    final val = double.tryParse(controller.text);
    final isNormal = val == null ||
        normalMin == null ||
        normalMax == null ||
        (val >= normalMin && val <= normalMax);

    return ClinicCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: ClinicTextField(
              label: label,
              hint: '–',
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: validator,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(unit, style: AppTypography.monoSmall),
              if (val != null && normalMin != null && normalMax != null)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isNormal
                        ? AppColors.vitalNormal
                        : AppColors.vitalDanger,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    try {
      final userId = ref.read(currentUserProvider)?.id ?? '';
      await ref.read(vitalsRepositoryProvider).saveVitals({
        'appointment_id': widget.appointmentId,
        'patient_id': widget.patientId,
        'weight': double.tryParse(_weightCtrl.text),
        'height': double.tryParse(_heightCtrl.text),
        'bp_systolic': int.tryParse(_bpSysCtrl.text),
        'bp_diastolic': int.tryParse(_bpDiaCtrl.text),
        'pulse': int.tryParse(_pulseCtrl.text),
        'temperature': double.tryParse(_tempCtrl.text),
        'spo2': int.tryParse(_spo2Ctrl.text),
        'recorded_by': userId,
      });

      ref.invalidate(vitalsProvider(widget.appointmentId));

      if (mounted) {
        context.showSnackBar('Vitals saved successfully!');
        context.pop();
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

