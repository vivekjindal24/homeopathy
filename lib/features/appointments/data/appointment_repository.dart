import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/constants.dart';
import '../../../shared/models/appointment_model.dart';

/// Repository for appointments with real-time support.
class AppointmentRepository {
  final SupabaseClient _client;
  AppointmentRepository(this._client);

  /// Fetch today's appointment queue ordered by queue number.
  Future<List<AppointmentModel>> fetchTodayQueue() async {
    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      final data = await _client
          .from(AppConstants.tableAppointments)
          .select('''
            *,
            patients!inner(full_name, patient_code),
            profiles!doctor_id(full_name)
          ''')
          .gte('scheduled_at', '${today}T00:00:00')
          .lte('scheduled_at', '${today}T23:59:59')
          .order('queue_number');

      return (data as List).map((e) {
        final m = Map<String, dynamic>.from(e);
        m['patient_name'] = (e['patients'] as Map?)?['full_name'];
        m['patient_code'] = (e['patients'] as Map?)?['patient_code'];
        m['doctor_name'] = (e['profiles'] as Map?)?['full_name'];
        return AppointmentModel.fromJson(m);
      }).toList();
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }

  /// Fetch appointments for a specific patient.
  Future<List<AppointmentModel>> fetchPatientAppointments(
      String patientId) async {
    try {
      final data = await _client
          .from(AppConstants.tableAppointments)
          .select()
          .eq('patient_id', patientId)
          .order('scheduled_at', ascending: false);

      return (data as List)
          .map((e) => AppointmentModel.fromJson(e))
          .toList();
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }

  /// Fetch a single appointment.
  Future<AppointmentModel> fetchById(String id) async {
    try {
      final data = await _client
          .from(AppConstants.tableAppointments)
          .select('''
            *,
            patients!inner(full_name, patient_code),
            profiles!doctor_id(full_name)
          ''')
          .eq('id', id)
          .single();

      final m = Map<String, dynamic>.from(data);
      m['patient_name'] = (data['patients'] as Map?)?['full_name'];
      m['patient_code'] = (data['patients'] as Map?)?['patient_code'];
      m['doctor_name'] = (data['profiles'] as Map?)?['full_name'];
      return AppointmentModel.fromJson(m);
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }

  /// Book a new appointment.
  Future<AppointmentModel> createAppointment(
      Map<String, dynamic> data) async {
    try {
      data.remove('id');
      final response = await _client
          .from(AppConstants.tableAppointments)
          .insert(data)
          .select()
          .single();
      return AppointmentModel.fromJson(response);
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }

  /// Update appointment status.
  Future<void> updateStatus(String id, AppointmentStatus status) async {
    try {
      await _client
          .from(AppConstants.tableAppointments)
          .update({'status': status.value})
          .eq('id', id);
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }

  /// Real-time stream of today's appointments.
  Stream<List<AppointmentModel>> watchTodayQueue() {
    final today = DateTime.now().toIso8601String().split('T').first;
    final startOfDay = DateTime.parse('${today}T00:00:00');
    final endOfDay = DateTime.parse('${today}T23:59:59');
    return _client
        .from(AppConstants.tableAppointments)
        .stream(primaryKey: ['id'])
        .order('queue_number')
        .map((rows) => rows
            .map((e) => AppointmentModel.fromJson(e))
            .where((a) =>
                !a.scheduledAt.isBefore(startOfDay) &&
                !a.scheduledAt.isAfter(endOfDay))
            .toList());
  }
}

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository(ref.watch(supabaseClientProvider));
});

