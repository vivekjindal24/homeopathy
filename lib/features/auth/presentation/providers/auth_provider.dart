import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/utils/constants.dart';
import '../../../../shared/models/user_model.dart';
import '../../data/auth_repository_impl.dart';
import '../../domain/auth_repository.dart';
import '../../domain/auth_usecase.dart';

/// Auth state held by [AuthNotifier].
sealed class AuthState {
  const AuthState();
}

class AuthStateInitial extends AuthState {
  const AuthStateInitial();
}

class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

class AuthStateAuthenticated extends AuthState {
  final UserModel user;
  const AuthStateAuthenticated(this.user);

  /// Convenience role checks.
  bool get isDoctor => user.role == UserRole.doctor;
  bool get isStaff => user.role == UserRole.staff;
  bool get isReceptionist => user.role == UserRole.receptionist;
  bool get isAdmin => user.role == UserRole.admin;
  bool get isLabPartner => user.role == UserRole.labPartner;
  bool get isPatient => user.role == UserRole.patient;

  /// The home route for this role (all roles land on dashboard).
  String get homeRoute => '/dashboard';
}

class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

class AuthStateSessionExpired extends AuthState {
  const AuthStateSessionExpired();
}

class AuthStateError extends AuthState {
  final String message;
  const AuthStateError(this.message);
}

/// Central auth notifier. Screens listen to this for auth changes.
class AuthNotifier extends AsyncNotifier<AuthState> {
  late AuthRepository _repo;
  late SignInWithEmailUseCase _signInEmail;
  late SignInWithPhoneUseCase _signInPhone;
  late SignOutUseCase _signOut;
  StreamSubscription<dynamic>? _authSub;

  @override
  Future<AuthState> build() async {
    _repo = ref.read(authRepositoryProvider);
    _signInEmail = SignInWithEmailUseCase(_repo);
    _signInPhone = SignInWithPhoneUseCase(_repo);
    _signOut = SignOutUseCase(_repo);

    // Subscribe to Supabase auth stream for token refresh / expiry events
    _authSub?.cancel();
    _authSub = _repo.authStateStream.listen(_handleAuthEvent);

    // Cancel subscription when provider is disposed
    ref.onDispose(() => _authSub?.cancel());

    return _resolveCurrentSession();
  }

  // ── Session resolution ────────────────────────────────────────────────────

  Future<AuthState> _resolveCurrentSession() async {
    final user = await _repo.getCurrentUser();
    if (user != null) return AuthStateAuthenticated(user);
    return const AuthStateUnauthenticated();
  }

  void _handleAuthEvent(dynamic event) {
    final authEvent = (event as sb.AuthState).event;
    switch (authEvent) {
      case sb.AuthChangeEvent.signedIn:
      case sb.AuthChangeEvent.tokenRefreshed:
      case sb.AuthChangeEvent.userUpdated:
      case sb.AuthChangeEvent.initialSession:
      case sb.AuthChangeEvent.mfaChallengeVerified:
        ref.invalidateSelf();
        break;
      case sb.AuthChangeEvent.signedOut:
      case sb.AuthChangeEvent.userDeleted:
        state = const AsyncValue.data(AuthStateUnauthenticated());
        break;
      case sb.AuthChangeEvent.passwordRecovery:
        break;
    }
  }

  // ── Sign-in methods ───────────────────────────────────────────────────────

  /// Sign in with email + password.
  Future<String?> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    final result = await _signInEmail(email, password);
    return result.fold(
      (failure) {
        state = AsyncValue.data(AuthStateError(failure.message));
        return failure.message;
      },
      (user) {
        state = AsyncValue.data(AuthStateAuthenticated(user));
        return null; // null = success
      },
    );
  }

  /// Sign in with Indian phone number + password.
  /// [phone] should be 10 digits; E.164 is applied internally.
  Future<String?> signInWithPhone(String phone, String password) async {
    state = const AsyncValue.loading();
    final e164 = '+91${phone.replaceAll(RegExp(r'\D'), '')}';
    final result = await _signInPhone(e164, password);
    return result.fold(
      (failure) {
        state = AsyncValue.data(AuthStateError(failure.message));
        return failure.message;
      },
      (user) {
        state = AsyncValue.data(AuthStateAuthenticated(user));
        return null;
      },
    );
  }

  /// Sign out and purge all caches.
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    await _signOut();
    state = const AsyncValue.data(AuthStateUnauthenticated());
  }

  /// Mark session as expired (called by token-refresh failure handler).
  void markSessionExpired() {
    state = const AsyncValue.data(AuthStateSessionExpired());
  }
}

/// Global auth notifier provider.
final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Convenience provider that exposes the logged-in [UserModel] or null.
final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authNotifierProvider).valueOrNull;
  if (authState is AuthStateAuthenticated) return authState.user;
  return null;
});

/// True when a valid session exists.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

/// The role of the current user, or null if unauthenticated.
final currentRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(currentUserProvider)?.role;
});

/// True when a 4-digit PIN has been saved in secure storage.
final hasPinProvider = FutureProvider<bool>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return repo.hasPinSet;
});

/// Notifier for PIN operations — save / verify / clear.
class PinNotifier extends AsyncNotifier<void> {
  late AuthRepository _repo;

  @override
  Future<void> build() async {
    _repo = ref.read(authRepositoryProvider);
  }

  Future<void> savePin(String pin) => _repo.savePin(pin);

  Future<bool> verifyPin(String pin) async {
    return VerifyPinUseCase(_repo)(pin);
  }

  Future<void> clearPin() => _repo.clearPin();
}

final pinNotifierProvider =
    AsyncNotifierProvider<PinNotifier, void>(PinNotifier.new);
