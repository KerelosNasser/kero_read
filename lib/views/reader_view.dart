import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfrx/pdfrx.dart';
import '../models/pdf_model.dart';
import '../controllers/reader_controller.dart';
import '../controllers/ai_controller.dart';
import 'widgets/ai_chat_bottom_sheet.dart';

class ReaderView extends StatefulWidget {
  final PdfModel pdf;

  const ReaderView({super.key, required this.pdf});

  @override
  State<ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends State<ReaderView> {
  late final ReaderController controller;

  static const List<double> _invertMatrix = [
    -1, 0, 0, 0, 255,
    0, -1, 0, 0, 255,
    0, 0, -1, 0, 255,
    0, 0, 0, 1, 0,
  ];

  static const List<double> _identityMatrix = [
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          debugPrint("ReaderView body constraints: $constraints");
          return Stack(
            children: [
              const SizedBox.expand(),
              _buildFilteredPdfViewer(),
              _buildAppBarOverlay(context),
              _buildSearchBarOverlay(context),
              _buildPageIndexerOverlay(),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildPdfViewer() {
    return PdfViewer.file(
      widget.pdf.path,
      controller: controller.pdfController,
      initialPageNumber: widget.pdf.lastReadPage,
      params: PdfViewerParams(
        onGeneralTap: (context, pdfController, details) {
          controller.toggleAppBarVisibility();
          return false;
        },
        onInteractionUpdate: (details) {
          final dy = details.focalPointDelta.dy;
          if (dy < -3 && controller.isAppBarVisible.value) {
            controller.isAppBarVisible.value = false;
          } else if (dy > 3 && !controller.isAppBarVisible.value) {
            controller.isAppBarVisible.value = true;
          }
        },
        buildContextMenu: (context, params) {
          return Align(
            alignment: Alignment.topLeft,
            child: AdaptiveTextSelectionToolbar.buttonItems(
              anchors: TextSelectionToolbarAnchors(
                primaryAnchor: params.anchorA,
                secondaryAnchor: params.anchorB,
              ),
              buttonItems: [
                ContextMenuButtonItem(
                  onPressed: () {
                    params.textSelectionDelegate.copyTextSelection();
                    params.textSelectionDelegate.clearTextSelection();
                  },
                  type: ContextMenuButtonType.copy,
                ),
                ContextMenuButtonItem(
                  onPressed: () async {
                    final selectedText = await params.textSelectionDelegate.getSelectedText();
                    params.textSelectionDelegate.clearTextSelection();
                    if (selectedText.isNotEmpty && context.mounted) {
                      AiChatBottomSheet.show(
                        context,
                        initialQuestion: 'Explain: "$selectedText"',
                      );
                    }
                  },
                  label: "Ask Gemini",
                ),
              ],
            ),
          );
        },
        pagePaintCallbacks: [
          (canvas, pageRect, page) {
            final searcher = controller.textSearcher.value;
            if (searcher != null) {
              searcher.pageTextMatchPaintCallback(canvas, pageRect, page);
            }
          },
        ],
        onPageChanged: (page) {
          if (page != null) {
            controller.currentPage.value = page;
            controller.updateLastReadPage(page);
            controller.extractTextForAi(page);
          }
        },
        onViewerReady: (document, pdfController) {
          debugPrint(
            "onViewerReady: Document loaded successfully. Page count: ${document.pages.length}",
          );
          controller.pageCount.value = document.pages.length;
          controller.initTextSearcher();
        },
        errorBannerBuilder: (context, error, stackTrace, documentRef) {
          debugPrint("errorBannerBuilder: Error loading PDF: $error");
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
  }

  Widget _buildFilteredPdfViewer() {
    return Positioned.fill(
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          controller.onScrollNotification(notification);
          return false;
        },
        child: Obx(() {
          return ColorFiltered(
            colorFilter: controller.isDarkMode.value
                ? const ColorFilter.matrix(_invertMatrix)
                : const ColorFilter.matrix(_identityMatrix),
            child: _buildPdfViewer(),
          );
        }),
      ),
    );
  }

  Widget _buildGlassyAppBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            height: 60.0,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              toolbarHeight:
                  60.0, // Match container height to center elements perfectly
              leadingWidth: 10,
              titleSpacing: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  size: 10,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.maybePop(context),
              ),
              title: Text(
                widget.pdf.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, size: 20, color: Colors.white),
                  tooltip: "Search Text",
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  constraints: const BoxConstraints(),
                  onPressed: () => controller.toggleSearchBar(),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.document_scanner,
                    size: 20,
                    color: Colors.white,
                  ),
                  tooltip: "Scan PDF with OCR",
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  constraints: const BoxConstraints(),
                  onPressed: () => controller.performOcr(),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.screen_rotation,
                    size: 20,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  constraints: const BoxConstraints(),
                  onPressed: controller.toggleOrientation,
                ),
                Obx(
                  () => IconButton(
                    icon: Icon(
                      controller.isDarkMode.value
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      size: 20,
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    constraints: const BoxConstraints(),
                    onPressed: controller.toggleDarkMode,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarOverlay(BuildContext context) {
    return Obx(() {
      final bool isAppBarVisible = controller.isAppBarVisible.value;
      final double topPadding = MediaQuery.of(context).padding.top;
      const double appBarHeight = 60.0;
      final double topOffset = topPadding + 5.0;
      debugPrint(
        "ReaderView Appbar Obx build: isAppBarVisible = $isAppBarVisible",
      );
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        top: isAppBarVisible ? topOffset : -appBarHeight - topPadding,
        left: 22,
        right: 22,
        height: appBarHeight,
        child: _buildGlassyAppBar(context),
      );
    });
  }

  Widget _buildSearchBarOverlay(BuildContext context) {
    return Obx(() {
      if (!controller.isSearchActive.value) {
        return const SizedBox.shrink();
      }
      final double topPadding = MediaQuery.of(context).padding.top;
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        top: controller.isAppBarVisible.value
            ? topPadding + 76
            : topPadding + 8,
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
        ),
      );
    });
  }

  Widget _buildPageIndexerOverlay() {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Obx(
        () => AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          offset: controller.isAppBarVisible.value
              ? Offset.zero
              : const Offset(0, 2),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: controller.isAppBarVisible.value ? 1.0 : 0.0,
            child: Center(
              child: controller.pageCount.value == 0
                  ? const SizedBox.shrink()
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 12,
                          sigmaY: 12,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: 0.65,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(
                                alpha: 0.15,
                              ),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            "${controller.currentPage.value} / ${controller.pageCount.value}",
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return Obx(
      () => AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        offset: controller.isAppBarVisible.value
            ? Offset.zero
            : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: controller.isAppBarVisible.value ? 1.0 : 0.0,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () => AiChatBottomSheet.show(context),
                    child: const Center(
                      child: Icon(Icons.chat, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
