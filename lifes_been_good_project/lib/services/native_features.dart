import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

class NativeFeatures {
  final String dataDir;
  final String? nativeLibDir;

  const NativeFeatures({required this.dataDir, this.nativeLibDir});

  String _featurePath(String baseName) {
    if (Platform.isAndroid && nativeLibDir != null) {
      return p.join(nativeLibDir!, 'lib$baseName.so');
    }
    final name = Platform.isWindows ? '$baseName.exe' : baseName;
    return p.join(dataDir, 'bin', name);
  }

  Future<bool> hasFeature(String baseName) async {
    final exePath = _featurePath(baseName);
    return File(exePath).exists();
  }

  Future<Map<String, dynamic>> listStudents() async {
    final exePath = _featurePath('students_list');
    final exists = await File(exePath).exists();
    if (!exists) {
      return {
        'ok': false,
        'error': {
          'code': 'missing_binary',
          'message': '未找到二进制：$exePath',
        },
      };
    }

    final res = await Process.run(
      exePath,
      [dataDir],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> insertStudent({
    required String id,
    required String studentNo,
    required String fullName,
    required String classCode,
    required String phone,
    required String position,
  }) async {
    final exePath = _featurePath('students_insert');
    final exists = await File(exePath).exists();
    if (!exists) {
      return {
        'ok': false,
        'error': {
          'code': 'missing_binary',
          'message': '未找到二进制：$exePath',
        },
      };
    }

    final res = await Process.run(
      exePath,
      [dataDir, id, studentNo, fullName, classCode, phone, position],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> deleteStudent(
      {required String fullName, required String studentNo}) async {
    final exePath = _featurePath('students_delete');
    final exists = await File(exePath).exists();
    if (!exists) {
      return {
        'ok': false,
        'error': {
          'code': 'missing_binary',
          'message': '未找到二进制：$exePath',
        },
      };
    }

    final res = await Process.run(
      exePath,
      [dataDir, fullName, studentNo],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> systemInit({required bool seed}) async {
    final exePath = _featurePath('system_init');
    final exists = await File(exePath).exists();
    if (!exists) {
      return {
        'ok': false,
        'error': {
          'code': 'missing_binary',
          'message': '未找到二进制：$exePath',
        },
      };
    }

    final args = <String>[dataDir];
    if (seed) args.add('--seed');
    final res = await Process.run(exePath, args,
        stdoutEncoding: utf8, stderrEncoding: utf8);
    return _decode(res);
  }

  Future<Map<String, dynamic>> listProfiles() async {
    final exePath = _featurePath('profiles_list');
    final exists = await File(exePath).exists();
    if (!exists) {
      return {
        'ok': false,
        'error': {
          'code': 'missing_binary',
          'message': '未找到二进制：$exePath',
        },
      };
    }

    final res = await Process.run(exePath, [dataDir],
        stdoutEncoding: utf8, stderrEncoding: utf8);
    return _decode(res);
  }

  Future<Map<String, dynamic>> listCourses() async {
    final exePath = _featurePath('courses_list');
    final exists = await File(exePath).exists();
    if (!exists) {
      return {
        'ok': false,
        'error': {
          'code': 'missing_binary',
          'message': '未找到二进制：$exePath',
        },
      };
    }

    final res = await Process.run(exePath, [dataDir],
        stdoutEncoding: utf8, stderrEncoding: utf8);
    return _decode(res);
  }

  Future<Map<String, dynamic>> insertCourse({
    required String id,
    required String name,
    required String teacherId,
    required String term,
    required String color,
    required String credits,
    required String notes,
  }) async {
    final exePath = _featurePath('courses_insert');
    final exists = await File(exePath).exists();
    if (!exists) {
      return {
        'ok': false,
        'error': {
          'code': 'missing_binary',
          'message': '未找到二进制：$exePath',
        },
      };
    }

    final res = await Process.run(
      exePath,
      [dataDir, id, name, teacherId, term, color, credits, notes],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> listTimetable() async {
    final exePath = _featurePath('timetable_list');
    final exists = await File(exePath).exists();
    if (!exists) {
      return {
        'ok': false,
        'error': {
          'code': 'missing_binary',
          'message': '未找到二进制：$exePath',
        },
      };
    }

    final res = await Process.run(exePath, [dataDir],
        stdoutEncoding: utf8, stderrEncoding: utf8);
    return _decode(res);
  }

  Future<Map<String, dynamic>> insertTimetableItem({
    required String id,
    required String owner,
    required int weekday,
    required int startPeriod,
    required int endPeriod,
    required String startTime,
    required String endTime,
    required String courseId,
    required String location,
    required String creator,
    required bool isLocked,
    required String weeks,
  }) async {
    final exePath = _featurePath('timetable_insert');
    final exists = await File(exePath).exists();
    if (!exists) {
      return {
        'ok': false,
        'error': {
          'code': 'missing_binary',
          'message': '未找到二进制：$exePath',
        },
      };
    }

    final res = await Process.run(
      exePath,
      [
        dataDir,
        id,
        owner,
        weekday.toString(),
        startPeriod.toString(),
        endPeriod.toString(),
        startTime,
        endTime,
        courseId,
        location,
        creator,
        isLocked ? 'true' : 'false',
        weeks
      ],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> listContacts() async {
    final exePath = _featurePath('contacts_list');
    final exists = await File(exePath).exists();
    if (!exists) {
      return {
        'ok': false,
        'error': {
          'code': 'missing_binary',
          'message': '未找到二进制：$exePath',
        },
      };
    }

    final res = await Process.run(exePath, [dataDir],
        stdoutEncoding: utf8, stderrEncoding: utf8);
    return _decode(res);
  }

  Future<Map<String, dynamic>> listTodos() async {
    final exePath = _featurePath('todos_list');
    final exists = await File(exePath).exists();
    if (!exists) {
      return {
        'ok': false,
        'error': {
          'code': 'missing_binary',
          'message': '未找到二进制：$exePath',
        },
      };
    }

    final res = await Process.run(exePath, [dataDir],
        stdoutEncoding: utf8, stderrEncoding: utf8);
    return _decode(res);
  }

  Future<Map<String, dynamic>> addTodo(
      {required String ownerProfileId, required String title}) async {
    final exePath = _featurePath('todos_add');
    final exists = await File(exePath).exists();
    if (!exists) {
      return {
        'ok': false,
        'error': {
          'code': 'missing_binary',
          'message': '未找到二进制：$exePath',
        },
      };
    }

    final res = await Process.run(exePath, [dataDir, ownerProfileId, title],
        stdoutEncoding: utf8, stderrEncoding: utf8);
    return _decode(res);
  }

  Future<Map<String, dynamic>> toggleTodo({required String id}) async {
    final exePath = _featurePath('todos_toggle');
    final exists = await File(exePath).exists();
    if (!exists) {
      return {
        'ok': false,
        'error': {
          'code': 'missing_binary',
          'message': '未找到二进制：$exePath',
        },
      };
    }

    final res = await Process.run(exePath, [dataDir, id],
        stdoutEncoding: utf8, stderrEncoding: utf8);
    return _decode(res);
  }

  Future<Map<String, dynamic>> startAttendanceSession({
    required String courseId,
    required String createdByProfileId,
    int? week,
    int? period,
  }) async {
    try {
      final f = File(p.join(dataDir, 'attendance_sessions.csv'));
      if (!await f.exists()) {
        await f.writeAsString('id,course_id,created_by_profile_id,started_at,ended_at,week,period\n');
      } else {
        final content = await f.readAsString();
        if (!content.startsWith('id,course_id,created_by_profile_id,started_at,ended_at,week,period')) {
          final lines = const LineSplitter().convert(content);
          final out = <String>['id,course_id,created_by_profile_id,started_at,ended_at,week,period'];
          for (var i = 1; i < lines.length; i++) {
            if (lines[i].trim().isEmpty) continue;
            out.add('${lines[i].trim()},,');
          }
          await f.writeAsString('${out.join('\n')}\n');
        }
      }
      
      final id = 'as_${DateTime.now().millisecondsSinceEpoch}';
      final startedAt = '${DateTime.now().toUtc().toIso8601String().split('.').first}Z';
      final w = week?.toString() ?? '';
      final pStr = period?.toString() ?? '';
      await f.writeAsString('$id,$courseId,$createdByProfileId,$startedAt,,$w,$pStr\n', mode: FileMode.append);
      return {'ok': true, 'data': {'session_id': id, 'started_at': startedAt}};
    } catch(e) {
      return {'ok': false, 'error': {'message': e.toString()}};
    }
  }

  Future<Map<String, dynamic>> markAttendanceRecord({
    required String sessionId,
    required String studentId,
    required String status,
    required String markedByProfileId,
  }) async {
    final exePath = _featurePath('attendance_record_mark');
    final exists = await File(exePath).exists();
    if (!exists) {
      return {
        'ok': false,
        'error': {
          'code': 'missing_binary',
          'message': '未找到二进制：$exePath',
        },
      };
    }

    final res = await Process.run(
      exePath,
      [dataDir, sessionId, studentId, status, markedByProfileId],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> csvOp({
    required String action,
    required String file,
    List<String>? headers,
    List<Map<String, dynamic>>? rows,
  }) async {
    final exePath = _featurePath('csv_op');
    final exists = await File(exePath).exists();
    if (!exists) {
      return {
        'ok': false,
        'error': {
          'code': 'missing_binary',
          'message': '未找到二进制：$exePath',
        },
      };
    }

    final payload = <String, dynamic>{
      'action': action,
      'file': file,
    };
    if (headers != null) payload['headers'] = headers;
    if (rows != null) payload['rows'] = rows;

    final res = await Process.run(
      exePath,
      [dataDir, jsonEncode(payload)],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> jsonOp({
    required String action,
    required String file,
    dynamic data,
  }) async {
    final exePath = _featurePath('json_op');
    final exists = await File(exePath).exists();
    if (!exists) {
      return {
        'ok': false,
        'error': {
          'code': 'missing_binary',
          'message': '未找到二进制：$exePath',
        },
      };
    }

    final payload = <String, dynamic>{
      'action': action,
      'file': file,
    };
    if (data != null) payload['data'] = data;

    final res = await Process.run(
      exePath,
      [dataDir, jsonEncode(payload)],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    return _decode(res);
  }

  Map<String, dynamic> _decode(ProcessResult res) {
    final stdoutStr = (res.stdout is String)
        ? (res.stdout as String)
        : utf8.decode(res.stdout as List<int>);
    final stderrStr = (res.stderr is String)
        ? (res.stderr as String)
        : utf8.decode(res.stderr as List<int>);

    if (stdoutStr.trim().isEmpty) {
      return {
        'ok': false,
        'error': {
          'code': 'empty_output',
          'message': stderrStr.trim().isEmpty
              ? 'Binary returned no output. Exit code: ${res.exitCode}'
              : stderrStr.trim(),
        },
      };
    }

    try {
      final decoded = jsonDecode(stdoutStr) as Map<String, dynamic>;
      if (decoded['ok'] == true) return decoded;
      if (decoded['error'] is Map<String, dynamic>) return decoded;
      return {
        'ok': false,
        'error': {
          'code': 'invalid_response',
          'message': 'Binary returned invalid JSON structure'
        },
      };
    } catch (e) {
      return {
        'ok': false,
        'error': {
          'code': 'json_parse_error',
          'message':
              'Failed to parse binary output: $e\nOutput was: $stdoutStr',
        },
      };
    }
  }
}
