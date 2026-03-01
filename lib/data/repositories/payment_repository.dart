// lib/data/repositories/payment_repository.dart
import 'package:dairy_farm_app/core/database/database_helper.dart';
import 'package:dairy_farm_app/data/models/payment_model.dart';

class PaymentRepository {
  final _db = DatabaseHelper.instance;

  Future<int> insert(PaymentModel payment) =>
      _db.insert('payments', payment.toMap());

  Future<int> delete(int id) =>
      _db.delete('payments', 'id = ?', [id]);

  /// Update the amount (and optionally notes) for an existing payment.
  Future<void> updateAmount(int id, double newAmount, {String? notes}) async {
    if (notes != null) {
      await _db.rawQuery(
        'UPDATE payments SET amount_paid = ?, notes = ? WHERE id = ?',
        [newAmount, notes, id],
      );
    } else {
      await _db.rawQuery(
        'UPDATE payments SET amount_paid = ? WHERE id = ?',
        [newAmount, id],
      );
    }
  }

  /// All payments for a specific client + month.
  /// No JOIN needed here — we already know the client.
  Future<List<PaymentModel>> getByClientAndMonth(
      int clientId, int year, int month) async {
    final rows = await _db.rawQuery('''
      SELECT * FROM payments
      WHERE client_id = ? AND year = ? AND month = ?
      ORDER BY payment_date ASC
    ''', [clientId, year, month]);
    return rows.map((r) => PaymentModel.fromMap(r)).toList();
  }

  /// Returns all payments whose paymentDate falls within [from]..[to] (inclusive).
  /// JOINs clients so clientName is available for the DSR Excel report.
  Future<List<PaymentModel>> getByDateRange(String from, String to) async {
    final rows = await _db.rawQuery('''
      SELECT
        p.*,
        c.name AS client_name
      FROM payments p
      LEFT JOIN clients c ON c.id = p.client_id
      WHERE p.payment_date BETWEEN ? AND ?
      ORDER BY p.payment_date ASC, p.id ASC
    ''', [from, to]);
    return rows.map((r) => PaymentModel.fromMap(r)).toList();
  }

  /// Total paid for a specific client+month.
  Future<double> getTotalPaidForMonth(
      int clientId, int year, int month) async {
    final rows = await _db.rawQuery('''
      SELECT COALESCE(SUM(amount_paid), 0) AS total
      FROM payments
      WHERE client_id = ? AND year = ? AND month = ?
    ''', [clientId, year, month]);
    return (rows.first['total'] as num? ?? 0).toDouble();
  }

  /// Sum of all bill amounts for a client BEFORE the given year/month,
  /// minus all payments made for those months → gives cumulative pending.
  Future<double> getCumulativePendingBefore(
      int clientId, int year, int month) async {
    final billRows = await _db.rawQuery('''
      SELECT
        COALESCE(SUM(
          CASE WHEN s.taken_allocated = 1
               THEN s.allocated_liters * s.rate_per_liter ELSE 0 END
          + (s.extra_liters * s.rate_per_liter)
          + s.extra_amount
        ), 0) AS total_billed
      FROM sales s
      JOIN clients c ON c.id = s.client_id
      WHERE s.client_id = ?
        AND (
          CAST(strftime('%Y', s.sale_date) AS INTEGER) < ?
          OR (
            CAST(strftime('%Y', s.sale_date) AS INTEGER) = ?
            AND CAST(strftime('%m', s.sale_date) AS INTEGER) < ?
          )
        )
    ''', [clientId, year, year, month]);

    final totalBilled =
        (billRows.first['total_billed'] as num? ?? 0).toDouble();

    final paidRows = await _db.rawQuery('''
      SELECT COALESCE(SUM(amount_paid), 0) AS total_paid
      FROM payments
      WHERE client_id = ?
        AND (year < ? OR (year = ? AND month < ?))
    ''', [clientId, year, year, month]);

    final totalPaid =
        (paidRows.first['total_paid'] as num? ?? 0).toDouble();

    return (totalBilled - totalPaid).clamp(0.0, double.infinity);
  }

  /// Batch fetch cumulative pending for all payer clients before a month.
  Future<Map<int, double>> getCumulativePendingBeforeForAll(
      int year, int month) async {
    final billRows = await _db.rawQuery('''
      SELECT
        s.client_id,
        COALESCE(SUM(
          CASE WHEN s.taken_allocated = 1
               THEN s.allocated_liters * s.rate_per_liter ELSE 0 END
          + (s.extra_liters * s.rate_per_liter)
          + s.extra_amount
        ), 0) AS total_billed
      FROM sales s
      JOIN clients c ON c.id = s.client_id
      WHERE (
        CAST(strftime('%Y', s.sale_date) AS INTEGER) < ?
        OR (
          CAST(strftime('%Y', s.sale_date) AS INTEGER) = ?
          AND CAST(strftime('%m', s.sale_date) AS INTEGER) < ?
        )
      )
      GROUP BY s.client_id
    ''', [year, year, month]);

    final billed = <int, double>{};
    for (final r in billRows) {
      billed[(r['client_id'] as num).toInt()] =
          (r['total_billed'] as num? ?? 0).toDouble();
    }

    final paidRows = await _db.rawQuery('''
      SELECT client_id, COALESCE(SUM(amount_paid), 0) AS total_paid
      FROM payments
      WHERE (year < ? OR (year = ? AND month < ?))
      GROUP BY client_id
    ''', [year, year, month]);

    final paid = <int, double>{};
    for (final r in paidRows) {
      paid[(r['client_id'] as num).toInt()] =
          (r['total_paid'] as num? ?? 0).toDouble();
    }

    final result = <int, double>{};
    final allIds = {...billed.keys, ...paid.keys};
    for (final id in allIds) {
      final b = billed[id] ?? 0;
      final p = paid[id] ?? 0;
      result[id] = (b - p).clamp(0.0, double.infinity);
    }
    return result;
  }

  /// Returns map of clientId → amountPaidThisMonth
  Future<Map<int, double>> getPaidThisMonth(int year, int month) async {
    final rows = await _db.rawQuery('''
      SELECT client_id, COALESCE(SUM(amount_paid), 0) AS total_paid
      FROM payments
      WHERE year = ? AND month = ?
      GROUP BY client_id
    ''', [year, month]);

    final result = <int, double>{};
    for (final r in rows) {
      result[(r['client_id'] as num).toInt()] =
          (r['total_paid'] as num? ?? 0).toDouble();
    }
    return result;
  }
}