// lib/data/models/sale_model.dart
class SaleModel {
  final int? id;
  final int clientId;
  final String saleDate;
  final double allocatedLiters;
  final bool takenAllocated;
  final double extraLiters;
  final double extraAmount;
  final double ratePerLiter;
  final String createdAt;
  String? clientName;

  /// false = milk tracked & deducted from stock, but NO amount is calculated.
  final bool isPayer;

  SaleModel({
    this.id,
    required this.clientId,
    required this.saleDate,
    required this.allocatedLiters,
    this.takenAllocated = false,
    this.extraLiters = 0.0,
    this.extraAmount = 0.0,
    required this.ratePerLiter,
    required this.createdAt,
    this.clientName,
    this.isPayer = true,
  });

  // Always calculated — milk is physically deducted for everyone.
  double get extraAmountLiters =>
      (isPayer && ratePerLiter > 0 && extraAmount > 0)
          ? extraAmount / ratePerLiter
          : 0;

  double get totalLiters =>
      (takenAllocated ? allocatedLiters : 0) +
      extraLiters +
      extraAmountLiters;

  // Zero for non-payers — no bill generated, no amount tracked.
  double get totalAmount {
    if (!isPayer) return 0;
    return (takenAllocated ? allocatedLiters * ratePerLiter : 0) +
        (extraLiters * ratePerLiter) +
        extraAmount;
  }

  factory SaleModel.fromMap(Map<String, dynamic> map) => SaleModel(
        id: map['id'],
        clientId: map['client_id'],
        saleDate: map['sale_date'],
        allocatedLiters: (map['allocated_liters'] as num).toDouble(),
        takenAllocated: map['taken_allocated'] == 1,
        extraLiters: (map['extra_liters'] as num).toDouble(),
        extraAmount: (map['extra_amount'] as num).toDouble(),
        ratePerLiter: (map['rate_per_liter'] as num).toDouble(),
        createdAt: map['created_at'],
        clientName: map['client_name'],
        isPayer: (map['is_payer'] as int? ?? 1) == 1,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'client_id': clientId,
        'sale_date': saleDate,
        'allocated_liters': allocatedLiters,
        'taken_allocated': takenAllocated ? 1 : 0,
        'extra_liters': extraLiters,
        'extra_amount': extraAmount,
        'rate_per_liter': ratePerLiter,
        'created_at': createdAt,
        // is_payer is read-only from the clients table; not stored in sales
      };
}