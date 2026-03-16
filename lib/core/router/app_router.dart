import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/constants.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/set_pin_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/patients/presentation/screens/patient_list_screen.dart';
import '../../features/patients/presentation/screens/patient_registration_screen.dart';
import '../../features/patients/presentation/screens/patient_detail_screen.dart';
import '../../features/appointments/presentation/screens/appointment_booking_screen.dart';
import '../../features/appointments/presentation/screens/queue_screen.dart';
import '../../features/appointments/presentation/screens/appointment_detail_screen.dart';
import '../../features/prescriptions/presentation/screens/prescription_writer_screen.dart';
import '../../features/lab_reports/presentation/lab_reports_screen.dart';
import '../../features/media/presentation/patient_media_screen.dart';
import '../../features/commissions/presentation/commissions_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/vitals/presentation/vitals_entry_screen.dart';
import '../shell/app_shell.dart';
import 'app_routes.dart';

export 'app_routes.dart';


final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Provides the [GoRouter] instance, wired to [authNotifierProvider].
final appRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.watch(_routerNotifierProvider.notifier);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: routerNotifier,
    redirect: (context, state) => routerNotifier.redirect(ref, state),
    routes: [
      // ── Unauthenticated ──────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, state) => LoginScreen(
          message: state.extra as String?,
        ),
      ),

      // ── PIN screen (authenticated users only) ────────────────────────────
      GoRoute(
        path: AppRoutes.setPin,
        builder: (_, state) {
          final modeStr = state.uri.queryParameters['mode'] ?? 'set';
          final mode = switch (modeStr) {
            'verify' => PinScreenMode.verify,
            'change' => PinScreenMode.change,
            _ => PinScreenMode.set,
          };
          return SetPinScreen(mode: mode);
        },
      ),

      // ── Authenticated shell (with bottom nav) ────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (_, __) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.patientList,
            pageBuilder: (_, __) => const NoTransitionPage(
              child: PatientListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const PatientRegistrationScreen(),
              ),
              GoRoute(
                path: ':patientId',
                builder: (_, state) => PatientDetailScreen(
                  patientId: state.pathParameters['patientId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'reports',
                    builder: (_, state) => LabReportsScreen(
                      patientId: state.pathParameters['patientId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'media',
                    builder: (_, state) => PatientMediaScreen(
                      patientId: state.pathParameters['patientId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.queue,
            pageBuilder: (_, __) => const NoTransitionPage(
              child: QueueScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.commissions,
            pageBuilder: (_, __) => const NoTransitionPage(
              child: CommissionsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            pageBuilder: (_, __) => const NoTransitionPage(
              child: NotificationsScreen(),
            ),
          ),
        ],
      ),

      // ── Full-screen routes (outside shell) ───────────────────────────────
      GoRoute(
        path: AppRoutes.appointmentBooking,
        builder: (_, __) => const AppointmentBookingScreen(),
      ),
      GoRoute(
        path: '/appointments/:appointmentId',
        builder: (_, state) => AppointmentDetailScreen(
          appointmentId: state.pathParameters['appointmentId']!,
        ),
      ),
      GoRoute(
        path: '/prescriptions/:appointmentId/write',
        builder: (_, state) => PrescriptionWriterScreen(
          appointmentId: state.pathParameters['appointmentId']!,
        ),
      ),
      GoRoute(
        path: '/vitals/:appointmentId',
        builder: (_, state) {
          final apptId = state.pathParameters['appointmentId']!;
          final patientId = state.uri.queryParameters['patientId'] ?? '';
          return VitalsEntryScreen(
            appointmentId: apptId,
            patientId: patientId,
          );
        },
      ),
    ],
  );
});

// ---------------------------------------------------------------------------
// RouterNotifier — refresh on auth changes + redirect logic
// ---------------------------------------------------------------------------

final _routerNotifierProvider =
    NotifierProvider<RouterNotifier, void>(RouterNotifier.new);

class RouterNotifier extends Notifier<void> implements Listenable {
  VoidCallback? _listener;

  @override
  void build() {
    // Rebuild/notify GoRouter whenever auth state changes
    ref.listen(authNotifierProvider, (_, __) => _listener?.call());
  }

  /// Route-guard logic — called on every navigation attempt.
  String? redirect(Ref ref, GoRouterState state) {
    final authAsync = ref.read(authNotifierProvider);
    final path = state.matchedLocation;

    // Still resolving — let splash handle it
    if (authAsync.isLoading) return null;

    // Auth failure — go to login
    if (authAsync.hasError) return AppRoutes.login;

    return authAsync.when(
      loading: () => null,
      error: (_, __) => AppRoutes.login,
      data: (authState) => _guardRoute(authState, path, state),
    );
  }

  String? _guardRoute(AuthState authState, String path, GoRouterState state) {
    final isOnSplash = path == AppRoutes.splash;
    final isOnAuthRoute = path == AppRoutes.login || isOnSplash;
    final isOnPinRoute = path == AppRoutes.setPin;

    // ── Session expired → login with message ──────────────────────────────
    if (authState is AuthStateSessionExpired) {
      if (!isOnAuthRoute) {
        return '${AppRoutes.login}?session_expired=1';
      }
      return null;
    }

    // ── Not authenticated ─────────────────────────────────────────────────
    if (authState is AuthStateUnauthenticated) {
      if (!isOnAuthRoute) return AppRoutes.login;
      return null;
    }

    // ── Authenticated ─────────────────────────────────────────────────────
    if (authState is AuthStateAuthenticated) {
      // Redirect away from splash/login to the role's home
      if (isOnAuthRoute) return authState.homeRoute;

      // PIN screen is always reachable for authenticated users
      if (isOnPinRoute) return null;

      final role = authState.user.role;

      // Patient guard — patients can only see their own notifications/dashboard
      if (role == UserRole.patient) {
        const patientAllowed = [AppRoutes.dashboard, AppRoutes.notifications];
        if (!patientAllowed.any((r) => path.startsWith(r))) {
          return AppRoutes.dashboard;
        }
        return null;
      }

      // Lab partner guard — can see dashboard, notifications, and lab reports
      // Lab reports are under /patients/:id/reports so allow /patients prefix.
      // Queue, commissions, and appointment booking are restricted.
      if (role == UserRole.labPartner) {
        const labDenied = [
          AppRoutes.queue,
          AppRoutes.commissions,
          AppRoutes.appointmentBooking,
        ];
        if (labDenied.any((r) => path.startsWith(r))) {
          return AppRoutes.dashboard;
        }
        return null;
      }

      // Staff guard — can access everything except commissions
      if (role == UserRole.staff) {
        if (path == AppRoutes.commissions) return AppRoutes.dashboard;
        return null;
      }

      // Receptionist guard — can access appointments/patients/queue/billing,
      // but not commissions or clinical write operations (prescriptions).
      if (role == UserRole.receptionist) {
        const receptionistDenied = [AppRoutes.commissions];
        if (receptionistDenied.any((r) => path.startsWith(r))) {
          return AppRoutes.dashboard;
        }
        return null;
      }

      // Doctor and Admin have full access.
      return null;
    }

    return null;
  }

  @override
  void addListener(VoidCallback listener) => _listener = listener;

  @override
  void removeListener(VoidCallback listener) {
    if (_listener == listener) _listener = null;
  }
}

