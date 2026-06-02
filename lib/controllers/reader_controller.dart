import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sync_pdf;
import '../models/pdf_model.dart';
import '../services/ocr_service.dart';
import '../controllers/ai_controller.dart';

class ReaderController extends GetxController {
  var isDarkMode = true.obs;
  var isLandscape = false.obs;
  
  late PdfModel currentPdf;
  late PdfViewerController pdfController;
  late PdfTextSearcher textSearcher;
  late TextEditingController searchTextController;

  sync_pdf.PdfDocument? _cachedSyncDoc;
  Future<void>? _initSyncDocFuture;

  // Search Observables
  var isSearchActive = false.obs;
  var currentMatchIndex = 0.obs;
  var totalMatches = 0.obs;
  var isSearching = false.obs;

  @override
  void onInit() {
    super.onInit();
    pdfController = PdfViewerController();
    textSearcher = PdfTextSearcher(pdfController);
    searchTextController = TextEditingController();

    // Listen to the text searcher to update reactive states
    textSearcher.addListener(() {
      isSearching.value = textSearcher.isSearching;
      totalMatches.value = textSearcher.matches.length;
      currentMatchIndex.value = (textSearcher.currentIndex ?? -1) + 1; // 1-indexed for display
    });
  }

  void toggleSearchBar() {
    isSearchActive.value = !isSearchActive.value;
    if (!isSearchActive.value) {
      clearSearch();
    }
  }

  void startSearch(String query) {
    if (query.isEmpty) {
      textSearcher.resetTextSearch();
      return;
    }
    // High performance search utilizing pdfrx caching
    textSearcher.startTextSearch(query, caseInsensitive: true, goToFirstMatch: true);
  }

  void nextMatch() {
    if (textSearcher.hasMatches) {
      textSearcher.goToNextMatch();
    }
  }

  void prevMatch() {
    if (textSearcher.hasMatches) {
      textSearcher.goToPrevMatch();
    }
  }

  void clearSearch() {
    searchTextController.clear();
    textSearcher.resetTextSearch();
  }

  void setPdf(PdfModel pdf) {
    currentPdf = pdf;
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

  void updateLastReadPage(int page) {
    currentPdf.lastReadPage = page;
    currentPdf.save();
  }

  Future<void> performOcr() async {
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    final ocrService = Get.find<OcrService>();
    String? result = await ocrService.performOcr(File(currentPdf.path));
    Get.back(); // close loading

    if (result != null && result.isNotEmpty) {
      Get.find<AiController>().setPageContext(result);
      Get.snackbar('OCR Success', 'Text extracted and sent to AI context.');
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
        debugPrint("Error initializing sync PDF document: $e");
        _initSyncDocFuture = null; // Allow retry on failure
      }
    }();

    await _initSyncDocFuture;
    return _cachedSyncDoc;
  }

  Future<void> extractTextForAi(int pageNumber) async {
    try {
      final doc = await _getOrInitSyncDoc();
      if (doc != null) {
        String text = sync_pdf.PdfTextExtractor(doc).extractText(
          startPageIndex: pageNumber - 1,
          endPageIndex: pageNumber - 1,
        );
        Get.find<AiController>().setPageContext(text);
      }
    } catch (e) {
      debugPrint("Error extracting text: $e");
    }
  }

  @override
  void onClose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    textSearcher.dispose();
    searchTextController.dispose();
    _cachedSyncDoc?.dispose();
    super.onClose();
  }
}
