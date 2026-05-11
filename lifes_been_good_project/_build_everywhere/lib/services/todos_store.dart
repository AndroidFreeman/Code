import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/todo_item.dart';

class TodosStore {
  final String dataDir;

  const TodosStore({required this.dataDir});

  static const _headerV2 =
      'id,owner_profile_id,folder,title,content,is_done,due_at,start_at,end_at,created_at,updated_at';
  static const _headerV1 =
      'id,owner_profile_id,folder,title,is_done,due_at,created_at,updated_at';

  File get _file => File(p.join(dataDir, 'todos.csv'));

  List<String> _splitCsvLine(String line) {
    final res = <String>[];
    var current = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        res.add(current.toString().trim());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    res.add(current.toString().trim());
    if (res.isNotEmpty && res.first.startsWith('\uFEFF')) {
      res[0] = res.first.replaceFirst('\uFEFF', '');
    }
    return res;
  }

  Future<void> ensureSchema() async {
    if (!await _file.exists()) {
      await _file.writeAsString('$_headerV2\n', encoding: utf8);
      return;
    }
    final content = await _file.readAsString(encoding: utf8);
    final lines = const LineSplitter().convert(content);
    if (lines.isEmpty) {
      await _file.writeAsString('$_headerV2\n', encoding: utf8);
      return;
    }
    final header = _splitCsvLine(lines.first.trim()).join(',');
    if (header == _headerV2) return;

    // Migration logic
    final out = <String>[_headerV2];
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final parts = _splitCsvLine(line);

      if (header == _headerV1 && parts.length >= 8) {
        out.add([
          parts[0], // id
          parts[1], // owner_profile_id
          parts[2], // folder
          parts[3], // title
          '', // content
          parts[4], // is_done
          parts[5], // due_at
          '', // start_at
          '', // end_at
          parts[6], // created_at
          parts[7], // updated_at
        ].map((e) => '"${e.replaceAll('"', '""')}"').join(','));
      } else if (parts.length >= 7) {
        // V0 migration (missing folder)
        out.add([
          parts[0],
          parts[1],
          '默认',
          parts[2],
          '',
          parts[3],
          parts[4],
          '',
          '',
          parts[5],
          parts[6],
        ].map((e) => '"${e.replaceAll('"', '""')}"').join(','));
      }
    }
    await _file.writeAsString('${out.join('\n')}\n', encoding: utf8);
  }

  Future<List<TodoItem>> listTodos({required String ownerProfileId}) async {
    await ensureSchema();
    if (!await _file.exists()) return const [];
    final content = await _file.readAsString(encoding: utf8);
    final lines = const LineSplitter()
        .convert(content)
        .where((e) => e.trim().isNotEmpty)
        .toList();
    if (lines.length <= 1) return const [];
    final headers = _splitCsvLine(lines.first.trim());
    final items = <TodoItem>[];
    for (var i = 1; i < lines.length; i++) {
      final parts = _splitCsvLine(lines[i].trim());
      final row = <String, dynamic>{};
      for (var j = 0; j < headers.length && j < parts.length; j++) {
        row[headers[j]] = parts[j];
      }
      final item = TodoItem.fromJson(row);
      if (item.ownerProfileId == ownerProfileId) items.add(item);
    }
    return items;
  }

  Future<String> addTodo({
    required String ownerProfileId,
    required String title,
    required String folder,
    String content = '',
    String startAt = '',
    String endAt = '',
    String dueAt = '',
  }) async {
    await ensureSchema();
    final now = DateTime.now().toIso8601String();
    final id = 'td_${DateTime.now().microsecondsSinceEpoch}';
    final row = [
      id,
      ownerProfileId,
      folder.trim().isEmpty ? '默认' : folder.trim(),
      title.trim(),
      content.trim(),
      'false',
      dueAt.trim(),
      startAt.trim(),
      endAt.trim(),
      now,
      now,
    ].map((e) => '"${e.replaceAll('"', '""')}"').join(',');
    await _file.writeAsString('$row\n', encoding: utf8, mode: FileMode.append);
    return id;
  }

  Future<void> toggleTodo(
      {required String ownerProfileId, required String id}) async {
    await ensureSchema();
    final content = await _file.readAsString(encoding: utf8);
    final lines = const LineSplitter()
        .convert(content)
        .where((e) => e.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return;
    final headers = _splitCsvLine(lines.first.trim());
    final rows = <Map<String, String>>[];
    for (var i = 1; i < lines.length; i++) {
      final parts = _splitCsvLine(lines[i].trim());
      final row = <String, String>{};
      for (var j = 0; j < headers.length && j < parts.length; j++) {
        row[headers[j]] = parts[j];
      }
      rows.add(row);
    }

    final idx = rows.indexWhere((r) =>
        (r['id'] ?? '') == id &&
        (r['owner_profile_id'] ?? '') == ownerProfileId);
    if (idx < 0) return;
    final cur = (rows[idx]['is_done'] ?? '').toLowerCase();
    final next =
        (cur == 'true' || cur == '1' || cur == 'yes') ? 'false' : 'true';
    rows[idx]['is_done'] = next;
    rows[idx]['updated_at'] = DateTime.now().toIso8601String();

    final out = <String>[headers.join(',')];
    for (final r in rows) {
      out.add(headers.map((h) => (r[h] ?? '').replaceAll(',', '')).join(','));
    }
    await _file.writeAsString('${out.join('\n')}\n', encoding: utf8);
  }

  Future<void> updateTodoDueAt(
      {required String ownerProfileId,
      required String id,
      required String dueAt}) async {
    await ensureSchema();
    final content = await _file.readAsString(encoding: utf8);
    final lines = const LineSplitter()
        .convert(content)
        .where((e) => e.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return;
    final headers = _splitCsvLine(lines.first.trim());
    final rows = <Map<String, String>>[];
    for (var i = 1; i < lines.length; i++) {
      final parts = _splitCsvLine(lines[i].trim());
      final row = <String, String>{};
      for (var j = 0; j < headers.length && j < parts.length; j++) {
        row[headers[j]] = parts[j];
      }
      rows.add(row);
    }

    final idx = rows.indexWhere((r) =>
        (r['id'] ?? '') == id &&
        (r['owner_profile_id'] ?? '') == ownerProfileId);
    if (idx < 0) return;

    rows[idx]['due_at'] = dueAt;
    rows[idx]['updated_at'] = DateTime.now().toIso8601String();

    final out = <String>[headers.join(',')];
    for (final r in rows) {
      out.add(headers.map((h) => (r[h] ?? '').replaceAll(',', '')).join(','));
    }
    await _file.writeAsString('${out.join('\n')}\n', encoding: utf8);
  }

  Future<void> updateTodoTimeRange({
    required String ownerProfileId,
    required String id,
    required String startAt,
    required String endAt,
  }) async {
    await ensureSchema();
    final content = await _file.readAsString(encoding: utf8);
    final lines = const LineSplitter()
        .convert(content)
        .where((e) => e.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return;
    final headers = _splitCsvLine(lines.first.trim());
    final rows = <Map<String, String>>[];
    for (var i = 1; i < lines.length; i++) {
      final parts = _splitCsvLine(lines[i].trim());
      final row = <String, String>{};
      for (var j = 0; j < headers.length && j < parts.length; j++) {
        row[headers[j]] = parts[j];
      }
      rows.add(row);
    }

    final idx = rows.indexWhere((r) =>
        (r['id'] ?? '') == id &&
        (r['owner_profile_id'] ?? '') == ownerProfileId);
    if (idx < 0) return;

    rows[idx]['start_at'] = startAt;
    rows[idx]['end_at'] = endAt;
    rows[idx]['due_at'] = startAt;
    rows[idx]['updated_at'] = DateTime.now().toIso8601String();

    final out = <String>[headers.join(',')];
    for (final r in rows) {
      out.add(headers
          .map((h) => '"${(r[h] ?? '').replaceAll('"', '""')}"')
          .join(','));
    }
    await _file.writeAsString('${out.join('\n')}\n', encoding: utf8);
  }

  Future<void> upsertTodo(TodoItem item) async {
    await ensureSchema();
    final content = await _file.readAsString(encoding: utf8);
    final lines = const LineSplitter()
        .convert(content)
        .where((e) => e.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return;
    final headers = _splitCsvLine(lines.first.trim());
    final rows = <Map<String, String>>[];
    for (var i = 1; i < lines.length; i++) {
      final parts = _splitCsvLine(lines[i].trim());
      final row = <String, String>{};
      for (var j = 0; j < headers.length && j < parts.length; j++) {
        row[headers[j]] = parts[j];
      }
      rows.add(row);
    }

    final idx = rows.indexWhere((r) =>
        (r['id'] ?? '') == item.id &&
        (r['owner_profile_id'] ?? '') == item.ownerProfileId);

    final now = DateTime.now().toIso8601String();
    final itemData = {
      'id': item.id,
      'owner_profile_id': item.ownerProfileId,
      'folder': item.folder,
      'title': item.title,
      'content': item.content,
      'is_done': item.isDone.toString(),
      'due_at': item.dueAt,
      'start_at': item.startAt,
      'end_at': item.endAt,
      'created_at': item.createdAt,
      'updated_at': now,
    };

    if (idx >= 0) {
      rows[idx] = itemData;
    } else {
      rows.add(itemData);
    }

    final out = <String>[headers.join(',')];
    for (final r in rows) {
      out.add(headers
          .map((h) => '"${(r[h] ?? '').replaceAll('"', '""')}"')
          .join(','));
    }
    await _file.writeAsString('${out.join('\n')}\n', encoding: utf8);
  }

  Future<void> deleteTodo(
      {required String ownerProfileId, required String id}) async {
    await ensureSchema();
    final content = await _file.readAsString(encoding: utf8);
    final lines = const LineSplitter()
        .convert(content)
        .where((e) => e.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return;
    final headers = _splitCsvLine(lines.first.trim());
    final rows = <Map<String, String>>[];
    for (var i = 1; i < lines.length; i++) {
      final parts = _splitCsvLine(lines[i].trim());
      final row = <String, String>{};
      for (var j = 0; j < headers.length && j < parts.length; j++) {
        row[headers[j]] = parts[j];
      }
      rows.add(row);
    }

    rows.removeWhere((r) =>
        (r['id'] ?? '') == id &&
        (r['owner_profile_id'] ?? '') == ownerProfileId);

    final out = <String>[headers.join(',')];
    for (final r in rows) {
      out.add(headers.map((h) => (r[h] ?? '').replaceAll(',', '')).join(','));
    }
    await _file.writeAsString('${out.join('\n')}\n', encoding: utf8);
  }
}
