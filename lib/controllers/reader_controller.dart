import 'dart:async';
import 'dart:io';
import 'dart:isolate';
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
import '../models/ocr_result_model.dart';

class ReaderController extends GetxController with WidgetsBindingObserver {
  var isDarkMode = false.obs;
  var isLandscape = false.obs;
  final ocrResults = <int, OcrResult>{}.obs;

  late PdfModel currentPdf;
  late PdfViewerController pdfController;
  final textSearcher = Rxn<PdfTextSearcher>();
  late TextEditingController searchTextController;

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

  // (filePath, text) cache for whole-document extraction.
  // ponytail: single-entry cache; key by path+modified time if docs change.
  (String, String)? _wholeDocCache;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    pdfController = PdfViewerController();
    searchTextController = TextEditingController();

    // Enter immersive reading mode once to prevent OS-level layout recalculations during scrolling
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Reset initial load status after rendering stabilises
    Future.delayed(const Duration(milliseconds: 1500), () {
      _isInitialLoad = false;
    });
  }

  void initTextSearcher() {
    if (textSearcher.value != null) return;
    final searcher = PdfTextSearcher(pdfController);
    searcher.addListener(_onSearcherChanged);
    textSearcher.value = searcher;
  }

  void _onSearcherChanged() {
    final searcher = textSearcher.value;
    if (searcher == null) return;
    isSearching.value = searcher.isSearching;
    totalMatches.value = searcher.matches.length;
    currentMatchIndex.value =
        (searcher.currentIndex ?? -1) + 1; // 1-indexed for display
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
      final OcrResult? result = await ocrService.performOcr(tempFile);

      // 4. Clean up temp file
      try {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}

      // 5. Close loading dialog safely
      if (Get.isDialogOpen ?? false) Get.back();

      // 6. Set results
      if (result != null && result.text.isNotEmpty) {
        ocrResults[currentPage.value] = result;
        Get.find<AiController>().setPageContext(result.text);
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

  String? getMappedOcrText(PdfTextSelectionAnchor? a, PdfTextSelectionAnchor? b) {
    if (a == null || b == null) return null;
    final pageNumber = a.page.pageNumber;
    if (pageNumber != b.page.pageNumber) return null;

    final ocrResult = ocrResults[pageNumber];
    if (ocrResult == null) return null;

    final start = a.index < b.index ? a.index : b.index;
    final end = a.index < b.index ? b.index : a.index;

    final pageText = a.page;
    final selectedRects = <PdfRect>[];
    for (int i = start; i <= end; i++) {
      if (i >= 0 && i < pageText.charRects.length) {
        selectedRects.add(pageText.charRects[i]);
      }
    }

    if (selectedRects.isEmpty) return null;

    final pdfPage = pdfController.document.pages[pageNumber - 1];
    final pageHeight = pdfPage.height;

    final matchedWords = <String>[];

    for (final word in ocrResult.words) {
      const scale = 1.5;
      final pdfLeft = word.left / scale;
      final pdfRight = (word.left + word.width) / scale;
      final pdfTop = pageHeight - (word.top / scale);
      final pdfBottom = pageHeight - ((word.top + word.height) / scale);

      final wordRect = PdfRect(pdfLeft, pdfTop, pdfRight, pdfBottom);

      bool overlapsSelection = false;
      for (final charRect in selectedRects) {
        if (wordRect.overlaps(charRect)) {
          overlapsSelection = true;
          break;
        }
      }

      if (overlapsSelection) {
        matchedWords.add(word.text);
      }
    }

    if (matchedWords.isEmpty) return null;
    return matchedWords.join(' ');
  }

  Future<String?> extractPdfText({bool wholeDocument = false}) async {
    final filePath = currentPdf.path;
    final targetPageNumber = currentPage.value;

    // Skip re-extracting the whole document when the same file was already
    // parsed; extraction is heavy even in the isolate.
    if (wholeDocument) {
      final cached = _wholeDocCache;
      if (cached != null && cached.$1 == filePath) return cached.$2;
    }

    final result = await Isolate.run(() async {
      try {
        final file = File(filePath);
        if (!await file.exists()) return null;
        
        final bytes = await file.readAsBytes();
        final doc = sync_pdf.PdfDocument(inputBytes: bytes);
        final extractor = sync_pdf.PdfTextExtractor(doc);
        
        String extractedText = '';
        if (wholeDocument) {
          extractedText = extractor.extractText();
        } else {
          // Syncfusion is 0-indexed
          final pageIndex = (targetPageNumber - 1).clamp(0, doc.pages.count - 1);
          extractedText = extractor.extractText(
            startPageIndex: pageIndex,
            endPageIndex: pageIndex,
          );
        }
        
        doc.dispose();
        
        // Compress text for whole document
        if (wholeDocument && extractedText.isNotEmpty) {
          extractedText = extractedText.replaceAll(RegExp(r'\s+'), ' ').trim();
          // Safe truncation to ~40k chars to avoid token exhaustion
          if (extractedText.length > 40000) {
            extractedText = "${extractedText.substring(0, 40000)}... [Text truncated due to length limits]";
          }
        }
        
        return extractedText;
      } catch (e) {
        debugPrint('Isolate Error extracting text: $e');
        return null;
      }
    });

    if (wholeDocument && result != null && result.isNotEmpty) {
      _wholeDocCache = (filePath, result);
    }
    return result;
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
      // Raster stays on UI isolate (native pdfrx call); only the PNG encode
      // is offloaded to a background isolate.
      // ponytail: page raster itself is native; review if encode is not the
      // bottleneck on low-end devices.
      final pageImage = await page.render(
        width: page.width.toInt(),
        height: page.height.toInt(),
      );
      if (pageImage == null) return null;

      final ui.Image uiImage = await pageImage.createImage();
      // Fast CPU-side copy of raw RGBA pixels (no encode yet).
      final rawPixels =
          await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
      final width = uiImage.width;
      final height = uiImage.height;
      uiImage.dispose(); // ← dispose native handle immediately after byte extraction
      pageImage.dispose();

      if (rawPixels == null) return null;
      // PNG encode off the UI isolate.
      return await compute(
        _encodePng,
        (
          pixels: rawPixels.buffer.asUint8List(),
          width: width,
          height: height,
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint("Error rendering current page: $e");
      return null;
    }
  }

  /// Top-level PNG encode for [compute]; runs on a background isolate.
  static Future<Uint8List?> _encodePng(
      ({Uint8List pixels, int width, int height}) args) async {
    try {
      final image = await _decodeImageFromPixels(args);
      final ByteData? png =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return png?.buffer.asUint8List();
    } catch (e) {
      if (kDebugMode) debugPrint("Isolate PNG encode failed: $e");
      return null;
    }
  }

  /// dart:ui's [ui.decodeImageFromPixels] is callback-based; bridge to a Future.
  static Future<ui.Image> _decodeImageFromPixels(
      ({Uint8List pixels, int width, int height}) args) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      args.pixels,
      args.width,
      args.height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      currentPdf.save();
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    currentPdf.save(); // Save progress when leaving the reader
    
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    textSearcher.value?.removeListener(_onSearcherChanged);
    textSearcher.value?.dispose();
    _wholeDocCache = null; // release cached whole-doc text
    searchTextController.dispose();
    super.onClose();
  }
}
