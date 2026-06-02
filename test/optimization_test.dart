import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kero_read/controllers/home_controller.dart';
import 'package:kero_read/models/folder_model.dart';
import 'package:kero_read/models/pdf_model.dart';
import 'package:kero_read/services/storage_service.dart';

void main() {
  late Directory tempDir;
  late StorageService storageService;

  setUp(() async {
    // Clean up GetX dependencies
    Get.reset();

    // Setup temporary directory for Hive inside workspace
    tempDir = Directory('${Directory.current.path}/test_temp');
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
    await tempDir.create(recursive: true);

    // Initialize Hive for raw Dart test
    Hive.init(tempDir.path);
    
    // Register adapters if not registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(FolderModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(PdfModelAdapter());
    }

    // Mock/Setup storage service
    storageService = StorageService();
    storageService.folderBox = await Hive.openBox<FolderModel>('folders');
    storageService.pdfBox = await Hive.openBox<PdfModel>('pdfs');
    Get.put<StorageService>(storageService);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('HomeController - Index grouping and navigation complexity tests', () async {
    final controller = HomeController();
    
    // Add mock folders
    final f1 = FolderModel(id: 'folder1', name: 'Folder 1', createdAt: DateTime.now());
    final f2 = FolderModel(id: 'folder2', name: 'Folder 2', createdAt: DateTime.now());
    await storageService.folderBox.put(f1.id, f1);
    await storageService.folderBox.put(f2.id, f2);

    // Add mock PDFs
    final pdf1 = PdfModel(
      id: 'pdf1',
      name: 'Doc 1.pdf',
      path: '/path/doc1.pdf',
      folderId: '',
      timeAdded: DateTime.now(),
    );
    final pdf2 = PdfModel(
      id: 'pdf2',
      name: 'Doc 2.pdf',
      path: '/path/doc2.pdf',
      folderId: 'folder1',
      timeAdded: DateTime.now(),
    );
    final pdf3 = PdfModel(
      id: 'pdf3',
      name: 'Doc 3.pdf',
      path: '/path/doc3.pdf',
      folderId: 'folder1',
      timeAdded: DateTime.now(),
    );
    await storageService.pdfBox.put(pdf1.id, pdf1);
    await storageService.pdfBox.put(pdf2.id, pdf2);
    await storageService.pdfBox.put(pdf3.id, pdf3);

    // Load initial data
    controller.loadData();

    // Verify root PDFs (folderId is empty)
    expect(controller.folders.length, 2);
    expect(controller.pdfs.length, 1);
    expect(controller.pdfs[0].id, 'pdf1');

    // Navigation test: Open folder 1 in O(1)
    controller.openFolder('folder1');
    expect(controller.currentFolderId.value, 'folder1');
    expect(controller.pdfs.length, 2);
    expect(controller.pdfs.any((p) => p.id == 'pdf2'), true);
    expect(controller.pdfs.any((p) => p.id == 'pdf3'), true);

    // Test Delete PDF incrementally in O(1)
    await controller.deletePdf('pdf2');
    expect(controller.pdfs.length, 1);
    expect(controller.pdfs[0].id, 'pdf3');
    expect(storageService.pdfBox.containsKey('pdf2'), false);

    // Test Delete Folder (which performs batch deletion)
    controller.goBack();
    await controller.deleteFolder('folder1');
    expect(controller.folders.length, 1);
    expect(controller.folders[0].id, 'folder2');
    expect(storageService.pdfBox.containsKey('pdf3'), false); // inside deleted folder
    expect(storageService.pdfBox.containsKey('pdf1'), true);  // root PDF remains
  });
}
