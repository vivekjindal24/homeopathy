import 'package:dartz/dartz.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/models/user_model.dart';
import 'auth_repository.dart';

/// Use-case return type — Either a failure or a success value.
typedef AuthResult<T> = Either<AppException, T>;

// ---------------------------------------------------------------------------
// Sign-in use cases
// ---------------------------------------------------------------------------

/// Signs in with email + password.
class SignInWithEmailUseCase {
  const SignInWithEmailUseCase(this._repo);

  final AuthRepository _repo;

  Future<AuthResult<UserModel>> call(String email, String password) async {
    try {
      final user = await _repo.signInWithEmail(email, password);
      return Right(user);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(AuthException(message: e.toString()));
    }
  }
}

/// Signs in with phone number + password.
class SignInWithPhoneUseCase {
  const SignInWithPhoneUseCase(this._repo);

  final AuthRepository _repo;

  /// [phone] must be in E.164 format, e.g. "+919876543210".
  Future<AuthResult<UserModel>> call(String phone, String password) async {
    try {
      final user = await _repo.signInWithPhone(phone, password);
      return Right(user);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(AuthException(message: e.toString()));
    }
  }
}

// ---------------------------------------------------------------------------
// Sign-out use case
// ---------------------------------------------------------------------------

/// Signs out and clears all session data.
class SignOutUseCase {
  const SignOutUseCase(this._repo);

  final AuthRepository _repo;

  Future<AuthResult<void>> call() async {
    try {
      await _repo.signOut();
      return const Right(null);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(AuthException(message: e.toString()));
    }
  }
}

// ---------------------------------------------------------------------------
// Session use case
// ---------------------------------------------------------------------------

/// Fetches the current user from the active session.
class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._repo);

  final AuthRepository _repo;

  Future<UserModel?> call() => _repo.getCurrentUser();
}

// ---------------------------------------------------------------------------
// PIN use cases
// ---------------------------------------------------------------------------

/// Saves a 4-digit PIN to secure storage.
class SavePinUseCase {
  const SavePinUseCase(this._repo);

  final AuthRepository _repo;

  Future<void> call(String pin) => _repo.savePin(pin);
}

/// Verifies the entered [pin] against the stored PIN.
class VerifyPinUseCase {
  const VerifyPinUseCase(this._repo);

  final AuthRepository _repo;

  Future<bool> call(String pin) async {
    final stored = await _repo.getPin();
    return stored != null && stored == pin;
  }
}

/// Clears the saved PIN.
class ClearPinUseCase {
  const ClearPinUseCase(this._repo);

  final AuthRepository _repo;

  Future<void> call() => _repo.clearPin();
}

