import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/home_controller.dart';
import '../glassy_container.dart';
import 'home_dialogs.dart';

class HomeQuickActions extends StatelessWidget {
  final HomeController controller;

  const HomeQuickActions({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionPill(
            icon: Icons.add_rounded,
            label: "Import PDF",
            accentColor: Colors.blueAccent,
            onTap: () => controller.importPdf(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionPill(
            icon: Icons.create_new_folder_outlined,
            label: "New Folder",
            accentColor: Colors.amberAccent,
            onTap: () => HomeDialogs.showCreateFolderDialog(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Obx(() {
            final isScanning = controller.isScanningDevice.value;
            return _buildActionPill(
              icon: Icons.sync_rounded,
              label: isScanning ? "Scanning..." : "Scan Files",
              accentColor: Colors.purpleAccent,
              isLoading: isScanning,
              onTap: isScanning ? null : () => controller.scanDevicePdfs(),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required Color accentColor,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return GlassyContainer(
      borderRadius: BorderRadius.circular(16),
      color: Colors.white.withValues(alpha: 0.07),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.14),
        width: 1.0,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 6.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.15),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accentColor,
                          ),
                        )
                      : Icon(icon, size: 16, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeFilterRow extends StatelessWidget {
  final HomeController controller;

  const HomeFilterRow({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentFilter = controller.selectedFilter.value;
      final isGrid = controller.isGridView.value;

      return Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterChip("All", HomeFilter.all, currentFilter),
                  const SizedBox(width: 6),
                  _buildFilterChip("In Progress", HomeFilter.inProgress, currentFilter),
                  const SizedBox(width: 6),
                  _buildFilterChip("Folders", HomeFilter.folders, currentFilter),
                  const SizedBox(width: 6),
                  _buildFilterChip("Device", HomeFilter.device, currentFilter),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Grid / List View Switcher
          GlassyContainer(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
            child: IconButton(
              icon: Icon(
                isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                size: 20,
                color: Colors.white,
              ),
              tooltip: isGrid ? "Switch to List" : "Switch to Grid",
              padding: const EdgeInsets.all(7),
              constraints: const BoxConstraints(),
              onPressed: () => controller.toggleViewMode(),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildFilterChip(String label, HomeFilter filter, HomeFilter activeFilter) {
    final bool isSelected = activeFilter == filter;

    return GestureDetector(
      onTap: () => controller.setFilter(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
