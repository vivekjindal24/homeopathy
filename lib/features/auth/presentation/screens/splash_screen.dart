import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/constants.dart';
import '../providers/auth_provider.dart';

/// Splash screen shown at app launch.
///
/// Behaviour:
///  1. Fades in the clinic logo + name over 800 ms.
///  2. Calls [_checkAuthAndNavigate] which races the Supabase session check
///     against a 5-second timeout — whichever fires first wins.
///  3. A second hard-timeout in [initState] guarantees navigation after 5 s
///     even if the Future.any somehow stalls.
///  4. Waits a minimum of 1.5 s before navigating (brand visibility).
///  5. Routes to the correct dashboard based on role, or to /login.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  bool _minimumElapsed = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _scaleAnim = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    // ── Hard timeout: navigate to login after 5 s no matter what ──────────
    // This is the last-resort guard in case Future.any or the provider stalls.
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_navigated) {
        debugPrint('SplashScreen: hard timeout fired — navigating to /login');
        _navigated = true;
        context.go(AppRoutes.login);
      }
    });

    // ── Minimum brand display of 1.5 s, then kick off auth check ─────────
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _minimumElapsed = true);
        _checkAuthAndNavigate();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Auth helpers ──────────────────────────────────────────────────────────

  /// Returns the current Supabase [Session], or null when not signed in.
  Future<Session?> _getAuthState() async {
    // Give the Riverpod provider a chance to resolve first.
    final authAsync = ref.read(authNotifierProvider);
    if (!authAsync.isLoading) {
      final state = authAsync.valueOrNull;
      if (state is AuthStateAuthenticated) {
        return Supabase.instance.client.auth.currentSession;
      }
      return null;
    }
    // Provider is still loading — read directly from Supabase client.
    return Supabase.instance.client.auth.currentSession;
  }

  /// Races the auth check against a 5-second timeout.
  /// Navigates based on result; always goes to /login on timeout or error.
  Future<void> _checkAuthAndNavigate() async {
    if (!mounted || _navigated) return;

    try {
      final result = await Future.any<dynamic>([
        _getAuthState(),
        Future.delayed(const Duration(seconds: 5), () => 'timeout'),
      ]);

      if (!mounted || _navigated) return;

      if (result == 'timeout' || result == null) {
        debugPrint('SplashScreen: auth check timed out or no session');
        _navigated = true;
        context.go(AppRoutes.login);
        return;
      }

      // We have a session — look up the role from the provider/profile.
      final authAsync = ref.read(authNotifierProvider);
      final authState = authAsync.valueOrNull;

      _navigated = true;
      if (authState is AuthStateAuthenticated) {
        debugPrint('SplashScreen: authenticated as ${authState.user.role.name}');
        context.go(authState.homeRoute);
      } else if (authState is AuthStateSessionExpired) {
        context.go(AppRoutes.login, extra: 'session_expired');
      } else {
        context.go(AppRoutes.login);
      }
    } catch (e) {
      debugPrint('SplashScreen: auth check error — $e');
      if (mounted && !_navigated) {
        _navigated = true;
        context.go(AppRoutes.login);
      }
    }
  }

  // ── Riverpod listener path (fires when provider resolves before timeout) ──

  void _onAuthProviderResolved() {
    if (!mounted || _navigated || !_minimumElapsed) return;
    final authAsync = ref.read(authNotifierProvider);
    if (authAsync.isLoading) return;

    _navigated = true;
    final authState = authAsync.valueOrNull;

    if (authState is AuthStateAuthenticated) {
      context.go(authState.homeRoute);
    } else if (authState is AuthStateSessionExpired) {
      context.go(AppRoutes.login, extra: 'session_expired');
    } else if (authAsync.hasError) {
      context.go(AppRoutes.login);
    } else {
      context.go(AppRoutes.login);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Also react to Riverpod auth changes in case the provider resolves
    // before the 1.5 s minimum has elapsed (rare, but handle it cleanly).
    ref.listen(authNotifierProvider, (_, next) {
      if (!next.isLoading) _onAuthProviderResolved();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Subtle radial glow in top-right corner
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.12),
                    AppColors.primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo mark
                    _HomeopathyLogo(size: 96),
                    const SizedBox(height: 28),
                    // Clinic name
                    Text(
                      AppConstants.clinicName,
                      style: AppTypography.displaySmall.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppConstants.clinicCity,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Loading indicator
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Version tag at bottom
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Text(
                'v1.0.0',
                style: AppTypography.labelSmall,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Homeopathy logo widget — teal leaf / caduceus mark
// ---------------------------------------------------------------------------

class _HomeopathyLogo extends StatelessWidget {
  final double size;
  const _HomeopathyLogo({this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.primary, AppColors.primaryDark],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.40),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Leaf / cross symbol using Flutter's built-in icons
          Icon(
            Icons.local_pharmacy_rounded,
            size: size * 0.52,
            color: AppColors.textInverse,
          ),
        ],
      ),
    );
  }
}

