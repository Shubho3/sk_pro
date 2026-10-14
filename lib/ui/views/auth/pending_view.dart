import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_user.dart';
import '../../../core/providers/auth_providers.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/kiosk_scaffold.dart';

/// Shown to a signed-in user whose account is awaiting admin approval, disabled,
/// or missing a valid role/profile.
///
/// Designed with the frosted glass kiosk aesthetic.
class PendingView extends ConsumerWidget {
  const PendingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(appUserProvider).value;
    final isDisabled = appUser?.status == UserStatus.disabled;

    final emblemColor =
        isDisabled ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
    final badgeBg =
        isDisabled ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7);
    final badgeFg =
        isDisabled ? const Color(0xFF991B1B) : const Color(0xFF92400E);
    final badgeText = isDisabled ? 'ACCOUNT DISABLED' : 'APPROVAL PENDING';
    final titleText =
        isDisabled ? 'Account Disabled' : 'Awaiting Verification';
    final descText = isDisabled
        ? 'Your account has been disabled by the administrator. You cannot access terminal actions or record sales until re-enabled.'
        : 'Your account has been registered but is awaiting administrator approval before accessing the terminal. Please check back shortly.';

    return KioskScaffold(
      terminalName: 'Station 01',
      hubName: 'Indore Central Hub',
      body: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: GlassContainer(
          borderRadius: BorderRadius.circular(32),
          blurSigma: 24,
          color: Colors.white.withValues(alpha: 0.88),
          borderColor: Colors.white.withValues(alpha: 0.7),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 54,
              offset: const Offset(0, 20),
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Icon Emblem
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: emblemColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: emblemColor.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isDisabled
                        ? Icons.block_rounded
                        : Icons.hourglass_top_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: badgeFg,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 3. Title
              Text(
                titleText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2530),
                ),
              ),
              const SizedBox(height: 12),

              // 4. Description
              Text(
                descText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5A6474),
                ),
              ),
              const SizedBox(height: 28),

              // 5. Sign Out Button
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: const Color(0xFFF06030),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Return to Sign In'),
                onPressed: () async {
                  await ref.read(sessionServiceProvider).clear();
                  await ref.read(authServiceProvider).signOut();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
