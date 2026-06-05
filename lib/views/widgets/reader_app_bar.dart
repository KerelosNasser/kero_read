import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/reader_controller.dart';
import '../../models/pdf_model.dart';
import 'glassy_container.dart';

class ReaderAppBar extends StatelessWidget {
  final PdfModel pdf;
  final ReaderController controller;

  const ReaderAppBar({
    super.key,
    required this.pdf,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return GlassyContainer(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 60.0,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 60.0, // Match container height to center elements perfectly
          leadingWidth: 10,
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              size: 10,
              color: Colors.white,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            pdf.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, size: 20, color: Colors.white),
              tooltip: "Search Text",
              padding: const EdgeInsets.symmetric(horizontal: 8),
              constraints: const BoxConstraints(),
              onPressed: () => controller.toggleSearchBar(),
            ),
            IconButton(
              icon: const Icon(
                Icons.document_scanner,
                size: 20,
                color: Colors.white,
              ),
              tooltip: "Scan PDF with OCR",
              padding: const EdgeInsets.symmetric(horizontal: 8),
              constraints: const BoxConstraints(),
              onPressed: () => controller.performOcr(),
            ),
            IconButton(
              icon: const Icon(
                Icons.screen_rotation,
                size: 20,
                color: Colors.white,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              constraints: const BoxConstraints(),
              onPressed: controller.toggleOrientation,
            ),
            Obx(
              () => IconButton(
                icon: Icon(
                  controller.isDarkMode.value ? Icons.light_mode : Icons.dark_mode,
                  size: 20,
                  color: Colors.white,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                constraints: const BoxConstraints(),
                onPressed: controller.toggleDarkMode,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
