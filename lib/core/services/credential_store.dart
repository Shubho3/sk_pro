import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Credentials saved for the "remember me" prefill on the login page.
class SavedCredentials {
  final String userId;
  final String password;

  const SavedCredentials({required this.userId, required this.password});

  /// Backward-compatibility getter
  String get email => userId;
}

/// Securely stores the login userId/password (encrypted at rest via
/// flutter_secure_storage) so the login form can be pre-filled on the next
/// daily sign-in when the user opted in to "remember me".
class CredentialStore {
  CredentialStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _kUserId = 'saved_user_id';
  static const _kEmail = 'saved_email';
  static const _kPassword = 'saved_password';
  static const _kRemember = 'saved_remember';

  Future<void> save(String userId, String password) async {
    await _storage.write(key: _kUserId, value: userId.trim());
    await _storage.write(key: _kPassword, value: password);
    await _storage.write(key: _kRemember, value: 'true');
  }

  Future<void> updatePassword(String newPassword) async {
    if (await isRemembered) {
      await _storage.write(key: _kPassword, value: newPassword);
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _kUserId);
    await _storage.delete(key: _kEmail);
    await _storage.delete(key: _kPassword);
    await _storage.delete(key: _kRemember);
  }

  Future<bool> get isRemembered async =>
      (await _storage.read(key: _kRemember)) == 'true';

  Future<SavedCredentials?> load() async {
    if (!await isRemembered) return null;
    var userId = await _storage.read(key: _kUserId);
    if (userId == null || userId.isEmpty) {
      userId = await _storage.read(key: _kEmail);
      if (userId != null && userId.contains('@')) {
        userId = userId.split('@').first;
      }
    }
    final password = await _storage.read(key: _kPassword);
    if (userId == null || password == null) return null;
    return SavedCredentials(userId: userId, password: password);
  }
}
