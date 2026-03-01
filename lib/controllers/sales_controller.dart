// lib/controllers/sales_controller.dart
import 'package:dairy_farm_app/controllers/dashboard_controller.dart';
import 'package:dairy_farm_app/controllers/settings_controller.dart';
import 'package:dairy_farm_app/data/models/cash_sale_model.dart';
import 'package:dairy_farm_app/data/models/sale_model.dart';
import 'package:dairy_farm_app/data/repositories/cash_sale_repository.dart';
import 'package:dairy_farm_app/data/repositories/client_repository.dart';
import 'package:dairy_farm_app/data/repositories/credit_repository.dart';
import 'package:dairy_farm_app/data/repositories/production_repository.dart';
import 'package:dairy_farm_app/data/repositories/sale_repository.dart';
import 'package:get/get.dart';

class SalesController extends GetxController {
  final _saleRepo     = Get.find<SaleRepository>();
  final _clientRepo   = Get.find<ClientRepository>();
  final _cashRepo     = Get.find<CashSaleRepository>();
  final _prodRepo     = Get.find<ProductionRepository>();
  final _creditRepo   = CreditRepository();
  final _settingsCtrl = Get.find<SettingsController>();

  final selectedDate = DateTime.now().obs;
  final sales        = <SaleModel>[].obs;
  final cashSales    = <CashSaleModel>[].obs;
  final isLoading    = false.obs;

  final searchQuery = ''.obs;

  /// Production total for the currently selected sales date.
  final productionTotalForDate = 0.0.obs;

  /// Remaining milk carried over from the day BEFORE the selected date.
  final previousRemaining = 0.0.obs;

  /// Liters given on credit for the currently selected date.
  final creditLitersForDate = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadSalesForDate(DateTime.now());
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> loadSalesForDate(DateTime date) async {
    isLoading.value    = true;
    selectedDate.value = date;
    searchQuery.value  = '';
    final dateStr = _fmt(date);

    final existingSales = await _saleRepo.getByDate(dateStr);
    final clients       = await _clientRepo.getAll(activeOnly: true);
    final existingCash  = await _cashRepo.getByDate(dateStr);

    // ── Production for this date ─────────────────────────────────────────────
    productionTotalForDate.value =
        await _prodRepo.getTotalByDate(dateStr);

    // ── Credit liters given on this date (deducted from stock) ───────────────
    creditLitersForDate.value =
        await _creditRepo.getCreditLitersForDate(dateStr);

    // ── Previous-day remaining ───────────────────────────────────────────────
    final prevDate    = date.subtract(const Duration(days: 1));
    final prevDateStr = _fmt(prevDate);
    final prevProd    = await _prodRepo.getTotalByDate(prevDateStr);
    final prevSales   = await _saleRepo.getByDate(prevDateStr);
    final prevCash    = await _cashRepo.getByDate(prevDateStr);
    final prevCreditL = await _creditRepo.getCreditLitersForDate(prevDateStr);
    final prevSold    = prevSales.fold(0.0, (s, e) => s + e.totalLiters);
    final prevCashL   = prevCash.fold(0.0, (s, e) => s + e.litersFromCash);
    // Previous remaining now also subtracts credit liters from that day
    previousRemaining.value =
        (prevProd - prevSold - prevCashL - prevCreditL)
            .clamp(0.0, double.infinity);

    // ── Build sales rows ─────────────────────────────────────────────────────
    final Map<int, SaleModel> saleMap = {
      for (final s in existingSales) s.clientId: s
    };

    final List<SaleModel> result = [];
    for (final client in clients) {
      if (saleMap.containsKey(client.id)) {
        result.add(saleMap[client.id]!);
      } else {
        result.add(SaleModel(
          clientId: client.id!,
          saleDate: dateStr,
          allocatedLiters: client.allocatedLiters,
          ratePerLiter: _settingsCtrl.ratePerLiter.value,
          createdAt: DateTime.now().toIso8601String(),
          clientName: client.name,
          isPayer: client.isPayer,
        ));
      }
    }

    sales.value     = result;
    cashSales.value = existingCash;
    isLoading.value = false;
  }

  Future<void> updateSale(SaleModel sale) async {
    if (sale.id != null) {
      await _saleRepo.update(sale);
    } else {
      await _saleRepo.upsert(sale);
    }
    final idx = sales.indexWhere((s) => s.clientId == sale.clientId);
    if (idx != -1) sales[idx] = sale;
    sales.refresh();
    Get.find<DashboardController>().loadDashboard();
  }

  Future<void> addCashSale(CashSaleModel cashSale) async {
    await _cashRepo.insert(cashSale);
    cashSales.value = await _cashRepo.getByDate(_fmt(selectedDate.value));
    Get.find<DashboardController>().loadDashboard();
  }

  Future<void> deleteCashSale(int id) async {
    await _cashRepo.delete(id);
    cashSales.removeWhere((c) => c.id == id);
    Get.find<DashboardController>().loadDashboard();
  }

  // ── Totals ─────────────────────────────────────────────────────────────────

  // ALL clients (payers + non-payers) — milk is physically deducted for both.
  double get totalClientLiters =>
      sales.fold(0.0, (s, e) => s + e.totalLiters);

  double get totalCashLiters =>
      cashSales.fold(0.0, (s, e) => s + e.litersFromCash);

  double get totalCashReceived =>
      cashSales.fold(0.0, (s, e) => s + e.cashAmount);

  double get totalAvailable =>
      productionTotalForDate.value + previousRemaining.value;

  /// Remaining = available − client sales − cash sales − credit liters
  double get currentRemaining =>
      totalAvailable -
      totalClientLiters -
      totalCashLiters -
      creditLitersForDate.value;

  Future<List<SaleModel>> getSalesByRange(String from, String to) =>
      _saleRepo.getByDateRange(from, to);
}