// lib/widgets/animated_counter.dart
import 'package:flutter/material.dart';

/// An animated counter widget that smoothly transitions between numbers.
class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final String? prefix;
  final String? suffix;
  final Curve curve;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 1000),
    this.prefix,
    this.suffix,
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: curve,
      builder: (context, animatedValue, child) {
        return Text(
          '${prefix ?? ''}${_formatNumber(animatedValue)}${suffix ?? ''}',
          style: style ?? const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      },
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

/// An animated money counter with formatting
class AnimatedMoneyCounter extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final Duration duration;
  final String currency;
  final Curve curve;

  const AnimatedMoneyCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 1200),
    this.currency = "so'm",
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: value),
      duration: duration,
      curve: curve,
      builder: (context, animatedValue, child) {
        return Text(
          '${_formatMoney(animatedValue)} $currency',
          style: style ?? const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.greenAccent,
          ),
        );
      },
    );
  }

  String _formatMoney(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(2)}M';
    } else if (number >= 1000) {
      final formatted = number.toStringAsFixed(0);
      final result = StringBuffer();
      int count = 0;
      for (int i = formatted.length - 1; i >= 0; i--) {
        count++;
        result.write(formatted[i]);
        if (count % 3 == 0 && i > 0) {
          result.write(' ');
        }
      }
      return result.toString().split('').reversed.join();
    }
    return number.toStringAsFixed(0);
  }
}

/// A stat card with animated counter
class AnimatedStatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final String? suffix;
  final VoidCallback? onTap;
  final bool showTrend;
  final double? trendValue;

  const AnimatedStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = const Color(0xFF4DB6AC),
    this.suffix,
    this.onTap,
    this.showTrend = false,
    this.trendValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          AnimatedCounter(
                            value: value,
                            suffix: suffix,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (showTrend && trendValue != null) ...[
                            const SizedBox(width: 8),
                            _buildTrendIndicator(),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendIndicator() {
    final isPositive = trendValue! >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isPositive ? Colors.greenAccent : Colors.redAccent).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color: isPositive ? Colors.greenAccent : Colors.redAccent,
          ),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}${trendValue!.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}

/// A progress indicator with animation
class AnimatedProgressBar extends StatelessWidget {
  final double value;
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final Duration duration;
  final String? label;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.color,
    this.backgroundColor,
    this.height = 8,
    this.duration = const Duration(milliseconds: 800),
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? const Color(0xFF4DB6AC);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label!,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '${(value * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: effectiveColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: value.clamp(0.0, 1.0)),
            duration: duration,
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: animatedValue,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [effectiveColor.withOpacity(0.8), effectiveColor],
                    ),
                    borderRadius: BorderRadius.circular(height / 2),
                    boxShadow: [
                      BoxShadow(
                        color: effectiveColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
