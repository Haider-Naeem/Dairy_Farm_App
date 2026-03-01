// lib/data/repositories/expense_repository.dart
import 'package:dairy_farm_app/core/database/database_helper.dart';
import 'package:dairy_farm_app/data/models/expense_model.dart';

class ExpenseRepository {
  final _db = DatabaseHelper.instance;

  Future<List<ExpenseModel>> getByDateRange(String from, String to) async {
    final rows = await _db.query(
      'expenses',
      where: 'expense_date BETWEEN ? AND ?',
      whereArgs: [from, to],
      orderBy: 'expense_date DESC',
    );
    return rows.map((r) => ExpenseModel.fromMap(r)).toList();
  }

  Future<List<ExpenseModel>> getByDate(String date) async {
    final rows = await _db.query('expenses',
        where: 'expense_date = ?', whereArgs: [date], orderBy: 'id DESC');
    return rows.map((r) => ExpenseModel.fromMap(r)).toList();
  }

  /// All expenses for a given month, ordered newest-date first.
  Future<List<ExpenseModel>> getByMonth(int year, int month) async {
    final from = '$year-${month.toString().padLeft(2, '0')}-01';
    final to   = '$year-${month.toString().padLeft(2, '0')}-31';
    final rows = await _db.query(
      'expenses',
      where: 'expense_date >= ? AND expense_date <= ?',
      whereArgs: [from, to],
      orderBy: 'expense_date DESC, id DESC',
    );
    return rows.map((r) => ExpenseModel.fromMap(r)).toList();
  }

  Future<int> insert(ExpenseModel e) => _db.insert('expenses', e.toMap());
  Future<int> delete(int id) => _db.delete('expenses', 'id = ?', [id]);
}