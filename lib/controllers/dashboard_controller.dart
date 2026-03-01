// lib/controllers/dashboard_controller.dart
import 'package:dairy_farm_app/data/repositories/cash_sale_repository.dart';
import 'package:dairy_farm_app/data/repositories/client_repository.dart';
import 'package:dairy_farm_app/data/repositories/credit_repository.dart';
import 'package:dairy_farm_app/data/repositories/production_repository.dart';
import 'package:dairy_farm_app/data/repositories/sale_repository.dart';
import 'package:get/get.dart';

class DashboardController extends GetxController {
  final _saleRepo   = Get.find<SaleRepository>();
  final _prodRepo   = Get.find<ProductionRepository>();
  final _clientRepo = Get.find<ClientRepository>();
  final _cashRepo   = Get.find<CashSaleRepository>();
  final _creditRepo = CreditRepository();

  final dailySales        = 0.0.obs;
  final dailyCashLiters   = 0.0.obs;
  final dailyCashReceived = 0.0.obs;
  final dailyProduction   = 0.0.obs;
  final totalClients      = 0.obs;
  final remainingMilk     = 0.0.obs;
  final previousRemaining = 0.0.obs; // carry-over from yesterday
  final totalAvailable    = 0.0.obs; // production + carry-over
  final dailyCreditLiters = 0.0.obs; // ← liters taken on credit today
  final isLoading         = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    isLoading.value = true;
    final today = _fmt(DateTime.now());

    // ── Today ─────────────────────────────────────────────────────────────────
    final sales      = await _saleRepo.getByDate(today);
    final prod       = await _prodRepo.getTotalByDate(today);
    final clients    = await _clientRepo.getAll();
    final cashSales  = await _cashRepo.getByDate(today);
    final creditL    = await _creditRepo.getCreditLitersForDate(today);

    final soldLiters   = sales.fold(0.0, (s, e) => s + e.totalLiters);
    final cashLiters   = cashSales.fold(0.0, (s, e) => s + e.litersFromCash);
    final cashReceived = cashSales.fold(0.0, (s, e) => s + e.cashAmount);

    // ── Yesterday carry-over ──────────────────────────────────────────────────
    final yesterday  = DateTime.now().subtract(const Duration(days: 1));
    final yStr       = _fmt(yesterday);
    final yProd      = await _prodRepo.getTotalByDate(yStr);
    final ySales     = await _saleRepo.getByDate(yStr);
    final yCash      = await _cashRepo.getByDate(yStr);
    final yCreditL   = await _creditRepo.getCreditLitersForDate(yStr);
    final ySold      = ySales.fold(0.0, (s, e) => s + e.totalLiters);
    final yCashL     = yCash.fold(0.0, (s, e) => s + e.litersFromCash);
    // Yesterday's remaining accounts for credit deductions too
    final yRemaining = (yProd - ySold - yCashL - yCreditL).clamp(0.0, double.infinity);

    // ── Assign observables ────────────────────────────────────────────────────
    dailySales.value        = soldLiters;
    dailyCashLiters.value   = cashLiters;
    dailyCashReceived.value = cashReceived;
    dailyProduction.value   = prod;
    totalClients.value      = clients.length;
    previousRemaining.value = yRemaining;
    totalAvailable.value    = prod + yRemaining;
    dailyCreditLiters.value = creditL;

    // Remaining = (today's prod + carry-over) − client sales − cash sales − credit liters
    remainingMilk.value = prod + yRemaining - soldLiters - cashLiters - creditL;

    isLoading.value = false;
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}