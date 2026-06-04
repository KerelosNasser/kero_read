import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/folder_model.dart';
import '../models/pdf_model.dart';
import '../services/storage_service.dart';
import '../views/reader_view.dart';
import 'dart:io';

class HomeController extends GetxController {
  static const platform = MethodChannel('kero_read/intent');

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
    platform.setMethodCallHandler((call) async {
      if (call.method == "onPdfOpened") {
        final path = call.arguments as String?;
        if (path != null) {
          _handleExternalPdf(path);
        }
      }
    });

    // Check for intent when app cold-starts
    platform.invokeMethod<String>('getInitialPdf').then((path) {
      if (path != null) {
        _handleExternalPdf(path);
      }
    });
  }

  Future<void> _handleExternalPdf(String path) async {
    final file = File(path);
    if (!await file.exists()) return;

    // Extract name from path or give a default
    final name = path.split('/').last;

    final pdf = PdfModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      path: path,
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
    pdfs.value = List<PdfModel>.from(_pdfsByFolder[currentFolderId.value] ?? []);
  }

  void openFolder(String folderId) {
    currentFolderId.value = folderId;
    _updatePdfsList();
  }

  void goBack() {
    currentFolderId.value = '';
    _updatePdfsList();
  }

  Future<FolderModel?> createFolderWithName(String name) async {
    if (name.trim().isEmpty) return null;

    final folder = FolderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      createdAt: DateTime.now(),
    );
    await _storage.folderBox.put(folder.id, folder);
    folders.add(folder);
    return folder;
  }

  Future<void> createFolder() async {
    await createFolderWithName(folderNameController.text);
    folderNameController.clear();
  }

  Future<void> importPdf() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      String path = result.files.single.path!;
      String name = result.files.single.name;

      final pdf = PdfModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        path: path,
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

