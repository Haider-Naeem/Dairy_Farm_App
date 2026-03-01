// lib/data/repositories/production_repository.dart
import 'package:dairy_farm_app/core/database/database_helper.dart';
import 'package:dairy_farm_app/data/models/production_model.dart';

class ProductionRepository {
  final _db = DatabaseHelper.instance;

  /// Returns one row per active FEMALE animal that has in_production = 1.
  /// This includes regular animals AND any calves that were explicitly
  /// added to production via AnimalController.addCalfToProduction().
  /// Ordered by insertion sequence (a.id ASC).
  Future<List<ProductionModel>> getByDate(String date) async {
    final rows = await _db.rawQuery('''
      SELECT
        p.id,
        a.id          AS animal_id,
        a.tag_number,
        a.name        AS animal_name,
        ? AS production_date,
        COALESCE(p.morning,   0.0) AS morning,
        COALESCE(p.afternoon, 0.0) AS afternoon,
        COALESCE(p.evening,   0.0) AS evening,
        p.notes,
        COALESCE(p.created_at, datetime('now')) AS created_at
      FROM animals a
      LEFT JOIN production p
        ON p.animal_id = a.id
       AND p.production_date = ?
      WHERE a.is_active = 1
        AND a.gender = 'Female'
        AND a.in_production = 1
      ORDER BY a.id ASC
    ''', [date, date]);
    return rows.map((r) => ProductionModel.fromMap(r)).toList();
  }

  Future<List<ProductionModel>> getByAnimalAndMonth(
      int animalId, int year, int month) async {
    final from = '$year-${month.toString().padLeft(2, '0')}-01';
    final to   = '$year-${month.toString().padLeft(2, '0')}-31';
    final rows = await _db.rawQuery('''
      SELECT p.*, a.tag_number, a.name AS animal_name
      FROM production p
      JOIN animals a ON a.id = p.animal_id
      WHERE p.animal_id = ?
        AND p.production_date BETWEEN ? AND ?
      ORDER BY p.production_date ASC
    ''', [animalId, from, to]);
    return rows.map((r) => ProductionModel.fromMap(r)).toList();
  }

  /// Ordered by date then animal insertion sequence (a.id ASC).
  Future<List<ProductionModel>> getByDateRange(String from, String to) async {
    final rows = await _db.rawQuery('''
      SELECT p.*, a.tag_number, a.name AS animal_name
      FROM production p
      JOIN animals a ON a.id = p.animal_id
      WHERE p.production_date BETWEEN ? AND ?
        AND a.gender = 'Female'
        AND a.in_production = 1
      ORDER BY p.production_date ASC, a.id ASC
    ''', [from, to]);
    return rows.map((r) => ProductionModel.fromMap(r)).toList();
  }

  /// Only sums animals with in_production = 1 for the daily total.
  Future<double> getTotalByDate(String date) async {
    final rows = await _db.rawQuery('''
      SELECT COALESCE(SUM(p.morning + p.afternoon + p.evening), 0) AS total
      FROM production p
      JOIN animals a ON a.id = p.animal_id
      WHERE p.production_date = ?
        AND a.gender = 'Female'
        AND a.in_production = 1
    ''', [date]);
    return (rows.first['total'] as num? ?? 0).toDouble();
  }

  Future<void> upsert(ProductionModel p) async {
    if (p.id != null) {
      await _db.update('production', p.toMap(), 'id = ?', [p.id]);
    } else {
      await _db.rawInsert('''
        INSERT INTO production
          (animal_id, production_date, morning, afternoon, evening, notes, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(animal_id, production_date) DO UPDATE SET
          morning   = excluded.morning,
          afternoon = excluded.afternoon,
          evening   = excluded.evening,
          notes     = excluded.notes
      ''', [
        p.animalId,
        p.productionDate,
        p.morning,
        p.afternoon,
        p.evening,
        p.notes,
        p.createdAt,
      ]);
    }
  }

  Future<int> update(ProductionModel p) =>
      _db.update('production', p.toMap(), 'id = ?', [p.id]);
}