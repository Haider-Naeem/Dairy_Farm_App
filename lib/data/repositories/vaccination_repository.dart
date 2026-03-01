// lib/data/repositories/vaccination_repository.dart
import 'package:dairy_farm_app/core/database/database_helper.dart';
import 'package:dairy_farm_app/data/models/vaccination_model.dart';

class VaccinationRepository {
  final _db = DatabaseHelper.instance;

  Future<List<VaccinationModel>> getAll() async {
    final rows = await _db.rawQuery('''
      SELECT v.*, a.tag_number
      FROM vaccinations v
      JOIN animals a ON a.id = v.animal_id
      ORDER BY v.vaccination_date DESC
    ''');
    return rows.map((r) => VaccinationModel.fromMap(r)).toList();
  }

  Future<List<VaccinationModel>> getByAnimal(int animalId) async {
    final rows = await _db.rawQuery('''
      SELECT v.*, a.tag_number
      FROM vaccinations v
      JOIN animals a ON a.id = v.animal_id
      WHERE v.animal_id = ?
      ORDER BY v.vaccination_date DESC
    ''', [animalId]);
    return rows.map((r) => VaccinationModel.fromMap(r)).toList();
  }

  /// Filter by optional animalId, and/or date range [from]..[to] (yyyy-MM-dd).
  Future<List<VaccinationModel>> getFiltered({
    int? animalId,
    String? from,
    String? to,
    bool? dueOnly,
  }) async {
    final conditions = <String>[];
    final args = <dynamic>[];

    if (animalId != null) {
      conditions.add('v.animal_id = ?');
      args.add(animalId);
    }
    if (from != null) {
      conditions.add('v.vaccination_date >= ?');
      args.add(from);
    }
    if (to != null) {
      conditions.add('v.vaccination_date <= ?');
      args.add(to);
    }
    if (dueOnly == true) {
      conditions.add('v.next_due_date IS NOT NULL AND v.is_done = 0');
    }

    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

    final rows = await _db.rawQuery('''
      SELECT v.*, a.tag_number
      FROM vaccinations v
      JOIN animals a ON a.id = v.animal_id
      $where
      ORDER BY v.vaccination_date DESC
    ''', args);
    return rows.map((r) => VaccinationModel.fromMap(r)).toList();
  }

  Future<int> insert(VaccinationModel v) =>
      _db.insert('vaccinations', v.toMap());

  Future<int> update(VaccinationModel v) =>
      _db.update('vaccinations', v.toMap(), 'id = ?', [v.id]);

  /// Marks an existing vaccination record as done (is_done = 1).
  Future<void> markAsDone(int id) async {
    await _db.rawQuery(
        'UPDATE vaccinations SET is_done = 1 WHERE id = ?', [id]);
  }

  Future<int> delete(int id) =>
      _db.delete('vaccinations', 'id = ?', [id]);
}