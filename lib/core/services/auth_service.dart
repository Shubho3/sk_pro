import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';

/// Thin wrapper around Supabase Auth + the `public.users` profile record.
class AuthService {
  AuthService(this._supabase);

  final SupabaseClient _supabase;

  /// Internal domain used to map alphanumeric User IDs to Supabase Auth credentials.
  static const String internalDomain = 'chai.app';

  /// Converts an alphanumeric User ID (e.g. "emp101", "admin") or email into an auth email.
  static String normalizeToEmail(String userIdOrEmail) {
    final trimmed = userIdOrEmail.trim().toLowerCase();
    if (trimmed.contains('@')) return trimmed;
    return '$trimmed@$internalDomain';
  }

  AppUser? _cachedUserProfile;

  AppUser? get cachedUserProfile => _cachedUserProfile;

  User? get currentUser => _supabase.auth.currentUser;

  Stream<User?> authStateChanges() =>
      _supabase.auth.onAuthStateChange.map((event) => event.session?.user);

  /// Instantly fetches the user profile from `public.users` via fast REST query.
  Future<AppUser?> getUserProfile(String authId) async {
    try {
      final res = await _supabase
          .from('users')
          .select()
          .eq('auth_id', authId)
          .maybeSingle();
      if (res != null) {
        final profile = AppUser.fromMap(res);
        _cachedUserProfile = profile;
        return profile;
      }
    } catch (_) {}
    return null;
  }

  Future<AuthResponse> signIn(String userIdOrEmail, String password) async {
    final clean = userIdOrEmail.trim().toLowerCase();

    // 1. If input already contains '@', sign in directly
    String resolvedEmail = clean;
    if (!clean.contains('@')) {
      resolvedEmail = '$clean@$internalDomain';
      try {
        final res = await _supabase.rpc('lookup_user_email', params: {'p_user_id': clean});
        if (res != null && res.toString().contains('@')) {
          resolvedEmail = res.toString().trim().toLowerCase();
        }
      } catch (_) {
        // Fallback to internal domain
      }
    }

    // 2. Authenticate with Supabase
    final response = await _supabase.auth.signInWithPassword(
      email: resolvedEmail,
      password: password,
    );

    // 3. Eagerly fetch and cache profile so navigation is immediate
    if (response.user != null) {
      await getUserProfile(response.user!.id);
    }

    return response;
  }

  /// Re-authenticates the current user with [currentPassword] and updates to [newPassword].
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null || user.email == null) {
      throw const AuthException('No user is currently signed in.');
    }

    // Verify current password by signing in again
    await _supabase.auth.signInWithPassword(
      email: user.email!,
      password: currentPassword,
    );

    // Update password
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> signOut() {
    _cachedUserProfile = null;
    return _supabase.auth.signOut();
  }

  /// Streams the profile document for [authId]. Immediately emits the cached or
  /// direct REST profile so the app never hangs waiting for Realtime websocket handshakes.
  Stream<AppUser?> userDocStream(String authId) async* {
    if (_cachedUserProfile != null && _cachedUserProfile!.authId == authId) {
      yield _cachedUserProfile;
    } else {
      final immediateProfile = await getUserProfile(authId);
      if (immediateProfile != null) {
        yield immediateProfile;
      }
    }

    yield* _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('auth_id', authId)
        .map((list) {
          if (list.isEmpty) return null;
          final user = AppUser.fromMap(list.first);
          _cachedUserProfile = user;
          return user;
        });
  }

  /// Maps common [AuthException] codes to friendly messages.
  static String describeError(Object error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid claim') ||
          msg.contains('invalid credential')) {
        return 'Incorrect User ID or password.';
      }
      if (msg.contains('email not confirmed')) {
        return 'Email not confirmed yet. Please contact admin.';
      }
      if (msg.contains('user not found')) {
        return 'User ID not found.';
      }
      if (msg.contains('password should be at least')) {
        return 'Password must be at least 6 characters.';
      }
      return error.message;
    }
    return error.toString().replaceFirst('Exception: ', '');
  }
}
