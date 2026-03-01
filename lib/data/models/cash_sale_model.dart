// lib/data/models/cash_sale_model.dart
class CashSaleModel {
  final int? id;
  final String saleDate;
  final double cashAmount;
  final double ratePerLiter;
  final String? notes;
  final String createdAt;

  CashSaleModel({
    this.id,
    required this.saleDate,
    required this.cashAmount,
    required this.ratePerLiter,
    this.notes,
    required this.createdAt,
  });

  // Liters sold = cash received ÷ rate per liter
  double get litersFromCash => ratePerLiter > 0 ? cashAmount / ratePerLiter : 0;

  factory CashSaleModel.fromMap(Map<String, dynamic> map) => CashSaleModel(
        id: map['id'],
        saleDate: map['sale_date'],
        cashAmount: (map['cash_amount'] as num).toDouble(),
        ratePerLiter: (map['rate_per_liter'] as num).toDouble(),
        notes: map['notes'],
        createdAt: map['created_at'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'sale_date': saleDate,
        'cash_amount': cashAmount,
        'rate_per_liter': ratePerLiter,
        'notes': notes,
        'created_at': createdAt,
      };
}