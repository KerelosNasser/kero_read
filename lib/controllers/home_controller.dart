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
    loadData();

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
    if (currentFolderId.isEmpty) {
      pdfs.value = _storage.pdfBox.values
          .where((p) => p.folderId.isEmpty)
          .toList();
    } else {
      pdfs.value = _storage.pdfBox.values
          .where((p) => p.folderId == currentFolderId.value)
          .toList();
    }
  }

  void openFolder(String folderId) {
    currentFolderId.value = folderId;
    loadData();
  }

  void goBack() {
    currentFolderId.value = '';
    loadData();
  }

  Future<void> createFolder() async {
    String name = folderNameController.text;
    if (name.trim().isEmpty) return;

    final folder = FolderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      createdAt: DateTime.now(),
    );
    await _storage.folderBox.put(folder.id, folder);
    folderNameController.clear();
    loadData();
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
      loadData();
    }
  }

  Future<void> deletePdf(String id) async {
    await _storage.pdfBox.delete(id);
    loadData();
  }

  Future<void> deleteFolder(String id) async {
    var toDelete = _storage.pdfBox.values
        .where((p) => p.folderId == id)
        .map((p) => p.id)
        .toList();
    for (var pdfId in toDelete) {
      await _storage.pdfBox.delete(pdfId);
    }
    await _storage.folderBox.delete(id);
    loadData();
  }
}
