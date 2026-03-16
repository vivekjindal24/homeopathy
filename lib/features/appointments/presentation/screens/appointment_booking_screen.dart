import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/clinic_app_bar.dart';
import '../../../../shared/widgets/clinic_button.dart';
import '../../../../shared/widgets/clinic_text_field.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/patients/data/patient_repository.dart';
import '../../../../features/patients/presentation/providers/patient_provider.dart';
import '../../data/appointment_repository.dart';
import '../providers/appointment_provider.dart';

/// Screen for booking a new appointment.
class AppointmentBookingScreen extends ConsumerStatefulWidget {
  final String? preselectedPatientId;
  const AppointmentBookingScreen({super.key, this.preselectedPatientId});

  @override
  ConsumerState<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState
    extends ConsumerState<AppointmentBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 1));
  String? _selectedPatientId;
  String? _selectedPatientName;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedPatientId != null) {
      _selectedPatientId = widget.preselectedPatientId;
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const ClinicAppBar(title: 'Book Appointment'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            _buildPatientSelector(),
            const SizedBox(height: AppSpacing.lg),
            _buildDateTimePicker(),
            const SizedBox(height: AppSpacing.lg),
            ClinicTextField(
              label: 'Notes (optional)',
              hint: 'Any special notes for this appointment',
              controller: _notesCtrl,
              maxLines: 3,
              prefixIcon: Icons.notes_outlined,
            ),
            const SizedBox(height: AppSpacing.xxxl),
            ClinicButton(
              label: 'Confirm Booking',
              isLoading: _saving,
              prefixIcon: Icons.check_circle_outline,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Patient *', style: AppTypography.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        GestureDetector(
          onTap: _pickPatient,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: _selectedPatientId != null
                    ? AppColors.primary.withOpacity(0.5)
                    : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_search_rounded,
                    size: 20, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    _selectedPatientName ?? 'Search and select a patient',
                    style: _selectedPatientName != null
                        ? AppTypography.bodyMedium
                        : AppTypography.bodyMedium.copyWith(
                            color: AppColors.textDisabled),
                  ),
                ),
                const Icon(Icons.arrow_drop_down,
                    color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickPatient() async {
    final patients = await ref
        .read(patientRepositoryProvider)
        .fetchPatients();

    if (!mounted) return;

    final selected = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PatientPickerSheet(patients: patients),
    );

    if (selected != null) {
      setState(() {
        _selectedPatientId = selected['id'];
        _selectedPatientName = selected['name'];
      });
    }
  }

  Widget _buildDateTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Appointment Date & Time *', style: AppTypography.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        GestureDetector(
          onTap: _pickDateTime,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.primary.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Text(
                  AppFormatters.dateTime(_scheduledAt),
                  style: AppTypography.bodyMedium,
                ),
                const Spacer(),
                const Icon(Icons.edit_outlined,
                    size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time == null) return;

    setState(() {
      _scheduledAt = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (_selectedPatientId == null) {
      context.showErrorSnackBar('Please select a patient');
      return;
    }

    setState(() => _saving = true);
    try {
      final doctorId = ref.read(currentUserProvider)?.id ?? '';
      await ref.read(appointmentRepositoryProvider).createAppointment({
        'patient_id': _selectedPatientId,
        'doctor_id': doctorId,
        'scheduled_at': _scheduledAt.toIso8601String(),
        'status': 'scheduled',
        'queue_number': 0,
        'notes': _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
      });

      ref.invalidate(queueStreamProvider);

      if (mounted) {
        context.showSnackBar('Appointment booked successfully!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        final msg =
            e is AppException ? e.message : e.toString();
        context.showErrorSnackBar(msg);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _PatientPickerSheet extends StatefulWidget {
  final List patients;
  const _PatientPickerSheet({required this.patients});

  @override
  State<_PatientPickerSheet> createState() => _PatientPickerSheetState();
}

class _PatientPickerSheetState extends State<_PatientPickerSheet> {
  final _searchCtrl = TextEditingController();
  late List _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.patients;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, ctrl) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm, horizontal: AppSpacing.pagePadding),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search patient…',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (q) {
                setState(() {
                  _filtered = widget.patients
                      .where((p) =>
                          p.fullName.toLowerCase().contains(q.toLowerCase()) ||
                          p.patientCode
                              .toLowerCase()
                              .contains(q.toLowerCase()))
                      .toList();
                });
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding),
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final p = _filtered[i];
                return ListTile(
                  title: Text(p.fullName),
                  subtitle: Text(p.patientCode),
                  onTap: () => Navigator.pop(
                    context,
                    {'id': p.id, 'name': p.fullName},
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

