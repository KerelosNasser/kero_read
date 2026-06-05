import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/reader_controller.dart';

class ReaderSearchBar extends StatelessWidget {
  final ReaderController controller;

  const ReaderSearchBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(8),
        bottomRight: Radius.circular(8),
      ),
      color: Theme.of(context).colorScheme.surface,
      child: Container(
        width: MediaQuery.of(context).size.width < 360
            ? (MediaQuery.of(context).size.width - 32)
            : 320.0,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller.searchTextController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Find",
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: controller.startSearch,
              ),
            ),
            // Match Counter
            Obx(() {
              if (controller.isSearching.value &&
                  controller.totalMatches.value == 0) {
                return const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                );
              }
              if (controller.searchTextController.text.isEmpty) {
                return const SizedBox.shrink();
              }
              return Text(
                '${controller.totalMatches.value > 0 ? controller.currentMatchIndex.value : 0} of ${controller.totalMatches.value}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              );
            }),
            const SizedBox(width: 8),
            // Navigation & Close
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.keyboard_arrow_up,
                    size: 20,
                  ),
                  onPressed: controller.prevMatch,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                  ),
                  onPressed: controller.nextMatch,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: controller.toggleSearchBar,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
