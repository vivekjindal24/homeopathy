import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/appointment_model.dart';
import '../../data/appointment_repository.dart';

/// Live queue — backed by Supabase Realtime stream.
final queueStreamProvider = StreamProvider<List<AppointmentModel>>((ref) {
  return ref.watch(appointmentRepositoryProvider).watchTodayQueue();
});

/// Detail provider for a single appointment.
final appointmentDetailProvider =
    FutureProvider.family<AppointmentModel, String>((ref, id) {
  return ref.watch(appointmentRepositoryProvider).fetchById(id);
});

/// Notifier for booking a new appointment.
class AppointmentBookingNotifier extends AsyncNotifier<AppointmentModel?> {
  @override
  Future<AppointmentModel?> build() async => null;

  Future<bool> book(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      return ref.read(appointmentRepositoryProvider).createAppointment(data);
    });
    state = result;
    return result.hasValue;
  }
}

final appointmentBookingProvider =
    AsyncNotifierProvider<AppointmentBookingNotifier, AppointmentModel?>(
        AppointmentBookingNotifier.new);

