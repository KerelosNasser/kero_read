import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/home_controller.dart';
import '../generative_placeholder.dart';
import 'pdf_list_tile.dart';

class RecentlyTab extends StatelessWidget {
  const RecentlyTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    
    return Obx(() {
      final items = controller.recentPdfs;

      if (items.isEmpty) {
        return const GenerativePlaceholder(
          title: "No Recent Books",
          subtitle: "Import a PDF file from the device tab to begin reading.",
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return PdfListTile(pdf: items[index]);
        },
      );
    });
  }
}
