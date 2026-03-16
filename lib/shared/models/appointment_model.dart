import '../../core/utils/constants.dart';

/// Domain model for an appointment.
class AppointmentModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String? staffId;
  final DateTime scheduledAt;
  final AppointmentStatus status;
  final int queueNumber;
  final String? notes;
  final String? patientName;
  final String? patientCode;
  final String? doctorName;
  final DateTime createdAt;

  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    this.staffId,
    required this.scheduledAt,
    required this.status,
    required this.queueNumber,
    this.notes,
    this.patientName,
    this.patientCode,
    this.doctorName,
    required this.createdAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    // Support both `queue_number` (Dart model name) and legacy `token_number`
    // (initial DB column name before migration 002).
    final queueNum = json['queue_number'] as int? ??
        json['token_number'] as int? ??
        0;
    return AppointmentModel(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      doctorId: json['doctor_id'] as String,
      staffId: json['staff_id'] as String?,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      status: AppointmentStatusX.fromString(
        json['status'] as String? ?? 'scheduled',
      ),
      queueNumber: queueNum,
      notes: json['notes'] as String?,
      patientName: json['patient_name'] as String?,
      patientCode: json['patient_code'] as String?,
      doctorName: json['doctor_name'] as String?,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'doctor_id': doctorId,
        'staff_id': staffId,
        'scheduled_at': scheduledAt.toIso8601String(),
        'status': status.value,
        'queue_number': queueNumber,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  AppointmentModel copyWith({
    AppointmentStatus? status,
    String? notes,
    DateTime? scheduledAt,
    int? queueNumber,
  }) {
    return AppointmentModel(
      id: id,
      patientId: patientId,
      doctorId: doctorId,
      staffId: staffId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      queueNumber: queueNumber ?? this.queueNumber,
      notes: notes ?? this.notes,
      patientName: patientName,
      patientCode: patientCode,
      doctorName: doctorName,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AppointmentModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

