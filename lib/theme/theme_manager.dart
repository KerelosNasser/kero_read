import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Persisted app-theme selection. Palette id drives which color set is active;
/// remote-config ready: any external value for `palette` maps 1:1 to a local
/// palette id override.
class ThemeManager extends GetxService {
  static const String _modeKey = 'themeMode';
  static const String _paletteKey = 'themePalette';

  late Box<dynamic> _box;

  final Rx<ThemeMode> mode = ThemeMode.system.obs;
  final RxString paletteId = 'ink_amber'.obs;

  /// Available palette ids. Only `ink_amber` ships today; more slots reserved
  /// for future palettes driven from AB tests / remote config.
  static const List<String> availablePaletteIds = ['ink_amber'];

  Future<ThemeManager> init() async {
    _box = await Hive.openBox<dynamic>('settings');

    mode.value = _readMode(_box.get(_modeKey, defaultValue: 'system'));
    paletteId.value = _box.get(_paletteKey, defaultValue: 'ink_amber') as String;

    mode.listen((m) => _box.put(_modeKey, _writeMode(m)));
    paletteId.listen((id) => _box.put(_paletteKey, id));
    return this;
  }

  void setMode(ThemeMode m) => mode.value = m;
  void setPalette(String id) {
    if (availablePaletteIds.contains(id)) paletteId.value = id;
  }

  static String _writeMode(ThemeMode m) =>
      m == ThemeMode.dark ? 'dark' : (m == ThemeMode.light ? 'light' : 'system');

  static ThemeMode _readMode(String s) =>
      s == 'dark' ? ThemeMode.dark : (s == 'light' ? ThemeMode.light : ThemeMode.system);
}
