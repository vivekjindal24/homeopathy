/// Domain model for a registered patient.
class PatientModel {
  final String id;
  final String? profileId;
  final String patientCode;
  final String fullName;
  final DateTime? dateOfBirth;
  final String gender;
  final String? bloodGroup;
  final String? phone;
  final String? email;
  final String? address;
  final String? referredBy;
  final String? caseNumber;
  final String? avatarUrl;
  final String? chiefComplaint;
  final String? medicalHistory;
  final String? allergies;
  final String? currentMedications;
  final String createdBy;
  final DateTime createdAt;

  const PatientModel({
    required this.id,
    this.profileId,
    required this.patientCode,
    required this.fullName,
    this.dateOfBirth,
    required this.gender,
    this.bloodGroup,
    this.phone,
    this.email,
    this.address,
    this.referredBy,
    this.caseNumber,
    this.avatarUrl,
    this.chiefComplaint,
    this.medicalHistory,
    this.allergies,
    this.currentMedications,
    required this.createdBy,
    required this.createdAt,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String?,
      patientCode: json['patient_code'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      dateOfBirth: json['dob'] != null
          ? DateTime.tryParse(json['dob'] as String)
          : null,
      gender: json['gender'] as String? ?? 'unknown',
      bloodGroup: json['blood_group'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      referredBy: json['referred_by'] as String?,
      caseNumber: json['case_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      chiefComplaint: json['chief_complaint'] as String?,
      medicalHistory: json['medical_history'] as String?,
      allergies: json['allergies'] as String?,
      currentMedications: json['current_medications'] as String?,
      createdBy: json['created_by'] as String? ?? '',
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'profile_id': profileId,
        'patient_code': patientCode,
        'full_name': fullName,
        'dob': dateOfBirth?.toIso8601String().split('T').first,
        'gender': gender,
        'blood_group': bloodGroup,
        'phone': phone,
        'email': email,
        'address': address,
        'referred_by': referredBy,
        'case_number': caseNumber,
        'avatar_url': avatarUrl,
        'chief_complaint': chiefComplaint,
        'medical_history': medicalHistory,
        'allergies': allergies,
        'current_medications': currentMedications,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
      };

  PatientModel copyWith({
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? phone,
    String? email,
    String? address,
    String? referredBy,
    String? caseNumber,
    String? avatarUrl,
    String? chiefComplaint,
    String? medicalHistory,
    String? allergies,
    String? currentMedications,
  }) {
    return PatientModel(
      id: id,
      profileId: profileId,
      patientCode: patientCode,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      referredBy: referredBy ?? this.referredBy,
      caseNumber: caseNumber ?? this.caseNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      allergies: allergies ?? this.allergies,
      currentMedications: currentMedications ?? this.currentMedications,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PatientModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

