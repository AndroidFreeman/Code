import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';

void main() {
  runApp(const NewKidApp());
}

class NewKidApp extends StatelessWidget {
  const NewKidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
      ),
      home: const ManagementPanel(),
    );
  }
}

class ManagementPanel extends StatefulWidget {
  const ManagementPanel({super.key});

  @override
  State<ManagementPanel> createState() => _ManagementPanelState();
}

class _ManagementPanelState extends State<ManagementPanel> {
  // 1. 定义变量：控制台输出内容和输入框控制器
  String _terminalOutput = "等待内核指令输入...";
  final TextEditingController _inputController = TextEditingController();
  bool _isWorking = false;

  // 2. 核心调用逻辑：通过代码操纵底层的 C 程序
  Future<void> _invokeCore(String input) async {
    if (input.isEmpty) return;

    setState(() {
      _isWorking = true;
      _terminalOutput = "正在向 C 内核发送指令: $input ...";
    });

    try {
      // 执行指令: ./backend [你的输入]
      // 这里的 './backend' 必须和你编译出来的文件名一致
      var result = await Process.run('./backend', [input]);

      setState(() {
        _terminalOutput = result.stdout.toString().isEmpty
            ? "内核执行完毕，但没有标准输出。"
            : result.stdout.toString();
      });
    } catch (e) {
      setState(() {
        _terminalOutput = "状态错误: 无法调用 ./backend\n请检查文件是否存在并具有执行权限(chmod +x)。";
      });
    } finally {
      setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景渐变
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D1117), Color(0xFF161B22)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "CORE CONTROLLER",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const Text(
                    "管理信息系统",
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 25),

                  // 3. 模拟终端显示区（磨砂玻璃效果）
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _terminalOutput,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                color: Colors.greenAccent,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. 输入与交互区
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _inputController,
                            decoration: const InputDecoration(
                              hintText: "输入查询内容...",
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.white24),
                            ),
                            style: const TextStyle(color: Colors.white),
                            onSubmitted: (val) => _invokeCore(val), // 按回车也能触发
                          ),
                        ),
                        _isWorking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : IconButton(
                                icon: const Icon(
                                  Icons.send_rounded,
                                  color: Colors.blueAccent,
                                ),
                                onPressed: () =>
                                    _invokeCore(_inputController.text),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
