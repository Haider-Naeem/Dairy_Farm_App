// lib/data/repositories/cash_sale_repository.dart
import 'package:dairy_farm_app/core/database/database_helper.dart';
import 'package:dairy_farm_app/data/models/cash_sale_model.dart';

class CashSaleRepository {
  final _db = DatabaseHelper.instance;

  Future<List<CashSaleModel>> getByDate(String date) async {
    final rows = await _db.query('cash_sales',
        where: 'sale_date = ?', whereArgs: [date], orderBy: 'id ASC');
    return rows.map((r) => CashSaleModel.fromMap(r)).toList();
  }

  /// Returns all cash sales between [from] and [to] (inclusive), ordered by date.
  Future<List<CashSaleModel>> getByDateRange(String from, String to) async {
    final rows = await _db.query(
      'cash_sales',
      where: 'sale_date BETWEEN ? AND ?',
      whereArgs: [from, to],
      orderBy: 'sale_date ASC, id ASC',
    );
    return rows.map((r) => CashSaleModel.fromMap(r)).toList();
  }

  /// All cash sales for a given month — used by the ledger controller.
  Future<List<CashSaleModel>> getByMonth(int year, int month) async {
    final from = '$year-${month.toString().padLeft(2, '0')}-01';
    final to   = '$year-${month.toString().padLeft(2, '0')}-31';
    final rows = await _db.query(
      'cash_sales',
      where: 'sale_date >= ? AND sale_date <= ?',
      whereArgs: [from, to],
      orderBy: 'sale_date ASC, id ASC',
    );
    return rows.map((r) => CashSaleModel.fromMap(r)).toList();
  }

  /// Returns one aggregated CashSaleModel per day in the given month.
  Future<List<CashSaleModel>> getMonthlySummaryByDay(
      int year, int month) async {
    final from = '$year-${month.toString().padLeft(2, '0')}-01';
    final to   = '$year-${month.toString().padLeft(2, '0')}-31';
    final rows = await _db.rawQuery('''
      SELECT
        sale_date,
        SUM(cash_amount)    AS cash_amount,
        AVG(rate_per_liter) AS rate_per_liter,
        COUNT(*)            AS sale_count,
        MIN(created_at)     AS created_at
      FROM cash_sales
      WHERE sale_date BETWEEN ? AND ?
      GROUP BY sale_date
      ORDER BY sale_date ASC
    ''', [from, to]);

    return rows.map((r) {
      final count = r['sale_count'] as int? ?? 1;
      return CashSaleModel(
        saleDate: r['sale_date'] as String,
        cashAmount: (r['cash_amount'] as num).toDouble(),
        ratePerLiter: (r['rate_per_liter'] as num).toDouble(),
        notes: '$count sale${count != 1 ? 's' : ''}',
        createdAt: r['created_at'] as String,
      );
    }).toList();
  }

  /// Returns total liters sold for cash on a given date.
  Future<double> getTotalLitersByDate(String date) async {
    final rows = await _db.rawQuery(
      'SELECT COALESCE(SUM(cash_amount / rate_per_liter), 0) AS total '
      'FROM cash_sales WHERE sale_date = ?',
      [date],
    );
    return (rows.first['total'] as num? ?? 0).toDouble();
  }

  /// Returns total cash received on a given date.
  Future<double> getTotalCashByDate(String date) async {
    final rows = await _db.rawQuery(
      'SELECT COALESCE(SUM(cash_amount), 0) AS total '
      'FROM cash_sales WHERE sale_date = ?',
      [date],
    );
    return (rows.first['total'] as num? ?? 0).toDouble();
  }

  Future<int> insert(CashSaleModel m) => _db.insert('cash_sales', m.toMap());
  Future<int> delete(int id) => _db.delete('cash_sales', 'id = ?', [id]);
}