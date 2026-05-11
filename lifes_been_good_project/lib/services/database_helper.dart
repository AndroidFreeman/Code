import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/timetable_item.dart';
import '../models/schedule_event.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_data.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE cache_data (
          key TEXT PRIMARY KEY,
          json_value TEXT
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE timetable (
        id TEXT PRIMARY KEY,
        owner_profile_id TEXT,
        weekday INTEGER,
        start_period INTEGER,
        end_period INTEGER,
        start_time TEXT,
        end_time TEXT,
        course_id TEXT,
        location TEXT,
        created_by_profile_id TEXT,
        is_locked INTEGER,
        weeks TEXT,
        updated_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE schedule_event (
        id TEXT PRIMARY KEY,
        title TEXT,
        location TEXT,
        start_time TEXT,
        end_time TEXT,
        type TEXT,
        background_color TEXT,
        note TEXT,
        updated_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_state (
        key TEXT PRIMARY KEY,
        value INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE cache_data (
        key TEXT PRIMARY KEY,
        json_value TEXT
      )
    ''');
  }

  Future<String?> getCacheData(String key) async {
    final db = await instance.database;
    final res =
        await db.query('cache_data', where: 'key = ?', whereArgs: [key]);
    if (res.isNotEmpty) {
      return res.first['json_value'] as String?;
    }
    return null;
  }

  Future<void> setCacheData(String key, String jsonValue) async {
    final db = await instance.database;
    await db.insert('cache_data', {'key': key, 'json_value': jsonValue},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> getSyncState(String key) async {
    final db = await instance.database;
    final res =
        await db.query('sync_state', where: 'key = ?', whereArgs: [key]);
    if (res.isNotEmpty) {
      return res.first['value'] as int;
    }
    return 0;
  }

  Future<void> setSyncState(String key, int value) async {
    final db = await instance.database;
    await db.insert('sync_state', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Sync State ---
  Future<int> getLastSyncTime() async {
    return getSyncState('last_sync');
  }

  Future<void> setLastSyncTime(int time) async {
    return setSyncState('last_sync', time);
  }

  // --- ScheduleEvent ---
  Future<void> insertScheduleEvent(ScheduleEvent event) async {
    final db = await instance.database;
    await db.insert('schedule_event', event.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ScheduleEvent>> getScheduleEvents() async {
    final db = await instance.database;
    final maps = await db.query('schedule_event');
    return maps.map((map) => ScheduleEvent.fromMap(map)).toList();
  }

  Future<void> deleteScheduleEvent(String id) async {
    final db = await instance.database;
    await db.delete('schedule_event', where: 'id = ?', whereArgs: [id]);
  }

  // --- TimetableItem ---
  Future<void> insertTimetableItem(TimetableItem item,
      {int updatedAt = 0}) async {
    final db = await instance.database;
    final map = item.toJson();
    map['updated_at'] = updatedAt;
    map['is_locked'] = item.isLocked ? 1 : 0;
    await db.insert('timetable', map,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TimetableItem>> getTimetableItems() async {
    final db = await instance.database;
    final maps = await db.query('timetable');
    return maps.map((map) {
      final mutableMap = Map<String, dynamic>.from(map);
      mutableMap['is_locked'] = mutableMap['is_locked'] == 1 ? 'true' : 'false';
      return TimetableItem.fromJson(mutableMap);
    }).toList();
  }

  Future<void> deleteTimetableItem(String id) async {
    final db = await instance.database;
    await db.delete('timetable', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearTimetable() async {
    final db = await instance.database;
    await db.delete('timetable');
  }
}
