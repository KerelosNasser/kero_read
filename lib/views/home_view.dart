import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../models/folder_model.dart';
import '../models/pdf_model.dart';
import 'reader_view.dart';
import 'widgets/generative_placeholder.dart';
import 'widgets/glassy_container.dart';

class HomeView extends GetView<HomeController> {
  HomeView({super.key}) {
    Get.put(HomeController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Obx(
          () => Text(
            controller.currentFolderId.isEmpty ? 'Kero Read' : 'Folder',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        leading: Obx(() {
          if (controller.currentFolderId.isNotEmpty) {
            return IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => controller.goBack(),
            );
          }
          return const SizedBox.shrink();
        }),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3B1578), Color(0xFF1C0E4B), Color(0xFF0C2461)],
          ),
        ),
        child: SafeArea(
          child: Obx(() {
            final items = [
              if (controller.currentFolderId.isEmpty) ...controller.folders,
              ...controller.pdfs,
            ];

            if (items.isEmpty) {
              return const GenerativePlaceholder(
                title: "No Books or Folders Found",
                subtitle:
                    "Import a PDF file or create a folder to begin reading.",
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                if (item is FolderModel) {
                  return _buildFolderCard(item);
                } else if (item is PdfModel) {
                  return _buildPdfCard(item);
                }
                return const SizedBox.shrink();
              },
            );
          }),
        ),
      ),
      floatingActionButton: GlassyContainer(
        width: 56,
        height: 56,
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () {
                _showAddOptions(context);
              },
              child: const Center(
                child: Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFolderCard(FolderModel folder) {
    final folderColor = Color(folder.colorValue ?? 0xFFFFB300);
    return GestureDetector(
      onTap: () => controller.openFolder(folder.id),
      onLongPress: () => _showFolderOptions(Get.context!, folder),
      child: GlassyContainer(
        borderRadius: BorderRadius.circular(16),
        color: folderColor.withValues(alpha: 0.25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder, size: 48, color: folderColor),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                folder.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfCard(PdfModel pdf) {
    return GestureDetector(
      onTap: () {
        Get.to(() => ReaderView(pdf: pdf));
      },
      onLongPress: () => _showPdfOptions(Get.context!, pdf),
      child: GlassyContainer(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, size: 48, color: Colors.white70),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                pdf.name,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGlassyDialog({
    required String title,
    required Widget content,
    required String confirmText,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
  }) {
    Get.dialog(
      Center(
        child: GlassyContainer(
          width: 320,
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
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
                  const SizedBox(height: 16),
                  content,
                  const SizedBox(height: 20),
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
    );
  }

  void _showFolderOptions(BuildContext context, FolderModel folder) {
    final List<int> folderColors = [
      0xFFFFB300, // Amber
      0xFF00BFA5, // Teal
      0xFF29B6F6, // Blue
      0xFFFF5252, // Coral
      0xFFAB47BC, // Purple
      0xFF66BB6A, // Green
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final double sheetWidth = MediaQuery.of(context).size.width;
        return GlassyContainer(
          width: sheetWidth,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
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
                // Color Selector Row
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 16.0,
                  ),
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
                        children: folderColors.map((colorVal) {
                          final isCurrent =
                              folder.colorValue == colorVal ||
                              (folder.colorValue == null &&
                                  colorVal == 0xFFFFB300);
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
                                  color: isCurrent
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: isCurrent
                                  ? const Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Colors.black,
                                    )
                                  : null,
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
                  title: const Text(
                    'Rename Folder',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Get.back();
                    _showRenameFolderDialog(folder);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.redAccent),
                  title: const Text(
                    'Delete Folder',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () {
                    Get.back();
                    _showGlassyDialog(
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
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRenameFolderDialog(FolderModel folder) {
    final renameController = TextEditingController(text: folder.name);
    _showGlassyDialog(
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
      },
      onCancel: () => Get.back(),
    );
  }

  void _showPdfOptions(BuildContext context, PdfModel pdf) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final double sheetWidth = MediaQuery.of(context).size.width;
        return GlassyContainer(
          width: sheetWidth,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
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
                  leading: const Icon(
                    Icons.drive_file_move,
                    color: Colors.white70,
                  ),
                  title: const Text(
                    'Move to Folder',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Get.back();
                    _showMovePdfSheet(context, pdf);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.white70),
                  title: const Text(
                    'Rename PDF',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Get.back();
                    _showRenamePdfDialog(pdf);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.redAccent),
                  title: const Text(
                    'Delete PDF',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () {
                    Get.back();
                    _showGlassyDialog(
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
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRenamePdfDialog(PdfModel pdf) {
    final renameController = TextEditingController(text: pdf.name);
    _showGlassyDialog(
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
      },
      onCancel: () => Get.back(),
    );
  }

  void _showMovePdfSheet(BuildContext context, PdfModel pdf) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final double sheetWidth = MediaQuery.of(context).size.width;
        final double sheetHeight = MediaQuery.of(context).size.height * 0.6;
        return GlassyContainer(
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
              return SafeArea(
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
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
                      leading: const Icon(
                        Icons.create_new_folder,
                        color: Colors.white70,
                      ),
                      title: const Text(
                        'Create New Folder & Move',
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Get.back();
                        _showCreateAndMoveFolderDialog(pdf);
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
                                leading: const Icon(
                                  Icons.home,
                                  color: Colors.white70,
                                ),
                                title: const Text(
                                  'Home (Root)',
                                  style: TextStyle(color: Colors.white),
                                ),
                                trailing: isHome
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white70,
                                      )
                                    : null,
                                onTap: isHome
                                    ? null
                                    : () {
                                        controller.movePdf(pdf.id, '');
                                        Get.back();
                                      },
                              );
                            }
                            final folder = controller.folders[index - 1];
                            final isCurrent = pdf.folderId == folder.id;
                            return ListTile(
                              leading: Icon(
                                Icons.folder,
                                color: Color(folder.colorValue ?? 0xFFFFB300),
                              ),
                              title: Text(
                                folder.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              trailing: isCurrent
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white70,
                                    )
                                  : null,
                              onTap: isCurrent
                                  ? null
                                  : () {
                                      controller.movePdf(pdf.id, folder.id);
                                      Get.back();
                                    },
                            );
                          },
                        );
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showCreateAndMoveFolderDialog(PdfModel pdf) {
    final folderController = TextEditingController();
    _showGlassyDialog(
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
      },
      onCancel: () => Get.back(),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final double sheetWidth = MediaQuery.of(context).size.width;
        return GlassyContainer(
          width: sheetWidth,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.currentFolderId.isEmpty)
                  ListTile(
                    leading: const Icon(
                      Icons.create_new_folder,
                      color: Colors.white70,
                    ),
                    title: const Text(
                      'Create Folder',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Get.back();
                      _showCreateFolderDialog();
                    },
                  ),
                ListTile(
                  leading: const Icon(
                    Icons.picture_as_pdf,
                    color: Colors.white70,
                  ),
                  title: const Text(
                    'Import PDF',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Get.back();
                    controller.importPdf();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateFolderDialog() {
    final List<int> folderColors = [
      0xFFFFB300, // Amber
      0xFF00BFA5, // Teal
      0xFF29B6F6, // Blue
      0xFFFF5252, // Coral
      0xFFAB47BC, // Purple
      0xFF66BB6A, // Green
    ];

    Get.dialog(
      Center(
        child: GlassyContainer(
          width: 320,
          height: 280,
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
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
                  const SizedBox(height: 16),
                  const Text(
                    "Select Folder Color",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: folderColors.map((colorVal) {
                        final isSelected =
                            controller.selectedColor.value == colorVal;
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
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: Color(
                                      colorVal,
                                    ).withValues(alpha: 0.5),
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
                  const SizedBox(height: 20),
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
    );
  }
}
