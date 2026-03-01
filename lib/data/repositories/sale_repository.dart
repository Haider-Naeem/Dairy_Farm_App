// lib/data/repositories/sale_repository.dart
import 'package:dairy_farm_app/core/database/database_helper.dart';
import 'package:dairy_farm_app/data/models/monthly_bill_model.dart';
import 'package:dairy_farm_app/data/models/sale_model.dart';

class SaleRepository {
  final _db = DatabaseHelper.instance;

  /// Sales for a specific date, ordered by the client's physical sort_order.
  Future<List<SaleModel>> getByDate(String date) async {
    final rows = await _db.rawQuery('''
      SELECT s.*, c.name AS client_name, c.is_payer
      FROM sales s
      JOIN clients c ON c.id = s.client_id
      WHERE s.sale_date = ?
        AND c.is_active = 1
      ORDER BY c.sort_order ASC, c.id ASC
    ''', [date]);
    return rows.map((r) => SaleModel.fromMap(r)).toList();
  }

  Future<List<SaleModel>> getByClientAndMonth(
      int clientId, int year, int month) async {
    final from = '$year-${month.toString().padLeft(2, '0')}-01';
    final to   = '$year-${month.toString().padLeft(2, '0')}-31';
    final rows = await _db.rawQuery('''
      SELECT s.*, c.name AS client_name, c.is_payer
      FROM sales s
      JOIN clients c ON c.id = s.client_id
      WHERE s.client_id = ?
        AND s.sale_date BETWEEN ? AND ?
      ORDER BY s.sale_date ASC
    ''', [clientId, from, to]);
    return rows.map((r) => SaleModel.fromMap(r)).toList();
  }

  Future<List<SaleModel>> getByDateRange(String from, String to) async {
    final rows = await _db.rawQuery('''
      SELECT s.*, c.name AS client_name, c.is_payer
      FROM sales s
      JOIN clients c ON c.id = s.client_id
      WHERE s.sale_date BETWEEN ? AND ?
      ORDER BY s.sale_date ASC, c.sort_order ASC
    ''', [from, to]);
    return rows.map((r) => SaleModel.fromMap(r)).toList();
  }

  /// All individual sales rows for a given month across all clients.
  /// Used by the ledger controller to aggregate billing and milk totals.
  Future<List<SaleModel>> getByMonth(int year, int month) async {
    final from = '$year-${month.toString().padLeft(2, '0')}-01';
    final to   = '$year-${month.toString().padLeft(2, '0')}-31';
    final rows = await _db.rawQuery('''
      SELECT s.*, c.name AS client_name, c.is_payer
      FROM sales s
      JOIN clients c ON c.id = s.client_id
      WHERE s.sale_date >= ? AND s.sale_date <= ?
      ORDER BY s.sale_date ASC, c.sort_order ASC
    ''', [from, to]);
    return rows.map((r) => SaleModel.fromMap(r)).toList();
  }

  /// Returns the total liters consumed across ALL clients for a given month.
  /// Mirrors the totalLiters getter on SaleModel so free-client liters are included.
  Future<double> getTotalLitersForMonth(int year, int month) async {
    final from = '$year-${month.toString().padLeft(2, '0')}-01';
    final to   = '$year-${month.toString().padLeft(2, '0')}-31';
    final rows = await _db.rawQuery('''
      SELECT COALESCE(SUM(
        (CASE WHEN taken_allocated = 1 THEN allocated_liters ELSE 0 END)
        + extra_liters
        + (CASE WHEN rate_per_liter > 0
                THEN extra_amount / rate_per_liter ELSE 0 END)
      ), 0) AS total
      FROM sales
      WHERE sale_date >= ? AND sale_date <= ?
    ''', [from, to]);
    return (rows.first['total'] as num? ?? 0).toDouble();
  }

  Future<List<MonthlyBillModel>> getMonthlyBillsByClient(
      int clientId) async {
    final rows = await _db.rawQuery('''
      SELECT
        CAST(strftime('%Y', sale_date) AS INTEGER) AS year,
        CAST(strftime('%m', sale_date) AS INTEGER) AS month,
        COUNT(*)                                   AS day_count,
        SUM(
          CASE WHEN taken_allocated = 1 THEN allocated_liters ELSE 0 END
          + extra_liters
          + CASE WHEN rate_per_liter > 0
                 THEN extra_amount / rate_per_liter ELSE 0 END
        )                                          AS total_liters,
        SUM(
          CASE WHEN taken_allocated = 1
               THEN allocated_liters * rate_per_liter ELSE 0 END
          + (extra_liters * rate_per_liter)
          + extra_amount
        )                                          AS total_amount
      FROM sales
      WHERE client_id = ?
      GROUP BY year, month
      ORDER BY year DESC, month DESC
    ''', [clientId]);
    return rows
        .map((r) => MonthlyBillModel(
              year: (r['year'] as num).toInt(),
              month: (r['month'] as num).toInt(),
              dayCount: (r['day_count'] as num).toInt(),
              totalLiters: (r['total_liters'] as num? ?? 0).toDouble(),
              totalAmount: (r['total_amount'] as num? ?? 0).toDouble(),
            ))
        .toList();
  }

  /// Monthly aggregate per client.
  Future<List<SaleModel>> getMonthlyByClient(int year, int month) async {
    final from = '$year-${month.toString().padLeft(2, '0')}-01';
    final to   = '$year-${month.toString().padLeft(2, '0')}-31';
    final rows = await _db.rawQuery('''
      SELECT
        s.client_id,
        c.name              AS client_name,
        c.allocated_liters,
        c.is_payer,
        SUM(CASE WHEN s.taken_allocated = 1
                 THEN s.allocated_liters ELSE 0 END) AS total_allocated_taken,
        SUM(s.extra_liters)                          AS total_extra_liters,
        SUM(s.extra_amount)                          AS total_extra_amount,
        COUNT(CASE WHEN s.taken_allocated = 1 THEN 1 END) AS days_taken,
        MAX(s.rate_per_liter)                        AS rate_per_liter
      FROM sales s
      JOIN clients c ON c.id = s.client_id
      WHERE s.sale_date BETWEEN ? AND ?
        AND c.is_active = 1
      GROUP BY s.client_id
      ORDER BY c.sort_order ASC
    ''', [from, to]);
    return rows
        .map((r) => SaleModel(
              clientId: (r['client_id'] as num).toInt(),
              saleDate: from,
              allocatedLiters:
                  (r['total_allocated_taken'] as num? ?? 0).toDouble(),
              takenAllocated: true,
              extraLiters:
                  (r['total_extra_liters'] as num? ?? 0).toDouble(),
              extraAmount:
                  (r['total_extra_amount'] as num? ?? 0).toDouble(),
              ratePerLiter:
                  (r['rate_per_liter'] as num? ?? 100).toDouble(),
              createdAt: DateTime.now().toIso8601String(),
              clientName: r['client_name'] as String?,
              isPayer: (r['is_payer'] as int? ?? 1) == 1,
            ))
        .toList();
  }

  Future<int> update(SaleModel sale) =>
      _db.update('sales', sale.toMap(), 'id = ?', [sale.id]);

  Future<SaleModel?> getByClientAndDate(
      int clientId, String date) async {
    final rows = await _db.rawQuery('''
      SELECT s.*, c.name AS client_name, c.is_payer
      FROM sales s
      JOIN clients c ON c.id = s.client_id
      WHERE s.client_id = ? AND s.sale_date = ?
    ''', [clientId, date]);
    return rows.isEmpty ? null : SaleModel.fromMap(rows.first);
  }

  Future<int> upsert(SaleModel sale) async {
    final existing =
        await getByClientAndDate(sale.clientId, sale.saleDate);
    if (existing != null) {
      return _db.update('sales', sale.toMap(), 'id = ?', [existing.id]);
    }
    return _db.insert('sales', sale.toMap());
  }

  Future<int> delete(int id) => _db.delete('sales', 'id = ?', [id]);
}