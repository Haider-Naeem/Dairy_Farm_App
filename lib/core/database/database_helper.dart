import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'migrations.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Stores the database at C:\dairyfarm\dairy_farm.db
  Future<String> get databasePath async {
    const dbDir = r'C:\dairyfarm';
    final directory = Directory(dbDir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return join(dbDir, 'dairy_farm.db');
  }

  Future<Database> _initDatabase() async {
    final path = await databasePath;
    return await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: Migrations.dbVersion,
        onCreate: Migrations.onCreate,
        onUpgrade: Migrations.onUpgrade,
      ),
    );
  }

  // Convenience methods
  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert(table, row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(String table, Map<String, dynamic> row, String where,
      List whereArgs) async {
    final db = await database;
    return await db.update(table, row, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, String where, List whereArgs) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return await db.query(table,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit);
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List? args]) async {
    final db = await database;
    return await db.rawQuery(sql, args);
  }

  Future<int> rawInsert(String sql, [List? args]) async {
    final db = await database;
    return await db.rawInsert(sql, args);
  }
}