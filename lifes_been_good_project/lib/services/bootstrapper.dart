import 'dart:io';

import 'package:path/path.dart' as p;

import 'app_paths.dart';
import 'android_native_installer.dart';
import 'native_cli.dart';
import 'native_features.dart';

class BootstrapResult {
  final bool ok;
  final String message;
  final String? messageEn;
  final String dataDir;
  final String cliPath;
  final String? nativeLibDir;

  const BootstrapResult({
    required this.ok,
    required this.message,
    this.messageEn,
    required this.dataDir,
    required this.cliPath,
    this.nativeLibDir,
  });
}

class Bootstrapper {
  static Future<BootstrapResult> run({
    void Function(String message)? onProgress,
  }) async {
    void progress(String msg) {
      onProgress?.call(msg);
    }

    progress('准备数据目录...');
    final data = await AppPaths.dataDir();
    final bin = await AppPaths.binDir();
    final cliFile = await AppPaths.defaultCliFile();

    progress('检查本地二进制...');
    String? nativeLibDir;
    if (Platform.isAndroid) {
      nativeLibDir = await AndroidNativeInstaller.getNativeLibraryDir();
    } else {
      await _ensureCliInstalled(
          cliFile: cliFile, binDir: bin, progress: progress);
      await _ensureFeaturesInstalled(binDir: bin, progress: progress);
    }

    progress('初始化数据结构...');
    final features = NativeFeatures(dataDir: data.path, nativeLibDir: nativeLibDir);
    Map<String, dynamic> res;
    if (await features.hasFeature('system_init')) {
      res = await features.systemInit(seed: false);
    } else {
      if (!await cliFile.exists() && !Platform.isAndroid) {
        final tip =
            '未找到本地 CLI：${cliFile.path}（且缺少 system_init）。\n\n请将 `native/campus_cli/dist` 下的二进制复制到：${bin.path}，并将 `native/features/dist` 下的功能二进制复制到同目录；或设置环境变量 `CAMPUS_CLI_DIST` / `CAMPUS_FEATURES_DIST` 指向 dist 目录。';
        final tipEn =
            'Local CLI not found: ${cliFile.path} (and system_init is missing).\n\nCopy the binaries under `native/campus_cli/dist` to: ${bin.path}, and copy the feature binaries under `native/features/dist` to the same directory; or set environment variables `CAMPUS_CLI_DIST` / `CAMPUS_FEATURES_DIST` to point to the dist directories.';
        return BootstrapResult(
          ok: false,
          message: tip,
          messageEn: tipEn,
          dataDir: data.path,
          cliPath: cliFile.path,
          nativeLibDir: nativeLibDir,
        );
      }
      
      final actualCliPath = (Platform.isAndroid && nativeLibDir != null)
          ? p.join(nativeLibDir, 'libcampus_cli.so')
          : cliFile.path;

      if (Platform.isAndroid && !await File(actualCliPath).exists()) {
        final tip =
            '未找到内置本地二进制：$actualCliPath（且缺少 system_init）。\n\n请确认 Android 构建已生成并打包 jniLibs 资源，然后重启应用。';
        final tipEn =
            'Built-in local binary not found: $actualCliPath (and system_init is missing).\n\nPlease ensure the Android build has generated and packaged the jniLibs resources, then restart the app.';
        return BootstrapResult(
          ok: false,
          message: tip,
          messageEn: tipEn,
          dataDir: data.path,
          cliPath: actualCliPath,
          nativeLibDir: nativeLibDir,
        );
      }

      final cli = NativeCli(exePath: actualCliPath, dataDir: data.path);
      res = await cli.init(seed: false);
    }

    if (res['ok'] != true) {
      final msg = ((res['error'] ?? const {}) as Map)['message']?.toString() ??
          'unknown error';
      return BootstrapResult(
        ok: false,
        message: msg,
        dataDir: data.path,
        cliPath: cliFile.path,
        nativeLibDir: nativeLibDir,
      );
    }

    return BootstrapResult(
      ok: true,
      message: '就绪',
      messageEn: 'Ready',
      dataDir: data.path,
      cliPath: cliFile.path,
      nativeLibDir: nativeLibDir,
    );
  }

  static Future<void> _ensureCliInstalled({
    required File cliFile,
    required Directory binDir,
    required void Function(String msg) progress,
  }) async {
    if (await cliFile.exists()) return;

    final env = Platform.environment['CAMPUS_CLI_DIST'];
    final candidates = <String?>[
      env,
      p.join(Directory.current.path, 'native', 'campus_cli', 'dist'),
      p.join(Directory.current.path, '..', 'native', 'campus_cli', 'dist'),
      p.join(
          Directory.current.path, '..', '..', 'native', 'campus_cli', 'dist'),
    ];

    Directory? src;
    for (final c in candidates) {
      if (c == null || c.trim().isEmpty) continue;
      final d = Directory(c);
      if (await d.exists()) {
        src = d;
        break;
      }
    }
    if (src == null) return;

    progress('安装本地 CLI...');
    final exeName = Platform.isWindows ? 'campus_cli.exe' : 'campus_cli';
    final srcExe = File(p.join(src.path, exeName));
    if (!await srcExe.exists()) return;
    await srcExe.copy(cliFile.path);
  }

  static Future<void> _ensureFeaturesInstalled({
    required Directory binDir,
    required void Function(String msg) progress,
  }) async {
    final env = Platform.environment['CAMPUS_FEATURES_DIST'];
    final candidates = <String?>[
      env,
      p.join(Directory.current.path, 'native', 'features', 'dist'),
      p.join(Directory.current.path, '..', 'native', 'features', 'dist'),
      p.join(Directory.current.path, '..', '..', 'native', 'features', 'dist'),
    ];

    Directory? src;
    for (final c in candidates) {
      if (c == null || c.trim().isEmpty) continue;
      final d = Directory(c);
      if (await d.exists()) {
        src = d;
        break;
      }
    }
    if (src == null) return;

    progress('检查并同步功能二进制...');
    final files = await src
        .list(followLinks: false)
        .where((e) => e is File)
        .cast<File>()
        .toList();

    for (final f in files) {
      final name = p.basename(f.path);
      if (Platform.isWindows) {
        if (!name.toLowerCase().endsWith('.exe')) continue;
      } else {
        if (name.contains('.')) continue;
      }
      final dst = File(p.join(binDir.path, name));

      // Copy if destination doesn't exist OR if source is newer
      bool shouldCopy = !await dst.exists();
      if (!shouldCopy) {
        final srcStat = await f.stat();
        final dstStat = await dst.stat();
        if (srcStat.modified.isAfter(dstStat.modified)) {
          shouldCopy = true;
        }
      }

      if (shouldCopy) {
        progress('正在安装 $name...');
        await f.copy(dst.path);
      }
    }
  }
}
