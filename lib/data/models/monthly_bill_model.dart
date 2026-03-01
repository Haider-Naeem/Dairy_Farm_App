// lib/data/models/monthly_bill_model.dart

class MonthlyBillModel {
  final int year;
  final int month;
  final int dayCount;
  final double totalLiters;
  final double totalAmount;

  const MonthlyBillModel({
    required this.year,
    required this.month,
    required this.dayCount,
    required this.totalLiters,
    required this.totalAmount,
  });

  String get monthKey =>
      '$year-${month.toString().padLeft(2, '0')}';
}