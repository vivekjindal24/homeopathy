import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/constants.dart';
import '../../../shared/models/vitals_model.dart';

/// Repository for vitals CRUD operations.
class VitalsRepository {
  final SupabaseClient _client;
  VitalsRepository(this._client);

  Future<VitalsModel?> fetchByAppointment(String appointmentId) async {
    try {
      final data = await _client
          .from(AppConstants.tableVitals)
          .select()
          .eq('appointment_id', appointmentId)
          .maybeSingle();
      if (data == null) return null;
      return VitalsModel.fromJson(data);
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }

  Future<List<VitalsModel>> fetchPatientHistory(String patientId) async {
    try {
      final data = await _client
          .from(AppConstants.tableVitals)
          .select()
          .eq('patient_id', patientId)
          .order('recorded_at', ascending: false)
          .limit(20);
      return (data as List).map((e) => VitalsModel.fromJson(e)).toList();
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }

  Future<VitalsModel> saveVitals(Map<String, dynamic> data) async {
    try {
      data.remove('id');
      final response = await _client
          .from(AppConstants.tableVitals)
          .upsert(data, onConflict: 'appointment_id')
          .select()
          .single();
      return VitalsModel.fromJson(response);
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }
}

final vitalsRepositoryProvider = Provider<VitalsRepository>((ref) {
  return VitalsRepository(ref.watch(supabaseClientProvider));
});

final vitalsProvider =
    FutureProvider.family<VitalsModel?, String>((ref, appointmentId) {
  return ref.watch(vitalsRepositoryProvider).fetchByAppointment(appointmentId);
});

