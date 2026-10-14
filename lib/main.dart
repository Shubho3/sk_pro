import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_tea_stall/core/config/supabase_config.dart';
import 'package:smart_tea_stall/core/providers/auth_providers.dart';
import 'package:smart_tea_stall/core/providers/supabase_providers.dart';
import 'package:smart_tea_stall/core/services/session_service.dart';
import 'package:smart_tea_stall/core/theme/app_theme.dart';
import 'package:smart_tea_stall/core/utils/router.dart';
import 'package:smart_tea_stall/core/utils/url_strategy.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable clean path-based URLs on web (no-op on mobile/desktop).
  configureUrlStrategy();

  final prefs = await SharedPreferences.getInstance();

  var supabaseReady = false;
  try {
    if (SupabaseConfig.url.isNotEmpty &&
        !SupabaseConfig.url.contains('REPLACE_ME')) {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        // ignore: deprecated_member_use
        anonKey: SupabaseConfig.anonKey,
      );
      supabaseReady = true;
    }
  } catch (_) {
    supabaseReady = false;
  }

  // Daily auto-logout: if the last login was on an earlier calendar day, sign
  // the user out at startup.
  if (supabaseReady) {
    final session = SessionService(prefs);
    if (session.shouldAutoLogout() &&
        Supabase.instance.client.auth.currentUser != null) {
      await Supabase.instance.client.auth.signOut();
      await session.clear();
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        supabaseReadyProvider.overrideWithValue(supabaseReady),
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check the daily auto-logout rule whenever the app is resumed.
    if (state == AppLifecycleState.resumed && ref.read(supabaseReadyProvider)) {
      final session = ref.read(sessionServiceProvider);
      final auth = ref.read(authServiceProvider);
      if (session.shouldAutoLogout() && auth.currentUser != null) {
        session.clear();
        auth.signOut();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Indore Chai Company',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
