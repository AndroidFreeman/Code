import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/profile.dart';
import '../models/student.dart';
import 'api_config.dart';
import 'native_features.dart';

class LocalProfiles {
  static const _header =
      'id,role,staff_no,student_no,display_name,real_name,org_code,class_code,password_hash,created_at,phone,email,dorm,avatar,signature';
  static const _studentsHeader =
      'id,student_no,full_name,class_code,phone,position';

  static String? validateAccountNo({
    required String role,
    required String accountNo,
  }) {
    final v = accountNo.trim();
    if (v.isEmpty) return '账号不能为空';
    if (role == 'teacher') {
      if (!v.startsWith('T')) return '老师工号必须以 T 开头';
      return null;
    }
    if (!v.startsWith('S')) return '学生学号必须以 S 开头';
    return null;
  }

  static File profilesFile(String dataDir) {
    return File(p.join(dataDir, 'profiles.csv'));
  }

  static File studentsFile(String dataDir) {
    return File(p.join(dataDir, 'students.csv'));
  }

  static Future<String> saveProfileAvatarFile({
    required String dataDir,
    required String profileId,
    required List<int> bytes,
    String extension = '.jpg',
  }) async {
    final sanitizedExt = extension.startsWith('.') ? extension : '.$extension';
    final dir = Directory(p.join(dataDir, 'profile_avatars'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = File(p.join(dir.path, '$profileId$sanitizedExt'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static String _fnv1a64Hex(String input) {
    const offset = 0xcbf29ce484222325;
    const prime = 0x100000001b3;
    var hash = BigInt.from(offset);
    for (final b in utf8.encode(input)) {
      hash = hash ^ BigInt.from(b);
      hash = (hash * BigInt.from(prime)) &
          BigInt.parse('FFFFFFFFFFFFFFFF', radix: 16);
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  static Future<void> ensureSchema(String dataDir) async {
    final f = profilesFile(dataDir);
    if (!await f.exists()) {
      await f.writeAsString('$_header\n', encoding: utf8);
      return;
    }
    String firstLine;
    try {
      firstLine = await f
          .openRead(0, 4096)
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first;
    } catch (_) {
      await f.writeAsString('$_header\n', encoding: utf8);
      return;
    }
    if (firstLine.trim() == _header) return;
    if (firstLine.trim() == 'id,role,display_name,org_code,class_code') {
      final original = await f.readAsString(encoding: utf8);
      final lines = const LineSplitter().convert(original);
      final out = <String>[_header];
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = _splitCsvLine(line);
        if (parts.length < 5) continue;
        final id = parts[0];
        final role = parts[1];
        final display = parts[2];
        final org = parts[3];
        final cls = parts[4];
        out.add(
            '$id,$role,,,${_csvEncode(display)},${_csvEncode(display)},${_csvEncode(org)},${_csvEncode(cls)},,,,,,,');
      }
      await f.writeAsString('${out.join('\n')}\n', encoding: utf8);
      return;
    }
    if (firstLine.trim() ==
        'id,role,staff_no,student_no,display_name,org_code,class_code,password_hash,created_at') {
      final original = await f.readAsString(encoding: utf8);
      final lines = const LineSplitter().convert(original);
      final out = <String>[_header];
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = _splitCsvLine(line);
        if (parts.length < 9) continue;
        // insert real_name after display_name
        final display = parts[4];
        out.add(
            '${parts[0]},${parts[1]},${parts[2]},${parts[3]},$display,$display,${parts[5]},${parts[6]},${parts[7]},${parts[8]},,,,,');
      }
      await f.writeAsString('${out.join('\n')}\n', encoding: utf8);
      return;
    }
    if (firstLine.trim() ==
        'id,role,staff_no,student_no,display_name,org_code,class_code,password_hash,created_at,phone,email,dorm,avatar,signature') {
      final original = await f.readAsString(encoding: utf8);
      final lines = const LineSplitter().convert(original);
      final out = <String>[_header];
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = _splitCsvLine(line);
        if (parts.length < 14) continue;
        final display = parts[4];
        out.add(
            '${parts[0]},${parts[1]},${parts[2]},${parts[3]},$display,$display,${parts[5]},${parts[6]},${parts[7]},${parts[8]},${parts[9]},${parts[10]},${parts[11]},${parts[12]},${parts[13]}');
      }
      await f.writeAsString('${out.join('\n')}\n', encoding: utf8);
      return;
    }
  }

  static Future<void> ensureStudentsSchema(String dataDir) async {
    final f = studentsFile(dataDir);
    if (!await f.exists()) {
      await f.writeAsString('$_studentsHeader\n', encoding: utf8);
      return;
    }
    String firstLine;
    try {
      firstLine = await f
          .openRead(0, 4096)
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first;
    } catch (_) {
      await f.writeAsString('$_studentsHeader\n', encoding: utf8);
      return;
    }

    final header = firstLine.trim();
    if (header == _studentsHeader) return;
    if (header == 'id,student_no,full_name,class_code,phone') {
      final original = await f.readAsString(encoding: utf8);
      final lines = const LineSplitter().convert(original);
      final out = <String>[_studentsHeader];
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = _splitCsvLine(line);
        if (parts.length < 5) continue;
        out.add('${parts[0]},${parts[1]},${parts[2]},${parts[3]},${parts[4]},');
      }
      await f.writeAsString('${out.join('\n')}\n', encoding: utf8);
      return;
    }
  }

  static Future<String> loadStudentPosition({
    required String dataDir,
    required Profile profile,
  }) async {
    if (profile.role.trim().toLowerCase() == 'teacher') return '';

    final studentNo = profile.studentNo.trim();
    final staffNo = profile.staffNo.trim();
    final id = profile.id.trim();

    String foundPosition = '';

    if (ApiConfig.instance.useCloud) {
      final res = await ApiConfig.instance.get('/api/students');
      if (res['ok'] == true) {
        final rawData = res['data'];
        final rows = (rawData is List)
            ? rawData
            : ((rawData as Map?)?['items'] as List? ?? []);
        for (final row in rows) {
          final r = (row as Map).cast<String, dynamic>();
          final rNo = (r['student_no'] ?? '').toString().trim();
          final rId = (r['id'] ?? '').toString().trim();
          final rFullName = (r['full_name'] ?? '').toString().trim();

          bool match = false;
          if (studentNo.isNotEmpty &&
              rNo.toLowerCase() == studentNo.toLowerCase()) {
            match = true;
          } else if (staffNo.isNotEmpty &&
              rNo.toLowerCase() == staffNo.toLowerCase()) {
            match = true;
          } else if (id.isNotEmpty && rId == id) {
            match = true;
          } else if (profile.realName.isNotEmpty &&
              rFullName == profile.realName &&
              rNo.isEmpty) {
            match = true;
          }

          if (match) {
            final pos = (r['position'] ?? '').toString().trim();
            if (pos.isNotEmpty) return pos;
            foundPosition = pos;
          }
        }
      }
      return foundPosition;
    }

    await ensureStudentsSchema(dataDir);
    final f = studentsFile(dataDir);
    final rows = await _readRowsFromFile(f);

    for (final r in rows) {
      final rNo = (r['student_no'] ?? '').trim();
      final rId = (r['id'] ?? '').trim();
      final rFullName = (r['full_name'] ?? '').trim();

      bool match = false;
      // Multi-layer matching strategy
      if (studentNo.isNotEmpty &&
          rNo.toLowerCase() == studentNo.toLowerCase()) {
        match = true;
      } else if (staffNo.isNotEmpty &&
          rNo.toLowerCase() == staffNo.toLowerCase()) {
        match = true;
      } else if (id.isNotEmpty && rId == id) {
        match = true;
      } else if (profile.realName.isNotEmpty &&
          rFullName == profile.realName &&
          rNo.isEmpty) {
        // Fallback to full_name matching only if the CSV row has no student number
        match = true;
      }

      if (match) {
        final pos = (r['position'] ?? '').trim();
        if (pos.isNotEmpty)
          return pos; // Found a valid position, return immediately
        foundPosition = pos; // Keep track of the last matched (even if empty)
      }
    }
    return foundPosition;
  }

  static String loadStudentPositionFast({
    required String dataDir,
    required Profile profile,
  }) {
    if (profile.role.trim().toLowerCase() == 'teacher') return '';
    if (ApiConfig.instance.useCloud) return '';

    try {
      final f = studentsFile(dataDir);
      if (!f.existsSync()) return '';
      final lines = const LineSplitter().convert(f.readAsStringSync());
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = _splitCsvLine(line);
        if (parts.length < 6) continue;
        final id = parts[0].trim();
        final studentNo = parts[1].trim();
        final position = parts[5].trim();
        final match = (profile.id.isNotEmpty && id == profile.id) ||
            (profile.studentNo.isNotEmpty &&
                studentNo.toLowerCase() == profile.studentNo.toLowerCase()) ||
            (profile.staffNo.isNotEmpty &&
                studentNo.toLowerCase() == profile.staffNo.toLowerCase());
        if (match) return position;
      }
    } catch (_) {}
    return '';
  }

  static String _csvEncode(String s) {
    if (s.contains(',') || s.contains('"')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static List<String> _splitCsvLine(String line) {
    final parts = <String>[];
    int start = 0;
    bool inQuotes = false;
    for (int j = 0; j < line.length; j++) {
      if (line[j] == '"') {
        inQuotes = !inQuotes;
      } else if (line[j] == ',' && !inQuotes) {
        parts.add(line
            .substring(start, j)
            .replaceAll('""', '"')
            .replaceAll(RegExp(r'^"|"$'), ''));
        start = j + 1;
      }
    }
    parts.add(line
        .substring(start)
        .replaceAll('""', '"')
        .replaceAll(RegExp(r'^"|"$'), ''));
    return parts;
  }

  static String _safe(String s) {
    return s;
  }

  static Future<List<Map<String, String>>> _readRowsFromFile(File f) async {
    if (!await f.exists()) return const [];
    final content = await f.readAsString(encoding: utf8);
    final lines = const LineSplitter()
        .convert(content)
        .where((e) => e.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return const [];
    final headers = _splitCsvLine(lines.first).map((e) => e.trim()).toList();
    final rows = <Map<String, String>>[];
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];
      final parts = <String>[];
      int start = 0;
      bool inQuotes = false;
      for (int j = 0; j < line.length; j++) {
        if (line[j] == '"') {
          inQuotes = !inQuotes;
        } else if (line[j] == ',' && !inQuotes) {
          parts.add(line
              .substring(start, j)
              .replaceAll('""', '"')
              .replaceAll(RegExp(r'^"|"$'), ''));
          start = j + 1;
        }
      }
      parts.add(line
          .substring(start)
          .replaceAll('""', '"')
          .replaceAll(RegExp(r'^"|"$'), ''));

      final row = <String, String>{};
      for (var j = 0; j < headers.length && j < parts.length; j++) {
        row[headers[j]] = parts[j];
      }
      rows.add(row);
    }
    return rows;
  }

  static Future<List<Map<String, String>>> _readRows(String dataDir) async {
    return _readRowsFromFile(profilesFile(dataDir));
  }

  static Future<List<String>> getTeacherClasses(
      String dataDir, String profileId) async {
    if (ApiConfig.instance.useCloud) {
      final res = await ApiConfig.instance.get('/api/profiles');
      if (res['ok'] == true) {
        final rawData = res['data'];
        final rows = (rawData is List)
            ? rawData
            : ((rawData as Map?)?['items'] as List? ?? []);
        for (final r in rows) {
          if (r['id'] == profileId) {
            final code = (r['class_code'] ?? '').trim();
            return code
                .split('|')
                .where((e) => (e as String).isNotEmpty)
                .toList();
          }
        }
      }
      return [];
    }
    final rows = await _readRows(dataDir);
    for (final r in rows) {
      if (r['id'] == profileId) {
        final code = (r['class_code'] ?? '').trim();
        return code.split('|').where((e) => e.isNotEmpty).toList();
      }
    }
    return [];
  }

  static Future<List<Map<String, String>>> getAllClassesWithNames(
      String dataDir) async {
    final classesMap = <String, String>{};

    try {
      final features = NativeFeatures(dataDir: dataDir);
      final res = await features.listClasses();
      if (res['ok'] == true && res['data'] != null) {
        final rawData = res['data'];
        final rows = (rawData is List)
            ? rawData
            : (rawData is Map
                ? (rawData['items'] ?? const []) as List
                : const []);
        for (final r in rows) {
          final id = (r['id'] ?? r['classCode'] ?? '').toString().trim();
          final name =
              (r['className'] ?? r['class_name'] ?? '').toString().trim();
          if (id.isNotEmpty) {
            classesMap[id] = name.isNotEmpty ? name : id;
          }
        }
      }
    } catch (_) {}

    // Fallback/Supplement: Scan profiles only if listClasses was empty or failed
    if (classesMap.isEmpty) {
      try {
        await ensureSchema(dataDir);
        final rows = await _readRows(dataDir);
        for (final r in rows) {
          final code = (r['class_code'] ?? '').trim();
          if (code.isNotEmpty) {
            if ((r['role'] ?? '') == 'teacher') {
              for (final c in code.split('|').where((e) => e.isNotEmpty)) {
                if (!classesMap.containsKey(c)) classesMap[c] = c;
              }
            } else {
              if (!classesMap.containsKey(code)) classesMap[code] = code;
            }
          }
        }
      } catch (_) {}
    }

    final result =
        classesMap.entries.map((e) => {'id': e.key, 'name': e.value}).toList();
    result.sort((a, b) => a['id']!.compareTo(b['id']!));
    return result;
  }

  static Future<List<String>> getAllClasses(String dataDir) async {
    if (ApiConfig.instance.useCloud) {
      final classes = <String>{};
      final classRes = await ApiConfig.instance.get('/api/classes');
      if (classRes['ok'] == true) {
        final rawData = classRes['data'];
        final rows = (rawData is List)
            ? rawData
            : (rawData is Map
                ? (rawData['items'] ?? const []) as List
                : const []);
        for (final r in rows) {
          final id = (r['id'] ?? '').toString().trim();
          if (id.isNotEmpty) classes.add(id);
        }
      }
      final list = classes.toList();
      list.sort();
      return list;
    }
    await ensureSchema(dataDir);
    final rows = await _readRows(dataDir);
    final classes = <String>{};
    for (final r in rows) {
      final code = (r['class_code'] ?? '').trim();
      if (code.isNotEmpty) {
        // Teachers might have multiple classes joined by |
        if ((r['role'] ?? '') == 'teacher') {
          classes.addAll(code.split('|').where((e) => e.isNotEmpty));
        } else {
          classes.add(code);
        }
      }
    }
    // Also check students.csv just in case
    await ensureStudentsSchema(dataDir);
    final sRows = await _readRowsFromFile(studentsFile(dataDir));
    for (final r in sRows) {
      final code = (r['class_code'] ?? '').trim();
      if (code.isNotEmpty) classes.add(code);
    }
    final list = classes.toList();
    list.sort();
    return list;
  }

  static Future<void> addTeacherClass(
      String dataDir, String profileId, String newClass) async {
    final targetClass = newClass.trim();
    if (targetClass.isEmpty) return;

    if (ApiConfig.instance.useCloud) {
      final classes = await getTeacherClasses(dataDir, profileId);
      if (!classes.contains(targetClass)) {
        classes.add(targetClass);
        final payload = {'class_code': classes.join('|')};
        await ApiConfig.instance
            .put('/api/profiles/$profileId/classes', payload);
      }
      return;
    }
    await ensureSchema(dataDir);
    final f = profilesFile(dataDir);
    final rows = await _readRows(dataDir);
    final headers = _header.split(',');

    for (final r in rows) {
      if (r['id'] == profileId) {
        final current = (r['class_code'] ?? '').trim();
        final classes = current.split('|').where((e) => e.isNotEmpty).toList();
        if (!classes.contains(targetClass)) {
          classes.add(targetClass);
          r['class_code'] = classes.join('|');
        }
      }
    }

    final out = <String>[_header];
    for (final r in rows) {
      out.add(headers.map((h) {
        String val = r[h] ?? '';
        return _csvEncode(val);
      }).join(','));
    }
    await f.writeAsString('${out.join('\n')}\n', encoding: utf8);
  }

  static Future<void> removeTeacherClass(
      String dataDir, String profileId, String classCode) async {
    if (ApiConfig.instance.useCloud) {
      final classes = await getTeacherClasses(dataDir, profileId);
      classes.remove(classCode.trim());
      final payload = {'class_code': classes.join('|')};
      await ApiConfig.instance.put('/api/profiles/$profileId/classes', payload);
      return;
    }
    await ensureSchema(dataDir);
    final f = profilesFile(dataDir);
    final rows = await _readRows(dataDir);
    final headers = _header.split(',');

    for (final r in rows) {
      if (r['id'] == profileId) {
        final current = (r['class_code'] ?? '').trim();
        final classes = current.split('|').where((e) => e.isNotEmpty).toList();
        classes.remove(classCode.trim());
        r['class_code'] = classes.join('|');
      }
    }

    final out = <String>[_header];
    for (final r in rows) {
      out.add(headers.map((h) {
        String val = r[h] ?? '';
        return _csvEncode(val);
      }).join(','));
    }
    await f.writeAsString('${out.join('\n')}\n', encoding: utf8);
  }

  static Future<void> disbandClassLocally(
      String dataDir, String classCode) async {
    final targetClass = classCode.trim();
    if (targetClass.isEmpty) return;

    // 1. Remove classCode from all profiles (students and teachers)
    await ensureSchema(dataDir);
    final pf = profilesFile(dataDir);
    final pRows = await _readRows(dataDir);
    final pHeaders = _header.split(',');

    for (final r in pRows) {
      final role = r['role'] ?? '';
      if (role == 'student' || role == 'cadre') {
        if ((r['class_code'] ?? '').trim() == targetClass) {
          r['class_code'] = '';
        }
      } else if (role == 'teacher') {
        final current = (r['class_code'] ?? '').trim();
        final classes = current.split('|').where((e) => e.isNotEmpty).toList();
        classes.remove(targetClass);
        r['class_code'] = classes.join('|');
      }
    }

    final pOut = <String>[_header];
    for (final r in pRows) {
      pOut.add(pHeaders.map((h) {
        String val = r[h] ?? '';
        return _csvEncode(val);
      }).join(','));
    }
    await pf.writeAsString('${pOut.join('\n')}\n', encoding: utf8);

    // 2. Remove classCode from all students in students.csv
    await ensureStudentsSchema(dataDir);
    final sf = studentsFile(dataDir);
    final sRows = await _readRowsFromFile(sf);
    final sHeaders = _studentsHeader.split(',');
    final classStudentIds = <String>{};

    for (final r in sRows) {
      if ((r['class_code'] ?? '').trim() == targetClass) {
        classStudentIds.add((r['id'] ?? '').trim());
        r['class_code'] = '';
      }
    }

    final sOut = <String>[_studentsHeader];
    for (final r in sRows) {
      sOut.add(sHeaders.map((h) => (r[h] ?? '').replaceAll(',', '')).join(','));
    }
    await sf.writeAsString('${sOut.join('\n')}\n', encoding: utf8);

    // 3. Remove timetables for the class and its students
    final tf = File(p.join(dataDir, 'timetable.csv'));
    if (await tf.exists()) {
      final tRows = await _readRowsFromFile(tf);
      if (tRows.isNotEmpty) {
        final tHeaders = tRows.first.keys.toList();
        tRows.removeWhere((r) {
          final owner = (r['owner_profile_id'] ?? '').trim();
          if (owner == 'class_$targetClass') return true;
          if (classStudentIds.contains(owner)) return true;
          return false;
        });

        final tOut = <String>[tHeaders.join(',')];
        for (final r in tRows) {
          tOut.add(
              tHeaders.map((h) => (r[h] ?? '').replaceAll(',', '')).join(','));
        }
        await tf.writeAsString('${tOut.join('\n')}\n', encoding: utf8);
      }
    }
  }

  static Future<void> updateProfile({
    required String dataDir,
    required String profileId,
    required String displayName,
    required String phone,
    required String email,
    required String dorm,
    required String avatar,
    required String signature,
  }) async {
    if (ApiConfig.instance.useCloud) {
      /*
      final payload = {
        'display_name': _safe(displayName),
        'phone': _safe(phone),
        'email': _safe(email),
        'dorm': _safe(dorm),
        'avatar': _safe(avatar),
        'signature': _safe(signature),
      };
      */

      // Also update via the specific avatar endpoint if avatar is provided and it's base64
      if (avatar.isNotEmpty && avatar.startsWith('data:image')) {
        try {
          final res = await ApiConfig.instance
              .post('/api/profiles/$profileId/avatar', {'avatar': avatar});
          if (res['ok'] != true) {
            throw 'Failed to update avatar in cloud: ${res['error']?['message'] ?? 'Unknown error'}';
          }
        } catch (e) {
          throw 'Failed to update avatar in cloud: $e';
        }
      }

      // Cloud update logic... (simulated here as we didn't add a full PUT endpoint to spring boot yet)
      return; // Skip local update if cloud is enabled, or implement proper sync
    }

    await ensureSchema(dataDir);
    final f = profilesFile(dataDir);
    final rows = await _readRows(dataDir);
    final headers = _header.split(',');

    for (final r in rows) {
      if (r['id'] == profileId) {
        r['display_name'] = _safe(displayName);
        r['phone'] = _safe(phone);
        r['email'] = _safe(email);
        r['dorm'] = _safe(dorm);
        r['avatar'] = avatar; // Update in memory map
        r['signature'] = _safe(signature);
      }
    }

    final out = <String>[_header];
    for (final r in rows) {
      out.add(headers.map((h) {
        String val = r[h] ?? '';
        return _csvEncode(val);
      }).join(','));
    }
    await f.writeAsString('${out.join('\n')}\n', encoding: utf8);
  }

  static Future<Profile> login({
    required String dataDir,
    required String role,
    required String accountNo,
    required String password,
  }) async {
    final normalizedRole = role == 'teacher' ? 'teacher' : 'student';
    final msg = validateAccountNo(role: normalizedRole, accountNo: accountNo);
    if (msg != null) throw msg;

    if (ApiConfig.instance.useCloud) {
      final res = await ApiConfig.instance.get('/api/profiles');
      if (res['ok'] == true) {
        final passwordHash = _fnv1a64Hex(password);
        final rawData = res['data'];
        final profilesRaw = (rawData is List)
            ? rawData
            : ((rawData as Map?)?['items'] as List? ?? []);
        for (final p in profilesRaw) {
          final r = (p as Map).cast<String, dynamic>();
          final rr = (r['role'] ?? '').toString();
          final roleOk = normalizedRole == 'teacher'
              ? rr == 'teacher'
              : (rr == 'student' || rr == 'cadre');
          if (!roleOk) continue;
          final staffNo = (r['staff_no'] ?? '').trim();
          final studentNo = (r['student_no'] ?? '').trim();
          final match = normalizedRole == 'teacher'
              ? staffNo == accountNo
              : studentNo == accountNo;
          if (!match) continue;
          if ((r['password_hash'] ?? '').trim() != passwordHash) {
            throw '账号或密码错误';
          }
          if (normalizedRole == 'student' && rr == 'cadre') {
            r['role'] = 'student';
          }
          return Profile.fromJson(r);
        }
      }
      throw '账号或密码错误';
    }

    await ensureSchema(dataDir);
    final rows = await _readRows(dataDir);
    final passwordHash = _fnv1a64Hex(password);
    for (final r in rows) {
      final rr = (r['role'] ?? '').toString();
      final roleOk = normalizedRole == 'teacher'
          ? rr == 'teacher'
          : (rr == 'student' || rr == 'cadre');
      if (!roleOk) continue;
      final staffNo = (r['staff_no'] ?? '').trim();
      final studentNo = (r['student_no'] ?? '').trim();
      final match = normalizedRole == 'teacher'
          ? staffNo == accountNo
          : studentNo == accountNo;
      if (!match) continue;
      if ((r['password_hash'] ?? '').trim() != passwordHash) {
        throw '账号或密码错误';
      }
      if (normalizedRole == 'student' && rr == 'cadre') {
        r['role'] = 'student';
      }
      return Profile.fromJson(r);
    }
    throw '账号或密码错误';
  }

  static Future<Profile> register({
    required String dataDir,
    required String role,
    required String accountNo,
    required String fullName,
    required String password,
    String phone = '',
    String orgCode = 'ORG1',
    String classCode = 'CLS1',
  }) async {
    final normalizedRole = role == 'teacher' ? 'teacher' : 'student';
    final msg = validateAccountNo(role: normalizedRole, accountNo: accountNo);
    if (msg != null) throw msg;

    final isTeacher = normalizedRole == 'teacher';
    final passwordHash = _fnv1a64Hex(password);
    final now = '${DateTime.now().toUtc().toIso8601String().split('.').first}Z';
    final idPrefix = isTeacher ? 'u_teacher' : 'u_student';
    final id = '${idPrefix}_${DateTime.now().millisecondsSinceEpoch}';
    final staffNo = isTeacher ? accountNo : '';
    final studentNo = isTeacher ? '' : accountNo;
    final finalClassCode = isTeacher ? '' : classCode;

    if (ApiConfig.instance.useCloud) {
      final profilesRes = await ApiConfig.instance.get('/api/profiles');
      if (profilesRes['ok'] == true) {
        final rawData = profilesRes['data'];
        final rows = (rawData is List) ? rawData : ((rawData as Map?)?['items'] as List? ?? []);
        for (final r in rows) {
          final sNo = (r['staff_no'] ?? '').trim();
          final stuNo = (r['student_no'] ?? '').trim();
          if (isTeacher && sNo == accountNo) throw '工号已存在';
          if (!isTeacher && stuNo == accountNo) throw '学号已存在';
        }
      }

      final profilePayload = {
        'id': id,
        'role': normalizedRole,
        'staff_no': staffNo,
        'student_no': studentNo,
        'display_name': _safe(fullName),
        'real_name': _safe(fullName),
        'org_code': _safe(orgCode),
        'class_code': _safe(finalClassCode),
        'password_hash': passwordHash,
        'created_at': now,
        'phone': _safe(phone),
        'email': '',
        'dorm': '',
        'avatar': '',
        'signature': '',
      };

      final res =
          await ApiConfig.instance.post('/api/profiles', profilePayload);
      if (res['ok'] != true) {
        throw '注册失败: ${res['error']?['message'] ?? 'Unknown'}';
      }

      if (!isTeacher) {
        await ApiConfig.instance.post('/api/students', {
          'id': id,
          'student_no': accountNo,
          'full_name': _safe(fullName),
          'class_code': _safe(classCode),
          'phone': _safe(phone),
          'position': '',
        });
      }
      return Profile.fromJson(profilePayload);
    }

    await ensureSchema(dataDir);
    final rows = await _readRows(dataDir);

    for (final r in rows) {
      final sNo = (r['staff_no'] ?? '').trim();
      final stuNo = (r['student_no'] ?? '').trim();
      if (isTeacher && sNo == accountNo) throw '工号已存在';
      if (!isTeacher && stuNo == accountNo) throw '学号已存在';
    }
    final row = <String, String>{
      'id': id,
      'role': normalizedRole,
      'staff_no': staffNo,
      'student_no': studentNo,
      'display_name': _safe(fullName),
      'real_name': _safe(fullName),
      'org_code': _safe(orgCode),
      'class_code': _safe(finalClassCode),
      'password_hash': passwordHash,
      'created_at': now,
      'phone': _safe(phone),
      'email': '',
      'dorm': '',
      'avatar': '',
      'signature': '',
    };

    final f = profilesFile(dataDir);
    final line = [
      row['id'],
      row['role'],
      row['staff_no'],
      row['student_no'],
      row['display_name'],
      row['display_name'], // real_name initially same as display_name
      row['org_code'],
      row['class_code'],
      row['password_hash'],
      row['created_at'],
      row['phone'], // phone
      '', // email
      '', // dorm
      '', // avatar
      '', // signature
    ].map((val) {
      String s = val ?? '';
      if (s.contains(',')) return '"${s.replaceAll('"', '""')}"';
      return s;
    }).join(',');
    await f.writeAsString('$line\n', encoding: utf8, mode: FileMode.append);

    if (!isTeacher) {
      await ensureStudentsSchema(dataDir);
      final sf = studentsFile(dataDir);
      final sRows = await _readRowsFromFile(sf);

      // Check if this student already exists by student_no
      final existingIndex = sRows.indexWhere((r) =>
          (r['student_no'] ?? '').trim().toLowerCase() ==
          accountNo.trim().toLowerCase());

      if (existingIndex >= 0) {
        // Update existing student entry with new profile ID
        sRows[existingIndex]['id'] = id;

        final sOut = <String>[_studentsHeader];
        final sHeaders = _studentsHeader.split(',');
        for (final r in sRows) {
          sOut.add(sHeaders.map((h) {
            String val = r[h] ?? '';
            if (val.contains(',')) return '"${val.replaceAll('"', '""')}"';
            return val;
          }).join(','));
        }
        await sf.writeAsString('${sOut.join('\n')}\n', encoding: utf8);
      } else {
        // Append new student entry
        final sLine = [
          id,
          accountNo,
          fullName,
          classCode,
          phone,
          '',
        ].map((val) {
          String s = val;
          if (s.contains(',')) return '"${s.replaceAll('"', '""')}"';
          return s;
        }).join(',');
        await sf.writeAsString('$sLine\n',
            encoding: utf8, mode: FileMode.append);
      }
    }

    return Profile.fromJson(row);
  }

  static File _autoLoginFile(String dataDir) {
    return File(p.join(dataDir, 'auto_login.json'));
  }

  static Future<void> saveAutoLogin({
    required String dataDir,
    required String profileId,
  }) async {
    final f = _autoLoginFile(dataDir);
    final payload = <String, dynamic>{
      'profile_id': profileId,
      'saved_at': DateTime.now().toIso8601String(),
    };
    await f.writeAsString(jsonEncode(payload), encoding: utf8);
  }

  static Future<void> clearAutoLogin(String dataDir) async {
    final f = _autoLoginFile(dataDir);
    if (await f.exists()) {
      await f.delete();
    }
  }

  static Future<Profile?> loadAutoLoginProfile({
    required String dataDir,
  }) async {
    final f = _autoLoginFile(dataDir);
    if (!await f.exists()) return null;
    try {
      final raw = jsonDecode(await f.readAsString(encoding: utf8));
      final pid = (raw is Map ? raw['profile_id'] : null).toString().trim();
      if (pid.isEmpty) return null;

      if (ApiConfig.instance.useCloud) {
        final res = await ApiConfig.instance.get('/api/profiles');
        if (res['ok'] == true) {
          final rows = (res['data']?['items'] as List?) ?? const [];
          for (final r in rows) {
            final map = (r as Map).cast<String, dynamic>();
            if ((map['id'] ?? '').toString().trim() == pid) {
              return Profile.fromJson(map);
            }
          }
        }
        return null;
      }

      await ensureSchema(dataDir);
      final rows = await _readRows(dataDir);
      for (final r in rows) {
        if ((r['id'] ?? '').trim() == pid) {
          return Profile.fromJson(r);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Profile? loadAutoLoginProfileFast({
    required String dataDir,
  }) {
    if (ApiConfig.instance.useCloud) return null;

    try {
      final f = _autoLoginFile(dataDir);
      if (!f.existsSync()) return null;
      final raw = jsonDecode(f.readAsStringSync(encoding: utf8));
      final pid = (raw is Map ? raw['profile_id'] : null).toString().trim();
      if (pid.isEmpty) return null;

      final pf = profilesFile(dataDir);
      if (!pf.existsSync()) return null;
      final lines = const LineSplitter().convert(
        pf.readAsStringSync(encoding: utf8),
      );
      if (lines.isEmpty) return null;
      final headers = _splitCsvLine(lines.first);
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = _splitCsvLine(line);
        if (parts.isEmpty || parts.first.trim() != pid) continue;
        final row = <String, dynamic>{};
        for (var j = 0; j < headers.length && j < parts.length; j++) {
          row[headers[j]] = parts[j];
        }
        return Profile.fromJson(row);
      }
    } catch (_) {}

    return null;
  }

  static Future<String?> ensureStudentAccountByTeacher({
    required String dataDir,
    required String profileId,
    required String studentNo,
    required String fullName,
    required String classCode,
    required String phone,
  }) async {
    await ensureSchema(dataDir);
    final f = profilesFile(dataDir);
    final rows = await _readRows(dataDir);

    // Check if account already exists
    for (final r in rows) {
      if ((r['student_no'] ?? '').trim() == studentNo) {
        return null; // Already exists, no new password
      }
    }

    final defaultPwd = studentNo;
    final passwordHash = _fnv1a64Hex(defaultPwd);
    final now = '${DateTime.now().toUtc().toIso8601String().split('.').first}Z';

    final line = [
      profileId,
      'student',
      '',
      studentNo,
      fullName,
      fullName,
      'ORG1',
      classCode,
      passwordHash,
      now,
      phone,
      '',
      '',
      '',
      '',
    ].map((val) {
      String s = val;
      if (s.contains(',')) return '"${s.replaceAll('"', '""')}"';
      return s;
    }).join(',');

    await f.writeAsString('$line\n', encoding: utf8, mode: FileMode.append);
    return defaultPwd;
  }

  static Future<Student?> getStudent(String dataDir, String id) async {
    final rows = await _readRowsFromFile(studentsFile(dataDir));
    for (final r in rows) {
      if ((r['id'] ?? '').toString().trim() == id.trim()) {
        return Student.fromJson(r);
      }
    }
    return null;
  }

  static Future<bool> updateStudent(String dataDir, Student s) async {
    final f = studentsFile(dataDir);
    final rows = await _readRowsFromFile(f);
    bool found = false;
    for (var i = 0; i < rows.length; i++) {
      if (rows[i]['id'] == s.id) {
        rows[i] =
            s.toJson().map((key, value) => MapEntry(key, value.toString()));
        found = true;
        break;
      }
    }
    if (!found) return false;

    final headers = _studentsHeader.split(',');
    final content = StringBuffer();
    content.writeln(headers.join(','));
    for (final r in rows) {
      content.writeln(headers.map((h) => _csvEncode(r[h] ?? '')).join(','));
    }
    await f.writeAsString(content.toString(), encoding: utf8);
    return true;
  }
}
