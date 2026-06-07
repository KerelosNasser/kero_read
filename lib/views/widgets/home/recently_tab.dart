import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/home_controller.dart';
import '../../../models/folder_model.dart';
import '../../../models/pdf_model.dart';
import '../generative_placeholder.dart';
import 'folder_list_tile.dart';
import 'pdf_list_tile.dart';

class RecentlyTab extends StatelessWidget {
  const RecentlyTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    
    return Obx(() {
      final items = [
        if (controller.currentFolderId.isEmpty) ...controller.folders,
        ...controller.pdfs,
      ];

      if (items.isEmpty) {
        return const GenerativePlaceholder(
          title: "No Books or Folders Found",
          subtitle: "Import a PDF file or create a folder to begin reading.",
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          if (item is FolderModel) {
            return FolderListTile(folder: item);
          } else if (item is PdfModel) {
            return PdfListTile(pdf: item);
          }
          return const SizedBox.shrink();
        },
      );
    });
  }
}
