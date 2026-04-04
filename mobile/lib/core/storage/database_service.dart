import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'academy_cache.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cache(
            key TEXT PRIMARY KEY,
            value TEXT,
            updated_at INTEGER
          )
        ''');
      },
    );
  }

  Future<void> saveCache(String key, String value) async {
    final db = await database;
    await db.insert(
      'cache',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getCache(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cache',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isNotEmpty) {
      // For now, let's just return the value. 
      // We could also check 'updated_at' to implement TTL.
      return maps.first['value'] as String;
    }
    return null;
  }

  Future<void> clearCache(String key) async {
    final db = await database;
    await db.delete(
      'cache',
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  Future<void> clearAllCache() async {
    final db = await database;
    await db.delete('cache');
  }
}
