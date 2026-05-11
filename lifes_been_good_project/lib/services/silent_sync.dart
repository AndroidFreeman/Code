import 'dart:collection';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_config.dart';
import 'database_helper.dart';
import '../models/timetable_item.dart';
import '../models/schedule_event.dart';
import '../main.dart';

String stableDataSignature(Object? value) {
  return jsonEncode(_normalizeStableValue(value));
}

Object? _normalizeStableValue(Object? value) {
  if (value is Map) {
    final sorted = SplayTreeMap<String, Object?>();
    for (final entry in value.entries) {
      sorted[entry.key.toString()] = _normalizeStableValue(entry.value);
    }
    return sorted;
  }
  if (value is Iterable) {
    return value.map(_normalizeStableValue).toList(growable: false);
  }
  if (value is DateTime) {
    return value.toIso8601String();
  }
  return value;
}

class IncrementalSync {
  static Future<void> startSync(
      BuildContext context, VoidCallback onUpdate) async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);

    // Wait 500ms before starting
    await Future.delayed(const Duration(milliseconds: 500));

    // 1. Sync global courses and classes in background
    bool dictUpdated = false;
    try {
      final coursesRes = await ApiConfig.instance.get('/api/courses');
      if (coursesRes['ok'] == true) {
        final data = coursesRes['data'];
        final currentStr =
            await DatabaseHelper.instance.getCacheData('courses');
        final newStr = jsonEncode(data);
        if (currentStr != newStr) {
          await DatabaseHelper.instance.setCacheData('courses', newStr);
          dictUpdated = true;
        }
      }

      final classesRes = await ApiConfig.instance.get('/api/classes');
      if (classesRes['ok'] == true) {
        final data = classesRes['data'];
        final currentStr =
            await DatabaseHelper.instance.getCacheData('classes');
        final newStr = jsonEncode(data);
        if (currentStr != newStr) {
          await DatabaseHelper.instance.setCacheData('classes', newStr);
          dictUpdated = true;
        }
      }
    } catch (_) {}

    // 2. Sync incremental timetable & schedules
    int lastSync = await DatabaseHelper.instance.getLastSyncTime();

    try {
      final res = await ApiConfig.instance.get('/api/sync?since=$lastSync');
      if (res['ok'] == true) {
        final data = res['data'] as Map;
        final timetable = data['timetable'] as List?;
        final schedules = data['schedules'] as List?;
        final timestamp = data['timestamp'] as int?;

        bool hasUpdates = false;

        if (timetable != null && timetable.isNotEmpty) {
          for (final t in timetable) {
            final map = Map<String, dynamic>.from(t as Map);
            map['is_locked'] = map['is_locked'] == true ? 1 : 0;
            final item = TimetableItem.fromJson(map);
            await DatabaseHelper.instance.insertTimetableItem(item,
                updatedAt: map['updated_at'] as int? ?? 0);
          }
          hasUpdates = true;
        }

        if (schedules != null && schedules.isNotEmpty) {
          for (final s in schedules) {
            final map = Map<String, dynamic>.from(s as Map);
            final event = ScheduleEvent.fromMap(map);
            await DatabaseHelper.instance.insertScheduleEvent(event);
          }
          hasUpdates = true;
        }

        if (timestamp != null) {
          await DatabaseHelper.instance.setLastSyncTime(timestamp);
        }

        if (hasUpdates || dictUpdated) {
          onUpdate();
          _showBanner(context, loc.t('已同步课表 ✓', 'Timetable synced ✓'));
        } else {
          _showBanner(
              context, loc.t('本地数据库 · 刚刚', 'Local database · Just now'));
        }
      } else if (dictUpdated) {
        onUpdate();
        _showBanner(context, loc.t('已同步课表 ✓', 'Timetable synced ✓'));
      }
    } catch (e) {
      // Retry once if failed
      await Future.delayed(const Duration(seconds: 2));
      try {
        final res2 = await ApiConfig.instance.get('/api/sync?since=$lastSync');
        if (res2['ok'] == true) {
          final data = res2['data'] as Map;
          final timestamp = data['timestamp'] as int?;
          if (timestamp != null) {
            await DatabaseHelper.instance.setLastSyncTime(timestamp);
          }
          _showBanner(context, loc.t('已同步课表 ✓', 'Timetable synced ✓'));
          onUpdate();
        }
      } catch (_) {
        // Silently fail
      }
    }
  }

  static void _showBanner(BuildContext context, String message) {
    if (!context.mounted) return;

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      entry.remove();
    });
  }
}
