import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/home_controller.dart';
import '../../../models/folder_model.dart';
import '../../../models/pdf_model.dart';
import '../glassy_container.dart';
import 'shared.dart';

class HomeDialogs {
  static void showGlassyDialog({
    required String title,
    required Widget content,
    required String confirmText,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
  }) {
    Get.dialog(
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: GlassyContainer(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withValues(alpha: 0.1),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    content,
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: onCancel,
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: onConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(confirmText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void showRenameFolderDialog(FolderModel folder) {
    final controller = Get.find<HomeController>();
    final renameController = TextEditingController(text: folder.name);
    showGlassyDialog(
      title: "Rename Folder",
      content: TextField(
        controller: renameController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: "Folder Name",
          hintStyle: TextStyle(color: Colors.white38),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white38),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
        ),
      ),
      confirmText: "Rename",
      onConfirm: () {
        controller.renameFolder(folder.id, renameController.text);
        Get.back();
        renameController.dispose();
      },
      onCancel: () {
        Get.back();
        renameController.dispose();
      },
    );
  }

  static void showRenamePdfDialog(PdfModel pdf) {
    final controller = Get.find<HomeController>();
    final renameController = TextEditingController(text: pdf.name);
    showGlassyDialog(
      title: "Rename PDF",
      content: TextField(
        controller: renameController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: "PDF Name",
          hintStyle: TextStyle(color: Colors.white38),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white38),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
        ),
      ),
      confirmText: "Rename",
      onConfirm: () {
        controller.renamePdf(pdf.id, renameController.text);
        Get.back();
        renameController.dispose();
      },
      onCancel: () {
        Get.back();
        renameController.dispose();
      },
    );
  }

  static void showCreateAndMoveFolderDialog(PdfModel pdf) {
    final controller = Get.find<HomeController>();
    final folderController = TextEditingController();
    showGlassyDialog(
      title: "New Folder",
      content: TextField(
        controller: folderController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: "Folder Name",
          hintStyle: TextStyle(color: Colors.white38),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white38),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
        ),
      ),
      confirmText: "Create & Move",
      onConfirm: () async {
        final name = folderController.text.trim();
        if (name.isNotEmpty) {
          final folder = await controller.createFolderWithName(name);
          if (folder != null) {
            await controller.movePdf(pdf.id, folder.id);
          }
        }
        Get.back();
        folderController.dispose();
      },
      onCancel: () {
        Get.back();
        folderController.dispose();
      },
    );
  }

  static void showCreateFolderDialog() {
    final controller = Get.find<HomeController>();
    Get.dialog(
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: GlassyContainer(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withValues(alpha: 0.1),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "New Folder",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller.folderNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Folder Name",
                        hintStyle: TextStyle(color: Colors.white38),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Select Folder Color",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Obx(
                      () => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: kFolderColors.map((colorVal) {
                          final isSelected = controller.selectedColor.value == colorVal;
                          return GestureDetector(
                            onTap: () {
                              controller.selectedColor.value = colorVal;
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(colorVal),
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: Color(colorVal).withValues(alpha: 0.5),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                ],
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.black,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            controller.folderNameController.clear();
                            controller.selectedColor.value = 0xFFFFB300;
                            Get.back();
                          },
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            controller.createFolder();
                            Get.back();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Create"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
