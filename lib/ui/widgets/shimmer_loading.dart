import 'package:flutter/material.dart';

/// A lightweight, high-performance pure Flutter shimmer effect designed
/// specifically for smooth 60fps web and mobile rendering without external dependencies.
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE2E8F0),
    this.highlightColor = const Color(0xFFF8FAFC),
    this.duration = const Duration(milliseconds: 1400),
  });

  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  static ShimmerState? of(BuildContext context) {
    return context.findAncestorStateOfType<ShimmerState>();
  }

  @override
  State<Shimmer> createState() => ShimmerState();
}

class ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Listenable get listenable => _controller;
  Color get baseColor => widget.baseColor;
  Color get highlightColor => widget.highlightColor;
  double get percent => _controller.value;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final width = bounds.width;
            final offset = (width * 2) * _controller.value - width;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(offset / width),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);
  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

/// A generic shimmer box placeholder with customizable dimensions and rounding.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
    this.color = const Color(0xFFE2E8F0),
  });

  final double? width;
  final double height;
  final double borderRadius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Stat card shimmer skeleton for the Admin Home View.
class ShimmerStatCard extends StatelessWidget {
  const ShimmerStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const ShimmerBox(width: 48, height: 16, borderRadius: 100),
            ],
          ),
          const SizedBox(height: 14),
          const ShimmerBox(width: 60, height: 26, borderRadius: 6),
          const SizedBox(height: 6),
          const ShimmerBox(width: 90, height: 12, borderRadius: 4),
        ],
      ),
    );
  }
}

/// Full Admin Dashboard shimmer skeleton with stats, chart, and management cards.
class ShimmerDashboard extends StatelessWidget {
  const ShimmerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth > 700;
    final isWideCards = screenWidth > 600;

    return Shimmer(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          // Header shimmer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 180, height: 24, borderRadius: 6),
                  SizedBox(height: 6),
                  ShimmerBox(width: 120, height: 12, borderRadius: 4),
                ],
              ),
              ShimmerBox(width: 90, height: 32, borderRadius: 100),
            ],
          ),
          const SizedBox(height: 20),

          // Customer bill card shimmer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2530),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShimmerBox(width: 36, height: 36, borderRadius: 12, color: Color(0xFF334155)),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 130, height: 16, borderRadius: 4, color: Color(0xFF334155)),
                        SizedBox(height: 6),
                        ShimmerBox(width: 220, height: 11, borderRadius: 4, color: Color(0xFF334155)),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ShimmerBox(height: 48, borderRadius: 14, color: Color(0xFF334155)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stat Cards shimmer
          if (isDesktop)
            const Row(
              children: [
                Expanded(child: ShimmerStatCard()),
                SizedBox(width: 14),
                Expanded(child: ShimmerStatCard()),
                SizedBox(width: 14),
                Expanded(child: ShimmerStatCard()),
                SizedBox(width: 14),
                Expanded(child: ShimmerStatCard()),
              ],
            )
          else ...[
            const Row(
              children: [
                Expanded(child: ShimmerStatCard()),
                SizedBox(width: 14),
                Expanded(child: ShimmerStatCard()),
              ],
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Expanded(child: ShimmerStatCard()),
                SizedBox(width: 14),
                Expanded(child: ShimmerStatCard()),
              ],
            ),
          ],
          const SizedBox(height: 24),

          // Chart Card shimmer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 180, height: 16, borderRadius: 4),
                        SizedBox(height: 6),
                        ShimmerBox(width: 140, height: 11, borderRadius: 4),
                      ],
                    ),
                    ShimmerBox(width: 80, height: 22, borderRadius: 100),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (int h in [60, 90, 110, 80, 130, 70, 40])
                      ShimmerBox(width: 22, height: h.toDouble(), borderRadius: 6),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Management Cards shimmer
          const ShimmerBox(width: 160, height: 18, borderRadius: 4),
          const SizedBox(height: 12),
          if (isWideCards)
            const Row(
              children: [
                Expanded(child: ShimmerManagementCard()),
                SizedBox(width: 14),
                Expanded(child: ShimmerManagementCard()),
              ],
            )
          else
            const Column(
              children: [
                ShimmerManagementCard(),
                SizedBox(height: 12),
                ShimmerManagementCard(),
              ],
            ),
        ],
      ),
    );
  }
}

/// Management card shimmer skeleton.
class ShimmerManagementCard extends StatelessWidget {
  const ShimmerManagementCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerBox(width: 40, height: 40, borderRadius: 12),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 130, height: 15, borderRadius: 4),
                  SizedBox(height: 6),
                  ShimmerBox(width: 90, height: 11, borderRadius: 4),
                ],
              ),
            ],
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: ShimmerBox(height: 34, borderRadius: 10)),
              SizedBox(width: 8),
              ShimmerBox(width: 70, height: 34, borderRadius: 10),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shimmer list skeleton for Companies, Employees, or Complaints screens.
class ShimmerList extends StatelessWidget {
  const ShimmerList({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Row(
            children: [
              ShimmerBox(width: 44, height: 44, borderRadius: 14),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 160, height: 15, borderRadius: 4),
                    SizedBox(height: 6),
                    ShimmerBox(width: 100, height: 12, borderRadius: 4),
                    SizedBox(height: 6),
                    ShimmerBox(width: 200, height: 10, borderRadius: 4),
                  ],
                ),
              ),
              SizedBox(width: 10),
              ShimmerBox(width: 60, height: 26, borderRadius: 100),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer grid skeleton for Inventory / Products view.
class ShimmerGrid extends StatelessWidget {
  const ShimmerGrid({super.key, this.itemCount = 8});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 240,
          childAspectRatio: 0.85,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemBuilder: (_, _) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(width: double.infinity, height: 80, borderRadius: 12),
              SizedBox(height: 10),
              ShimmerBox(width: 110, height: 14, borderRadius: 4),
              SizedBox(height: 6),
              ShimmerBox(width: 60, height: 12, borderRadius: 4),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerBox(width: 50, height: 16, borderRadius: 4),
                  ShimmerBox(width: 32, height: 32, borderRadius: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
