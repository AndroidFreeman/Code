import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../services/app_paths.dart';
import '../services/android_native_installer.dart';
import '../services/native_features.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('zh', 'CN');
  ThemeMode _themeMode = ThemeMode.light;
  bool _enableQuickRollCall = true;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  bool get isEnglish => _locale.languageCode == 'en';
  bool get enableQuickRollCall => _enableQuickRollCall;

  static const _settingsFileName = 'app_settings.json';

  Locale _normalizeLocale(Locale input) {
    if (input.languageCode == 'en') return const Locale('en', 'US');
    if (input.languageCode == 'zh') return const Locale('zh', 'CN');
    return input;
  }

  Future<void> load() async {
    try {
      final dataDir = await AppPaths.dataDir();
      final nativeLibDir = Platform.isAndroid
          ? await AndroidNativeInstaller.getNativeLibraryDir()
          : null;
      final features =
          NativeFeatures(dataDir: dataDir.path, nativeLibDir: nativeLibDir);
      final res =
          await features.jsonOp(action: 'read', file: _settingsFileName);
      if (res['ok'] != true || res['data'] == null) return;
      final decoded = res['data'];

      if (decoded is Map && decoded.containsKey('themeMode')) {
        final modeIndex = decoded['themeMode'] as int?;
        if (modeIndex != null &&
            modeIndex >= 0 &&
            modeIndex < ThemeMode.values.length) {
          _themeMode = ThemeMode.values[modeIndex];
        }
      }
      if (decoded is! Map) return;

      if (decoded.containsKey('enableQuickRollCall')) {
        _enableQuickRollCall = decoded['enableQuickRollCall'] == true;
      }

      final rawLocale = decoded['locale']?.toString().trim();
      if (rawLocale == null || rawLocale.isEmpty) return;
      final parts = rawLocale.replaceAll('-', '_').split('_');
      if (parts.isEmpty) return;
      final lang = parts[0];
      final country =
          (parts.length >= 2 && parts[1].trim().isNotEmpty) ? parts[1] : null;
      _locale = _normalizeLocale(Locale(lang, country));
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final dataDir = await AppPaths.dataDir();
      final nativeLibDir = Platform.isAndroid
          ? await AndroidNativeInstaller.getNativeLibraryDir()
          : null;
      final features =
          NativeFeatures(dataDir: dataDir.path, nativeLibDir: nativeLibDir);
      final payload = <String, dynamic>{
        'locale': _locale.toLanguageTag(),
        'enableQuickRollCall': _enableQuickRollCall,
      };
      await features.jsonOp(
          action: 'write', file: _settingsFileName, data: payload);
    } catch (_) {}
  }

  void setLocale(Locale newLocale) {
    final normalized = _normalizeLocale(newLocale);
    if (_locale == normalized) return;
    _locale = normalized;
    notifyListeners();
    unawaited(_save());
  }

  void setEnableQuickRollCall(bool value) {
    _enableQuickRollCall = value;
    notifyListeners();
    unawaited(_save());
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  String t(String zh, String en) {
    return _locale.languageCode == 'en' ? en : zh;
  }
}
