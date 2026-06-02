import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/folder_model.dart';
import '../models/pdf_model.dart';

class StorageService extends GetxService {
  late Box<FolderModel> folderBox;
  late Box<PdfModel> pdfBox;

  Future<StorageService> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(FolderModelAdapter());
    Hive.registerAdapter(PdfModelAdapter());

    folderBox = await Hive.openBox<FolderModel>('folders');
    pdfBox = await Hive.openBox<PdfModel>('pdfs');

    return this;
  }
}
