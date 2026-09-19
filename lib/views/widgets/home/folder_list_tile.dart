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
        enableBlur: false, // Performance: skip saveLayer in scrollable list
        borderRadius: BorderRadius.circular(18),
        color: folderColor.withValues(alpha: 0.12),
        border: Border.all(
          color: folderColor.withValues(alpha: 0.28),
          width: 1.0,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: folderColor.withValues(alpha: 0.2),
                  border: Border.all(
                    color: folderColor.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.folder_rounded,
                    size: 22,
                    color: folderColor,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Builder(
                      builder: (context) {
                        final count = controller.pdfs
                            .where((p) => p.folderId == folder.id)
                            .length;
                        return Text(
                          count == 1 ? "1 book" : "$count books",
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 18, color: Colors.white54),
                tooltip: "Folder Options",
                onPressed: () => HomeBottomSheets.showFolderOptions(context, folder),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}
