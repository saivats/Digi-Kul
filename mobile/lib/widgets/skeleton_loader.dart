import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../core/theme/app_colors.dart';

class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  factory SkeletonLoader.card() => const SkeletonLoader(height: 120);

  factory SkeletonLoader.listTile() => const SkeletonLoader(height: 72);

  factory SkeletonLoader.circle({double size = 48}) => SkeletonLoader(
        width: size,
        height: size,
        borderRadius: size / 2,
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : AppColors.shimmerBase,
      highlightColor: isDark ? Colors.grey[700]! : AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class SkeletonListLoader extends StatelessWidget {
  const SkeletonListLoader({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SkeletonLoader.circle(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(
                      width: MediaQuery.of(context).size.width * 0.6,
                    ),
                    const SizedBox(height: 8),
                    SkeletonLoader(
                      width: MediaQuery.of(context).size.width * 0.4,
                      height: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SkeletonHorizontalCards extends StatelessWidget {
  const SkeletonHorizontalCards({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => const SkeletonLoader(width: 260, height: 140),
      ),
    );
  }
}

class SkeletonStatsRow extends StatelessWidget {
  const SkeletonStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(
          3,
          (index) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: index == 0 ? 0 : 8),
              child: const SkeletonLoader(height: 90, borderRadius: 12),
            ),
          ),
        ),
      ),
    );
  }
}

class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: itemCount,
        itemBuilder: (_, __) => const SkeletonLoader(
          height: double.infinity,
          borderRadius: 12,
        ),
      ),
    );
  }
}

class SkeletonBanner extends StatelessWidget {
  const SkeletonBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: SkeletonLoader(height: 100, borderRadius: 16),
    );
  }
}

