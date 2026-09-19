import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/home_controller.dart';
import '../../../models/pdf_model.dart';
import '../../reader_view.dart';
import '../glassy_container.dart';
import 'home_bottom_sheets.dart';

class PdfGridCard extends StatelessWidget {
  final PdfModel pdf;

  const PdfGridCard({super.key, required this.pdf});

  @override
  Widget build(BuildContext context) {
    final int page = pdf.lastReadPage;

    return GestureDetector(
      onTap: () => Get.to(() => ReaderView(pdf: pdf)),
      onLongPress: () => HomeBottomSheets.showPdfOptions(context, pdf),
      child: GlassyContainer(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.07),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: 1.0,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover area with gradient & page badge
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blueAccent.withValues(alpha: 0.35),
                        Colors.indigo.withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 38,
                          color: Colors.white70,
                        ),
                      ),
                      if (page > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              "p. $page",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Title
              Text(
                pdf.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: -0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    page > 0 ? "Reading" : "Unread",
                    style: TextStyle(
                      color: page > 0 ? Colors.amberAccent : Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => HomeBottomSheets.showPdfOptions(context, pdf),
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Icon(
                        Icons.more_vert,
                        size: 16,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DevicePdfGridCard extends StatelessWidget {
  final File file;

  const DevicePdfGridCard({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final name = file.path.split('/').last;

    return GestureDetector(
      onTap: () => controller.openDevicePdf(file),
      onLongPress: () => HomeBottomSheets.showDevicePdfOptions(context, file),
      child: GlassyContainer(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.0,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.tealAccent.withValues(alpha: 0.2),
                        Colors.blueGrey.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.description_rounded,
                      size: 38,
                      color: Colors.white60,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: -0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Device File",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => HomeBottomSheets.showDevicePdfOptions(context, file),
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Icon(
                        Icons.more_vert,
                        size: 16,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
