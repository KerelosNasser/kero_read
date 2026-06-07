import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import 'widgets/glassy_container.dart';
import 'widgets/home/mini_dashboard.dart';
import 'widgets/home/recently_tab.dart';
import 'widgets/home/device_tab.dart';
import 'widgets/home/home_bottom_sheets.dart';

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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3B1578), Color(0xFF1C0E4B), Color(0xFF0C2461)],
            ),
          ),
          child: SafeArea(
            child: Column(
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
            ),
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
                  HomeBottomSheets.showAddOptions(context);
                },
                child: const Center(
                  child: Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
        ),
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
