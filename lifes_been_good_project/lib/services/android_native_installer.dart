import 'dart:io';

import 'package:flutter/services.dart';

class AndroidNativeInstaller {
  static const MethodChannel _channel =
      MethodChannel('com.androidfreeman.lifesbeengood/native_installer');

  static Future<String?> getNativeLibraryDir() async {
    if (!Platform.isAndroid) return null;
    return await _channel.invokeMethod('getNativeLibraryDir');
  }
}

