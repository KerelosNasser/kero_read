import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/reader_controller.dart';
import '../../models/pdf_model.dart';
import 'glassy_container.dart';

class ReaderAppBar extends StatelessWidget {
  final PdfModel pdf;
  final ReaderController controller;

  const ReaderAppBar({super.key, required this.pdf, required this.controller});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double appBarWidth =
        screenWidth - 44; // matching Positioned left/right: 22

    return GlassyContainer(
      width: appBarWidth,
      height: 60.0,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 60.0,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final bool isNarrow = width < 450;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Back Button
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 22,
                    color: Colors.white,
                  ),
                  tooltip: "Back",
                  onPressed: () => Navigator.maybePop(context),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                // Title (responsive font and truncation)
                Expanded(
                  child: Text(
                    pdf.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isNarrow ? 14 : 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Actions
                if (isNarrow) ...[
                  // On narrow screen, show Search, Dark mode, and others in PopupMenu
                  IconButton(
                    icon: const Icon(
                      Icons.search,
                      size: 20,
                      color: Colors.white,
                    ),
                    tooltip: "Search Text",
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    onPressed: () => controller.toggleSearchBar(),
                  ),
                  const SizedBox(width: 4),
                  Obx(
                    () => IconButton(
                      icon: Icon(
                        controller.isDarkMode.value
                            ? Icons.light_mode
                            : Icons.dark_mode,
                        size: 20,
                        color: Colors.white,
                      ),
                      tooltip: "Toggle Theme",
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      onPressed: controller.toggleDarkMode,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildPopupMenu(context, isNarrow: true),
                ] else ...[
                  IconButton(
                    icon: const Icon(
                      Icons.search,
                      size: 20,
                      color: Colors.white,
                    ),
                    tooltip: "Search Text",
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    onPressed: () => controller.toggleSearchBar(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.document_scanner,
                      size: 20,
                      color: Colors.white,
                    ),
                    tooltip: "Scan PDF with OCR",
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    onPressed: () => controller.performOcr(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.screen_rotation,
                      size: 20,
                      color: Colors.white,
                    ),
                    tooltip: "Rotate Screen",
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    onPressed: controller.toggleOrientation,
                  ),
                  const SizedBox(width: 8),
                  Obx(
                    () => IconButton(
                      icon: Icon(
                        controller.isDarkMode.value
                            ? Icons.light_mode
                            : Icons.dark_mode,
                        size: 20,
                        color: Colors.white,
                      ),
                      tooltip: "Toggle Theme",
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      onPressed: controller.toggleDarkMode,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildPopupMenu(context, isNarrow: false),
                ],
                const SizedBox(width: 4),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context, {required bool isNarrow}) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
      offset: const Offset(0, 40),
      color: Colors.white.withValues(
        alpha: 0.12,
      ), // translucent white glassy style
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.0,
        ),
      ),
      onSelected: (value) {
        if (value == 'fit') {
          controller.fitPageWidth();
        } else if (value == 'save') {
          controller.savePdf();
        } else if (value == 'ocr') {
          controller.performOcr();
        } else if (value == 'rotate') {
          controller.toggleOrientation();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'fit',
          child: Row(
            children: [
              Icon(Icons.fit_screen, size: 18, color: Colors.white70),
              SizedBox(width: 8),
              Text(
                "Fit Page Width",
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'save',
          child: Row(
            children: [
              Icon(Icons.save, size: 18, color: Colors.white70),
              SizedBox(width: 8),
              Text(
                "Save PDF As",
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
        if (isNarrow) ...[
          const PopupMenuItem<String>(
            value: 'ocr',
            child: Row(
              children: [
                Icon(Icons.document_scanner, size: 18, color: Colors.white70),
                SizedBox(width: 8),
                Text(
                  "Scan PDF with OCR",
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'rotate',
            child: Row(
              children: [
                Icon(Icons.screen_rotation, size: 18, color: Colors.white70),
                SizedBox(width: 8),
                Text(
                  "Rotate Screen",
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
