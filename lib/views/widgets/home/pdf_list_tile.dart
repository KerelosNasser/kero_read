import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/home_controller.dart';
import '../../../models/pdf_model.dart';
import '../../reader_view.dart';
import '../glassy_container.dart';
import 'home_bottom_sheets.dart';

class PdfListTile extends StatelessWidget {
  final PdfModel pdf;

  const PdfListTile({super.key, required this.pdf});

  @override
  Widget build(BuildContext context) {
    final int page = pdf.lastReadPage;

    return GestureDetector(
      onTap: () => Get.to(() => ReaderView(pdf: pdf)),
      onLongPress: () => HomeBottomSheets.showPdfOptions(context, pdf),
      child: GlassyContainer(
        enableBlur: false, // Performance: skip saveLayer in scrollable list
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.13),
          width: 1.0,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Stylized cover thumbnail
              Container(
                width: 44,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blueAccent.withValues(alpha: 0.35),
                      Colors.indigo.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 24,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Title and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pdf.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: page > 0 ? Colors.amberAccent : Colors.white30,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          page > 0 ? "Page $page" : "Unread",
                          style: TextStyle(
                            color: page > 0 ? Colors.amberAccent : Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 18, color: Colors.white54),
                tooltip: "Options",
                onPressed: () => HomeBottomSheets.showPdfOptions(context, pdf),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DevicePdfListTile extends StatelessWidget {
  final File file;

  const DevicePdfListTile({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final name = file.path.split('/').last;

    return GestureDetector(
      onTap: () => controller.openDevicePdf(file),
      onLongPress: () => HomeBottomSheets.showDevicePdfOptions(context, file),
      child: GlassyContainer(
        enableBlur: false, // Performance: skip saveLayer in scrollable list
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.11),
          width: 1.0,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.tealAccent.withValues(alpha: 0.2),
                      Colors.blueGrey.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.description_rounded,
                    size: 24,
                    color: Colors.white60,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      file.parent.path,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 18, color: Colors.white54),
                tooltip: "Options",
                onPressed: () => HomeBottomSheets.showDevicePdfOptions(context, file),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
