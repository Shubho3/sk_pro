import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_tea_stall/core/providers/supabase_providers.dart';
import 'package:smart_tea_stall/main.dart';

void main() {
  testWidgets('shows setup screen when Supabase is not configured',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supabaseReadyProvider.overrideWithValue(false),
          sharedPrefsProvider.overrideWithValue(prefs),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Supabase not configured'), findsOneWidget);
  });
}
