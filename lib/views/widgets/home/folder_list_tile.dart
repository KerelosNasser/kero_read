import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/folder_model.dart';
import '../../../controllers/home_controller.dart';
import '../glassy_container.dart';
import 'home_bottom_sheets.dart';

class FolderListTile extends StatelessWidget {
  final FolderModel folder;

  const FolderListTile({super.key, required this.folder});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final folderColor = Color(folder.colorValue ?? 0xFFFFB300);

    return GestureDetector(
      onTap: () => controller.openFolder(folder.id),
      onLongPress: () => HomeBottomSheets.showFolderOptions(context, folder),
      child: GlassyContainer(
        borderRadius: BorderRadius.circular(16),
        color: folderColor.withValues(alpha: 0.15),
        border: Border.all(color: folderColor.withValues(alpha: 0.3)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Icon(Icons.folder, size: 40, color: folderColor),
          title: Text(
            folder.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        ),
      ),
    );
  }
}
