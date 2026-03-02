/// Route path constants — used by both the router and screens.
/// Kept in a separate file to avoid circular imports between
/// app_router.dart and screen files that need to navigate.
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const setPin = '/set-pin';
  static const dashboard = '/dashboard';
  static const patientList = '/patients';
  static const patientNew = '/patients/new';
  static const patientDetail = '/patients/:patientId';
  static const appointmentBooking = '/appointments/new';
  static const queue = '/queue';
  static const appointmentDetail = '/appointments/:appointmentId';
  static const prescriptionWriter = '/prescriptions/:appointmentId/write';
  static const labReports = '/patients/:patientId/reports';
  static const patientMedia = '/patients/:patientId/media';
  static const commissions = '/commissions';
  static const notifications = '/notifications';

  static String patientDetailPath(String patientId) => '/patients/$patientId';
  static String appointmentDetailPath(String id) => '/appointments/$id';
  static String prescriptionWriterPath(String apptId) =>
      '/prescriptions/$apptId/write';
  static String labReportsPath(String patientId) =>
      '/patients/$patientId/reports';
  static String patientMediaPath(String patientId) =>
      '/patients/$patientId/media';
}

