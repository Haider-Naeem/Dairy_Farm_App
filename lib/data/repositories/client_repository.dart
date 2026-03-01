// lib/data/repositories/client_repository.dart
import 'package:dairy_farm_app/core/database/database_helper.dart';
import 'package:dairy_farm_app/data/models/client_model.dart';

class ClientRepository {
  final _db = DatabaseHelper.instance;

  /// Returns ALL clients (active + inactive) ordered by their physical position.
  /// In sales we only show active ones, but the ORDER stays consistent.
  Future<List<ClientModel>> getAll({bool activeOnly = false}) async {
    final rows = await _db.query(
      'clients',
      where: activeOnly ? 'is_active = 1' : null,
      orderBy: 'sort_order ASC, id ASC',
    );
    return rows.map((r) => ClientModel.fromMap(r)).toList();
  }

  Future<ClientModel?> getById(int id) async {
    final rows = await _db.query('clients', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : ClientModel.fromMap(rows.first);
  }

  /// Next sort_order = current max + 1 so new clients go to the bottom.
  Future<int> getNextSortOrder() async {
    final rows = await _db.rawQuery(
        'SELECT COALESCE(MAX(sort_order), 0) AS m FROM clients');
    return ((rows.first['m'] as num?)?.toInt() ?? 0) + 1;
  }

  Future<int> insert(ClientModel client) async {
    final so = client.sortOrder > 0 ? client.sortOrder : await getNextSortOrder();
    return await _db.insert('clients', client.copyWith(sortOrder: so).toMap());
  }

  Future<int> update(ClientModel client) async {
    return await _db.update('clients', client.toMap(), 'id = ?', [client.id]);
  }

  /// Deactivating keeps the physical slot — number is preserved.
  Future<int> deactivate(int id) async {
    return await _db.update('clients', {'is_active': 0}, 'id = ?', [id]);
  }

  /// Hard delete (only call if you really want to remove the record).
  Future<int> delete(int id) async {
    return await _db.delete('clients', 'id = ?', [id]);
  }

  /// Swap the sort_order of two clients (used by up/down buttons).
  Future<void> swapSortOrder(int idA, int soA, int idB, int soB) async {
    await _db.update('clients', {'sort_order': soB}, 'id = ?', [idA]);
    await _db.update('clients', {'sort_order': soA}, 'id = ?', [idB]);
  }

  /// Bulk-write sort orders after a drag-reorder (0-based index list → 1-based order).
  Future<void> updateSortOrders(List<int> orderedIds) async {
    for (int i = 0; i < orderedIds.length; i++) {
      await _db.update(
          'clients', {'sort_order': i + 1}, 'id = ?', [orderedIds[i]]);
    }
  }
}