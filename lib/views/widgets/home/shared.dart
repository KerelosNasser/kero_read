import 'package:flutter/material.dart';

/// Shared palette — defined once, referenced everywhere (avoids rebuilding on each gesture).
const List<int> kFolderColors = [
  0xFFFFB300, // Amber
  0xFF00BFA5, // Teal
  0xFF29B6F6, // Blue
  0xFFFF5252, // Coral
  0xFFC98A2D, // Amber bronze (was purple)
  0xFF66BB6A, // Green
];

/// Legacy purple folder color mapped to its amber-bronze counterpart so
/// folders created before the theme change still render in-palette.
const int kLegacyPurpleColor = 0xFFAB47BC;
const int kPurpleFallbackColor = 0xFFC98A2D;

/// Resolve a stored folder color, mapping the legacy purple to its fallback.
int kResolveFolderColor(int? value) =>
    value == kLegacyPurpleColor ? kPurpleFallbackColor : (value ?? 0xFFFFB300);

/// Reusable styled drag handle pill.
class DragHandle extends StatelessWidget {
  const DragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
