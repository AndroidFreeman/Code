/*
 * @Date: 2026-03-25 22:45:35
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-26 01:16:11
 * @FilePath: /Code_Sync/_MyProjects/lifes_been_good/lib/services/bridge.dart
 */
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class LBGService {
  static Future<String> execute(String command, String payload) async {
    // 1. 获取合法的存储根目录
    Directory dataDir;
    if (Platform.isAndroid) {
      // Android 16 必须使用私有目录
      dataDir = await getApplicationSupportDirectory();
    } else {
      // Windows 和 Linux 默认在项目根目录运行
      dataDir = Directory.current;
    }

    // 2. 确定二进制引擎的物理路径
    String platformDir = Platform.isAndroid
        ? "android"
        : (Platform.isWindows ? "windows" : "linux");
    String ext = Platform.isWindows ? ".exe" : ".bin";

    // 开发环境下，二进制文件在 lib/services/bin/...
    // 注意：如果是打包后的 Android，路径需要根据你的资源释放逻辑调整
    String enginePath;
    if (Platform.isAndroid) {
      enginePath = "${dataDir.path}/services/bin/$platformDir/$command$ext";
    } else {
      enginePath = "${dataDir.path}/lib/services/bin/$platformDir/$command$ext";
    }

    // 3. 检查文件是否存在，防止 ProcessException
    final engineFile = File(enginePath);
    if (!await engineFile.exists()) {
      debugPrint(">>> [7945HX ALERT] 找不到引擎: $enginePath");
      return "[]";
    }

    // 4. 赋予执行权限 (Android/Linux 必备)
    if (!Platform.isWindows) {
      await Process.run('chmod', ['755', enginePath]);
    }

    // 5. 参数解析与分发
    // payload 格式: "students,班级,学号,姓名"
    final parts = payload.split(',');
    List<String> args = [dataDir.path]; // argv[1]: 根目录
    args.addAll(parts); // argv[2]: 表名, argv[3...]: 字段数据

    try {
      final result = await Process.run(enginePath, args);

      if (result.exitCode != 0) {
        debugPrint(">>> [7945HX ERROR] 指令: $command, 报错: ${result.stderr}");
        return "[]";
      }

      return result.stdout.trim();
    } catch (e) {
      debugPrint(">>> [7945HX FATAL] 进程启动失败: $e");
      return "[]";
    }
  }
}
