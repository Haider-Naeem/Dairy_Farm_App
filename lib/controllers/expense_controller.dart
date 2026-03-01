// lib/controllers/expense_controller.dart
import 'package:dairy_farm_app/data/models/expense_model.dart';
import 'package:dairy_farm_app/data/repositories/expense_repository.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ExpenseController extends GetxController {
  final _repo = Get.find<ExpenseRepository>();

  // ── Month state ─────────────────────────────────────────────────────────────
  final selectedMonth    = DateTime(DateTime.now().year, DateTime.now().month, 1).obs;
  final monthlyExpenses  = <ExpenseModel>[].obs;
  final isLoading        = false.obs;

  // ── Kept for backward compat (Sales date picker still uses these) ───────────
  final selectedDate = DateTime.now().obs;
  final expenses     = <ExpenseModel>[].obs;

  final categories = const [
    'Feed', 'Medicine', 'Labor', 'Maintenance',
    'Electricity', 'Fuel', 'Veterinary', 'Other',
  ];

  @override
  void onInit() {
    super.onInit();
    loadMonth(selectedMonth.value);
  }

  // ── Month navigation ────────────────────────────────────────────────────────

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
    selectedMonth.value  = DateTime(month.year, month.month, 1);
    isLoading.value      = true;
    monthlyExpenses.value =
        await _repo.getByMonth(month.year, month.month);
    isLoading.value = false;
  }

  // ── Backward-compat daily loader ────────────────────────────────────────────
  Future<void> loadForDate(DateTime date) async {
    selectedDate.value = date;
    expenses.value =
        await _repo.getByDate(date.toIso8601String().substring(0, 10));
    // Also refresh the month if it changed
    if (date.month != selectedMonth.value.month ||
        date.year  != selectedMonth.value.year) {
      await loadMonth(DateTime(date.year, date.month));
    }
  }

  // ── CRUD ────────────────────────────────────────────────────────────────────

  Future<void> add(ExpenseModel e) async {
    await _repo.insert(e);
    await loadMonth(selectedMonth.value);
    Get.snackbar('Expense Added', '${e.category} — Rs. ${e.amount.toStringAsFixed(0)}',
        snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await loadMonth(selectedMonth.value);
  }

  // ── Grouping helpers ────────────────────────────────────────────────────────

  /// Entries grouped by date, newest-date first.
  Map<String, List<ExpenseModel>> get groupedByDate {
    final map = <String, List<ExpenseModel>>{};
    for (final e in monthlyExpenses) {
      map.putIfAbsent(e.expenseDate, () => []).add(e);
    }
    return Map.fromEntries(
        map.entries.toList()..sort((a, b) => b.key.compareTo(a.key)));
  }

  double get monthTotal =>
      monthlyExpenses.fold(0.0, (s, e) => s + e.amount);

  Map<String, double> get categoryTotals {
    final map = <String, double>{};
    for (final e in monthlyExpenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return Map.fromEntries(
        map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }
}