/// Application-wide constant strings.
/// No hardcoded strings anywhere else in the codebase.
class AppConstants {
  AppConstants._();

  // App info
  static const appName = 'HomeoClinic';
  static const clinicName = 'Homeopathy Clinic';
  static const clinicCity = 'Indore, Madhya Pradesh';
  static const clinicPhone = '+91 XXXXXXXXXX';
  static const clinicEmail = 'clinic@homeopathy.in';

  // Supabase tables
  static const tableProfiles = 'profiles';
  static const tablePatients = 'patients';
  static const tableAppointments = 'appointments';
  static const tableVitals = 'vitals';
  static const tablePrescriptions = 'prescriptions';
  static const tableLabReports = 'lab_reports';
  static const tablePatientMedia = 'patient_media';
  static const tableCommissions = 'commissions';
  static const tableNotifications = 'notifications';
  static const tableNotificationTokens = 'notification_tokens';

  // Supabase storage buckets
  static const bucketLabReports = 'lab-reports';
  static const bucketPatientMedia = 'patient-media';
  static const bucketPrescriptionPdfs = 'prescription-pdfs';
  static const bucketAvatars = 'avatars';

  // Supabase RPC functions
  static const rpcGetAppointmentStats = 'get_appointment_stats';
  static const rpcGetPatientGrowth = 'get_patient_growth';
  static const rpcGetRevenueByStaff = 'get_revenue_by_staff';
  static const rpcGetTopRemedies = 'get_top_remedies';

  // Supabase edge functions
  static const edgeSendNotification = 'send-notification';
  static const edgeGeneratePatientCode = 'generate-patient-code';

  // Hive boxes
  static const hiveBoxPatients = 'patients_box';
  static const hiveBoxAppointments = 'appointments_box';
  static const hiveBoxPrescriptions = 'prescriptions_box';
  static const hiveBoxRemedies = 'remedies_box';
  static const hiveBoxSettings = 'settings_box';

  // Secure storage keys
  static const secureKeyUserId = 'user_id';
  static const secureKeyUserRole = 'user_role';
  static const secureKeyRefreshToken = 'refresh_token';

  // Pagination
  static const pageSize = 20;

  // Vitals normal ranges
  static const bpSystolicMin = 90;
  static const bpSystolicMax = 130;
  static const bpDiastolicMin = 60;
  static const bpDiastolicMax = 85;
  static const spo2Min = 95;
  static const pulseMin = 60;
  static const pulseMax = 100;
  static const temperatureMin = 36.0;
  static const temperatureMax = 37.5;

  // Default commission percentage
  static const defaultCommissionPercent = 10.0;

  // Appointment reminder hours before
  static const appointmentReminderHours = 1;

  // Max upload sizes (bytes)
  static const maxImageBytes = 5 * 1024 * 1024; // 5 MB
  static const maxPdfBytes = 10 * 1024 * 1024;  // 10 MB
}

/// User role enum matching the database constraint.
enum UserRole { doctor, staff, patient }

extension UserRoleX on UserRole {
  String get name {
    switch (this) {
      case UserRole.doctor:
        return 'doctor';
      case UserRole.staff:
        return 'staff';
      case UserRole.patient:
        return 'patient';
    }
  }

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'doctor':
        return UserRole.doctor;
      case 'staff':
        return UserRole.staff;
      default:
        return UserRole.patient;
    }
  }
}

/// Appointment status enum.
enum AppointmentStatus {
  scheduled,
  waiting,
  inProgress,
  completed,
  cancelled,
  noShow,
}

extension AppointmentStatusX on AppointmentStatus {
  String get value {
    switch (this) {
      case AppointmentStatus.scheduled:
        return 'scheduled';
      case AppointmentStatus.waiting:
        return 'waiting';
      case AppointmentStatus.inProgress:
        return 'in_progress';
      case AppointmentStatus.completed:
        return 'completed';
      case AppointmentStatus.cancelled:
        return 'cancelled';
      case AppointmentStatus.noShow:
        return 'no_show';
    }
  }

  String get displayName {
    switch (this) {
      case AppointmentStatus.scheduled:
        return 'Scheduled';
      case AppointmentStatus.waiting:
        return 'Waiting';
      case AppointmentStatus.inProgress:
        return 'In Progress';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.noShow:
        return 'No Show';
    }
  }

  static AppointmentStatus fromString(String v) {
    switch (v) {
      case 'waiting':
        return AppointmentStatus.waiting;
      case 'in_progress':
        return AppointmentStatus.inProgress;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'no_show':
        return AppointmentStatus.noShow;
      default:
        return AppointmentStatus.scheduled;
    }
  }
}

/// Media type enum for patient media.
enum MediaType { before, after, xray, other }

extension MediaTypeX on MediaType {
  String get value {
    switch (this) {
      case MediaType.before:
        return 'before';
      case MediaType.after:
        return 'after';
      case MediaType.xray:
        return 'xray';
      default:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case MediaType.before:
        return 'Before';
      case MediaType.after:
        return 'After';
      case MediaType.xray:
        return 'X-Ray';
      default:
        return 'Other';
    }
  }

  static MediaType fromString(String v) {
    switch (v) {
      case 'before':
        return MediaType.before;
      case 'after':
        return MediaType.after;
      case 'xray':
        return MediaType.xray;
      default:
        return MediaType.other;
    }
  }
}

