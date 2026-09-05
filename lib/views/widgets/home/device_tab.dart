import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/home_controller.dart';
import '../generative_placeholder.dart';
import '../glassy_container.dart';
import 'folder_list_tile.dart';
import 'home_bottom_sheets.dart';

class DeviceTab extends StatelessWidget {
  const DeviceTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Obx(() {
      final hasContent = controller.folders.isNotEmpty || controller.devicePdfs.isNotEmpty;

      if (controller.isScanningDevice.value && !hasContent) {
        return const Center(child: CircularProgressIndicator(color: Colors.white));
      }

      if (!hasContent) {
        return const GenerativePlaceholder(
          title: "No PDFs Found",
          subtitle: "We couldn't find any PDF files or folders.",
        );
      }

      final int totalCount = controller.folders.length + controller.devicePdfs.length;

      return RefreshIndicator(
        onRefresh: controller.scanDevicePdfs,
        color: Colors.white,
        backgroundColor: Colors.grey[900],
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: totalCount,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index < controller.folders.length) {
              return FolderListTile(folder: controller.folders[index]);
            }
            
            final pdfIndex = index - controller.folders.length;
            final file = controller.devicePdfs[pdfIndex];
            final name = file.path.split('/').last;
            return GestureDetector(
              onTap: () => controller.openDevicePdf(file),
              child: GlassyContainer(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const Icon(Icons.description, size: 40, color: Colors.white54),
                  title: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    file.parent.path,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white70),
                    onPressed: () => HomeBottomSheets.showDevicePdfOptions(context, file),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
