import 'dart:math';
import 'package:flutter/material.dart';

class FlickeringCandleWidget extends StatefulWidget {
  final double height;
  final bool animate;

  const FlickeringCandleWidget({
    super.key,
    this.height = 45.0,
    this.animate = true,
  });

  @override
  State<FlickeringCandleWidget> createState() => _FlickeringCandleWidgetState();
}

class _FlickeringCandleWidgetState extends State<FlickeringCandleWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final flickerValue = widget.animate
              ? (0.85 + (_random.nextDouble() * 0.28) + (_controller.value * 0.15)).clamp(0.72, 1.28)
              : 1.0;

          return Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // 1. Ambient Radial Flame Glow Halo
              Positioned(
                top: -28,
                child: Container(
                  width: 68 * flickerValue,
                  height: 68 * flickerValue,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFA726).withValues(alpha: 0.38 * flickerValue),
                        const Color(0xFFE27D38).withValues(alpha: 0.18 * flickerValue),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Brass Candlestick Holder Base
              Positioned(
                bottom: -4,
                child: Container(
                  width: 24,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF8A6D3B),
                        Color(0xFFD4AF37),
                        Color(0xFF8A6D3B),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Taper Candle Wax Body Container
              Container(
                width: 16,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(3),
                    bottom: Radius.circular(2),
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFFD9D0BE),
                      Color(0xFFFFFBF0),
                      Color(0xFFC8BCA8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Wax drip detail
                    Positioned(
                      top: 2,
                      left: 2,
                      child: Container(
                        width: 3.5,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBF0).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Flame & Wick
              Positioned(
                top: -13,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Flame
                    Container(
                      width: 8.5 * flickerValue,
                      height: 15 * flickerValue,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                          bottom: Radius.circular(6),
                        ),
                        gradient: const RadialGradient(
                          center: Alignment(0, 0.35),
                          colors: [
                            Color(0xFFFFFFFF),
                            Color(0xFFFFF176),
                            Color(0xFFFFA726),
                            Color(0xFFE27D38),
                          ],
                          stops: [0.0, 0.28, 0.68, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFA726).withValues(alpha: 0.85),
                            blurRadius: 9 * flickerValue,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    // Wick
                    Container(
                      width: 1.5,
                      height: 4,
                      color: Colors.black87,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
