import 'package:flutter/material.dart';

import '../../widgets/app_logo.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/kiosk_scaffold.dart';

/// Shown when Firebase has not been configured yet (placeholder
/// firebase_options.dart). Guides the developer to run `flutterfire configure`.
///
/// Designed with the frosted glass kiosk aesthetic.
class SetupRequiredView extends StatelessWidget {
  const SetupRequiredView({super.key});

  @override
  Widget build(BuildContext context) {
    return KioskScaffold(
      terminalName: 'Initial Setup',
      hubName: 'Configuration Mode',
      isOnline: false,
      body: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: GlassContainer(
          borderRadius: BorderRadius.circular(32),
          blurSigma: 24,
          color: Colors.white.withValues(alpha: 0.9),
          borderColor: Colors.white.withValues(alpha: 0.7),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 54,
              offset: const Offset(0, 20),
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    const AppLogo.full(height: 90),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF06030).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Text(
                        'CLOUD INITIALIZATION REQUIRED',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Color(0xFFF06030),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Supabase not configured',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E2530),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Connect your Supabase project to enable authentication, live '
                      'inventories, and order dispatching.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5A6474),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _Step(
                number: '1',
                title: 'Set Supabase URL & Anon Key',
                text: 'Add credentials to lib/core/config/supabase_config.dart',
              ),
              _Step(
                number: '2',
                title: 'Enable Database & Tables',
                text: 'Ensure PostgreSQL tables and RLS are active in Supabase.',
              ),
              _Step(
                number: '3',
                title: 'Enable Supabase Auth',
                text: 'Enable Email provider in your Supabase project console.',
              ),
              _Step(
                number: '4',
                title: 'Hot restart application',
                text: 'This screen disappears automatically once credentials are live.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String title;
  final String text;

  const _Step({
    required this.number,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFF06030),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF1E2530),
                  ),
                ),
                const SizedBox(height: 3),
                SelectableText(
                  text,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    color: Color(0xFF475569),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
