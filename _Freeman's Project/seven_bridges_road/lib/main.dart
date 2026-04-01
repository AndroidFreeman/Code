/*
 * @Date: 2026-03-25 22:07:24
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-25 22:13:15
 * @FilePath: /Code_Sync/_Freeman's Project/seven_bridges_road/lib/main.dart
 */
import 'package:flutter/material.dart';
import 'views/home_page.dart';

void main() => runApp(const LBGApp());

class LBGApp extends StatelessWidget {
  const LBGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Life's Been Good",
      theme: ThemeData(
        useMaterial3: true,
        // 使用 M3 的种子配色，它会自动生成一套深色调
        colorSchemeSeed: Colors.blueAccent,
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}
