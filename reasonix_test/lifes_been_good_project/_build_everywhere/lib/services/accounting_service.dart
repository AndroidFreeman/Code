import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/accounting_record.dart';

class AccountingService {
  final String dataDir;
  final String? nativeLibDir;
  
  AccountingService({required this.dataDir, this.nativeLibDir});

  File get _file => File(p.join(dataDir, 'accounting.csv'));

  Future<void> _ensureSchema() async {
    final f = _file;
    if (!await f.exists()) {
      await f.writeAsString('id,student_id,amount,type,category,description,timestamp\n', encoding: utf8);
      return;
    }
    try {
      final firstLine = await f.openRead(0, 1024).transform(utf8.decoder).transform(const LineSplitter()).first;
      if (firstLine.trim() != 'id,student_id,amount,type,category,description,timestamp') {
        await f.writeAsString('id,student_id,amount,type,category,description,timestamp\n', encoding: utf8);
      }
    } catch (_) {
      await f.writeAsString('id,student_id,amount,type,category,description,timestamp\n', encoding: utf8);
    }
  }

  Future<List<AccountingRecord>> listRecords() async {
    await _ensureSchema();
    final f = _file;
    if (!await f.exists()) return [];

    final lines = await f.readAsLines(encoding: utf8);
    if (lines.length <= 1) return [];

    final records = <AccountingRecord>[];
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final parts = line.split(',');
      if (parts.length >= 7) {
        records.add(AccountingRecord(
          id: parts[0],
          studentId: parts[1],
          amount: double.tryParse(parts[2]) ?? 0.0,
          type: int.tryParse(parts[3]) ?? 1,
          category: parts[4],
          description: parts[5],
          timestamp: parts[6],
        ));
      }
    }
    return records.reversed.toList();
  }

  Future<bool> addRecord({
    required String studentId,
    required double amount,
    required int type,
    required String category,
    required String description,
  }) async {
    await _ensureSchema();
    final f = _file;
    final now = '${DateTime.now().toUtc().toIso8601String().split('.').first}Z';
    final id = 'acc_${DateTime.now().millisecondsSinceEpoch}';
    
    final safeDesc = description.replaceAll(',', '，').replaceAll('\n', ' ');
    final safeCat = category.replaceAll(',', '，');

    final line = '$id,$studentId,$amount,$type,$safeCat,$safeDesc,$now\n';
    await f.writeAsString(line, mode: FileMode.append, encoding: utf8);
    return true;
  }

  Future<bool> deleteRecord(String id) async {
    await _ensureSchema();
    final f = _file;
    if (!await f.exists()) return false;

    final lines = await f.readAsLines(encoding: utf8);
    if (lines.length <= 1) return false;

    final newLines = <String>[lines.first];
    bool deleted = false;
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      if (line.startsWith('$id,')) {
        deleted = true;
      } else {
        newLines.add(line);
      }
    }

    if (deleted) {
      await f.writeAsString('${newLines.join('\n')}\n', encoding: utf8);
    }
    return deleted;
  }
}
