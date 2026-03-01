// lib/controllers/credit_controller.dart
import 'package:dairy_farm_app/data/models/credit_model.dart';
import 'package:dairy_farm_app/data/repositories/credit_repository.dart';
import 'package:dairy_farm_app/controllers/settings_controller.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PersonBalance {
  final String personName;
  final String? phone;
  final double totalCredit;
  final double totalPaid;
  final double totalLiters;
  final double balance; // positive = owes us

  PersonBalance({
    required this.personName,
    this.phone,
    required this.totalCredit,
    required this.totalPaid,
    required this.totalLiters,
    required this.balance,
  });
}

class CreditController extends GetxController {
  final _repo         = CreditRepository();
  final _settingsCtrl = Get.find<SettingsController>();

  final selectedMonth  = DateTime(DateTime.now().year, DateTime.now().month, 1).obs;
  final monthlyEntries = <CreditModel>[].obs;
  final personBalances = <PersonBalance>[].obs;
  final isLoading      = false.obs;

  /// The person selected in the right panel (null = show balances)
  final selectedPerson = RxnString();
  final personEntries  = <CreditModel>[].obs;

  /// Exposes current rate per liter for the add-credit dialog
  double get ratePerLiter => _settingsCtrl.ratePerLiter.value;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  // ── Month navigation ────────────────────────────────────────────────────────

  void previousMonth() {
    final m = selectedMonth.value;
    loadMonth(DateTime(m.year, m.month - 1));
  }

  void nextMonth() {
    final m    = selectedMonth.value;
    final next = DateTime(m.year, m.month + 1);
    if (!next.isAfter(DateTime(DateTime.now().year, DateTime.now().month))) {
      loadMonth(next);
    }
  }

  Future<void> loadMonth(DateTime month) async {
    selectedMonth.value = DateTime(month.year, month.month, 1);
    isLoading.value     = true;
    monthlyEntries.value =
        await _repo.getByMonth(month.year, month.month);
    isLoading.value = false;
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    await loadMonth(selectedMonth.value);
    await _refreshBalances();
    isLoading.value = false;
  }

  Future<void> _refreshBalances() async {
    final rows = await _repo.getPersonBalances();
    personBalances.value = rows
        .map((r) => PersonBalance(
              personName:  r['person_name'] as String,
              phone:       r['phone'] as String?,
              totalCredit: (r['total_credit'] as num).toDouble(),
              totalPaid:   (r['total_paid']   as num).toDouble(),
              totalLiters: (r['total_liters'] as num).toDouble(),
              balance:     (r['balance']      as num).toDouble(),
            ))
        .toList();
  }

  // ── Person drill-down ───────────────────────────────────────────────────────

  Future<void> selectPerson(String name) async {
    selectedPerson.value = name;
    final all = await _repo.getAll();
    personEntries.value  = all.where((e) => e.personName == name).toList();
  }

  void clearPersonSelection() {
    selectedPerson.value = null;
    personEntries.clear();
  }

  // ── CRUD ────────────────────────────────────────────────────────────────────

  /// Adds a credit or debit entry.
  /// For 'credit': liters are deducted from daily production automatically
  ///   because the dashboard subtracts credit liters from remaining milk.
  /// For 'debit' (payment): the amount is reflected as income in the ledger.
  Future<void> addEntry(CreditModel entry) async {
    await _repo.insert(entry);
    await loadAll();
    if (selectedPerson.value != null) {
      await selectPerson(selectedPerson.value!);
    }
    Get.snackbar(
      entry.isCredit ? 'Credit Added' : 'Payment Recorded',
      entry.isCredit
          ? '${entry.personName} — Rs. ${entry.amount.toStringAsFixed(0)} '
            '(${entry.liters.toStringAsFixed(1)} L deducted from production)'
          : '${entry.personName} — Rs. ${entry.amount.toStringAsFixed(0)} received',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> deleteEntry(int id) async {
    await _repo.delete(id);
    await loadAll();
    if (selectedPerson.value != null) {
      await selectPerson(selectedPerson.value!);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String get monthLabel =>
      DateFormat('MMMM yyyy').format(selectedMonth.value);

  double get monthCreditTotal =>
      monthlyEntries.where((e) => e.isCredit).fold(0.0, (s, e) => s + e.amount);

  double get monthDebitTotal =>
      monthlyEntries.where((e) => e.isDebit).fold(0.0, (s, e) => s + e.amount);

  double get monthCreditLiters =>
      monthlyEntries.where((e) => e.isCredit).fold(0.0, (s, e) => s + e.liters);

  double get totalOutstanding =>
      personBalances.fold(0.0, (s, p) => s + (p.balance > 0 ? p.balance : 0));

  Map<String, List<CreditModel>> get groupedByDate {
    final map = <String, List<CreditModel>>{};
    for (final e in monthlyEntries) {
      map.putIfAbsent(e.entryDate, () => []).add(e);
    }
    return Map.fromEntries(
        map.entries.toList()..sort((a, b) => b.key.compareTo(a.key)));
  }

  /// Returns all entries for Excel export purposes
  Future<List<CreditModel>> getAllEntries() => _repo.getAll();
}