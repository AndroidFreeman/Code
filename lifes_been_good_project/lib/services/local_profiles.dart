import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/profile.dart';

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
        final parts = line.split(',');
        if (parts.length < 5) continue;
        final id = parts[0];
        final role = parts[1];
        final display = parts[2];
        final org = parts[3];
        final cls = parts[4];
        out.add(
            '$id,$role,,,${_safe(display)},${_safe(display)},${_safe(org)},${_safe(cls)},,,,,,,');
      }
      await f.writeAsString(out.join('\n') + '\n', encoding: utf8);
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
        final parts = line.split(',');
        if (parts.length < 9) continue;
        // insert real_name after display_name
        final display = parts[4];
        out.add(
            '${parts[0]},${parts[1]},${parts[2]},${parts[3]},$display,$display,${parts[5]},${parts[6]},${parts[7]},${parts[8]},,,,,');
      }
      await f.writeAsString(out.join('\n') + '\n', encoding: utf8);
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
        final parts = line.split(',');
        if (parts.length < 14) continue;
        final display = parts[4];
        out.add(
            '${parts[0]},${parts[1]},${parts[2]},${parts[3]},$display,$display,${parts[5]},${parts[6]},${parts[7]},${parts[8]},${parts[9]},${parts[10]},${parts[11]},${parts[12]},${parts[13]}');
      }
      await f.writeAsString(out.join('\n') + '\n', encoding: utf8);
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
        final parts = line.split(',');
        if (parts.length < 5) continue;
        out.add('${parts[0]},${parts[1]},${parts[2]},${parts[3]},${parts[4]},');
      }
      await f.writeAsString(out.join('\n') + '\n', encoding: utf8);
      return;
    }
  }

  static Future<String> loadStudentPosition({
    required String dataDir,
    required Profile profile,
  }) async {
    if (profile.role.trim() == 'teacher') return '';
    await ensureStudentsSchema(dataDir);
    final f = studentsFile(dataDir);
    final rows = await _readRowsFromFile(f);
    final targetNo = profile.studentNo.trim();
    for (final r in rows) {
      if ((r['student_no'] ?? '').trim() != targetNo) continue;
      return (r['position'] ?? '').trim();
    }
    return '';
  }

  static String _safe(String s) {
    return s.replaceAll(',', '');
  }

  static Future<List<Map<String, String>>> _readRowsFromFile(File f) async {
    if (!await f.exists()) return const [];
    final content = await f.readAsString(encoding: utf8);
    final lines = const LineSplitter()
        .convert(content)
        .where((e) => e.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return const [];
    final headers = lines.first.split(',').map((e) => e.trim()).toList();
    final rows = <Map<String, String>>[];
    for (var i = 1; i < lines.length; i++) {
      final parts = lines[i].split(',');
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
    final rows = await _readRows(dataDir);
    for (final r in rows) {
      if (r['id'] == profileId) {
        final code = (r['class_code'] ?? '').trim();
        return code.split('|').where((e) => e.isNotEmpty).toList();
      }
    }
    return [];
  }

  static Future<List<String>> getAllClasses(String dataDir) async {
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
    await ensureSchema(dataDir);
    final f = profilesFile(dataDir);
    final rows = await _readRows(dataDir);
    final headers = _header.split(',');

    for (final r in rows) {
      if (r['id'] == profileId) {
        final current = (r['class_code'] ?? '').trim();
        final classes = current.split('|').where((e) => e.isNotEmpty).toList();
        if (!classes.contains(newClass.trim())) {
          classes.add(newClass.trim());
        }
        r['class_code'] = classes.join('|');
      }
    }

    final out = <String>[_header];
    for (final r in rows) {
      out.add(headers.map((h) => (r[h] ?? '').replaceAll(',', '')).join(','));
    }
    await f.writeAsString(out.join('\n') + '\n', encoding: utf8);
  }

  static Future<void> removeTeacherClass(
      String dataDir, String profileId, String classCode) async {
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
      out.add(headers.map((h) => (r[h] ?? '').replaceAll(',', '')).join(','));
    }
    await f.writeAsString(out.join('\n') + '\n', encoding: utf8);
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
        r['avatar'] = _safe(avatar);
        r['signature'] = _safe(signature);
      }
    }

    final out = <String>[_header];
    for (final r in rows) {
      out.add(headers.map((h) => (r[h] ?? '').replaceAll(',', '')).join(','));
    }
    await f.writeAsString(out.join('\n') + '\n', encoding: utf8);
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
    await ensureSchema(dataDir);
    final rows = await _readRows(dataDir);

    final isTeacher = normalizedRole == 'teacher';

    for (final r in rows) {
      final staffNo = (r['staff_no'] ?? '').trim();
      final studentNo = (r['student_no'] ?? '').trim();
      if (isTeacher && staffNo == accountNo) throw '工号已存在';
      if (!isTeacher && studentNo == accountNo) throw '学号已存在';
    }

    final now = DateTime.now().toUtc().toIso8601String().split('.').first + 'Z';
    final idPrefix = isTeacher ? 'u_teacher' : 'u_student';
    final id = '${idPrefix}_${DateTime.now().millisecondsSinceEpoch}';
    final staffNo = isTeacher ? accountNo : '';
    final studentNo = isTeacher ? '' : accountNo;
    final passwordHash = _fnv1a64Hex(password);
    final row = <String, String>{
      'id': id,
      'role': normalizedRole,
      'staff_no': staffNo,
      'student_no': studentNo,
      'display_name': _safe(fullName),
      'real_name': _safe(fullName),
      'org_code': _safe(orgCode),
      'class_code': _safe(classCode),
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
      _safe(phone), // phone
      '', // email
      '', // dorm
      '', // avatar
      '', // signature
    ].join(',');
    await f.writeAsString('$line\n', encoding: utf8, mode: FileMode.append);

    if (!isTeacher) {
      await ensureStudentsSchema(dataDir);
      final sf = studentsFile(dataDir);
      final sRows = await _readRowsFromFile(sf);
      final exists = sRows.any((r) => (r['id'] ?? '').trim() == id);
      if (!exists) {
        final sLine = [
          id,
          accountNo,
          _safe(fullName),
          _safe(classCode),
          _safe(phone),
          '',
        ].join(',');
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
}
