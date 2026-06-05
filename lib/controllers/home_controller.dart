import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../models/folder_model.dart';
import '../models/pdf_model.dart';
import '../services/storage_service.dart';
import '../views/reader_view.dart';
import 'dart:io';

class HomeController extends GetxController {
  static const _intentChannel = MethodChannel('kero_read/intent');

  final StorageService _storage = Get.find<StorageService>();
  late TextEditingController folderNameController;

  var folders = <FolderModel>[].obs;
  var pdfs = <PdfModel>[].obs;
  var currentFolderId = ''.obs;

  // In-memory index grouping PDFs by folder for O(1) reads
  final Map<String, List<PdfModel>> _pdfsByFolder = {};

  @override
  void onInit() {
    super.onInit();
    folderNameController = TextEditingController();
    requestPermissions();
    loadData();
    setupIntentListener();
  }

  void setupIntentListener() {
    // Listen for intents while app is running
    _intentChannel.setMethodCallHandler((call) async {
      if (call.method == "onPdfOpened") {
        final path = call.arguments as String?;
        if (path != null) {
          _handleExternalPdf(path);
        }
      }
    });

    // Check for intent when app cold-starts
    _intentChannel.invokeMethod<String>('getInitialPdf').then((path) {
      if (path != null) {
        _handleExternalPdf(path);
      }
    });
  }

  Future<void> _handleExternalPdf(String path) async {
    final file = File(path);
    if (!await file.exists()) return;

    final int length = await file.length();
    final name = path.split('/').last;

    // Check if the same file is already registered in the library
    PdfModel? existingPdf;
    for (var pdf in _storage.pdfBox.values) {
      final f = File(pdf.path);
      if (f.existsSync()) {
        try {
          if (f.lengthSync() == length && pdf.name == name) {
            existingPdf = pdf;
            break;
          }
        } catch (_) {}
      }
    }

    if (existingPdf != null) {
      if (existingPdf.path != path) {
        try {
          await file.delete();
        } catch (e) {
          debugPrint("Failed to delete duplicate cache file: $e");
        }
      }
      Get.to(() => ReaderView(pdf: existingPdf!));
      return;
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final appDocDir = await getApplicationDocumentsDirectory();
    final permanentPath = '${appDocDir.path}/${id}_$name';

    try {
      await file.copy(permanentPath);
      // Clean up cache file if it was a temp file from sharing
      if (path.contains('/cache/') || path.contains('/tmp/') || path.contains('/file_picker/')) {
        try {
          await file.delete();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint("Error copying external PDF: $e");
    }

    final pdf = PdfModel(
      id: id,
      name: name,
      path: File(permanentPath).existsSync() ? permanentPath : path,
      folderId: '', // Put it in the root folder
      timeAdded: DateTime.now(),
    );

    await _storage.pdfBox.put(pdf.id, pdf);

    // Incremental index update
    _pdfsByFolder.putIfAbsent(pdf.folderId, () => []).add(pdf);
    _updatePdfsList();

    // Navigate immediately
    Get.to(() => ReaderView(pdf: pdf));
  }

  Future<void> requestPermissions() async {
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  }

  @override
  void onClose() {
    folderNameController.dispose();
    super.onClose();
  }

  void loadData() {
    folders.value = _storage.folderBox.values.toList();

    _pdfsByFolder.clear();
    for (var pdf in _storage.pdfBox.values) {
      _pdfsByFolder.putIfAbsent(pdf.folderId, () => []).add(pdf);
    }
    _updatePdfsList();
  }

  void _updatePdfsList() {
    pdfs.value = List<PdfModel>.from(
      _pdfsByFolder[currentFolderId.value] ?? [],
    );
  }

  void openFolder(String folderId) {
    currentFolderId.value = folderId;
    _updatePdfsList();
  }

  void goBack() {
    currentFolderId.value = '';
    _updatePdfsList();
  }

  Future<FolderModel?> createFolderWithName(String name, {int? colorValue}) async {
    if (name.trim().isEmpty) return null;

    final folder = FolderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      createdAt: DateTime.now(),
      colorValue: colorValue,
    );
    await _storage.folderBox.put(folder.id, folder);
    folders.add(folder);
    return folder;
  }

  var selectedColor = 0xFFFFB300.obs;

  Future<void> createFolder() async {
    await createFolderWithName(folderNameController.text, colorValue: selectedColor.value);
    folderNameController.clear();
    selectedColor.value = 0xFFFFB300;
  }

  Future<void> updateFolderColor(String id, int colorValue) async {
    final folder = _storage.folderBox.get(id);
    if (folder != null) {
      folder.colorValue = colorValue;
      await _storage.folderBox.put(folder.id, folder);

      final index = folders.indexWhere((f) => f.id == id);
      if (index != -1) {
        folders[index] = folder;
        folders.refresh();
      }
    }
  }

  Future<void> importPdf() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      String tempPath = result.files.single.path!;
      String name = result.files.single.name;

      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final appDocDir = await getApplicationDocumentsDirectory();
      final permanentPath = '${appDocDir.path}/${id}_$name';

      try {
        final tempFile = File(tempPath);
        await tempFile.copy(permanentPath);
      } catch (e) {
        debugPrint("Error copying imported PDF: $e");
        Get.snackbar('Import Error', 'Failed to copy PDF to permanent storage.');
        return;
      }

      final pdf = PdfModel(
        id: id,
        name: name,
        path: permanentPath,
        folderId: currentFolderId.value,
        timeAdded: DateTime.now(),
      );

      await _storage.pdfBox.put(pdf.id, pdf);

      _pdfsByFolder.putIfAbsent(pdf.folderId, () => []).add(pdf);
      _updatePdfsList();
    }
  }

  Future<void> deletePdf(String id) async {
    final pdf = _storage.pdfBox.get(id);
    if (pdf != null) {
      try {
        final file = File(pdf.path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint("Error deleting PDF file: $e");
      }
      await _storage.pdfBox.delete(id);
      _pdfsByFolder[pdf.folderId]?.removeWhere((p) => p.id == id);
      _updatePdfsList();
    }
  }

  Future<void> deleteFolder(String id) async {
    final toDelete = _pdfsByFolder[id] ?? [];
    final idsToDelete = toDelete.map((p) => p.id).toList();

    await _storage.pdfBox.deleteAll(idsToDelete);
    await _storage.folderBox.delete(id);

    _pdfsByFolder.remove(id);
    folders.removeWhere((f) => f.id == id);
    _updatePdfsList();
  }

  Future<void> movePdf(String id, String targetFolderId) async {
    final pdf = _storage.pdfBox.get(id);
    if (pdf != null) {
      final oldFolderId = pdf.folderId;
      pdf.folderId = targetFolderId;
      await _storage.pdfBox.put(pdf.id, pdf);

      _pdfsByFolder[oldFolderId]?.removeWhere((p) => p.id == id);
      _pdfsByFolder.putIfAbsent(targetFolderId, () => []).add(pdf);
      _updatePdfsList();
    }
  }

  Future<void> renamePdf(String id, String newName) async {
    final pdf = _storage.pdfBox.get(id);
    if (pdf != null && newName.trim().isNotEmpty) {
      pdf.name = newName.trim();
      await _storage.pdfBox.put(pdf.id, pdf);
      _updatePdfsList();
    }
  }

  Future<void> renameFolder(String id, String newName) async {
    final folder = _storage.folderBox.get(id);
    if (folder != null && newName.trim().isNotEmpty) {
      folder.name = newName.trim();
      await _storage.folderBox.put(folder.id, folder);

      final index = folders.indexWhere((f) => f.id == id);
      if (index != -1) {
        folders[index] = folder;
        folders.refresh();
      }
    }
  }
}
