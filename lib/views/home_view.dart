import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/color_tokens.dart';
import '../controllers/home_controller.dart';
import 'widgets/glassy_container.dart';
import 'widgets/home/mini_dashboard.dart';
import 'widgets/home/recently_tab.dart';
import 'widgets/home/device_tab.dart';
import 'widgets/home/home_dialogs.dart';
import 'widgets/home/pdf_list_tile.dart';

class HomeView extends GetView<HomeController> {
  HomeView({super.key}) {
    Get.put(HomeController());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
            gradient: AppColors.homeGradient,
          ),
          child: SafeArea(
            child: Obx(() {
              if (controller.currentFolderId.isNotEmpty) {
                return Column(
                  children: [
                    const MiniDashboard(),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: controller.pdfs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => PdfListTile(pdf: controller.pdfs[index]),
                      ),
                    ),
                  ],
                );
              }
              
              return Column(
                children: [
                  const MiniDashboard(),
                  _buildTabBar(),
                  const Expanded(
                    child: TabBarView(
                      children: [
                        RecentlyTab(),
                        DeviceTab(),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
        floatingActionButton: Obx(() {
          if (controller.currentFolderId.isNotEmpty) return const SizedBox.shrink();
          return GlassyContainer(
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
                    HomeDialogs.showCreateFolderDialog();
                  },
                  child: const Center(
                    child: Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withValues(alpha: 0.15),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        tabs: const [
          Tab(text: "Recently"),
          Tab(text: "Device"),
        ],
      ),
    );
  }
}
