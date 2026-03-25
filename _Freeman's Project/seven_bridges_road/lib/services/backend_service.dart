/*
 * @Date: 2026-03-25 22:14:03
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-25 22:14:04
 * @FilePath: /Code_Sync/_Freeman's Project/seven_bridges_road/lib/services/backend_service.dart
 */
import 'dart:io';

class BackendService {
  // 封装 Process 调用，让 UI 层只管拿结果，不管怎么调
  static Future<String> exec(String command, List<String> args) async {
    try {
      // 这里的路径对应你之前说的 _tools 编译产物
      final result = await Process.run('./tools/backend_tool', [command, ...args]);
      return result.stdout.toString().trim();
    } catch (e) {
      return "Backend Error: $e";
    }
  }
}