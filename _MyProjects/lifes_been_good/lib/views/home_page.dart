import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/bridge.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _selectedClass;
  List<String> _classes = [];
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = false;
  bool _isCollapsed = false; // 侧边栏折叠状态

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  // --- 逻辑：数据交互 ---
  void _loadClasses() async {
    final res = await LBGService.execute("find", "classes,");
    try {
      final List<dynamic> data = json.decode(res);
      setState(() {
        _classes = data.map((e) => e.toString()).toList();
        if (_classes.isNotEmpty && _selectedClass == null) {
          _selectedClass = _classes[0];
          _loadStudents();
        }
      });
    } catch (e) {
      debugPrint(">>> [7945HX] Class Load Error: $e");
    }
  }

  void _loadStudents() async {
    if (_selectedClass == null) return;
    setState(() => _isLoading = true);
    final res = await LBGService.execute("find", "students,$_selectedClass");
    try {
      final List<dynamic> data = json.decode(res);
      setState(() {
        _students = data.map((s) {
          final p = s.toString().split(',');
          return {
            "id": p.length > 1 ? p[1] : "ID缺失",
            "name": p.length > 2 ? p[2] : (p.isNotEmpty ? p[0] : "未知"),
            "status": "正常",
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _students = [];
        _isLoading = false;
      });
    }
  }

  // --- 逻辑：交互弹窗 ---
  void _showAddClassDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          "新建班级",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "输入班级名",
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("取消"),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await LBGService.execute(
                  "insert",
                  "classes,${controller.text}",
                );
                Navigator.pop(ctx);
                _loadClasses();
              }
            },
            child: const Text("创建"),
          ),
        ],
      ),
    );
  }

  void _showAddStudentDialog() {
    if (_selectedClass == null) return;
    final idCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          "添加学生至 $_selectedClass",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "学号"),
            ),
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "姓名"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("取消"),
          ),
          FilledButton(
            onPressed: () async {
              if (idCtrl.text.isNotEmpty && nameCtrl.text.isNotEmpty) {
                await LBGService.execute(
                  "insert",
                  "students,$_selectedClass,${idCtrl.text},${nameCtrl.text}",
                );
                Navigator.pop(ctx);
                _loadStudents();
              }
            },
            child: const Text("确认"),
          ),
        ],
      ),
    );
  }

  // --- 界面构建 ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Row(
          children: [
            // 1. 侧边栏：向内折叠逻辑
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: _isCollapsed ? 0 : 200, // 手机端缩窄到 200
              child: _isCollapsed ? const SizedBox() : _buildSidebar(),
            ),

            // 2. 主展示区
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildStudentList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        border: Border(right: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Column(
        children: [
          ListTile(
            title: const Text(
              "班级列表",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.add_circle_outline,
                color: Colors.blue,
                size: 20,
              ),
              onPressed: _showAddClassDialog,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _classes.length,
              itemBuilder: (context, i) => ListTile(
                selected: _selectedClass == _classes[i],
                selectedTileColor: Colors.blue.withOpacity(0.05),
                leading: const Icon(Icons.folder_shared_outlined, size: 18),
                title: Text(
                  _classes[i],
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                onTap: () {
                  setState(() => _selectedClass = _classes[i]);
                  _loadStudents();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isCollapsed ? Icons.menu : Icons.menu_open,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
          ),
          const SizedBox(width: 8),
          // 标题使用 Flexible 配合 ellipsis，防止溢出
          Expanded(
            child: Text(
              _selectedClass ?? "未选择班级",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: Colors.blue),
            onPressed: _showAddStudentDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    if (_students.isEmpty)
      return const Center(
        child: Text("无数据", style: TextStyle(color: Colors.grey)),
      );
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _students.length,
      itemBuilder: (context, i) {
        final s = _students[i];
        return Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.white10,
              child: Icon(Icons.person, color: Colors.white54),
            ),
            title: Text(
              s['name'],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              s['id'],
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
            trailing: _buildModernSlider(i, s['status']),
          ),
        );
      },
    );
  }

  Widget _buildModernSlider(int index, String status) {
    const double width = 140; // 手机端缩短滑块宽度
    return Container(
      width: width,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ["迟", "假", "旷", "正"]
                .map(
                  (t) => Text(
                    t,
                    style: const TextStyle(color: Colors.white24, fontSize: 9),
                  ),
                )
                .toList(),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            left: _getSliderPos(status, width),
            child: GestureDetector(
              onHorizontalDragUpdate: (d) =>
                  _updateStatus(index, d.localPosition.dx, width),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getSliderPos(String status, double width) {
    double step = width / 4;
    if (status == "迟到") return (step * 0.5) - 13;
    if (status == "请假") return (step * 1.5) - 13;
    if (status == "旷课") return (step * 2.5) - 13;
    return (step * 3.5) - 13;
  }

  Color _getStatusColor(String status) {
    if (status == "迟到") return Colors.orange;
    if (status == "请假") return Colors.blue;
    if (status == "旷课") return Colors.red;
    return Colors.green;
  }

  void _updateStatus(int index, double dx, double width) {
    String ns;
    if (dx < width * 0.25)
      ns = "迟到";
    else if (dx < width * 0.5)
      ns = "请假";
    else if (dx < width * 0.75)
      ns = "旷课";
    else
      ns = "正常";
    if (_students[index]['status'] != ns)
      setState(() => _students[index]['status'] = ns);
  }
}
