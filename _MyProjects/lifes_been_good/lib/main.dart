/*
 * @Date: 2026-03-25 22:27:37
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-26 01:27:45
 * @FilePath: /Code_Sync/_MyProjects/lifes_been_good/lib/main.dart
 */
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'views/home_page.dart';

void main() async {
  // 1. 确保 Flutter 框架初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 执行 Android 引擎部署逻辑
  try {
    await initAndroidEngines();
  } catch (e) {
    debugPrint(">>> [7945HX FATAL] 引擎部署失败: $e");
  }

  // 3. 启动 App
  runApp(const MyApp());
}

/// 核心函数：将资产中的二进制引擎释放到 Android 私有目录并授权
Future<void> initAndroidEngines() async {
  if (!Platform.isAndroid) return;

  debugPrint(">>> [7945HX] 开始检测并部署 Android 引擎...");
  final docDir = await getApplicationSupportDirectory();

  // 这里的目录结构必须与 bridge.dart 中的拼接逻辑完全对齐
  final String targetDir = "${docDir.path}/services/bin/android";
  final List<String> engines = [
    'find.bin',
    'insert.bin',
    'delete.bin',
    'backup.bin',
  ];

  for (String name in engines) {
    final file = File("$targetDir/$name");

    // 每次启动都重新检查，确保权限和文件完整性
    if (!await file.exists()) {
      debugPrint(">>> [7945HX] 正在释放引擎: $name");
      await file.create(recursive: true);

      // 注意：这里的路径必须与 pubspec.yaml 里的 assets 路径完全一致
      final ByteData data = await rootBundle.load(
        "lib/services/bin/android/$name",
      );
      final List<int> bytes = data.buffer.asUint8List();
      await file.writeAsBytes(bytes);
    }

    // 无论文件是否存在，都重新赋予 755 权限，防止 Android 16 权限丢失
    final result = await Process.run('chmod', ['755', file.path]);
    if (result.exitCode == 0) {
      debugPrint(">>> [7945HX] 引擎授权成功: $name");
    } else {
      debugPrint(">>> [7945HX ERROR] 授权失败: ${result.stderr}");
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lifes Been Good',
      debugShowCheckedModeBanner: false, // 关掉那个碍眼的 Debug 标志
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
