// ============================================================
// lib/data/repositories/settings_repository.dart
// ============================================================
import 'package:dairy_farm_app/core/database/database_helper.dart';
import 'package:dairy_farm_app/data/models/settings_model.dart';

class SettingsRepository {
  final _db = DatabaseHelper.instance;

  Future<SettingsModel?> get() async {
    final rows = await _db.query('settings', limit: 1);
    return rows.isEmpty ? null : SettingsModel.fromMap(rows.first);
  }

  Future<void> upsert(SettingsModel s) async {
    final existing = await get();
    if (existing == null) {
      await _db.insert('settings', s.toMap());
    } else {
      await _db.update('settings', s.toMap(), 'id = ?', [existing.id]);
    }
  }
}