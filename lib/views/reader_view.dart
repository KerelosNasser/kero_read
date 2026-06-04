import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../models/pdf_model.dart';
import '../controllers/reader_controller.dart';
import '../controllers/ai_controller.dart';

class ReaderView extends StatefulWidget {
  final PdfModel pdf;
  
  const ReaderView({super.key, required this.pdf});

  @override
  State<ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends State<ReaderView> {
  late final ReaderController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ReaderController());
    controller.setPdf(widget.pdf);
    Get.put(AiController());
  }

  @override
  void dispose() {
    Get.delete<ReaderController>();
    Get.delete<AiController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. PDF Viewer with scroll listener & tap toggle
          Positioned.fill(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                controller.onScrollNotification(notification);
                return false;
              },
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: controller.toggleAppBarVisibility,
                child: Obx(() {
                  final viewer = PdfViewer.file(
                    widget.pdf.path,
                    controller: controller.pdfController,
                    initialPageNumber: widget.pdf.lastReadPage,
                    params: PdfViewerParams(
                      onGeneralTap: (context, pdfController, details) {
                        controller.toggleAppBarVisibility();
                        return false;
                      },
                      // High performance O(V) native canvas highlighting
                      pagePaintCallbacks: [
                        if (controller.textSearcher.value != null)
                          controller.textSearcher.value!.pageTextMatchPaintCallback
                      ],
                      onPageChanged: (page) {
                        if (page != null) {
                          controller.updateLastReadPage(page);
                          controller.extractTextForAi(page);
                        }
                      },
                      onViewerReady: (document, pdfController) {
                        controller.initTextSearcher();
                      },
                      errorBannerBuilder: (context, error, stackTrace, documentRef) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              "Error loading PDF:\n$error",
                              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                  );

                  return ColorFiltered(
                    colorFilter: controller.isDarkMode.value
                        ? const ColorFilter.matrix([
                            -1,  0,  0, 0, 255,
                             0, -1,  0, 0, 255,
                             0,  0, -1, 0, 255,
                             0,  0,  0, 1,   0,
                          ])
                        : const ColorFilter.matrix([
                             1,  0,  0, 0,   0,
                             0,  1,  0, 0,   0,
                             0,  0,  1, 0,   0,
                             0,  0,  0, 1,   0,
                          ]),
                    child: viewer,
                  );
                }),
              ),
            ),
          ),

          // 2. Glassy Frosted AppBar overlay
          Obx(() {
            final bool isAppBarVisible = controller.isAppBarVisible.value;
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: isAppBarVisible ? 0 : -kToolbarHeight - MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: _buildGlassyAppBar(context),
            );
          }),

          // 3. VS Code style Search Bar Overlay
          Obx(() {
            if (!controller.isSearchActive.value) return const SizedBox.shrink();
            final double topPadding = MediaQuery.of(context).padding.top;
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: controller.isAppBarVisible.value ? topPadding + kToolbarHeight + 8 : topPadding + 8,
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
      floatingActionButton: Obx(() => AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        offset: controller.isAppBarVisible.value ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: controller.isAppBarVisible.value ? 1.0 : 0.0,
          child: FloatingActionButton(
            onPressed: () => _showAiChatBottomSheet(context),
            child: const Icon(Icons.chat),
          ),
        ),
      )),
    );
  }

  Widget _buildGlassyAppBar(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(top: topPadding),
      color: const Color(0xFF1E1E1E),
      child: SizedBox(
        height: kToolbarHeight,
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(widget.pdf.name, overflow: TextOverflow.ellipsis),
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
      ),
    );
  }

  void _showAiChatBottomSheet(BuildContext context) {
    final AiController aiController = Get.find<AiController>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Required for glassy effect
      barrierColor: Colors.black54,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              color: Colors.black.withValues(alpha: 0.75),
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                left: 16, right: 16, top: 10,
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.tealAccent, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Gemini AI Assistant",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 20),
                  
                  // Chat Messages Area
                  Expanded(
                    child: Obx(() {
                      if (aiController.messages.isEmpty) {
                        return Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[600]),
                                const SizedBox(height: 12),
                                Text(
                                  "Ask anything about this page",
                                  style: TextStyle(color: Colors.grey[500], fontSize: 15),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Supports equations, tables, and general concepts.",
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: aiController.suggestionChips.map((chipText) {
                                    return ActionChip(
                                      label: Text(
                                        chipText,
                                        style: const TextStyle(fontSize: 12, color: Colors.tealAccent),
                                      ),
                                      backgroundColor: Colors.teal.withValues(alpha: 0.15),
                                      side: const BorderSide(color: Colors.tealAccent, width: 0.5),
                                      onPressed: () => aiController.askPresetQuestion(chipText),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        controller: aiController.scrollController,
                        itemCount: aiController.messages.length,
                        itemBuilder: (context, index) {
                          final msg = aiController.messages[index];
                          bool isUser = msg['role'] == 'user';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isUser) ...[
                                  Container(
                                    margin: const EdgeInsets.only(right: 8, top: 4),
                                    width: 28,
                                    height: 28,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [Colors.tealAccent, Colors.teal],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: const Icon(Icons.auto_awesome, size: 14, color: Colors.black),
                                  ),
                                ],
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * (isUser ? 0.75 : 0.85),
                                    ),
                                    decoration: BoxDecoration(
                                      color: isUser 
                                          ? Colors.teal[800]!.withValues(alpha: 0.8) 
                                          : Colors.grey[900]!.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(12),
                                        topRight: const Radius.circular(12),
                                        bottomLeft: Radius.circular(isUser ? 12 : 0),
                                        bottomRight: Radius.circular(isUser ? 0 : 12),
                                      ),
                                      border: Border.all(
                                        color: isUser 
                                            ? Colors.tealAccent.withValues(alpha: 0.2) 
                                            : Colors.white12,
                                      ),
                                    ),
                                    child: isUser
                                        ? Text(
                                            msg['content'] ?? '',
                                            style: const TextStyle(color: Colors.white, fontSize: 14),
                                          )
                                        : GptMarkdown(
                                            msg['content'] ?? '',
                                            style: const TextStyle(color: Colors.white, fontSize: 14),
                                          ),
                                  ),
                                ),
                                if (isUser) ...[
                                  Container(
                                    margin: const EdgeInsets.only(left: 8, top: 4),
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey[800],
                                    ),
                                    child: const Icon(Icons.person, size: 14, color: Colors.white),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    }),
                  ),

                  // Loading indicator
                  Obx(() => aiController.isLoading.value 
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.tealAccent),
                              ),
                              const SizedBox(width: 10),
                              Text("Gemini is thinking...", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                            ],
                          ),
                        )
                      : const SizedBox.shrink()),
                  
                  const SizedBox(height: 8),

                  // Input Box
                  Obx(() => Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: aiController.chatTextController,
                            enabled: !aiController.isLoading.value,
                            style: const TextStyle(fontSize: 14, color: Colors.white),
                            minLines: 1,
                            maxLines: 4,
                            keyboardType: TextInputType.multiline,
                            decoration: const InputDecoration(
                              hintText: "Ask about this page...",
                              hintStyle: TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2.0),
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.tealAccent),
                            onPressed: aiController.isLoading.value
                                ? null
                                : () => aiController.askQuestion(),
                          ),
                        )
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
