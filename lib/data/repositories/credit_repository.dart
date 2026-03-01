// lib/data/repositories/credit_repository.dart

import 'package:dairy_farm_app/core/database/database_helper.dart';
import 'package:dairy_farm_app/data/models/credit_model.dart';

class CreditRepository {
  final _db = DatabaseHelper.instance;

  Future<List<CreditModel>> getAll() async {
    final rows = await _db.query(
      'credit_entries',
      orderBy: 'entry_date DESC, id DESC',
    );
    return rows.map((r) => CreditModel.fromMap(r)).toList();
  }

  Future<List<CreditModel>> getByMonth(int year, int month) async {
    final from = '$year-${month.toString().padLeft(2, '0')}-01';
    final to   = '$year-${month.toString().padLeft(2, '0')}-31';
    final rows = await _db.query(
      'credit_entries',
      where: "entry_date >= ? AND entry_date <= ?",
      whereArgs: [from, to],
      orderBy: 'entry_date DESC, id DESC',
    );
    return rows.map((r) => CreditModel.fromMap(r)).toList();
  }

  /// Total liters taken on credit for a specific date (deducted from production)
  Future<double> getCreditLitersForDate(String date) async {
    final rows = await _db.rawQuery('''
      SELECT COALESCE(SUM(liters), 0.0) AS total
      FROM credit_entries
      WHERE entry_type = 'credit' AND entry_date = ?
    ''', [date]);
    return (rows.first['total'] as num).toDouble();
  }

  /// Total credit payments (debits) received in a given month
  Future<double> getTotalPaymentsByMonth(int year, int month) async {
    final from = '$year-${month.toString().padLeft(2, '0')}-01';
    final to   = '$year-${month.toString().padLeft(2, '0')}-31';
    final rows = await _db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0.0) AS total
      FROM credit_entries
      WHERE entry_type = 'debit' AND entry_date >= ? AND entry_date <= ?
    ''', [from, to]);
    return (rows.first['total'] as num).toDouble();
  }

  /// Returns each unique person with their net balance (credit - debit).
  Future<List<Map<String, dynamic>>> getPersonBalances() async {
    return await _db.rawQuery('''
      SELECT
        person_name,
        phone,
        SUM(CASE WHEN entry_type = 'credit' THEN amount  ELSE 0 END) AS total_credit,
        SUM(CASE WHEN entry_type = 'debit'  THEN amount  ELSE 0 END) AS total_paid,
        SUM(CASE WHEN entry_type = 'credit' THEN liters  ELSE 0 END) AS total_liters,
        SUM(CASE WHEN entry_type = 'credit' THEN amount  ELSE 0 END)
          - SUM(CASE WHEN entry_type = 'debit' THEN amount ELSE 0 END) AS balance
      FROM credit_entries
      GROUP BY person_name
      ORDER BY balance DESC
    ''');
  }

  Future<int> insert(CreditModel m) async =>
      await _db.insert('credit_entries', m.toMap());

  Future<int> delete(int id) async =>
      await _db.delete('credit_entries', 'id = ?', [id]);
}