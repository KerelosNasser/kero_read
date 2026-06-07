import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/home_controller.dart';
import '../glassy_container.dart';

class MiniDashboard extends StatelessWidget {
  const MiniDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GlassyContainer(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDashboardStat("Total Books", () => controller.totalBooksCount.value.toString()),
              Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2)),
              _buildDashboardStat("Folders", () => controller.folders.length.toString()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardStat(String label, String Function() valueBuilder) {
    return Column(
      children: [
        Obx(() => Text(
          valueBuilder(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        )),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
