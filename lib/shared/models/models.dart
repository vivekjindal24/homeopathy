import '../../core/utils/constants.dart';

/// Domain model for a lab report uploaded to Supabase Storage.
class LabReportModel {
  final String id;
  final String patientId;
  final String? appointmentId;
  final String reportType;
  final String fileUrl;
  final String fileName;
  final String uploadedBy;
  final DateTime reportDate;
  final String? notes;
  final DateTime createdAt;

  const LabReportModel({
    required this.id,
    required this.patientId,
    this.appointmentId,
    required this.reportType,
    required this.fileUrl,
    required this.fileName,
    required this.uploadedBy,
    required this.reportDate,
    this.notes,
    required this.createdAt,
  });

  factory LabReportModel.fromJson(Map<String, dynamic> json) {
    return LabReportModel(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      appointmentId: json['appointment_id'] as String?,
      reportType: json['report_type'] as String? ?? 'general',
      fileUrl: json['file_url'] as String? ?? '',
      fileName: json['file_name'] as String? ?? '',
      uploadedBy: json['uploaded_by'] as String? ?? '',
      reportDate: DateTime.parse(
        json['report_date'] as String? ?? DateTime.now().toIso8601String(),
      ),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'appointment_id': appointmentId,
        'report_type': reportType,
        'file_url': fileUrl,
        'file_name': fileName,
        'uploaded_by': uploadedBy,
        'report_date': reportDate.toIso8601String().split('T').first,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  bool get isPdf => fileName.toLowerCase().endsWith('.pdf');
}

/// Domain model for patient media (before/after photos, X-rays, etc.).
class PatientMediaModel {
  final String id;
  final String patientId;
  final MediaType mediaType;
  final String fileUrl;
  final String? caption;
  final String uploadedBy;
  final DateTime createdAt;

  const PatientMediaModel({
    required this.id,
    required this.patientId,
    required this.mediaType,
    required this.fileUrl,
    this.caption,
    required this.uploadedBy,
    required this.createdAt,
  });

  factory PatientMediaModel.fromJson(Map<String, dynamic> json) {
    return PatientMediaModel(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      mediaType: MediaTypeX.fromString(json['media_type'] as String? ?? 'other'),
      fileUrl: json['file_url'] as String? ?? '',
      caption: json['caption'] as String?,
      uploadedBy: json['uploaded_by'] as String? ?? '',
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'media_type': mediaType.value,
        'file_url': fileUrl,
        'caption': caption,
        'uploaded_by': uploadedBy,
        'created_at': createdAt.toIso8601String(),
      };
}

/// Domain model for a commission record.
class CommissionModel {
  final String id;
  final String staffId;
  final String patientId;
  final String? appointmentId;
  final double amount;
  final double percentage;
  final String status; // 'pending' | 'paid'
  final DateTime? paidAt;
  final String? notes;
  final String? staffName;
  final String? patientName;
  final DateTime createdAt;

  const CommissionModel({
    required this.id,
    required this.staffId,
    required this.patientId,
    this.appointmentId,
    required this.amount,
    required this.percentage,
    required this.status,
    this.paidAt,
    this.notes,
    this.staffName,
    this.patientName,
    required this.createdAt,
  });

  factory CommissionModel.fromJson(Map<String, dynamic> json) {
    return CommissionModel(
      id: json['id'] as String,
      staffId: json['staff_id'] as String,
      patientId: json['patient_id'] as String,
      appointmentId: json['appointment_id'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'pending',
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'] as String)
          : null,
      notes: json['notes'] as String?,
      staffName: json['staff_name'] as String?,
      patientName: json['patient_name'] as String?,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'staff_id': staffId,
        'patient_id': patientId,
        'appointment_id': appointmentId,
        'amount': amount,
        'percentage': percentage,
        'status': status,
        'paid_at': paidAt?.toIso8601String(),
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  bool get isPaid => status == 'paid';
}

/// Domain model for in-app notifications.
class NotificationModel {
  final String id;
  final String recipientId;
  final String title;
  final String body;
  final String type;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.recipientId,
    required this.title,
    required this.body,
    required this.type,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      recipientId: json['recipient_id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      referenceId: json['reference_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipient_id': recipientId,
        'title': title,
        'body': body,
        'type': type,
        'reference_id': referenceId,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
      };

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        recipientId: recipientId,
        title: title,
        body: body,
        type: type,
        referenceId: referenceId,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}

