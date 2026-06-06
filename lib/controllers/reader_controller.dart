import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sync_pdf;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/pdf_model.dart';
import '../services/ocr_service.dart';
import '../controllers/ai_controller.dart';

class ReaderController extends GetxController {
  var isDarkMode = false.obs;
  var isLandscape = false.obs;

  late PdfModel currentPdf;
  late PdfViewerController pdfController;
  final textSearcher = Rxn<PdfTextSearcher>();
  late TextEditingController searchTextController;

  sync_pdf.PdfDocument? _cachedSyncDoc;
  Future<void>? _initSyncDocFuture;
  Timer? _extractDebounce;

  // UI visibility state
  var isAppBarVisible = true.obs;
  bool _isInitialLoad = true;

  // Search Observables
  var isSearchActive = false.obs;
  var currentMatchIndex = 0.obs;
  var totalMatches = 0.obs;
  var isSearching = false.obs;

  // Page tracking
  var currentPage = 1.obs;
  var pageCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    pdfController = PdfViewerController();
    searchTextController = TextEditingController();

    // Dynamically toggle full screen focus mode
    ever(isAppBarVisible, (bool visible) {
      if (visible) {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    });

    // Reset initial load status after rendering stabilises
    Future.delayed(const Duration(milliseconds: 1500), () {
      _isInitialLoad = false;
    });
  }

  void initTextSearcher() {
    if (textSearcher.value != null) return;
    final searcher = PdfTextSearcher(pdfController);
    searcher.addListener(() {
      isSearching.value = searcher.isSearching;
      totalMatches.value = searcher.matches.length;
      currentMatchIndex.value =
          (searcher.currentIndex ?? -1) + 1; // 1-indexed for display
    });
    textSearcher.value = searcher;
  }

  void toggleSearchBar() {
    isSearchActive.value = !isSearchActive.value;
    if (!isSearchActive.value) {
      clearSearch();
    }
  }

  void startSearch(String query) {
    if (query.isEmpty) {
      textSearcher.value?.resetTextSearch();
      return;
    }
    // High performance search utilizing pdfrx caching
    textSearcher.value?.startTextSearch(
      query,
      caseInsensitive: true,
      goToFirstMatch: true,
    );
  }

  void nextMatch() {
    if (textSearcher.value != null && textSearcher.value!.hasMatches) {
      textSearcher.value!.goToNextMatch();
    }
  }

  void prevMatch() {
    if (textSearcher.value != null && textSearcher.value!.hasMatches) {
      textSearcher.value!.goToPrevMatch();
    }
  }

  void clearSearch() {
    searchTextController.clear();
    textSearcher.value?.resetTextSearch();
  }

  void setPdf(PdfModel pdf) {
    currentPdf = pdf;
    currentPage.value = pdf.lastReadPage;
  }

  void toggleDarkMode() {
    isDarkMode.value = !isDarkMode.value;
  }

  void toggleOrientation() {
    isLandscape.value = !isLandscape.value;
    if (isLandscape.value) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  void fitPageWidth() {
    if (pdfController.isReady) {
      final matrix = pdfController.calcMatrixFitWidthForPage(pageNumber: currentPage.value);
      if (matrix != null) {
        pdfController.goTo(matrix);
      }
    }
  }

  Future<void> savePdf() async {
    try {
      final file = File(currentPdf.path);
      if (!await file.exists()) {
        Get.snackbar(
          'Error',
          'PDF file not found.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return;
      }

      final bytes = await file.readAsBytes();
      final String? outputFile = await FilePicker.saveFile(
        dialogTitle: 'Save PDF As:',
        fileName: currentPdf.name,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (outputFile != null) {
        final newFile = File(outputFile);
        await newFile.writeAsBytes(bytes);
        Get.snackbar(
          'Success',
          'PDF saved successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error saving PDF: $e");
      Get.snackbar(
        'Error',
        'Failed to save PDF: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  void updateLastReadPage(int page) {
    currentPdf.lastReadPage = page;
    currentPdf.save();
  }

  Future<void> performOcr() async {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      // 1. Render the current page as an image
      final Uint8List? imageBytes = await renderCurrentPageAsImage();
      if (imageBytes == null) {
        if (Get.isDialogOpen ?? false) Get.back();
        Get.snackbar(
          'OCR Error',
          'Failed to render current page as image.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return;
      }

      // 2. Save imageBytes to a temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/ocr_page.png');
      await tempFile.writeAsBytes(imageBytes);

      // 3. Call OCR service
      final ocrService = Get.find<OcrService>();
      final String? result = await ocrService.performOcr(tempFile);

      // 4. Clean up temp file
      try {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}

      // 5. Close loading dialog safely
      if (Get.isDialogOpen ?? false) Get.back();

      // 6. Set results
      if (result != null && result.isNotEmpty) {
        Get.find<AiController>().setPageContext(result);
        Get.snackbar(
          'OCR Success',
          'Text extracted and sent to AI context.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'OCR Error',
          'No text extracted from current page.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      // Close loading dialog safely
      if (Get.isDialogOpen ?? false) Get.back();

      if (kDebugMode) debugPrint("OCR Error: $e");
      Get.snackbar(
        'OCR Error',
        'Failed to perform OCR: ${e.toString().replaceAll('Exception: ', '')}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<sync_pdf.PdfDocument?> _getOrInitSyncDoc() async {
    if (_cachedSyncDoc != null) return _cachedSyncDoc;

    _initSyncDocFuture ??= () async {
      try {
        final file = File(currentPdf.path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          _cachedSyncDoc = sync_pdf.PdfDocument(inputBytes: bytes);
        }
      } catch (e) {
        if (kDebugMode) debugPrint("Error initializing sync PDF document: $e");
        _initSyncDocFuture = null; // Allow retry on failure
      }
    }();

    await _initSyncDocFuture;
    return _cachedSyncDoc;
  }

  void extractTextForAi(int pageNumber) {
    // Debounce: only extract after user settles on a page for 600ms
    _extractDebounce?.cancel();
    _extractDebounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        final doc = await _getOrInitSyncDoc();
        if (doc != null) {
          final text = sync_pdf.PdfTextExtractor(doc).extractText(
            startPageIndex: pageNumber - 1,
            endPageIndex: pageNumber - 1,
          );
          Get.find<AiController>().setPageContext(text);
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Error extracting text: $e');
      }
    });
  }

  void toggleAppBarVisibility() {
    isAppBarVisible.value = !isAppBarVisible.value;
  }

  void onScrollNotification(ScrollNotification notification) {
    if (_isInitialLoad) return;

    // Touch drag scroll handling
    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse &&
          isAppBarVisible.value) {
        isAppBarVisible.value = false;
      } else if (notification.direction == ScrollDirection.forward &&
          !isAppBarVisible.value) {
        isAppBarVisible.value = true;
      }
    }

    // Desktop/Windows mouse wheel or trackpad scroll handling
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta;
      if (delta != null && delta.abs() > 10) {
        if (delta > 0 && isAppBarVisible.value) {
          isAppBarVisible.value = false;
        } else if (delta < 0 && !isAppBarVisible.value) {
          isAppBarVisible.value = true;
        }
      }
    }
  }

  Future<Uint8List?> renderCurrentPageAsImage() async {
    try {
      final document = pdfController.document;
      final pageNumber = pdfController.pageNumber;
      if (pageNumber == null) return null;

      final page = document.pages[pageNumber - 1];
      final pageImage = await page.render(
        width: (page.width * 1.5).toInt(),
        height: (page.height * 1.5).toInt(),
      );
      if (pageImage == null) return null;

      final ui.Image uiImage = await pageImage.createImage();
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      uiImage.dispose(); // ← dispose native handle immediately after byte extraction
      pageImage.dispose();

      if (byteData == null) return null;
      return byteData.buffer.asUint8List();
    } catch (e) {
      if (kDebugMode) debugPrint("Error rendering current page: $e");
      return null;
    }
  }

  @override
  void onClose() {
    _extractDebounce?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    textSearcher.value?.dispose();
    searchTextController.dispose();
    _cachedSyncDoc?.dispose();
    super.onClose();
  }
}
