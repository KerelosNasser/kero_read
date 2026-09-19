import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/home_controller.dart';
import '../glassy_container.dart';

class HomeAppBar extends StatelessWidget {
  final HomeController controller;

  const HomeAppBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GlassyContainer(
      height: 56.0,
      borderRadius: BorderRadius.circular(28),
      color: Colors.white.withValues(alpha: 0.08),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.18),
        width: 1.0,
      ),
      child: Container(
        height: 56.0,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        child: Obx(() {
          final isInsideFolder = controller.currentFolderId.isNotEmpty;
          final isSearching = controller.isSearchOpen.value;

          if (isSearching) {
            return Row(
              children: [
                const Icon(Icons.search, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller.searchController,
                    autofocus: true,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    cursorColor: Colors.white,
                    decoration: const InputDecoration(
                      hintText: 'Search books, folders...',
                      hintStyle: TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (val) => controller.setSearchQuery(val),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                  onPressed: () => controller.toggleSearch(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            );
          }

          String title = 'Kero Read';
          if (isInsideFolder) {
            final folder = controller.folders.firstWhereOrNull(
              (f) => f.id == controller.currentFolderId.value,
            );
            title = folder?.name ?? 'Folder';
          }

          return Row(
            children: [
              if (isInsideFolder) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  tooltip: 'Back',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  onPressed: () => controller.goBack(),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.folder_open_rounded, color: Colors.amberAccent, size: 18),
                const SizedBox(width: 6),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white, size: 20),
                tooltip: 'Search',
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                onPressed: () => controller.toggleSearch(),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      size: 12,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${controller.totalBooksCount.value}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
