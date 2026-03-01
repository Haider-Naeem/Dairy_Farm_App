// lib/controllers/vaccination_controller.dart
import 'package:dairy_farm_app/app/utils/excel_exporter.dart';
import 'package:dairy_farm_app/controllers/animal_controller.dart';
import 'package:dairy_farm_app/data/models/animal_model.dart';
import 'package:dairy_farm_app/data/models/vaccination_model.dart';
import 'package:dairy_farm_app/data/repositories/animal_repository.dart';
import 'package:dairy_farm_app/data/repositories/vaccination_repository.dart';
import 'package:get/get.dart';


/// Period options shown in the filter bar.
enum VaccPeriod { all, thisWeek, thisMonth, thisYear, custom }

class VaccinationController extends GetxController {
  final _repo       = Get.find<VaccinationRepository>();
  final _animalRepo = Get.find<AnimalRepository>();

  // ── Raw data ──────────────────────────────────────────────────────────────
  final allVaccinations = <VaccinationModel>[].obs;
  final animals         = <AnimalModel>[].obs;
  final isLoading       = false.obs;

  // ── Filters ───────────────────────────────────────────────────────────────
  final selectedAnimalId = Rx<int?>(null);
  final selectedPeriod   = VaccPeriod.all.obs;
  final customFrom       = ''.obs;
  final customTo         = ''.obs;
  final showDueOnly      = false.obs;

  // ── Derived (filtered) list ───────────────────────────────────────────────
  List<VaccinationModel> get filtered {
    var list = allVaccinations.toList();

    // Animal filter
    if (selectedAnimalId.value != null) {
      list = list.where((v) => v.animalId == selectedAnimalId.value).toList();
    }

    // Period filter
    final now = DateTime.now();
    String? from;
    String? to;

    switch (selectedPeriod.value) {
      case VaccPeriod.thisWeek:
        final start = now.subtract(Duration(days: now.weekday - 1));
        from = _fmt(start);
        to   = _fmt(now);
        break;
      case VaccPeriod.thisMonth:
        from = '${now.year}-${_pad(now.month)}-01';
        to   = _fmt(now);
        break;
      case VaccPeriod.thisYear:
        from = '${now.year}-01-01';
        to   = _fmt(now);
        break;
      case VaccPeriod.custom:
        from = customFrom.value.isEmpty ? null : customFrom.value;
        to   = customTo.value.isEmpty   ? null : customTo.value;
        break;
      default:
        break;
    }

    if (from != null) {
      list = list.where((v) => v.vaccinationDate.compareTo(from!) >= 0).toList();
    }
    if (to != null) {
      list = list.where((v) => v.vaccinationDate.compareTo(to!) <= 0).toList();
    }

    // Due-only filter
    if (showDueOnly.value) {
      list = list.where((v) => v.nextDueDate != null && !v.isDone).toList();
    }

    return list;
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value       = true;
    allVaccinations.value = await _repo.getAll();
    animals.value         = await _animalRepo.getAll();
    isLoading.value       = false;
  }

  Future<void> add(VaccinationModel v) async {
    await _repo.insert(v);
    await load();
    _syncAnimalController(v.animalId);
  }

  Future<void> markDone(VaccinationModel v) async {
    await _repo.markAsDone(v.id!);
    await load();
    // Keep the Animal detail panel in sync — refresh that animal's vaccination
    // list and re-check alert badges so the red "Due" chip disappears.
    _syncAnimalController(v.animalId);
  }

  Future<void> delete(int id) async {
    // Capture animalId before deletion for sync purposes
    final vacc = allVaccinations.firstWhereOrNull((v) => v.id == id);
    await _repo.delete(id);
    await load();
    if (vacc != null) _syncAnimalController(vacc.animalId);
  }

  // ── Export ────────────────────────────────────────────────────────────────
  Future<void> exportToExcel() async {
    final list = filtered;
    if (list.isEmpty) return;
    final animalName = selectedAnimalId.value == null
        ? null
        : animals
            .firstWhereOrNull((a) => a.id == selectedAnimalId.value)
            ?.tagNumber;

    await ExcelExporter.exportVaccinations(
      list,
      animalTag: animalName,
      periodLabel: _periodLabel(),
    );
  }

  String _periodLabel() {
    switch (selectedPeriod.value) {
      case VaccPeriod.thisWeek:  return 'This Week';
      case VaccPeriod.thisMonth: return 'This Month';
      case VaccPeriod.thisYear:  return 'This Year';
      case VaccPeriod.custom:
        final f = customFrom.value.isEmpty ? '—' : customFrom.value;
        final t = customTo.value.isEmpty   ? '—' : customTo.value;
        return '$f to $t';
      default: return 'All Time';
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _fmt(DateTime d) =>
      '${d.year}-${_pad(d.month)}-${_pad(d.day)}';

  String _pad(int n) => n.toString().padLeft(2, '0');

  /// If AnimalController is registered and the given animal is currently
  /// selected in the detail panel, refresh its vaccination list and alert
  /// badges so both views stay in sync.
  void _syncAnimalController(int animalId) {
    try {
      final animalCtrl = Get.find<AnimalController>();
      animalCtrl.refreshAlerts();
      if (animalCtrl.selectedAnimal.value?.id == animalId) {
        animalCtrl.refreshSelectedVaccinations();
      }
    } catch (_) {
      // AnimalController not yet registered — nothing to sync.
    }
  }
}