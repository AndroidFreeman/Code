import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppPaths {
  static Future<Directory> dataDir() async {
    if (Platform.isWindows) {
      final exeDir = File(Platform.resolvedExecutable).parent;
      final preferred = Directory(p.join(exeDir.path, 'campus_data'));
      try {
        if (!await preferred.exists()) {
          await preferred.create(recursive: true);
        }
        return preferred;
      } catch (_) {}
    }

    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'campus_data'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<Directory> binDir() async {
    final data = await dataDir();
    final dir = Directory(p.join(data.path, 'bin'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<File> defaultCliFile() async {
    final bin = await binDir();
    final name = Platform.isWindows ? 'campus_cli.exe' : 'campus_cli';
    return File(p.join(bin.path, name));
  }

  static Future<File> featureFile(String baseName) async {
    final bin = await binDir();
    final name = Platform.isWindows ? '$baseName.exe' : baseName;
    return File(p.join(bin.path, name));
  }
}
