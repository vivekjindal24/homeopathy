import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../shared/models/user_model.dart';

/// Abstract contract — data layer must implement this.
/// Domain layer only ever sees this interface, never Supabase directly.
abstract class AuthRepository {
  // ── Auth operations ────────────────────────────────────────────────────────

  /// Sign in with [email] and [password].
  /// Returns the authenticated [UserModel] on success.
  Future<UserModel> signInWithEmail(String email, String password);

  /// Sign in with [phone] and [password].
  /// Returns the authenticated [UserModel] on success.
  Future<UserModel> signInWithPhone(String phone, String password);

  /// Sign out the current user, clearing all cached credentials.
  Future<void> signOut();

  // ── Session ────────────────────────────────────────────────────────────────

  /// Returns the currently authenticated [UserModel], or null when not signed in.
  Future<UserModel?> getCurrentUser();

  /// Emits an [sb.AuthState] event on every auth state change (sign-in, sign-out,
  /// token refresh, expiry, etc.).
  Stream<sb.AuthState> get authStateStream;

  // ── PIN ────────────────────────────────────────────────────────────────────

  /// Save a 4-digit PIN to secure storage for quick re-login.
  Future<void> savePin(String pin);

  /// Read the saved PIN, or null if not set.
  Future<String?> getPin();

  /// Remove the saved PIN.
  Future<void> clearPin();

  /// Returns true when a PIN has been saved.
  Future<bool> get hasPinSet;
}

