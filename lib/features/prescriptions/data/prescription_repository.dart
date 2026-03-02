import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/constants.dart';
import '../../../shared/models/prescription_model.dart';

/// Repository for prescription CRUD.
class PrescriptionRepository {
  final SupabaseClient _client;
  PrescriptionRepository(this._client);

  /// Save a new prescription record.
  Future<PrescriptionModel> savePrescription(
      Map<String, dynamic> data) async {
    try {
      // Fetch patient_id from appointment
      final appt = await _client
          .from(AppConstants.tableAppointments)
          .select('patient_id')
          .eq('id', data['appointment_id'])
          .single();
      data['patient_id'] = appt['patient_id'];
      data.remove('id');

      final response = await _client
          .from(AppConstants.tablePrescriptions)
          .insert(data)
          .select()
          .single();
      return PrescriptionModel.fromJson(response);
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }

  /// Fetch all prescriptions for an appointment.
  Future<List<PrescriptionModel>> fetchByAppointment(
      String appointmentId) async {
    try {
      final data = await _client
          .from(AppConstants.tablePrescriptions)
          .select()
          .eq('appointment_id', appointmentId)
          .order('created_at', ascending: false);
      return (data as List).map((e) => PrescriptionModel.fromJson(e)).toList();
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }

  /// Fetch all prescriptions for a patient.
  Future<List<PrescriptionModel>> fetchByPatient(String patientId) async {
    try {
      final data = await _client
          .from(AppConstants.tablePrescriptions)
          .select()
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);
      return (data as List).map((e) => PrescriptionModel.fromJson(e)).toList();
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }

  /// Update PDF URL after generation.
  Future<void> updatePdfUrl(String id, String pdfUrl) async {
    try {
      await _client
          .from(AppConstants.tablePrescriptions)
          .update({'pdf_url': pdfUrl})
          .eq('id', id);
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }
}

final prescriptionRepositoryProvider =
    Provider<PrescriptionRepository>((ref) {
  return PrescriptionRepository(ref.watch(supabaseClientProvider));
});

