import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app/app.dart';
import 'core/database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite for desktop (Windows/Linux/macOS)
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Initialize database (creates tables if not exist)
  await DatabaseHelper.instance.database;

  runApp(const DairyFarmApp());
}