// lib/controllers/billing_controller.dart
import 'package:dairy_farm_app/data/models/billing_summary_model.dart';
import 'package:dairy_farm_app/data/models/payment_model.dart';
import 'package:dairy_farm_app/data/repositories/payment_repository.dart';
import 'package:dairy_farm_app/data/repositories/sale_repository.dart';
import 'package:dairy_farm_app/data/repositories/client_repository.dart';
import 'package:get/get.dart';

class BillingController extends GetxController {
  final _saleRepo    = Get.find<SaleRepository>();
  final _paymentRepo = Get.find<PaymentRepository>();
  final _clientRepo  = Get.find<ClientRepository>();

  final selectedYear  = DateTime.now().year.obs;
  final selectedMonth = DateTime.now().month.obs;
  final billingSummary = <BillingSummaryModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadMonthly();
  }

  Future<void> loadMonthly() async {
    isLoading.value = true;
    try {
      final year  = selectedYear.value;
      final month = selectedMonth.value;

      // 1. Get raw monthly sales (only payers — we filter after)
      final rawSales = await _saleRepo.getMonthlyByClient(year, month);

      // 2. Get all clients to know isPayer status
      final clients = await _clientRepo.getAll(activeOnly: false);
      final clientMap = {for (final c in clients) c.id!: c};

      // 3. Cumulative pending before this month (for all clients)
      final pendingMap =
          await _paymentRepo.getCumulativePendingBeforeForAll(year, month);

      // 4. Payments made for this specific month
      final paidThisMonth = await _paymentRepo.getPaidThisMonth(year, month);

      // 5. Build summary — only include payers in billing
      final summaries = <BillingSummaryModel>[];
      for (final sale in rawSales) {
        final client = clientMap[sale.clientId];
        if (client == null) continue;
        // Non-payers: milk deducted but excluded from billing
        if (!client.isPayer) continue;

        summaries.add(BillingSummaryModel(
          clientId: sale.clientId,
          clientName: sale.clientName,
          isPayer: true,
          allocatedLiters: sale.allocatedLiters,
          extraLiters: sale.extraLiters,
          extraAmount: sale.extraAmount,
          currentMonthAmount: sale.totalAmount,
          previousPending: pendingMap[sale.clientId] ?? 0.0,
          amountPaidThisMonth: paidThisMonth[sale.clientId] ?? 0.0,
          ratePerLiter: sale.ratePerLiter,
        ));
      }

      billingSummary.value = summaries;
    } finally {
      isLoading.value = false;
    }
  }

  void changeMonth(int year, int month) {
    selectedYear.value  = year;
    selectedMonth.value = month;
    loadMonthly();
  }

  /// Record a payment for a client in the selected month.
  Future<void> addPayment({
    required int clientId,
    required double amount,
    String? notes,
  }) async {
    if (amount <= 0) return;
    final now = DateTime.now();
    await _paymentRepo.insert(PaymentModel(
      clientId: clientId,
      year: selectedYear.value,
      month: selectedMonth.value,
      amountPaid: amount,
      paymentDate: now.toIso8601String().substring(0, 10),
      notes: notes,
      createdAt: now.toIso8601String(),
    ));
    await loadMonthly();
  }

  // ── Grand totals for footer ──────────────────────────────────────────────

  double get grandTotalCurrentBill =>
      billingSummary.fold(0.0, (s, e) => s + e.currentMonthAmount);

  double get grandTotalPreviousPending =>
      billingSummary.fold(0.0, (s, e) => s + e.previousPending);

  double get grandTotalDue =>
      billingSummary.fold(0.0, (s, e) => s + e.totalDue);

  double get grandTotalPaid =>
      billingSummary.fold(0.0, (s, e) => s + e.amountPaidThisMonth);

  double get grandTotalRemaining =>
      billingSummary.fold(0.0, (s, e) => s + e.remainingBalance);

  double get grandTotalLiters =>
      billingSummary.fold(0.0, (s, e) => s + e.totalLiters);
}