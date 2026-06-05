import 'dart:ui';
import 'package:flutter/material.dart';

class GlassyContainer extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final double blurX;
  final double blurY;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  const GlassyContainer({
    super.key,
    required this.child,
    required this.borderRadius,
    this.blurX = 12.0,
    this.blurY = 12.0,
    this.color,
    this.padding,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = color ?? Colors.white.withValues(alpha: 0.65);
    final defaultBorder = border ?? Border.all(
      color: Colors.white.withValues(alpha: 0.15),
      width: 1.0,
    );
    final defaultShadows = boxShadow ?? [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.3),
        blurRadius: 10,
        spreadRadius: 1,
        offset: const Offset(0, 4),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: defaultColor,
        borderRadius: borderRadius,
        border: defaultBorder,
        boxShadow: defaultShadows,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurX, sigmaY: blurY),
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );
  }
}
