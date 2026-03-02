import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/prescription_model.dart';
import '../../data/prescription_repository.dart';

final prescriptionListProvider =
    FutureProvider.family<List<PrescriptionModel>, String>(
        (ref, appointmentId) {
  return ref
      .watch(prescriptionRepositoryProvider)
      .fetchByAppointment(appointmentId);
});

final prescriptionsByPatientProvider =
    FutureProvider.family<List<PrescriptionModel>, String>((ref, patientId) {
  return ref
      .watch(prescriptionRepositoryProvider)
      .fetchByPatient(patientId);
});

