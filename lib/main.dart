import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/storage_service.dart';
import 'services/ocr_service.dart';
import 'services/ai_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_manager.dart';
import 'views/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await initServices();

  runApp(const MyApp());
}

Future<void> initServices() async {
  await Get.putAsync(() => StorageService().init());
  await Get.putAsync(() => ThemeManager().init());
  Get.put(OcrService());
  await Get.putAsync(() => AiService().init());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = Get.find<ThemeManager>();
    return Obx(
      () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Kero Read',
        theme: AppTheme.buildLightTheme(),
        darkTheme: AppTheme.buildDarkTheme(),
        themeMode: themeManager.mode.value,
        enableLog: false,
        home: HomeView(),
      ),
    );
  }
}
