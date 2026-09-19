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
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final bool enableBlur;

  const GlassyContainer({
    super.key,
    required this.child,
    required this.borderRadius,
    this.blurX = 14.0,
    this.blurY = 14.0,
    this.color,
    this.padding,
    this.border,
    this.boxShadow,
    this.width,
    this.height,
    this.alignment,
    this.enableBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? Colors.white;
    final containerGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor.withValues(alpha: color != null ? color!.a * 0.40 : 0.10),
        baseColor.withValues(alpha: color != null ? color!.a * 0.15 : 0.04),
      ],
      stops: const [0.1, 1.0],
    );

    final isBorderTransparent =
        border is Border && (border as Border).top.color == Colors.transparent;
    final defaultBorder = isBorderTransparent
        ? null
        : (border ??
            Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.0,
            ));

    final defaultShadows = boxShadow ?? [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.20),
        blurRadius: 12,
        spreadRadius: 0,
        offset: const Offset(0, 4),
      ),
    ];

    final Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      alignment: alignment,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: containerGradient,
        border: defaultBorder,
      ),
      child: child,
    );

    // High-performance path for repeated scroll items:
    // Skips expensive BackdropFilter saveLayers to eliminate GPU/raster jank.
    if (!enableBlur) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: defaultShadows,
        ),
        child: content,
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: defaultShadows,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurX, sigmaY: blurY),
          child: content,
        ),
      ),
    );
  }
}
