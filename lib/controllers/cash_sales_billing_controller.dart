// ============================================================
// lib/controllers/cash_sales_billing_controller.dart
// ============================================================
import 'package:dairy_farm_app/data/models/cash_sale_model.dart';
import 'package:dairy_farm_app/data/repositories/cash_sale_repository.dart';
import 'package:get/get.dart';

class CashSalesBillingController extends GetxController {
  final _cashRepo = Get.find<CashSaleRepository>();

  final selectedMonth = DateTime.now().month.obs;
  final selectedYear = DateTime.now().year.obs;
  final dailySummary = <CashSaleModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadMonth(DateTime.now().year, DateTime.now().month);
  }

  Future<void> changeMonth(int year, int month) async {
    selectedYear.value = year;
    selectedMonth.value = month;
    await loadMonth(year, month);
  }

  Future<void> loadMonth(int year, int month) async {
    isLoading.value = true;
    dailySummary.value =
        await _cashRepo.getMonthlySummaryByDay(year, month);
    isLoading.value = false;
  }

  // ── Aggregates ─────────────────────────────────────────────────────────────
  double get totalCashReceived =>
      dailySummary.fold(0.0, (s, e) => s + e.cashAmount);

  double get totalLitersDeducted =>
      dailySummary.fold(0.0, (s, e) => s + e.litersFromCash);

  int get totalDaysWithSales => dailySummary.length;

  /// Average cash per sale day
  double get avgDailyCash =>
      totalDaysWithSales > 0 ? totalCashReceived / totalDaysWithSales : 0;

  Future<List<CashSaleModel>> getCashSalesByRange(
          String from, String to) =>
      _cashRepo.getByDateRange(from, to);
}