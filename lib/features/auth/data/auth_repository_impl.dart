import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/errors/app_exception.dart' as app_ex;
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/constants.dart';
import '../../../shared/models/user_model.dart';
import '../domain/auth_repository.dart';

// ---------------------------------------------------------------------------
// Secure storage provider (shared across features)
// ---------------------------------------------------------------------------
final secureStorageProvider = Provider<FlutterSecureStorage>((_) =>
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ));

// ---------------------------------------------------------------------------
// Supabase implementation
// ---------------------------------------------------------------------------

/// Full Supabase implementation of [AuthRepository].
/// Data flows:
///   signInWithEmail / signInWithPhone
///     → Supabase Auth → fetch profile row → cache in SecureStorage → return UserModel
///
///   signOut
///     → Supabase sign-out → clear SecureStorage → clear all Hive boxes
///
///   PIN
///     → stored in FlutterSecureStorage under key 'quick_pin'
class SupabaseAuthRepositoryImpl implements AuthRepository {
  const SupabaseAuthRepositoryImpl(this._client, this._storage);

  final sb.SupabaseClient _client;
  final FlutterSecureStorage _storage;

  static const _pinKey = 'quick_pin';

  // ── Sign-in ──────────────────────────────────────────────────────────────

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw const app_ex.AuthException(
            message: 'Sign-in failed. Please try again.');
      }
      final user = await _fetchProfile(response.user!.id);
      await _cacheUserLocally(user);
      return user;
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }

  @override
  Future<UserModel> signInWithPhone(String phone, String password) async {
    try {
      // Supabase phone+password login uses signInWithPassword with phone
      final response = await _client.auth.signInWithPassword(
        phone: phone,
        password: password,
      );
      if (response.user == null) {
        throw const app_ex.AuthException(
            message: 'Sign-in failed. Please try again.');
      }
      final user = await _fetchProfile(response.user!.id);
      await _cacheUserLocally(user);
      return user;
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }

  // ── Sign-out ──────────────────────────────────────────────────────────────

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();

      // Clear secure storage session keys
      await _storage.delete(key: AppConstants.secureKeyUserId);
      await _storage.delete(key: AppConstants.secureKeyUserRole);
      await _storage.delete(key: AppConstants.secureKeyRefreshToken);
      // Note: PIN is intentionally kept so user can still do quick re-login

      // Clear all Hive caches
      await _clearHiveCache();
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }

  // ── Session ───────────────────────────────────────────────────────────────

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) return null;
      // Token has expired — treat as unauthenticated
      if (session.isExpired) return null;
      return _fetchProfile(session.user.id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<sb.AuthState> get authStateStream => _client.auth.onAuthStateChange;

  // ── PIN ───────────────────────────────────────────────────────────────────

  @override
  Future<void> savePin(String pin) =>
      _storage.write(key: _pinKey, value: pin);

  @override
  Future<String?> getPin() => _storage.read(key: _pinKey);

  @override
  Future<void> clearPin() => _storage.delete(key: _pinKey);

  @override
  Future<bool> get hasPinSet async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null && pin.length == 4;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<UserModel> _fetchProfile(String userId) async {
    final data = await _client
        .from(AppConstants.tableProfiles)
        .select()
        .eq('id', userId)
        .single();

    // Merge auth user fields not stored in profiles
    final authUser = _client.auth.currentUser;
    data['email'] = authUser?.email ?? '';

    return UserModel.fromJson(data);
  }

  Future<void> _cacheUserLocally(UserModel user) async {
    await _storage.write(key: AppConstants.secureKeyUserId, value: user.id);
    await _storage.write(
        key: AppConstants.secureKeyUserRole, value: user.role.dbValue);
  }

  Future<void> _clearHiveCache() async {
    final boxNames = [
      AppConstants.hiveBoxPatients,
      AppConstants.hiveBoxAppointments,
      AppConstants.hiveBoxPrescriptions,
      AppConstants.hiveBoxRemedies,
      AppConstants.hiveBoxSettings,
    ];
    for (final name in boxNames) {
      if (Hive.isBoxOpen(name)) {
        await Hive.box(name).clear();
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

/// Provides the [AuthRepository] implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepositoryImpl(
    sb.Supabase.instance.client,
    ref.read(secureStorageProvider),
  );
});

