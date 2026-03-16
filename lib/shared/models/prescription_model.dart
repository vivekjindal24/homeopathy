/// A single remedy line inside a prescription.
class RemedyLine {
  final String remedyName;
  final String potency;
  final String dose;
  final String frequency;
  final String duration;
  final String? instructions;

  const RemedyLine({
    required this.remedyName,
    required this.potency,
    required this.dose,
    required this.frequency,
    required this.duration,
    this.instructions,
  });

  factory RemedyLine.fromJson(Map<String, dynamic> json) {
    return RemedyLine(
      remedyName: json['remedy_name'] as String,
      potency: json['potency'] as String? ?? '',
      dose: json['dose'] as String? ?? '',
      frequency: json['frequency'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      instructions: json['instructions'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'remedy_name': remedyName,
        'potency': potency,
        'dose': dose,
        'frequency': frequency,
        'duration': duration,
        'instructions': instructions,
      };

  RemedyLine copyWith({
    String? remedyName,
    String? potency,
    String? dose,
    String? frequency,
    String? duration,
    String? instructions,
  }) {
    return RemedyLine(
      remedyName: remedyName ?? this.remedyName,
      potency: potency ?? this.potency,
      dose: dose ?? this.dose,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      instructions: instructions ?? this.instructions,
    );
  }
}

/// Domain model for a prescription.
class PrescriptionModel {
  final String id;
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final String? chiefComplaint;
  final String? diagnosis;
  final String? miasm;
  final List<RemedyLine> remedies;
  final DateTime? followUpDate;
  final String? notes;
  final String? pdfUrl;
  final String? patientName;
  final String? doctorName;
  final DateTime createdAt;

  const PrescriptionModel({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    this.chiefComplaint,
    this.diagnosis,
    this.miasm,
    required this.remedies,
    this.followUpDate,
    this.notes,
    this.pdfUrl,
    this.patientName,
    this.doctorName,
    required this.createdAt,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    final rawRemedies = json['remedy_json'];
    List<RemedyLine> remedies = [];
    if (rawRemedies is List) {
      remedies = rawRemedies
          .map((e) => RemedyLine.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return PrescriptionModel(
      id: json['id'] as String,
      appointmentId: json['appointment_id'] as String? ?? '',
      patientId: json['patient_id'] as String,
      doctorId: json['doctor_id'] as String,
      chiefComplaint: json['chief_complaint'] as String?,
      diagnosis: json['diagnosis'] as String?,
      miasm: json['miasm'] as String?,
      remedies: remedies,
      followUpDate: json['follow_up_date'] != null
          ? DateTime.tryParse(json['follow_up_date'] as String)
          : null,
      notes: json['notes'] as String?,
      pdfUrl: json['pdf_url'] as String?,
      patientName: json['patient_name'] as String?,
      doctorName: json['doctor_name'] as String?,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'appointment_id': appointmentId,
        'patient_id': patientId,
        'doctor_id': doctorId,
        'chief_complaint': chiefComplaint,
        'diagnosis': diagnosis,
        'miasm': miasm,
        'remedy_json': remedies.map((r) => r.toJson()).toList(),
        'follow_up_date': followUpDate?.toIso8601String().split('T').first,
        'notes': notes,
        'pdf_url': pdfUrl,
        'created_at': createdAt.toIso8601String(),
      };

  PrescriptionModel copyWith({
    String? chiefComplaint,
    String? diagnosis,
    String? miasm,
    List<RemedyLine>? remedies,
    DateTime? followUpDate,
    String? notes,
    String? pdfUrl,
  }) {
    return PrescriptionModel(
      id: id,
      appointmentId: appointmentId,
      patientId: patientId,
      doctorId: doctorId,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      diagnosis: diagnosis ?? this.diagnosis,
      miasm: miasm ?? this.miasm,
      remedies: remedies ?? this.remedies,
      followUpDate: followUpDate ?? this.followUpDate,
      notes: notes ?? this.notes,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      patientName: patientName,
      doctorName: doctorName,
      createdAt: createdAt,
    );
  }
}

