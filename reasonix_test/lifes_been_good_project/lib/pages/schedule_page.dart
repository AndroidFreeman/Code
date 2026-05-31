import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schedule_event.dart';
import '../services/database_helper.dart';
import '../state/session.dart';
import '../state/locale_provider.dart';
import '../widgets/expressive_ui.dart';
import 'add_schedule_page.dart';
import '../models/timetable_item.dart';

class SchedulePage extends StatefulWidget {
  final Session session;
  final VoidCallback? onReady;

  const SchedulePage({super.key, required this.session, this.onReady});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<ScheduleEvent> _events = [];
  DateTime _currentWeekStart = _getStartOfWeek(DateTime.now());
  late PageController _pageController;

  static DateTime _getStartOfWeek(DateTime date) {
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 500); // Start at middle
    _loadEvents();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final events = await DatabaseHelper.instance.getScheduleEvents();
    if (!mounted) return;
    setState(() {
      _events = events;
    });
    widget.onReady?.call();
  }

  Future<void> _importFromTimetable() async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final ttItems = await DatabaseHelper.instance.getTimetableItems();
    if (ttItems.isEmpty) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(loc.t('没有可导入的课表数据', 'No timetable data to import'))));
      return;
    }

    // Auto import all for demo, or show selection. Let's just import all for simplicity.
    int imported = 0;
    for (final tt in ttItems) {
      // Find course name (we might not have it in TT, usually need to query courses.csv, but for simplicity let's use courseId as title if we can't find it)
      // Wait, we can get course info from native feature.
      String title = tt.courseId;
      try {
        final res = await widget.session.features.listCourses();
        if (res['ok'] == true) {
          final courses = ((res['data'] as Map?)?['items'] as List?) ?? [];
          for (final c in courses) {
            if (c['id'] == tt.courseId) {
              title = c['course_name'] ?? tt.courseId;
              break;
            }
          }
        }
      } catch (_) {}

      // Just create one schedule event for the next occurrence of this weekday
      final now = DateTime.now();
      int diff = tt.weekday - now.weekday;
      if (diff < 0) diff += 7;
      final targetDate = now.add(Duration(days: diff));

      final startStr =
          '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')} ${tt.startTime}:00';
      final endStr =
          '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')} ${tt.endTime}:00';

      final event = ScheduleEvent(
        id: 'se_${DateTime.now().microsecondsSinceEpoch}_$imported',
        title: title,
        location: tt.location,
        startTime: startStr,
        endTime: endStr,
        type: '学习',
        backgroundColor: 'FF2196F3',
        note: 'Imported from timetable',
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await DatabaseHelper.instance.insertScheduleEvent(event);
      imported++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.t('成功导入 $imported 个日程',
              'Successfully imported $imported schedules'))));
      _loadEvents();
    }
  }

  int _timeToMinutes(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      }
    } catch (_) {}
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocaleProvider>(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('日程表', 'Schedule')),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: loc.t('从课表导入', 'Import from Timetable'),
            onPressed: () async {
              // Not fully implemented multi-select here to keep it simple, but we can call a method
              await _importFromTimetable();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final res = await Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => AddSchedulePage(session: widget.session)),
              );
              if (res == true) _loadEvents();
            },
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              _pageController.animateToPage(
                500,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              setState(() {
                _currentWeekStart = _getStartOfWeek(DateTime.now());
              });
            },
          )
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          final diff = index - 500;
          setState(() {
            _currentWeekStart =
                _getStartOfWeek(DateTime.now().add(Duration(days: diff * 7)));
          });
        },
        itemBuilder: (context, index) {
          final weekStart = _getStartOfWeek(
              DateTime.now().add(Duration(days: (index - 500) * 7)));
          return _buildWeekView(weekStart, cs);
        },
      ),
    );
  }

  Widget _buildWeekView(DateTime weekStart, ColorScheme cs) {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final days = ['一', '二', '三', '四', '五', '六', '日'];
    final enDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            border: Border(bottom: BorderSide(color: cs.outlineVariant)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 50),
              ...List.generate(7, (i) {
                final date = weekStart.add(Duration(days: i));
                final isToday = date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;
                return Expanded(
                  child: Column(
                    children: [
                      Text(loc.t(days[i], enDays[i]),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isToday ? cs.primary : cs.onSurface)),
                      Text('${date.month}/${date.day}',
                          style: TextStyle(
                              fontSize: 12,
                              color:
                                  isToday ? cs.primary : cs.onSurfaceVariant)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        // Grid
        Expanded(
          child: SingleChildScrollView(
            child: SizedBox(
              height: 24 * 60.0, // 60 pixels per hour
              child: Stack(
                children: [
                  // Time lines
                  for (int h = 0; h < 24; h++)
                    Positioned(
                      top: h * 60.0,
                      left: 0,
                      right: 0,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 50,
                            child: Text(
                              '${h.toString().padLeft(2, '0')}:00',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12, color: cs.onSurfaceVariant),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: cs.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Vertical lines
                  for (int d = 0; d < 7; d++)
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 50 +
                          d * ((MediaQuery.of(context).size.width - 50) / 7),
                      width: 1,
                      child: Container(
                          color: cs.outlineVariant.withValues(alpha: 0.3)),
                    ),
                  // Events
                  for (final event in _events)
                    ..._buildEventWidgets(event, weekStart, cs),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildEventWidgets(
      ScheduleEvent event, DateTime weekStart, ColorScheme cs) {
    // For simplicity, assuming event happens every week if it doesn't have a specific date.
    // Wait, schedule_event only has start_time and end_time, e.g., "2026-05-11 08:00".
    // Let's parse full datetime.
    final widgets = <Widget>[];
    try {
      final startDt = DateTime.parse(event.startTime);
      final endDt = DateTime.parse(event.endTime);

      if (startDt.isBefore(weekStart.add(const Duration(days: 7))) &&
          endDt.isAfter(weekStart)) {
        // It's in this week
        int dayIndex = startDt.weekday - 1;

        final startMin = startDt.hour * 60 + startDt.minute;
        final endMin = endDt.hour * 60 + endDt.minute;

        // Handle cross-day events later, assuming same-day for now
        final top = startMin.toDouble();
        final height = (endMin - startMin).toDouble();

        Color bgColor = Colors.blue;
        if (event.backgroundColor.isNotEmpty) {
          try {
            bgColor = Color(int.parse(event.backgroundColor, radix: 16));
          } catch (_) {}
        }

        final colWidth = (MediaQuery.of(context).size.width - 50) / 7;

        widgets.add(
          Positioned(
            top: top,
            left: 50 + dayIndex * colWidth + 1,
            width: colWidth - 2,
            height: height > 0 ? height : 30,
            child: GestureDetector(
              onTap: () async {
                final res = await Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => AddSchedulePage(
                          session: widget.session, event: event)),
                );
                if (res == true) _loadEvents();
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: bgColor.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (height >= 40)
                      Text(
                        event.location,
                        style:
                            const TextStyle(fontSize: 9, color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    } catch (_) {}
    return widgets;
  }
}
