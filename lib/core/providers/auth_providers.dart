import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/credential_store.dart';
import '../services/session_service.dart';
import 'supabase_providers.dart';

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(supabaseClientProvider)),
);

final sessionServiceProvider = Provider<SessionService>(
  (ref) => SessionService(ref.watch(sharedPrefsProvider)),
);

final credentialStoreProvider = Provider<CredentialStore>(
  (ref) => CredentialStore(ref.watch(secureStorageProvider)),
);

/// Emits the raw Supabase [User] (or null) whenever auth state changes.
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges(),
);

/// Emits the signed-in user's [AppUser] profile (role, status, etc.), or null
/// when signed out / no profile record exists.
final appUserProvider = StreamProvider<AppUser?>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) return Stream<AppUser?>.value(null);
  return ref.watch(authServiceProvider).userDocStream(authUser.id);
});
