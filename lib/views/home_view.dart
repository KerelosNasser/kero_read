import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/color_tokens.dart';
import '../controllers/home_controller.dart';
import '../models/folder_model.dart';
import '../models/pdf_model.dart';
import 'widgets/glassy_container.dart';
import 'widgets/generative_placeholder.dart';
import 'widgets/home/home_app_bar.dart';
import 'widgets/home/hero_continue_reading_card.dart';
import 'widgets/home/home_controls.dart';
import 'widgets/home/pdf_grid_card.dart';
import 'widgets/home/folder_glass_card.dart';
import 'widgets/home/pdf_list_tile.dart';
import 'widgets/home/folder_list_tile.dart';
import 'widgets/home/home_dialogs.dart';

class HomeView extends GetView<HomeController> {
  HomeView({super.key}) {
    Get.put(HomeController());
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.homeGradient,
        ),
        child: Stack(
          children: [
            // Ambient midnight aura in top-right corner
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.midnightAura.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Ambient purple aura in bottom-left corner
            Positioned(
              bottom: 100,
              left: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.purpleAccent.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Main scrollable content
            Positioned.fill(
              child: RefreshIndicator(
                onRefresh: controller.scanDevicePdfs,
                color: Colors.white,
                backgroundColor: const Color(0xFF131622),
                child: Obx(() {
                  final isInsideFolder = controller.currentFolderId.isNotEmpty;
                  final isSearching = controller.isSearchOpen.value &&
                      controller.searchQuery.value.trim().isNotEmpty;
                  final isGrid = controller.isGridView.value;

                  final folders = controller.filteredFolders;
                  final pdfs = controller.filteredPdfs;
                  final devicePdfs = controller.filteredDevicePdfs;

                  final bool hasAnyContent =
                      folders.isNotEmpty || pdfs.isNotEmpty || devicePdfs.isNotEmpty;

                  return ListView(
                    padding: EdgeInsets.fromLTRB(16, topPadding + 76, 16, 100),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    children: [
                      if (!isInsideFolder && !isSearching) ...[
                        HeroContinueReadingCard(controller: controller),
                        const SizedBox(height: 18),
                        HomeQuickActions(controller: controller),
                        const SizedBox(height: 20),
                        HomeFilterRow(controller: controller),
                        const SizedBox(height: 18),
                      ] else if (isInsideFolder) ...[
                        _buildFolderHeader(context),
                        const SizedBox(height: 16),
                      ],
                      if (!hasAnyContent) ...[
                        _buildEmptyState(context, isSearching),
                      ] else if (isGrid) ...[
                        _buildGridContent(context, folders, pdfs, devicePdfs),
                      ] else ...[
                        _buildListContent(context, folders, pdfs, devicePdfs),
                      ],
                    ],
                  );
                }),
              ),
            ),
            // Floating HomeAppBar
            Positioned(
              top: topPadding + 8,
              left: 16,
              right: 16,
              child: HomeAppBar(controller: controller),
            ),
          ],
        ),
      ),
      floatingActionButton: Obx(() {
        final isInsideFolder = controller.currentFolderId.isNotEmpty;
        return GlassyContainer(
          width: 54,
          height: 54,
          borderRadius: BorderRadius.circular(27),
          color: Colors.white.withValues(alpha: 0.12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1.0,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(27),
              onTap: () {
                if (isInsideFolder) {
                  controller.importPdf();
                } else {
                  HomeDialogs.showCreateFolderDialog();
                }
              },
              child: Center(
                child: Icon(
                  isInsideFolder ? Icons.add : Icons.create_new_folder_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFolderHeader(BuildContext context) {
    final folder = controller.folders.firstWhereOrNull(
      (f) => f.id == controller.currentFolderId.value,
    );
    final folderColor = Color(folder?.colorValue ?? 0xFFFFB300);

    return GlassyContainer(
      borderRadius: BorderRadius.circular(20),
      color: folderColor.withValues(alpha: 0.12),
      border: Border.all(
        color: folderColor.withValues(alpha: 0.28),
        width: 1.0,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: folderColor.withValues(alpha: 0.2),
                border: Border.all(
                  color: folderColor.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Icon(Icons.folder_open_rounded, color: folderColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder?.name ?? "Folder",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "${controller.pdfs.length} books",
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => controller.importPdf(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text("Import", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridContent(
    BuildContext context,
    List<FolderModel> folders,
    List<PdfModel> pdfs,
    List<File> devicePdfs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (folders.isNotEmpty) ...[
          _buildSectionHeader("Folders", folders.length),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: folders.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (context, index) => FolderGridCard(folder: folders[index]),
          ),
          const SizedBox(height: 20),
        ],
        if (pdfs.isNotEmpty) ...[
          _buildSectionHeader("Library Books", pdfs.length),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pdfs.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) => PdfGridCard(pdf: pdfs[index]),
          ),
          const SizedBox(height: 20),
        ],
        if (devicePdfs.isNotEmpty) ...[
          _buildSectionHeader("Device Documents", devicePdfs.length),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: devicePdfs.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) => DevicePdfGridCard(file: devicePdfs[index]),
          ),
        ],
      ],
    );
  }

  Widget _buildListContent(
    BuildContext context,
    List<FolderModel> folders,
    List<PdfModel> pdfs,
    List<File> devicePdfs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (folders.isNotEmpty) ...[
          _buildSectionHeader("Folders", folders.length),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: folders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) => FolderListTile(folder: folders[index]),
          ),
          const SizedBox(height: 20),
        ],
        if (pdfs.isNotEmpty) ...[
          _buildSectionHeader("Library Books", pdfs.length),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pdfs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) => PdfListTile(pdf: pdfs[index]),
          ),
          const SizedBox(height: 20),
        ],
        if (devicePdfs.isNotEmpty) ...[
          _buildSectionHeader("Device Documents", devicePdfs.length),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: devicePdfs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) => DevicePdfListTile(file: devicePdfs[index]),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            "$count",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isSearching) {
    if (isSearching) {
      return Padding(
        padding: const EdgeInsets.only(top: 40.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 40,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "No Matching Documents",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Try searching for another keyword or clear the search query.",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.only(top: 20.0),
      child: GenerativePlaceholder(
        title: "Your Library is Empty",
        subtitle: "Import a PDF from your device or scan for documents to get started.",
      ),
    );
  }
}
