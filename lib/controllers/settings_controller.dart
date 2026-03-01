// ============================================================
// lib/controllers/settings_controller.dart
// ============================================================
import 'package:dairy_farm_app/data/models/settings_model.dart';
import 'package:dairy_farm_app/data/repositories/settings_repository.dart';
import 'package:get/get.dart';


class SettingsController extends GetxController {
  final _repo = Get.find<SettingsRepository>();

  final farmName = 'My Dairy Farm'.obs;
  final ratePerLiter = 100.0.obs;
  final ownerName = ''.obs;
  final phone = ''.obs;
  final address = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final s = await _repo.get();
    if (s != null) {
      farmName.value = s.farmName;
      ratePerLiter.value = s.ratePerLiter;
      ownerName.value = s.ownerName ?? '';
      phone.value = s.phone ?? '';
      address.value = s.address ?? '';
    }
  }

  Future<void> saveSettings({
    required String name,
    required double rate,
    String? owner,
    String? ph,
    String? addr,
  }) async {
    await _repo.upsert(SettingsModel(
      farmName: name,
      ratePerLiter: rate,
      ownerName: owner,
      phone: ph,
      address: addr,
      updatedAt: DateTime.now().toIso8601String(),
    ));
    farmName.value = name;
    ratePerLiter.value = rate;
    ownerName.value = owner ?? '';
    phone.value = ph ?? '';
    address.value = addr ?? '';
    Get.snackbar('Saved', 'Settings saved successfully',
        snackPosition: SnackPosition.BOTTOM);
  }
}
