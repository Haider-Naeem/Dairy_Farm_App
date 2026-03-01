// lib/data/repositories/animal_event_repository.dart
import 'package:dairy_farm_app/core/database/database_helper.dart';
import 'package:dairy_farm_app/data/models/animal_event_model.dart';

class AnimalEventRepository {
  final _db = DatabaseHelper.instance;

  Future<List<AnimalEventModel>> getByAnimal(int animalId) async {
    final rows = await _db.rawQuery('''
      SELECT ae.*, a.tag_number, a.name AS animal_name
      FROM animal_events ae
      JOIN animals a ON a.id = ae.animal_id
      WHERE ae.animal_id = ?
      ORDER BY ae.event_date DESC, ae.created_at DESC
    ''', [animalId]);
    return rows.map((r) => AnimalEventModel.fromMap(r)).toList();
  }

  Future<List<AnimalEventModel>> getAll() async {
    final rows = await _db.rawQuery('''
      SELECT ae.*, a.tag_number, a.name AS animal_name
      FROM animal_events ae
      JOIN animals a ON a.id = ae.animal_id
      ORDER BY ae.event_date DESC, ae.created_at DESC
    ''');
    return rows.map((r) => AnimalEventModel.fromMap(r)).toList();
  }

  Future<int> insert(AnimalEventModel e) =>
      _db.insert('animal_events', e.toMap());

  Future<int> update(AnimalEventModel e) =>
      _db.update('animal_events', e.toMap(), 'id = ?', [e.id]);

  Future<int> delete(int id) =>
      _db.delete('animal_events', 'id = ?', [id]);
}