import 'package:flutter/material.dart';
import 'glass_container.dart';

/// A cinematic kiosk scaffold inspired by modern self-ordering stations.
///
/// Features:
/// * Full-bleed cinematic hero background with multi-layered dark vignettes.
/// * Floating frosted-glass top status pill (pulsing online dot, terminal id).
/// * Centered responsive content slot with floating glass containers.
/// * Floating bottom security & system status info bar.
class KioskScaffold extends StatelessWidget {
  const KioskScaffold({
    super.key,
    required this.body,
    this.terminalName = 'Terminal 01',
    this.hubName = 'Indore Central Hub',
    this.isOnline = true,
    this.showTopBar = true,
    this.showFooter = true,
  });

  final Widget body;
  final String terminalName;
  final String hubName;
  final bool isOnline;
  final bool showTopBar;
  final bool showFooter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0B08),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Optimized cinematic dark gradient background (single-pass for 60fps web rendering)
          Positioned.fill(
            child: Container(
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
          ),

          // 3. Main layout structure
          SafeArea(
            child: Column(
              children: [
                // Top floating pill header
                if (showTopBar) _buildTopBar(context),

                // Center scrollable content
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: body,
                    ),
                  ),
                ),

                // Bottom floating system footer
                if (showFooter) _buildFooter(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 680;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 24,
        vertical: 12,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: GlassContainer(
          borderRadius: BorderRadius.circular(100),
          blurSigma: 14,
          color: Colors.white.withValues(alpha: 0.85),
          borderColor: Colors.white.withValues(alpha: 0.5),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 20,
            vertical: 8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Terminal status indicator
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isOnline
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isOnline
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444))
                                .withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        terminalName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF1E2530),
                        ),
                      ),
                    ),
                    if (!isCompact) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '•',
                          style: TextStyle(color: Color(0xFF8A94A6)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isOnline
                              ? const Color(0xFFD1FAE5)
                              : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          isOnline ? 'ONLINE' : 'OFFLINE',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isOnline
                                ? const Color(0xFF065F46)
                                : const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Right: Hub name and status badge
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isCompact) ...[
                    Text(
                      hubName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A5568),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0EB),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: const Color(0xFFF06030).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_cafe_rounded,
                          size: 13,
                          color: Color(0xFFF06030),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Indore Chai Co.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF06030),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 680;

    return Padding(
      padding: EdgeInsets.only(
        left: isCompact ? 12 : 24,
        right: isCompact ? 12 : 24,
        bottom: 16,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 8,
          spacing: 12,
          children: [
            // Left: System Version
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Indore Chai OS v2.1',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                    shadows: [
                      Shadow(blurRadius: 4, color: Colors.black87),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Text('•', style: TextStyle(color: Colors.white38)),
                SizedBox(width: 8),
                Text(
                  'Authorized Station',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                    shadows: [
                      Shadow(blurRadius: 4, color: Colors.black87),
                    ],
                  ),
                ),
              ],
            ),

            // Center / Right: Security badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    size: 14,
                    color: Color(0xFF34D399),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Secured by Supabase & TLS',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
