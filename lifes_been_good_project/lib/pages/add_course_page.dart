import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course.dart';
import '../models/timetable_item.dart';
import '../main.dart';
import '../widgets/expressive_ui.dart';

class AddCoursePage extends StatefulWidget {
  final Course? initialCourse;
  final TimetableItem? initialItem;
  final List<Course> availableCourses;
  final bool isTeacher;
  final List<String> teacherClasses;

  const AddCoursePage({
    super.key,
    this.initialCourse,
    this.initialItem,
    required this.availableCourses,
    required this.isTeacher,
    required this.teacherClasses,
  });

  @override
  State<AddCoursePage> createState() => _AddCoursePageState();
}

class _AddCoursePageState extends State<AddCoursePage> {
  final _courseNameCtrl = TextEditingController();
  final _creditsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _teacherCtrl = TextEditingController();

  Color _selectedColor = const Color(0xFFBAE1FF); // Default light blue

  // Time slots (one course can have multiple sessions)
  final List<Map<String, dynamic>> _timeSlots = [];

  final List<Color> _presetColors = [
    const Color(0xFFFFB3BA), // Light Red
    const Color(0xFFFFDFBA), // Light Orange
    const Color(0xFFFFFFBA), // Light Yellow
    const Color(0xFFBAFFC9), // Light Green
    const Color(0xFFBAE1FF), // Light Blue
    const Color(0xFFD4BAFF), // Light Purple
    const Color(0xFFFFBADC), // Light Pink
    const Color(0xFFBAFFF1), // Light Cyan
  ];

  final List<String> _courseSuggestions = ['晚自习', '体育', '物理实验', '离散数学'];

  @override
  void initState() {
    super.initState();
    if (widget.initialCourse != null) {
      _courseNameCtrl.text = widget.initialCourse!.courseName;
      _creditsCtrl.text = widget.initialCourse!.credits ?? '';
      _notesCtrl.text = widget.initialCourse!.notes ?? '';
      if (widget.initialCourse!.color != null) {
        _selectedColor = Color(int.parse(widget.initialCourse!.color!));
      }
    }

    if (widget.initialItem != null) {
      _locationCtrl.text = widget.initialItem!.location;
      // In a real WakeUp app, we'd load all time slots for this course
      _timeSlots.add({
        'weekday': widget.initialItem!.weekday,
        'startPeriod': widget.initialItem!.startPeriod,
        'endPeriod': widget.initialItem!.endPeriod,
        'weeks': widget.initialItem!.weeks,
      });
    } else {
      // Default time slot
      _timeSlots.add({
        'weekday': 1,
        'startPeriod': 1,
        'endPeriod': 2,
        'weeks': '1-20',
      });
    }
  }

  @override
  void dispose() {
    _courseNameCtrl.dispose();
    _creditsCtrl.dispose();
    _notesCtrl.dispose();
    _locationCtrl.dispose();
    _teacherCtrl.dispose();
    super.dispose();
  }

  void _showColorPicker() {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('选择颜色', 'Choose Color')),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presetColors.map((color) {
            return GestureDetector(
              onTap: () {
                setState(() => _selectedColor = color);
                Navigator.of(ctx).pop();
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                  border: _selectedColor == color
                      ? Border.all(color: Colors.black, width: 2)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _weekdayLabel(int w) {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    switch (w) {
      case 1:
        return loc.t('周一', 'Mon');
      case 2:
        return loc.t('周二', 'Tue');
      case 3:
        return loc.t('周三', 'Wed');
      case 4:
        return loc.t('周四', 'Thu');
      case 5:
        return loc.t('周五', 'Fri');
      case 6:
        return loc.t('周六', 'Sat');
      case 7:
        return loc.t('周日', 'Sun');
      default:
        return loc.t('未知', 'Unknown');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocaleProvider>(context);
    final canDelete = widget.initialItem != null &&
        (widget.isTeacher || !(widget.initialItem?.isLocked ?? false));
    final suggestions = loc.isEnglish
        ? const ['Study Hall', 'PE', 'Physics Lab', 'Discrete Math']
        : _courseSuggestions;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.initialItem == null
            ? loc.t('添加课程', 'Add Course')
            : loc.t('编辑课程', 'Edit Course')),
        actions: [
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                final it = widget.initialItem;
                Navigator.of(context).pop({
                  'action': 'delete',
                  'weekday': it?.weekday ?? 0,
                  'startPeriod': it?.startPeriod ?? 0,
                });
              },
            ),
          TextButton(
            onPressed: () {
              if (_courseNameCtrl.text.isEmpty) {
                showExpressiveSnackBar(
                  context,
                  loc.t('请输入课程名', 'Please enter course name'),
                );
                return;
              }
              final result = {
                'courseName': _courseNameCtrl.text,
                'credits': _creditsCtrl.text,
                'notes': _notesCtrl.text,
                'color': _selectedColor.toARGB32().toString(),
                'location': _locationCtrl.text,
                'timeSlots': _timeSlots,
              };
              Navigator.of(context).pop(result);
            },
            child: Text(loc.t('保存', 'Save'),
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Name Section
            _buildSection(
              icon: Icons.book_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _courseNameCtrl,
                    decoration: InputDecoration(
                      hintText: loc.t('课程名称', 'Course name'),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: suggestions.map((s) {
                      return ActionChip(
                        label: Text(s),
                        onPressed: () =>
                            setState(() => _courseNameCtrl.text = s),
                        backgroundColor: Colors.grey[100],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Color Picker
            _buildSection(
              icon: Icons.edit_outlined,
              child: GestureDetector(
                onTap: _showColorPicker,
                child: Text(loc.t('点此更改颜色', 'Tap to change color'),
                    style: const TextStyle(color: Colors.blue)),
              ),
            ),

            // Credits
            _buildSection(
              icon: Icons.flag_outlined,
              child: TextField(
                controller: _creditsCtrl,
                decoration: InputDecoration(
                  hintText: loc.t('学分 (可不填)', 'Credits (Optional)'),
                  border: InputBorder.none,
                ),
              ),
            ),

            // Notes
            _buildSection(
              icon: Icons.sticky_note_2_outlined,
              child: TextField(
                controller: _notesCtrl,
                decoration: InputDecoration(
                  hintText: loc.t('备注 (可不填)', 'Notes (Optional)'),
                  border: InputBorder.none,
                ),
              ),
            ),

            const Divider(),

            // Time Slots Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.t('时间段', 'Time Slots'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {}, // Close section?
                  ),
                ],
              ),
            ),

            ..._timeSlots.asMap().entries.map((entry) {
              final i = entry.key;
              final slot = entry.value;
              return _buildTimeSlot(i, slot);
            }),

            const SizedBox(height: 20),
            Center(
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _timeSlots.add({
                      'weekday': 1,
                      'startPeriod': 1,
                      'endPeriod': 2,
                      'weeks': '1-20',
                    });
                  });
                },
                icon:
                    const Icon(Icons.add_circle, color: Colors.blue, size: 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required IconData icon, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal[400]),
          const SizedBox(width: 16),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildTimeSlot(int index, Map<String, dynamic> slot) {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // Weeks Picker
          _buildSection(
            icon: Icons.calendar_today_outlined,
            child: GestureDetector(
              onTap: () => _showWeekPicker(index),
              child: Text(
                  loc.t('第 ${slot['weeks']} 周', 'Week ${slot['weeks']}'),
                  style: const TextStyle(fontSize: 16)),
            ),
          ),

          // Time Picker (Weekday & Periods)
          _buildSection(
            icon: Icons.access_time,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _showTimePicker(index),
                  child: Text(
                    loc.t(
                      '${_weekdayLabel(slot['weekday'])}  第 ${slot['startPeriod']}-${slot['endPeriod']} 节',
                      '${_weekdayLabel(slot['weekday'])}  Period ${slot['startPeriod']}-${slot['endPeriod']}',
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const Spacer(),
                Text(loc.t('自定义时间', 'Custom time'),
                    style: const TextStyle(color: Colors.grey)),
                Checkbox(value: false, onChanged: (v) {}),
              ],
            ),
          ),

          // Teacher (Optional)
          _buildSection(
            icon: Icons.person_outline,
            child: TextField(
              controller: _teacherCtrl,
              decoration: InputDecoration(
                hintText: loc.t('授课老师 (可不填)', 'Teacher (Optional)'),
                border: InputBorder.none,
              ),
            ),
          ),

          // Location
          _buildSection(
            icon: Icons.door_front_door_outlined,
            child: TextField(
              controller: _locationCtrl,
              decoration: InputDecoration(
                hintText: loc.t('上课地点 (可不填)', 'Location (Optional)'),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWeekPicker(int index) async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final currentWeeks = _timeSlots[index]['weeks'] as String;
    final selectedWeeks = <int>{};

    // Parse existing weeks string "1-20" or "1,2,3"
    if (currentWeeks.contains('-')) {
      final parts = currentWeeks.split('-');
      if (parts.length == 2) {
        final start = int.tryParse(parts[0]) ?? 1;
        final end = int.tryParse(parts[1]) ?? 20;
        for (var i = start; i <= end; i++) {
          selectedWeeks.add(i);
        }
      }
    } else {
      for (final s in currentWeeks.split(',')) {
        final w = int.tryParse(s.trim());
        if (w != null) selectedWeeks.add(w);
      }
    }

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc.t('请选择周数', 'Select Weeks'),
                  style: const TextStyle(fontSize: 18)),
              TextButton(
                  onPressed: () {},
                  child: Text(loc.t('日期模式', 'Date Mode'),
                      style: const TextStyle(color: Colors.blue))),
            ],
          ),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: 20,
                  itemBuilder: (ctx, i) {
                    final w = i + 1;
                    final isSelected = selectedWeeks.contains(w);
                    return GestureDetector(
                      onTap: () {
                        setLocal(() {
                          if (isSelected) {
                            selectedWeeks.remove(w);
                          } else {
                            selectedWeeks.add(w);
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              isSelected ? Colors.blue[400] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text('$w',
                              style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black)),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildShortcut(setLocal, loc.t('全周', 'All weeks'),
                        selectedWeeks, (w) => true),
                    _buildShortcut(setLocal, loc.t('单周', 'Odd weeks'),
                        selectedWeeks, (w) => w % 2 != 0),
                    _buildShortcut(setLocal, loc.t('双周', 'Even weeks'),
                        selectedWeeks, (w) => w % 2 == 0),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(loc.t('取消', 'Cancel'))),
            TextButton(
              onPressed: () {
                if (selectedWeeks.isEmpty) {
                  Navigator.of(ctx).pop();
                  return;
                }
                final list = selectedWeeks.toList()..sort();
                // Simple formatting: if consecutive, use 1-20, else 1,3,5
                bool consecutive = true;
                for (var i = 0; i < list.length - 1; i++) {
                  if (list[i + 1] != list[i] + 1) {
                    consecutive = false;
                    break;
                  }
                }
                final formatted = (consecutive && list.length > 1)
                    ? '${list.first}-${list.last}'
                    : list.join(',');
                Navigator.of(ctx).pop(formatted);
              },
              child: Text(loc.t('确定', 'OK')),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _timeSlots[index]['weeks'] = result;
      });
    }
  }

  Widget _buildShortcut(StateSetter setLocal, String label, Set<int> selected,
      bool Function(int) filter) {
    return GestureDetector(
      onTap: () {
        setLocal(() {
          selected.clear();
          for (var i = 1; i <= 20; i++) {
            if (filter(i)) selected.add(i);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label),
      ),
    );
  }

  void _showTimePicker(int index) async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final slot = _timeSlots[index];
    int selectedWeekday = slot['weekday'] as int;
    int startSection = slot['startPeriod'] as int;
    int endSection = slot['endPeriod'] as int;

    final weekdays = loc.isEnglish
        ? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
        : const ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final sections = loc.isEnglish
        ? List.generate(12, (i) => 'Period ${i + 1}')
        : List.generate(12, (i) => '第 ${i + 1} 节');

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Center(
              child: Text(loc.t('请选择时间', 'Select Time'),
                  style: const TextStyle(fontSize: 18))),
          content: SizedBox(
            height: 240, // Increased height for better visibility
            width: 400,
            child: Row(
              children: [
                _buildPicker(weekdays, selectedWeekday - 1,
                    (val) => setLocal(() => selectedWeekday = val + 1)),
                _buildPicker(sections, startSection - 1,
                    (val) => setLocal(() => startSection = val + 1)),
                _buildPicker(sections, endSection - 1,
                    (val) => setLocal(() => endSection = val + 1)),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(loc.t('取消', 'Cancel'))),
            TextButton(
              onPressed: () {
                if (startSection > endSection) {
                  showExpressiveSnackBar(
                    ctx,
                    loc.t('开始节次不能大于结束节次',
                        'Start period cannot be after end period'),
                  );
                  return;
                }
                Navigator.of(ctx).pop({
                  'weekday': selectedWeekday,
                  'start': startSection,
                  'end': endSection
                });
              },
              child: Text(loc.t('确定', 'OK')),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _timeSlots[index]['weekday'] = result['weekday'];
        _timeSlots[index]['startPeriod'] = result['start'];
        _timeSlots[index]['endPeriod'] = result['end'];
      });
    }
  }

  Widget _buildPicker(
      List<String> items, int initialIndex, ValueChanged<int> onChanged) {
    // Check if we are on desktop
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    if (isDesktop) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ListView.builder(
            itemCount: items.length,
            shrinkWrap: true,
            itemBuilder: (context, index) => InkWell(
              onTap: () => onChanged(index),
              child: Container(
                height: 40,
                color: initialIndex == index
                    ? Colors.blue.withValues(alpha: 0.1)
                    : null,
                child: Center(
                  child: Text(
                    items[index],
                    style: TextStyle(
                      color: initialIndex == index ? Colors.blue : Colors.black,
                      fontWeight: initialIndex == index
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: ListWheelScrollView.useDelegate(
        itemExtent: 40,
        perspective: 0.005,
        diameterRatio: 1.2,
        physics: const FixedExtentScrollPhysics(),
        controller: FixedExtentScrollController(initialItem: initialIndex),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: items.length,
          builder: (ctx, i) => Center(
            child: Text(items[i], style: const TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }
}
