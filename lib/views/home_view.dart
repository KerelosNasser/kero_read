import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../models/folder_model.dart';
import '../models/pdf_model.dart';
import 'reader_view.dart';
import 'widgets/generative_placeholder.dart';

class HomeView extends GetView<HomeController> {
  HomeView({super.key}) {
    Get.put(HomeController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.currentFolderId.isEmpty ? 'Kero Read' : 'Folder')),
        leading: Obx(() {
          if (controller.currentFolderId.isNotEmpty) {
            return IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => controller.goBack(),
            );
          }
          return const SizedBox.shrink();
        }),
      ),
      body: Obx(() {
        final items = [
          if (controller.currentFolderId.isEmpty) ...controller.folders,
          ...controller.pdfs
        ];

        if (items.isEmpty) {
          return const GenerativePlaceholder(
            title: "No Books or Folders Found",
            subtitle: "Import a PDF file or create a folder to begin reading.",
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddOptions(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFolderCard(FolderModel folder) {
    return GestureDetector(
      onTap: () => controller.openFolder(folder.id),
      onLongPress: () => _showFolderOptions(Get.context!, folder),
      child: Card(
        color: Colors.blueGrey.shade800,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder, size: 48, color: Colors.amber),
            const SizedBox(height: 8),
            Text(folder.name, style: const TextStyle(fontWeight: FontWeight.bold)),
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
      child: Card(
        color: Colors.grey.shade900,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, size: 48, color: Colors.redAccent),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                pdf.name, 
                style: const TextStyle(fontWeight: FontWeight.bold),
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

  void _showFolderOptions(BuildContext context, FolderModel folder) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  folder.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Rename Folder'),
                onTap: () {
                  Get.back();
                  _showRenameFolderDialog(folder);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Folder'),
                textColor: Colors.red,
                iconColor: Colors.red,
                onTap: () {
                  Get.back();
                  Get.defaultDialog(
                    title: "Delete Folder?",
                    middleText: "This will delete all PDFs inside.",
                    onConfirm: () {
                      controller.deleteFolder(folder.id);
                      Get.back();
                    },
                    textConfirm: "Delete",
                    textCancel: "Cancel",
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRenameFolderDialog(FolderModel folder) {
    final renameController = TextEditingController(text: folder.name);
    Get.defaultDialog(
      title: "Rename Folder",
      content: TextField(
        controller: renameController,
        decoration: const InputDecoration(hintText: "Folder Name"),
      ),
      textConfirm: "Rename",
      onConfirm: () {
        controller.renameFolder(folder.id, renameController.text);
        Get.back();
      },
      textCancel: "Cancel",
    );
  }

  void _showPdfOptions(BuildContext context, PdfModel pdf) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  pdf.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.drive_file_move),
                title: const Text('Move to Folder'),
                onTap: () {
                  Get.back();
                  _showMovePdfSheet(context, pdf);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Rename PDF'),
                onTap: () {
                  Get.back();
                  _showRenamePdfDialog(pdf);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete PDF'),
                textColor: Colors.red,
                iconColor: Colors.red,
                onTap: () {
                  Get.back();
                  Get.defaultDialog(
                    title: "Delete PDF?",
                    onConfirm: () {
                      controller.deletePdf(pdf.id);
                      Get.back();
                    },
                    textConfirm: "Delete",
                    textCancel: "Cancel",
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRenamePdfDialog(PdfModel pdf) {
    final renameController = TextEditingController(text: pdf.name);
    Get.defaultDialog(
      title: "Rename PDF",
      content: TextField(
        controller: renameController,
        decoration: const InputDecoration(hintText: "PDF Name"),
      ),
      textConfirm: "Rename",
      onConfirm: () {
        controller.renamePdf(pdf.id, renameController.text);
        Get.back();
      },
      textCancel: "Cancel",
    );
  }

  void _showMovePdfSheet(BuildContext context, PdfModel pdf) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Move to Folder',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.create_new_folder),
                    title: const Text('Create New Folder & Move'),
                    onTap: () {
                      Get.back();
                      _showCreateAndMoveFolderDialog(pdf);
                    },
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Obx(() {
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: 1 + controller.folders.length,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            final isHome = pdf.folderId.isEmpty;
                            return ListTile(
                              leading: const Icon(Icons.home),
                              title: const Text('Home (Root)'),
                              trailing: isHome ? const Icon(Icons.check, color: Colors.green) : null,
                              onTap: isHome ? null : () {
                                controller.movePdf(pdf.id, '');
                                Get.back();
                              },
                            );
                          }
                          final folder = controller.folders[index - 1];
                          final isCurrent = pdf.folderId == folder.id;
                          return ListTile(
                            leading: const Icon(Icons.folder, color: Colors.amber),
                            title: Text(folder.name),
                            trailing: isCurrent ? const Icon(Icons.check, color: Colors.green) : null,
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
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateAndMoveFolderDialog(PdfModel pdf) {
    final folderController = TextEditingController();
    Get.defaultDialog(
      title: "New Folder",
      content: TextField(
        controller: folderController,
        decoration: const InputDecoration(hintText: "Folder Name"),
      ),
      textConfirm: "Create & Move",
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
      textCancel: "Cancel",
    );
  }


  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.currentFolderId.isEmpty)
                ListTile(
                  leading: const Icon(Icons.create_new_folder),
                  title: const Text('Create Folder'),
                  onTap: () {
                    Get.back();
                    _showCreateFolderDialog();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Import PDF'),
                onTap: () {
                  Get.back();
                  controller.importPdf();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateFolderDialog() {
    Get.defaultDialog(
      title: "New Folder",
      content: TextField(
        controller: controller.folderNameController,
        decoration: const InputDecoration(hintText: "Folder Name"),
      ),
      textConfirm: "Create",
      onConfirm: () {
        controller.createFolder();
        Get.back();
      },
      textCancel: "Cancel",
      onCancel: () {
        controller.folderNameController.clear();
      }
    );
  }
}
