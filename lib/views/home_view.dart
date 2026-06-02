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
      onLongPress: () {
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
      onLongPress: () {
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
