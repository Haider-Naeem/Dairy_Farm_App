// lib/data/repositories/animal_repository.dart
import 'package:dairy_farm_app/core/database/database_helper.dart';
import 'package:dairy_farm_app/data/models/animal_model.dart';

class AnimalRepository {
  final _db = DatabaseHelper.instance;

  /// Returns all animals ordered by insertion sequence (id ASC).
  Future<List<AnimalModel>> getAll({bool activeOnly = true}) async {
    final rows = await _db.query(
      'animals',
      where: activeOnly ? 'is_active = 1' : null,
      orderBy: 'id ASC',
    );
    return rows.map((r) => AnimalModel.fromMap(r)).toList();
  }

  /// Returns all calves whose mother_id = [motherId], ordered by insertion.
  Future<List<AnimalModel>> getChildrenOf(int motherId) async {
    final rows = await _db.query(
      'animals',
      where: 'mother_id = ? AND is_active = 1',
      whereArgs: [motherId],
      orderBy: 'id ASC',
    );
    return rows.map((r) => AnimalModel.fromMap(r)).toList();
  }

  /// Returns IDs of animals that have a PENDING vaccination due within
  /// [withinDays] days.
  ///
  /// FIX: added `AND is_done = 0` — previously the query returned animal IDs
  /// even for vaccinations already marked done, so the "Due" badge never
  /// cleared after pressing the Done button.
  Future<Set<int>> getUpcomingDueAnimalIds({int withinDays = 7}) async {
    final cutoff = DateTime.now().add(Duration(days: withinDays));
    final cutoffStr = cutoff.toIso8601String().substring(0, 10);
    final rows = await _db.rawQuery('''
      SELECT DISTINCT animal_id
      FROM vaccinations
      WHERE next_due_date IS NOT NULL
        AND next_due_date <= ?
        AND is_done = 0
    ''', [cutoffStr]);
    return rows.map((r) => r['animal_id'] as int).toSet();
  }

  /// Marks a calf (or any animal) as included in the production tab.
  Future<void> setInProduction(int animalId, {required bool value}) async {
    await _db.update(
      'animals',
      {'in_production': value ? 1 : 0},
      'id = ?',
      [animalId],
    );
  }

  Future<int> insert(AnimalModel animal) =>
      _db.insert('animals', animal.toMap());

  Future<int> update(AnimalModel animal) =>
      _db.update('animals', animal.toMap(), 'id = ?', [animal.id]);

  Future<int> delete(int id) =>
      _db.delete('animals', 'id = ?', [id]);
}