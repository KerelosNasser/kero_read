import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/pdf_model.dart';
import '../../reader_view.dart';
import '../glassy_container.dart';
import 'home_bottom_sheets.dart';

class PdfListTile extends StatelessWidget {
  final PdfModel pdf;

  const PdfListTile({super.key, required this.pdf});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.to(() => ReaderView(pdf: pdf));
      },
      onLongPress: () => HomeBottomSheets.showPdfOptions(context, pdf),
      child: GlassyContainer(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: const Icon(Icons.picture_as_pdf, size: 40, color: Colors.white70),
          title: Text(
            pdf.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
