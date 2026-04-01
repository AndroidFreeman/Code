/*
 * @Date: 2026-03-25 22:13:37
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-25 22:13:38
 * @FilePath: /Code_Sync/_Freeman's Project/seven_bridges_road/lib/views/home_page.dart
 */
import 'package:flutter/material.dart';
import '../services/backend_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _status = "内核就绪";

  void _runCheck() async {
    final result = await BackendService.exec("check", []);
    setState(() => _status = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("LBG 控制台"), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // M3 风格的卡片容器
            Card(
              margin: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(_status, style: const TextStyle(fontFamily: 'monospace')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _runCheck,
        label: const Text("同步数据"),
        icon: const Icon(Icons.sync),
      ),
    );
  }
}