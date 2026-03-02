/// Domain model for patient vitals.
class VitalsModel {
  final String id;
  final String appointmentId;
  final String patientId;
  final double? weight;
  final double? height;
  final int? bpSystolic;
  final int? bpDiastolic;
  final int? pulse;
  final double? temperature;
  final int? spo2;
  final String recordedBy;
  final DateTime recordedAt;

  const VitalsModel({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    this.weight,
    this.height,
    this.bpSystolic,
    this.bpDiastolic,
    this.pulse,
    this.temperature,
    this.spo2,
    required this.recordedBy,
    required this.recordedAt,
  });

  factory VitalsModel.fromJson(Map<String, dynamic> json) {
    return VitalsModel(
      id: json['id'] as String,
      appointmentId: json['appointment_id'] as String,
      patientId: json['patient_id'] as String,
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      bpSystolic: json['bp_systolic'] as int?,
      bpDiastolic: json['bp_diastolic'] as int?,
      pulse: json['pulse'] as int?,
      temperature: (json['temperature'] as num?)?.toDouble(),
      spo2: json['spo2'] as int?,
      recordedBy: json['recorded_by'] as String? ?? '',
      recordedAt: DateTime.parse(
        json['recorded_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'appointment_id': appointmentId,
        'patient_id': patientId,
        'weight': weight,
        'height': height,
        'bp_systolic': bpSystolic,
        'bp_diastolic': bpDiastolic,
        'pulse': pulse,
        'temperature': temperature,
        'spo2': spo2,
        'recorded_by': recordedBy,
        'recorded_at': recordedAt.toIso8601String(),
      };

  /// BMI — null when weight or height is not provided.
  double? get bmi {
    if (weight == null || height == null || height! <= 0) return null;
    final hm = height! / 100;
    return weight! / (hm * hm);
  }
}

