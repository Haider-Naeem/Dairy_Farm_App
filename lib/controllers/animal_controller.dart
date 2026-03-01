// lib/controllers/animal_controller.dart
import 'package:dairy_farm_app/data/models/animal_event_model.dart';
import 'package:dairy_farm_app/data/models/animal_model.dart';
import 'package:dairy_farm_app/data/models/vaccination_model.dart';
import 'package:dairy_farm_app/data/repositories/animal_event_repository.dart';
import 'package:dairy_farm_app/data/repositories/animal_repository.dart';
import 'package:dairy_farm_app/data/repositories/vaccination_repository.dart';
import 'package:get/get.dart';

import 'vaccination_controller.dart';

class AnimalController extends GetxController {
  final _repo      = Get.find<AnimalRepository>();
  final _vaccRepo  = Get.find<VaccinationRepository>();
  final _eventRepo = Get.find<AnimalEventRepository>();

  final animals            = <AnimalModel>[].obs;
  final isLoading          = false.obs;

  // Master-detail state
  final selectedAnimal     = Rx<AnimalModel?>(null);
  final animalVaccinations = <VaccinationModel>[].obs;
  final animalChildren     = <AnimalModel>[].obs;
  final animalEvents       = <AnimalEventModel>[].obs;
  final isDetailLoading    = false.obs;

  final alertAnimalIds = <int>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAnimals();
  }

  // ── Animals ───────────────────────────────────────────────────────────────

  Future<void> loadAnimals() async {
    isLoading.value = true;
    animals.value   = await _repo.getAll(activeOnly: false);
    await _refreshAlertIds();
    isLoading.value = false;
  }

  Future<void> addAnimal(AnimalModel a) async {
    await _repo.insert(a);
    await loadAnimals();
  }

  Future<void> updateAnimal(AnimalModel a) async {
    await _repo.update(a);
    if (selectedAnimal.value?.id == a.id) selectedAnimal.value = a;
    await loadAnimals();
  }

  Future<void> deleteAnimal(int id) async {
    await _repo.delete(id);
    if (selectedAnimal.value?.id == id) {
      selectedAnimal.value = null;
      animalVaccinations.clear();
      animalChildren.clear();
      animalEvents.clear();
    }
    await loadAnimals();
  }

  // ── Selection / detail ────────────────────────────────────────────────────

  Future<void> selectAnimal(AnimalModel a) async {
    selectedAnimal.value  = a;
    isDetailLoading.value = true;
    await Future.wait([
      _refreshVaccinations(a.id!),
      _refreshChildren(a.id!),
      _refreshEvents(a.id!),
    ]);
    isDetailLoading.value = false;
  }

  Future<void> _refreshVaccinations(int animalId) async {
    animalVaccinations.value = await _vaccRepo.getByAnimal(animalId);
  }

  Future<void> _refreshChildren(int animalId) async {
    animalChildren.value = await _repo.getChildrenOf(animalId);
  }

  Future<void> _refreshEvents(int animalId) async {
    animalEvents.value = await _eventRepo.getByAnimal(animalId);
  }

  // ── FIX 1: use clear() + addAll() so both operations emit change events,
  // guaranteeing all Obx widgets are notified even if the new list is empty.
  Future<void> _refreshAlertIds() async {
    final ids = await _repo.getUpcomingDueAnimalIds(withinDays: 7);
    alertAnimalIds.clear();
    alertAnimalIds.addAll(ids);
  }

  // ── Public refresh helpers ────────────────────────────────────────────────

  Future<void> refreshSelectedVaccinations() async {
    final id = selectedAnimal.value?.id;
    if (id == null) return;
    await _refreshVaccinations(id);
  }

  Future<void> refreshAlerts() async {
    await _refreshAlertIds();
  }

  // ── Vaccination CRUD ──────────────────────────────────────────────────────

  Future<void> addVaccination(VaccinationModel v) async {
    await _vaccRepo.insert(v);
    await _refreshVaccinations(v.animalId);
    await _refreshAlertIds();
    _syncVaccinationController();
  }

  Future<void> markVaccinationDone(VaccinationModel v) async {
    await _vaccRepo.markAsDone(v.id!);
    await _refreshVaccinations(v.animalId);
    await _refreshAlertIds();
    _syncVaccinationController();
  }

  Future<void> deleteVaccination(int id) async {
    await _vaccRepo.delete(id);
    if (selectedAnimal.value != null) {
      await _refreshVaccinations(selectedAnimal.value!.id!);
    }
    await _refreshAlertIds();
    _syncVaccinationController();
  }

  // ── Events CRUD ───────────────────────────────────────────────────────────

  Future<void> addEvent(AnimalEventModel e) async {
    await _eventRepo.insert(e);
    await _refreshEvents(e.animalId);
  }

  Future<void> updateEvent(AnimalEventModel e) async {
    await _eventRepo.update(e);
    await _refreshEvents(e.animalId);
  }

  Future<void> deleteEvent(int id) async {
    if (selectedAnimal.value == null) return;
    await _eventRepo.delete(id);
    await _refreshEvents(selectedAnimal.value!.id!);
  }

  // ── Calves ────────────────────────────────────────────────────────────────

  Future<void> addCalf(AnimalModel calf) async {
    await _repo.insert(calf);
    await loadAnimals();
    if (selectedAnimal.value?.id == calf.motherId) {
      await _refreshChildren(calf.motherId!);
    }
  }

  Future<void> updateCalf(AnimalModel calf) async {
    await _repo.update(calf);
    await loadAnimals();
    if (selectedAnimal.value?.id == calf.motherId) {
      await _refreshChildren(calf.motherId!);
    }
  }

  // ── Production enrollment ─────────────────────────────────────────────────

  Future<void> addCalfToProduction(AnimalModel calf) async {
    if (calf.id == null) return;
    await _repo.setInProduction(calf.id!, value: true);
    await loadAnimals();
    if (calf.motherId != null) {
      await _refreshChildren(calf.motherId!);
    }
    Get.snackbar(
      'Added to Production',
      '${calf.tagNumber}${calf.name != null ? " (${calf.name})" : ""} '
          'will now appear in the production tab.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  // ── FIX 2: access .value explicitly on RxList so that Obx widgets
  // calling hasAlert() properly subscribe to alertAnimalIds as a reactive
  // dependency. Without .value, GetX may not register the Obx subscription,
  // leaving the "Due" badge stale after marking a vaccination done.
  bool hasAlert(int animalId) => alertAnimalIds.value.contains(animalId);

  void _syncVaccinationController() {
    try {
      Get.find<VaccinationController>().load();
    } catch (_) {
      // Not yet registered — nothing to sync.
    }
  }
}