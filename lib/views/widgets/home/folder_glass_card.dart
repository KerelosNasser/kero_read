import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/home_controller.dart';
import '../../../models/folder_model.dart';
import '../glassy_container.dart';
import 'home_bottom_sheets.dart';

class FolderGridCard extends StatelessWidget {
  final FolderModel folder;

  const FolderGridCard({super.key, required this.folder});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final folderColor = Color(folder.colorValue ?? 0xFFFFB300);

    return GestureDetector(
      onTap: () => controller.openFolder(folder.id),
      onLongPress: () => HomeBottomSheets.showFolderOptions(context, folder),
      child: GlassyContainer(
        enableBlur: false, // Performance: skip saveLayer in scrollable grid
        borderRadius: BorderRadius.circular(18),
        color: folderColor.withValues(alpha: 0.12),
        border: Border.all(
          color: folderColor.withValues(alpha: 0.28),
          width: 1.0,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: folderColor.withValues(alpha: 0.2),
                      border: Border.all(
                        color: folderColor.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.folder_rounded,
                      size: 20,
                      color: folderColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => HomeBottomSheets.showFolderOptions(context, folder),
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
              const SizedBox(height: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    folder.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Builder(
                    builder: (context) {
                      final count = controller.pdfs
                          .where((p) => p.folderId == folder.id)
                          .length;
                      return Text(
                        count == 1 ? "1 book" : "$count books",
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                        ),
                      );
                    },
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
