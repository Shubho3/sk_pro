import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_providers.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/shimmer_loading.dart';

/// Full-screen ambient loading view shown while initial user session loads.
/// Features a responsive shimmer loading pulse and safety timeout safeguard.
class LoadingView extends ConsumerStatefulWidget {
  const LoadingView({super.key});

  @override
  ConsumerState<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends ConsumerState<LoadingView> {
  bool _showTimeoutAction = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Safety guard: if session loading takes > 4.5s on slow networks, offer Retry / Sign Out
    _timer = Timer(const Duration(milliseconds: 4500), () {
      if (mounted) setState(() => _showTimeoutAction = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0B08),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Single-pass dark gradient for high performance on web full screen
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1E0E08),
                  Color(0xFF110804),
                  Color(0xFF070402),
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: GlassContainer(
                  borderRadius: BorderRadius.circular(24),
                  blurSigma: 14,
                  color: Colors.white.withValues(alpha: 0.08),
                  borderColor: Colors.white.withValues(alpha: 0.16),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppLogo.mark(height: 52),
                      const SizedBox(height: 18),
                      const Text(
                        'Indore Chai Company',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Opening terminal session...',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Elegant Shimmer Loading Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: SizedBox(
                          height: 4,
                          width: 180,
                          child: Shimmer(
                            baseColor: Colors.white.withValues(alpha: 0.1),
                            highlightColor: const Color(0xFFF06030),
                            duration: const Duration(milliseconds: 1200),
                            child: Container(color: Colors.white),
                          ),
                        ),
                      ),

                      if (_showTimeoutAction) ...[
                        const SizedBox(height: 28),
                        const Text(
                          'Connection taking a moment...',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                ref.invalidate(appUserProvider);
                                ref.invalidate(authStateProvider);
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text('Retry', style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 10),
                            TextButton(
                              onPressed: () => ref.read(authServiceProvider).signOut(),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFFCA5A5),
                              ),
                              child: const Text('Back to Login', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
