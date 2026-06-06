import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/storage_service.dart';
import 'services/ocr_service.dart';
import 'services/ai_service.dart';
import 'views/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await initServices();

  runApp(const MyApp());
}

Future<void> initServices() async {
  await Get.putAsync(() => StorageService().init());
  Get.put(OcrService());
  await Get.putAsync(() => AiService().init());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kero Read',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          surface: Color(0xFF141527),
        ),
        scaffoldBackgroundColor: const Color(0xFF141527),
        useMaterial3: true,
      ),
      enableLog: false,
      home: HomeView(),
    );
  }
}
