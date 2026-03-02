import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/constants.dart';
import '../../../shared/models/patient_model.dart';

/// Data source + repository for [PatientModel].
class PatientRepository {
  final SupabaseClient _client;
  PatientRepository(this._client);

  /// Fetch a paginated list of patients.
  Future<List<PatientModel>> fetchPatients({
    int page = 0,
    int pageSize = AppConstants.pageSize,
    String? searchQuery,
  }) async {
    try {
      var query = _client
          .from(AppConstants.tablePatients)
          .select()
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = _client
            .from(AppConstants.tablePatients)
            .select()
            .or('full_name.ilike.%$searchQuery%,patient_code.ilike.%$searchQuery%,phone.ilike.%$searchQuery%')
            .order('created_at', ascending: false)
            .range(page * pageSize, (page + 1) * pageSize - 1);
      }

      final data = await query;
      return (data as List).map((e) => PatientModel.fromJson(e)).toList();
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }

  /// Fetch a single patient by [id].
  Future<PatientModel> fetchPatientById(String id) async {
    try {
      final data = await _client
          .from(AppConstants.tablePatients)
          .select()
          .eq('id', id)
          .single();
      return PatientModel.fromJson(data);
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }

  /// Create a new patient record.
  Future<PatientModel> createPatient(Map<String, dynamic> data) async {
    try {
      // Remove id so Supabase auto-generates it
      data.remove('id');
      final response = await _client
          .from(AppConstants.tablePatients)
          .insert(data)
          .select()
          .single();
      return PatientModel.fromJson(response);
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }

  /// Update an existing patient.
  Future<PatientModel> updatePatient(String id, Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from(AppConstants.tablePatients)
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return PatientModel.fromJson(response);
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }

  /// Delete a patient (soft-delete in production; hard-delete here for simplicity).
  Future<void> deletePatient(String id) async {
    try {
      await _client
          .from(AppConstants.tablePatients)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }

  /// Total patient count.
  Future<int> countPatients() async {
    try {
      final response = await _client
          .from(AppConstants.tablePatients)
          .select()
          .count();
      return response.count;
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }
}

/// Riverpod provider.
final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository(ref.watch(supabaseClientProvider));
});

