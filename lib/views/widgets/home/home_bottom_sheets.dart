import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/home_controller.dart';
import '../../../models/folder_model.dart';
import '../../../models/pdf_model.dart';
import '../glassy_container.dart';
import 'shared.dart';
import 'home_dialogs.dart';

class HomeBottomSheets {
  static void showFolderOptions(BuildContext context, FolderModel folder) {
    final controller = Get.find<HomeController>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: GlassyContainer(
            width: sheetWidth,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 10, bottom: 6),
                child: DragHandle(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Text(
                  folder.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Folder Color",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: kFolderColors.map((colorVal) {
                        final isCurrent = folder.colorValue == colorVal || (folder.colorValue == null && colorVal == 0xFFFFB300);
                        return GestureDetector(
                          onTap: () {
                            controller.updateFolderColor(folder.id, colorVal);
                            Get.back();
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(colorVal),
                              border: Border.all(
                                color: isCurrent ? Colors.white : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: isCurrent ? const Icon(Icons.check, size: 18, color: Colors.black) : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white70),
                title: const Text('Rename Folder', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Get.back();
                  HomeDialogs.showRenameFolderDialog(folder);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text('Delete Folder', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Get.back();
                  HomeDialogs.showGlassyDialog(
                    title: "Delete Folder?",
                    content: const Center(
                      child: Text(
                        "This will delete all PDFs inside.",
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    confirmText: "Delete",
                    onConfirm: () {
                      controller.deleteFolder(folder.id);
                      Get.back();
                    },
                    onCancel: () => Get.back(),
                  );
                },
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  static void showPdfOptions(BuildContext context, PdfModel pdf) {
    final controller = Get.find<HomeController>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: GlassyContainer(
            width: sheetWidth,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 10, bottom: 6),
                child: DragHandle(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Text(
                  pdf.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              ListTile(
                leading: const Icon(Icons.drive_file_move, color: Colors.white70),
                title: const Text('Move to Folder', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Get.back();
                  showMovePdfSheet(context, pdf);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white70),
                title: const Text('Rename PDF', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Get.back();
                  HomeDialogs.showRenamePdfDialog(pdf);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text('Delete PDF', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Get.back();
                  HomeDialogs.showGlassyDialog(
                    title: "Delete PDF?",
                    content: const Center(
                      child: Text(
                        "Are you sure you want to delete this PDF?",
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    confirmText: "Delete",
                    onConfirm: () {
                      controller.deletePdf(pdf.id);
                      Get.back();
                    },
                    onCancel: () => Get.back(),
                  );
                },
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  static void showMovePdfSheet(BuildContext context, PdfModel pdf) {
    final controller = Get.find<HomeController>();
    final double screenHeight = MediaQuery.of(context).size.height;
    final int folderCount = controller.folders.length;
    final double contentHeight = 110 + (folderCount + 2) * 56.0;
    final double sheetHeight = contentHeight.clamp(200.0, screenHeight * 0.6);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: GlassyContainer(
            width: sheetWidth,
            height: sheetHeight,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            child: DraggableScrollableSheet(
            initialChildSize: 1.0,
            minChildSize: 0.5,
            maxChildSize: 1.0,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 6),
                    child: DragHandle(),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: Text(
                      'Move to Folder',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  ListTile(
                    leading: const Icon(Icons.create_new_folder, color: Colors.white70),
                    title: const Text('Create New Folder & Move', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Get.back();
                      HomeDialogs.showCreateAndMoveFolderDialog(pdf);
                    },
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  Expanded(
                    child: Obx(() {
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: 1 + controller.folders.length,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            final isHome = pdf.folderId.isEmpty;
                            return ListTile(
                              leading: const Icon(Icons.home, color: Colors.white70),
                              title: const Text('Home (Root)', style: TextStyle(color: Colors.white)),
                              trailing: isHome ? const Icon(Icons.check, color: Colors.white70) : null,
                              onTap: isHome ? null : () {
                                controller.movePdf(pdf.id, '');
                                Get.back();
                              },
                            );
                          }
                          final folder = controller.folders[index - 1];
                          final isCurrent = pdf.folderId == folder.id;
                          return ListTile(
                            leading: Icon(Icons.folder, color: Color(folder.colorValue ?? 0xFFFFB300)),
                            title: Text(folder.name, style: const TextStyle(color: Colors.white)),
                            trailing: isCurrent ? const Icon(Icons.check, color: Colors.white70) : null,
                            onTap: isCurrent ? null : () {
                              controller.movePdf(pdf.id, folder.id);
                              Get.back();
                            },
                          );
                        },
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  static void showAddOptions(BuildContext context) {
    final controller = Get.find<HomeController>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: GlassyContainer(
            width: sheetWidth,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 10, bottom: 6),
                child: DragHandle(),
              ),
              if (controller.currentFolderId.isEmpty)
                ListTile(
                  leading: const Icon(Icons.create_new_folder, color: Colors.white70),
                  title: const Text('Create Folder', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Get.back();
                    HomeDialogs.showCreateFolderDialog();
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
