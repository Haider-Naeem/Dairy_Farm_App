// lib/controllers/ledger_controller.dart
import 'package:dairy_farm_app/data/repositories/cash_sale_repository.dart';
import 'package:dairy_farm_app/data/repositories/client_repository.dart';
import 'package:dairy_farm_app/data/repositories/expense_repository.dart';
import 'package:dairy_farm_app/data/repositories/sale_repository.dart';
import 'package:dairy_farm_app/data/repositories/credit_repository.dart';
import 'package:dairy_farm_app/controllers/settings_controller.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class LedgerSummary {
  final int year;
  final int month;

  final double totalExpenses;
  final double totalClientBilling;
  final double totalCashSales;
  final double totalCreditPayments; // ← payments received for past credits
  final double totalMilkProduced;
  final double totalMilkSoldClients;
  final double totalMilkCash;
  final double totalMilkCredit;     // ← liters given on credit this period
  final double freeMilkGiven;
  final int    activePayingClients;
  final int    activeFreeClients;
  final double netProfit;
  final double ratePerLiter;

  final DateTime? rangeFrom;
  final DateTime? rangeTo;

  const LedgerSummary({
    required this.year,
    required this.month,
    required this.totalExpenses,
    required this.totalClientBilling,
    required this.totalCashSales,
    required this.totalCreditPayments,
    required this.totalMilkProduced,
    required this.totalMilkSoldClients,
    required this.totalMilkCash,
    required this.totalMilkCredit,
    required this.freeMilkGiven,
    required this.activePayingClients,
    required this.activeFreeClients,
    required this.netProfit,
    required this.ratePerLiter,
    this.rangeFrom,
    this.rangeTo,
  });

  /// Monetary value of milk given free at current rate
  double get freeMilkValue => freeMilkGiven * ratePerLiter;

  /// Gross revenue = client billing + cash sales + credit payments received
  double get grossRevenue => totalClientBilling + totalCashSales + totalCreditPayments;

  /// Net revenue after deducting free milk value
  double get netRevenue => grossRevenue - freeMilkValue;
}

class LedgerController extends GetxController {
  final _expRepo      = Get.find<ExpenseRepository>();
  final _saleRepo     = Get.find<SaleRepository>();
  final _cashRepo     = Get.find<CashSaleRepository>();
  final _clientRepo   = Get.find<ClientRepository>();
  final _creditRepo   = CreditRepository();
  final _settingsCtrl = Get.find<SettingsController>();

  final selectedMonth  = DateTime(DateTime.now().year, DateTime.now().month, 1).obs;
  final summary        = Rx<LedgerSummary?>(null);
  final rangeSummary   = Rx<LedgerSummary?>(null);
  final isLoading      = false.obs;
  final isRangeLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadMonth(selectedMonth.value);
  }

  String get monthLabel =>
      DateFormat('MMMM yyyy').format(selectedMonth.value);

  void previousMonth() {
    final m = selectedMonth.value;
    loadMonth(DateTime(m.year, m.month - 1));
  }

  void nextMonth() {
    final m    = selectedMonth.value;
    final next = DateTime(m.year, m.month + 1);
    if (!next.isAfter(
        DateTime(DateTime.now().year, DateTime.now().month + 1))) {
      loadMonth(next);
    }
  }

  Future<void> loadMonth(DateTime month) async {
    selectedMonth.value = DateTime(month.year, month.month, 1);
    isLoading.value     = true;
    summary.value = await _buildSummary(month.year, month.month);
    isLoading.value = false;
  }

  Future<LedgerSummary?> loadRangeSummary(DateTime from, DateTime to) async {
    isRangeLoading.value = true;

    double totalExpenses          = 0;
    double totalClientBilling     = 0;
    double totalCashSales         = 0;
    double totalCreditPayments    = 0;
    double totalMilkProduced      = 0;
    double totalMilkSoldClients   = 0;
    double totalMilkCash          = 0;
    double totalMilkCredit        = 0;
    double freeMilkGiven          = 0;

    DateTime cursor = DateTime(from.year, from.month, 1);
    final end       = DateTime(to.year, to.month, 1);

    while (!cursor.isAfter(end)) {
      final s = await _buildSummary(cursor.year, cursor.month);
      totalExpenses          += s.totalExpenses;
      totalClientBilling     += s.totalClientBilling;
      totalCashSales         += s.totalCashSales;
      totalCreditPayments    += s.totalCreditPayments;
      totalMilkProduced      += s.totalMilkProduced;
      totalMilkSoldClients   += s.totalMilkSoldClients;
      totalMilkCash          += s.totalMilkCash;
      totalMilkCredit        += s.totalMilkCredit;
      freeMilkGiven          += s.freeMilkGiven;
      cursor = DateTime(cursor.year, cursor.month + 1);
    }

    final allClients          = await _clientRepo.getAll(activeOnly: true);
    final activePayingClients = allClients.where((c) => c.isPayer).length;
    final activeFreeClients   = allClients.where((c) => !c.isPayer).length;
    final rate                = _settingsCtrl.ratePerLiter.value;

    final totalIncome = totalClientBilling + totalCashSales + totalCreditPayments;

    final result = LedgerSummary(
      year:                 from.year,
      month:                from.month,
      totalExpenses:        totalExpenses,
      totalClientBilling:   totalClientBilling,
      totalCashSales:       totalCashSales,
      totalCreditPayments:  totalCreditPayments,
      totalMilkProduced:    totalMilkProduced,
      totalMilkSoldClients: totalMilkSoldClients,
      totalMilkCash:        totalMilkCash,
      totalMilkCredit:      totalMilkCredit,
      freeMilkGiven:        freeMilkGiven,
      activePayingClients:  activePayingClients,
      activeFreeClients:    activeFreeClients,
      netProfit:            totalIncome - totalExpenses,
      ratePerLiter:         rate,
      rangeFrom:            from,
      rangeTo:              to,
    );

    rangeSummary.value   = result;
    isRangeLoading.value = false;
    return result;
  }

  Future<LedgerSummary> _buildSummary(int y, int m) async {
    final expenses         = await _expRepo.getByMonth(y, m);
    final totalExpenses    = expenses.fold(0.0, (s, e) => s + e.amount);

    final clientSales          = await _saleRepo.getByMonth(y, m);
    final totalClientBilling   = clientSales.fold(0.0, (s, e) => s + e.totalAmount);
    final totalMilkSoldClients =
        clientSales.where((e) => e.isPayer).fold(0.0, (s, e) => s + e.totalLiters);
    final freeMilkGiven        =
        clientSales.where((e) => !e.isPayer).fold(0.0, (s, e) => s + e.totalLiters);

    final cashSales      = await _cashRepo.getByMonth(y, m);
    final totalCashSales = cashSales.fold(0.0, (s, e) => s + e.cashAmount);
    final totalMilkCash  = cashSales.fold(0.0, (s, e) => s + e.litersFromCash);

    // Credit: payments received this month (positive income)
    final totalCreditPayments = await _creditRepo.getTotalPaymentsByMonth(y, m);

    // Credit: liters given on credit this month
    final monthCredits   = await _creditRepo.getByMonth(y, m);
    final totalMilkCredit =
        monthCredits.where((e) => e.isCredit).fold(0.0, (s, e) => s + e.liters);

    final allClients          = await _clientRepo.getAll(activeOnly: true);
    final activePayingClients = allClients.where((c) => c.isPayer).length;
    final activeFreeClients   = allClients.where((c) => !c.isPayer).length;

    final totalMilkProduced = await _saleRepo.getTotalLitersForMonth(y, m);
    final rate              = _settingsCtrl.ratePerLiter.value;

    final totalIncome = totalClientBilling + totalCashSales + totalCreditPayments;

    return LedgerSummary(
      year:                 y,
      month:                m,
      totalExpenses:        totalExpenses,
      totalClientBilling:   totalClientBilling,
      totalCashSales:       totalCashSales,
      totalCreditPayments:  totalCreditPayments,
      totalMilkProduced:    totalMilkProduced,
      totalMilkSoldClients: totalMilkSoldClients,
      totalMilkCash:        totalMilkCash,
      totalMilkCredit:      totalMilkCredit,
      freeMilkGiven:        freeMilkGiven,
      activePayingClients:  activePayingClients,
      activeFreeClients:    activeFreeClients,
      netProfit:            totalIncome - totalExpenses,
      ratePerLiter:         rate,
    );
  }
}