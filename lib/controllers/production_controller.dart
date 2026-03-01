// lib/controllers/production_controller.dart
import 'package:dairy_farm_app/data/models/production_model.dart';
import 'package:dairy_farm_app/data/repositories/production_repository.dart';
import 'package:get/get.dart';

class ProductionController extends GetxController {
  final _repo = Get.find<ProductionRepository>();

  // ── Selected-date state (used only by Production tab) ──────────────────
  final productions  = <ProductionModel>[].obs;
  final dailyTotal   = 0.0.obs;
  final selectedDate = DateTime.now().obs;
  final isLoading    = false.obs;

  // ── TODAY's state (used by Dashboard & never changes on date-pick) ─────
  final todayProductions = <ProductionModel>[].obs;
  final todayTotal       = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadProductionForDate(DateTime.now());
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  Future<void> loadProductionForDate(DateTime date) async {
    isLoading.value    = true;
    selectedDate.value = date;
    final dateStr      = _fmt(date);

    productions.value = await _repo.getByDate(dateStr);
    _recalcTotal();

    // If we loaded today, also refresh the "today" snapshot
    if (_isToday(date)) {
      todayProductions.value = List.from(productions);
      todayTotal.value       = dailyTotal.value;
    }

    isLoading.value = false;
  }

  Future<void> updateProduction(ProductionModel p) async {
    await _repo.upsert(p);

    final dateStr = _fmt(selectedDate.value);
    productions.value = await _repo.getByDate(dateStr);
    _recalcTotal();

    // Keep today snapshot in sync
    if (_isToday(selectedDate.value)) {
      todayProductions.value = List.from(productions);
      todayTotal.value       = dailyTotal.value;
    }
  }

  /// Reload the "today" snapshot explicitly (called by DashboardView on resume).
  Future<void> refreshToday() async {
    final todayStr         = _fmt(DateTime.now());
    todayProductions.value = await _repo.getByDate(todayStr);
    todayTotal.value       =
        todayProductions.fold(0.0, (s, p) => s + p.total);
  }

  void _recalcTotal() {
    dailyTotal.value = productions.fold(0.0, (sum, p) => sum + p.total);
  }

  Future<List<ProductionModel>> getAnimalHistory(
          int animalId, int year, int month) =>
      _repo.getByAnimalAndMonth(animalId, year, month);

  Future<List<ProductionModel>> getByRange(String from, String to) =>
      _repo.getByDateRange(from, to);
}