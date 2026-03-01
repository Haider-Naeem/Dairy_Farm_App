// lib/data/models/billing_summary_model.dart
class BillingSummaryModel {
  final int clientId;
  final String? clientName;
  final bool isPayer;

  // Current month sales data
  final double allocatedLiters;
  final double extraLiters;
  final double extraAmount;
  final double currentMonthAmount;

  // Previous pending (unpaid balance from all prior months)
  final double previousPending;

  // Total due = previousPending + currentMonthAmount
  double get totalDue => previousPending + currentMonthAmount;

  // Payments made specifically FOR this month
  final double amountPaidThisMonth;

  // Remaining balance = totalDue - amountPaidThisMonth
  double get remainingBalance => totalDue - amountPaidThisMonth;

  // Total liters this month
  double get totalLiters =>
      allocatedLiters + extraLiters + (ratePerLiter > 0 ? extraAmount / ratePerLiter : 0);

  final double ratePerLiter;

  const BillingSummaryModel({
    required this.clientId,
    this.clientName,
    required this.isPayer,
    required this.allocatedLiters,
    required this.extraLiters,
    required this.extraAmount,
    required this.currentMonthAmount,
    required this.previousPending,
    required this.amountPaidThisMonth,
    required this.ratePerLiter,
  });
}