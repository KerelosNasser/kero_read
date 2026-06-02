import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfrx/pdfrx.dart';
import '../models/pdf_model.dart';
import '../controllers/reader_controller.dart';
import '../controllers/ai_controller.dart';

class ReaderView extends GetView<ReaderController> {
  final PdfModel pdf;
  
  ReaderView({super.key, required this.pdf}) {
    Get.put(ReaderController()).setPdf(pdf);
    Get.put(AiController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pdf.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: "Search Text",
            onPressed: () => controller.toggleSearchBar(),
          ),
          IconButton(
            icon: const Icon(Icons.document_scanner),
            tooltip: "Scan PDF with OCR",
            onPressed: () => controller.performOcr(),
          ),
          IconButton(
            icon: const Icon(Icons.screen_rotation),
            onPressed: controller.toggleOrientation,
          ),
          Obx(() => IconButton(
            icon: Icon(controller.isDarkMode.value ? Icons.light_mode : Icons.dark_mode),
            onPressed: controller.toggleDarkMode,
          )),
        ],
      ),
      body: Stack(
        children: [
          Obx(() {
            return ColorFiltered(
              colorFilter: controller.isDarkMode.value
                  ? const ColorFilter.matrix([
                      -1,  0,  0, 0, 255,
                       0, -1,  0, 0, 255,
                       0,  0, -1, 0, 255,
                       0,  0,  0, 1,   0,
                    ])
                  : const ColorFilter.mode(Colors.white, BlendMode.dst),
              child: PdfViewer.file(
                pdf.path,
                controller: controller.pdfController,
                initialPageNumber: pdf.lastReadPage,
                params: PdfViewerParams(
                  // High performance O(V) native canvas highlighting
                  pagePaintCallbacks: [
                    controller.textSearcher.pageTextMatchPaintCallback
                  ],
                  onPageChanged: (page) {
                    if (page != null) {
                      controller.updateLastReadPage(page);
                      controller.extractTextForAi(page);
                    }
                  },
                ),
              ),
            );
          }),
          
          // VS Code style Search Bar Overlay
          Obx(() {
            if (!controller.isSearchActive.value) return const SizedBox.shrink();
            return Positioned(
              top: 0,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                color: Theme.of(context).colorScheme.surface,
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        if (controller.isSearching.value && controller.totalMatches.value == 0) {
                          return const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        }
                        if (controller.searchTextController.text.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          '${controller.totalMatches.value > 0 ? controller.currentMatchIndex.value : 0} of ${controller.totalMatches.value}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        );
                      }),
                      const SizedBox(width: 8),
                      // Navigation & Close
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                            onPressed: controller.prevMatch,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down, size: 20),
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
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAiChatBottomSheet(context),
        child: const Icon(Icons.chat),
      ),
    );
  }

  void _showAiChatBottomSheet(BuildContext context) {
    final AiController aiController = Get.find<AiController>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16, right: 16, top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Ask Gemini about this page", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              Flexible(
                child: Obx(() => ListView.builder(
                  shrinkWrap: true,
                  itemCount: aiController.messages.length,
                  itemBuilder: (context, index) {
                    final msg = aiController.messages[index];
                    bool isUser = msg['role'] == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.teal[700] : Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(msg['content'] ?? ''),
                      ),
                    );
                  },
                )),
              ),
              Obx(() => aiController.isLoading.value ? const CircularProgressIndicator() : const SizedBox.shrink()),
              Obx(() => Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: aiController.chatTextController,
                      enabled: !aiController.isLoading.value,
                      decoration: const InputDecoration(hintText: "Type a question..."),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: aiController.isLoading.value
                        ? null
                        : () => aiController.askQuestion(),
                  )
                ],
              )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
