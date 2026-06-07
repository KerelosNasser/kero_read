import 'package:flutter/material.dart';

/// Shared palette — defined once, referenced everywhere (avoids rebuilding on each gesture).
const List<int> kFolderColors = [
  0xFFFFB300, // Amber
  0xFF00BFA5, // Teal
  0xFF29B6F6, // Blue
  0xFFFF5252, // Coral
  0xFFAB47BC, // Purple
  0xFF66BB6A, // Green
];

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
