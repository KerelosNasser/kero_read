import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

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
    this.width,
    this.height,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    // Extract single double radius for GlassmorphicContainer
    final double radius = borderRadius.topLeft.x;

    // Handle transparent border or customize width
    final bool isBorderTransparent = border is Border && (border as Border).top.color == Colors.transparent;
    final double borderWidth = isBorderTransparent ? 0.0 : (border is Border ? (border as Border).top.width : 1.0);

    // Set linearGradient using the color parameter
    final baseColor = color ?? Colors.white;
    final containerGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor.withValues(alpha: color != null ? color!.a * 0.40 : 0.12),
        baseColor.withValues(alpha: color != null ? color!.a * 0.15 : 0.04),
      ],
      stops: const [0.1, 1.0],
    );

    final borderGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        isBorderTransparent ? Colors.transparent : Colors.white.withValues(alpha: 0.18),
        isBorderTransparent ? Colors.transparent : Colors.white.withValues(alpha: 0.04),
      ],
    );

    final defaultShadows = boxShadow ?? [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.25),
        blurRadius: 10,
        spreadRadius: 1,
        offset: const Offset(0, 4),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = width ?? (constraints.hasBoundedWidth ? constraints.maxWidth : MediaQuery.of(context).size.width);
        final double h = height ?? (constraints.hasBoundedHeight ? constraints.maxHeight : 100.0);

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: defaultShadows,
          ),
          child: GlassmorphicContainer(
            width: w,
            height: h,
            borderRadius: radius,
            blur: blurX,
            padding: padding as EdgeInsets? ?? EdgeInsets.zero,
            alignment: alignment,
            border: borderWidth,
            linearGradient: containerGradient,
            borderGradient: borderGradient,
            child: child,
          ),
        );
      },
    );
  }
}
