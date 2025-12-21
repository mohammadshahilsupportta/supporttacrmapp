import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final _storage = GetStorage();
  final _themeMode = ThemeMode.light.obs;
  
  static const String _themeKey = 'theme_mode';

  ThemeMode get themeMode => _themeMode.value;
  bool get isDarkMode => _themeMode.value == ThemeMode.dark;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  void _loadTheme() {
    // Load saved theme preference, default to light
    final savedTheme = _storage.read(_themeKey);
    if (savedTheme != null) {
      _themeMode.value = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == savedTheme,
        orElse: () => ThemeMode.light,
      );
    } else {
      // Default to light theme
      _themeMode.value = ThemeMode.light;
    }
    // Don't call _updateTheme() here as GetMaterialApp isn't ready yet
    // The theme will be applied when MyApp builds
  }

  void toggleTheme() {
    _themeMode.value = _themeMode.value == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    _storage.write(_themeKey, _themeMode.value.toString());
    _updateTheme();
  }

  void setTheme(ThemeMode mode) {
    _themeMode.value = mode;
    _storage.write(_themeKey, mode.toString());
    _updateTheme();
  }

  void _updateTheme() {
    Get.changeThemeMode(_themeMode.value);
  }
}

