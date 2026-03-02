import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/clinic_app_bar.dart';
import '../../../../shared/widgets/clinic_button.dart';
import '../../../../shared/widgets/clinic_text_field.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/patient_repository.dart';
import '../providers/patient_provider.dart';

/// Multi-step patient registration form (3 steps).
class PatientRegistrationScreen extends ConsumerStatefulWidget {
  const PatientRegistrationScreen({super.key});

  @override
  ConsumerState<PatientRegistrationScreen> createState() =>
      _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState
    extends ConsumerState<PatientRegistrationScreen> {
  int _step = 0;
  bool _saving = false;

  // Step 1 — Personal
  final _s1Key = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  DateTime? _dob;
  String _gender = 'Male';
  String? _bloodGroup;

  // Step 2 — Contact
  final _s2Key = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // Step 3 — Medical
  final _s3Key = GlobalKey<FormState>();
  final _chiefComplaintCtrl = TextEditingController();
  final _medHistoryCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _currentMedsCtrl = TextEditingController();
  final _referredByCtrl = TextEditingController();

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];
  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _chiefComplaintCtrl.dispose();
    _medHistoryCtrl.dispose();
    _allergiesCtrl.dispose();
    _currentMedsCtrl.dispose();
    _referredByCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ClinicAppBar(
        title: 'New Patient',
        subtitle: 'Step ${_step + 1} of 3',
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildStep(),
              ),
            ),
          ),
          _buildNavigation(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = i == _step;
          final isDone = i < _step;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              decoration: BoxDecoration(
                color: isDone || isActive
                    ? AppColors.primary
                    : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildPersonalStep();
      case 1:
        return _buildContactStep();
      default:
        return _buildMedicalStep();
    }
  }

  Widget _buildPersonalStep() {
    return Form(
      key: _s1Key,
      child: Column(
        key: const ValueKey(0),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Personal Information', style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.xxl),
          ClinicTextField(
            label: 'Full Name *',
            hint: 'e.g. Rahul Sharma',
            controller: _nameCtrl,
            prefixIcon: Icons.person_outlined,
            validator: (v) => AppValidators.required(v, 'Full name'),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildDateOfBirthPicker(),
          const SizedBox(height: AppSpacing.lg),
          ClinicDropdown<String>(
            label: 'Gender *',
            value: _gender,
            items: _genders
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (v) => setState(() => _gender = v ?? 'Male'),
          ),
          const SizedBox(height: AppSpacing.lg),
          ClinicDropdown<String>(
            label: 'Blood Group',
            value: _bloodGroup,
            hint: 'Select blood group',
            items: _bloodGroups
                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                .toList(),
            onChanged: (v) => setState(() => _bloodGroup = v),
          ),
        ],
      ),
    );
  }

  Widget _buildDateOfBirthPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date of Birth', style: AppTypography.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        GestureDetector(
          onTap: _pickDob,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.cake_outlined,
                    size: 20, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.md),
                Text(
                  _dob == null
                      ? 'Select date of birth'
                      : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                  style: _dob == null
                      ? AppTypography.bodyMedium
                          .copyWith(color: AppColors.textDisabled)
                      : AppTypography.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Widget _buildContactStep() {
    return Form(
      key: _s2Key,
      child: Column(
        key: const ValueKey(1),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contact Details', style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.xxl),
          ClinicTextField(
            label: 'Mobile Number *',
            hint: '98765 43210',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            validator: AppValidators.phone,
          ),
          const SizedBox(height: AppSpacing.lg),
          ClinicTextField(
            label: 'Email Address',
            hint: 'patient@email.com',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
          ),
          const SizedBox(height: AppSpacing.lg),
          ClinicTextField(
            label: 'Address',
            hint: 'House no., Street, City, PIN',
            controller: _addressCtrl,
            prefixIcon: Icons.location_on_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.lg),
          ClinicTextField(
            label: 'Referred By',
            hint: 'Doctor or patient name',
            controller: _referredByCtrl,
            prefixIcon: Icons.share_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalStep() {
    return Form(
      key: _s3Key,
      child: Column(
        key: const ValueKey(2),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Medical History', style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.xxl),
          ClinicTextField(
            label: 'Chief Complaint',
            hint: 'Primary reason for visit',
            controller: _chiefComplaintCtrl,
            prefixIcon: Icons.medical_information_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.lg),
          ClinicTextField(
            label: 'Past Medical History',
            hint: 'Previous illnesses, surgeries, etc.',
            controller: _medHistoryCtrl,
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.lg),
          ClinicTextField(
            label: 'Known Allergies',
            hint: 'Drug, food or environmental allergies',
            controller: _allergiesCtrl,
            prefixIcon: Icons.warning_amber_outlined,
          ),
          const SizedBox(height: AppSpacing.lg),
          ClinicTextField(
            label: 'Current Medications',
            hint: 'Any ongoing medications',
            controller: _currentMedsCtrl,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (_step > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step--),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _saving ? null : _next,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.textInverse,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(_step < 2 ? 'Continue' : 'Register Patient'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _next() async {
    final isValid = switch (_step) {
      0 => _s1Key.currentState?.validate() ?? false,
      1 => _s2Key.currentState?.validate() ?? false,
      _ => _s3Key.currentState?.validate() ?? false,
    };

    if (!isValid) return;

    if (_step < 2) {
      setState(() => _step++);
      return;
    }

    // Final step — save patient
    setState(() => _saving = true);
    try {
      final userId = ref.read(currentUserProvider)?.id ?? '';
      await ref.read(patientRepositoryProvider).createPatient({
        'full_name': _nameCtrl.text.trim(),
        'dob': _dob?.toIso8601String().split('T').first,
        'gender': _gender,
        'blood_group': _bloodGroup,
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'address': _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        'referred_by': _referredByCtrl.text.trim().isEmpty ? null : _referredByCtrl.text.trim(),
        'chief_complaint': _chiefComplaintCtrl.text.trim().isEmpty
            ? null
            : _chiefComplaintCtrl.text.trim(),
        'medical_history': _medHistoryCtrl.text.trim().isEmpty
            ? null
            : _medHistoryCtrl.text.trim(),
        'allergies': _allergiesCtrl.text.trim().isEmpty
            ? null
            : _allergiesCtrl.text.trim(),
        'current_medications': _currentMedsCtrl.text.trim().isEmpty
            ? null
            : _currentMedsCtrl.text.trim(),
        'created_by': userId,
      });

      // Refresh list
      ref.invalidate(patientListProvider);

      if (mounted) {
        context.showSnackBar('Patient registered successfully!');
        context.pop();
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

