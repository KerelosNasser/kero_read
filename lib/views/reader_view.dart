import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfrx/pdfrx.dart';
import '../models/pdf_model.dart';
import '../controllers/reader_controller.dart';
import '../controllers/ai_controller.dart';
import 'widgets/ai_chat_bottom_sheet.dart';
import 'widgets/glassy_container.dart';
import 'widgets/reader_app_bar.dart';
import 'widgets/reader_search_bar.dart';

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
      body: Stack(
        children: [
          const SizedBox.expand(),
          _buildFilteredPdfViewer(),
          _buildAppBarOverlay(context),
          _buildSearchBarOverlay(context),
          _buildPageIndexerOverlay(),
        ],
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

  Widget _buildAppBarOverlay(BuildContext context) {
    return Obx(() {
      final bool isAppBarVisible = controller.isAppBarVisible.value;
      final double topPadding = MediaQuery.of(context).padding.top;
      const double appBarHeight = 60.0;
      final double topOffset = topPadding + 5.0;
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        top: isAppBarVisible ? topOffset : -appBarHeight - topPadding,
        left: 22,
        right: 22,
        height: appBarHeight,
        child: ReaderAppBar(pdf: widget.pdf, controller: controller),
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
        child: ReaderSearchBar(controller: controller),
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
                  : GlassyContainer(
                      width: 80,
                      height: 32,
                      borderRadius: BorderRadius.circular(12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Center(
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
          child: GlassyContainer(
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
    );
  }
}
