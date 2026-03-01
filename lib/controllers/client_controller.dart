// lib/controllers/client_controller.dart
import 'package:dairy_farm_app/data/models/client_model.dart';
import 'package:dairy_farm_app/data/models/monthly_bill_model.dart';
import 'package:dairy_farm_app/data/models/sale_model.dart';
import 'package:dairy_farm_app/data/repositories/client_repository.dart';
import 'package:dairy_farm_app/data/repositories/sale_repository.dart';
import 'package:get/get.dart';

class ClientController extends GetxController {
  final _clientRepo = Get.find<ClientRepository>();
  final _saleRepo   = Get.find<SaleRepository>();

  // ── List state ─────────────────────────────────────────────────────────────
  final clients   = <ClientModel>[].obs;
  final isLoading = false.obs;

  // ── Profile / detail state ─────────────────────────────────────────────────
  final selectedClient   = Rx<ClientModel?>(null);
  final monthlyBills     = <MonthlyBillModel>[].obs;
  final selectedBill     = Rx<MonthlyBillModel?>(null);
  final dailyBreakdown   = <SaleModel>[].obs;
  final isProfileLoading = false.obs;
  final isDailyLoading   = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadClients();
  }

  // ── Client CRUD ────────────────────────────────────────────────────────────

  Future<void> loadClients() async {
    isLoading.value = true;
    clients.value   = await _clientRepo.getAll(activeOnly: false);
    isLoading.value = false;
  }

  Future<void> addClient(ClientModel client) async {
    await _clientRepo.insert(client);
    await loadClients();
    Get.snackbar('Success', 'Client added',
        snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> updateClient(ClientModel client) async {
    await _clientRepo.update(client);
    if (selectedClient.value?.id == client.id) {
      selectedClient.value = client;
    }
    await loadClients();
  }

  /// Deactivate = keep the slot, mark inactive.
  /// The physical position (number) is preserved forever.
  Future<void> deactivateClient(int id) async {
    await _clientRepo.deactivate(id);
    _clearSelectionIfMatch(id);
    await loadClients();
  }

  /// Hard delete — permanently removes the client record.
  /// Only intended for accidentally added clients with no sales history.
  Future<void> deleteClient(int id) async {
    await _clientRepo.delete(id);
    _clearSelectionIfMatch(id);
    await loadClients();
    Get.snackbar('Deleted', 'Client permanently removed',
        snackPosition: SnackPosition.BOTTOM);
  }

  void _clearSelectionIfMatch(int id) {
    if (selectedClient.value?.id == id) {
      selectedClient.value = null;
      monthlyBills.clear();
      selectedBill.value = null;
      dailyBreakdown.clear();
    }
  }

  // ── Reordering ─────────────────────────────────────────────────────────────

  Future<void> moveUp(ClientModel client) async {
    final idx = clients.indexWhere((c) => c.id == client.id);
    if (idx <= 0) return;
    final other = clients[idx - 1];
    await _clientRepo.swapSortOrder(
        client.id!, client.sortOrder, other.id!, other.sortOrder);
    await loadClients();
  }

  Future<void> moveDown(ClientModel client) async {
    final idx = clients.indexWhere((c) => c.id == client.id);
    if (idx < 0 || idx >= clients.length - 1) return;
    final other = clients[idx + 1];
    await _clientRepo.swapSortOrder(
        client.id!, client.sortOrder, other.id!, other.sortOrder);
    await loadClients();
  }

  Future<void> moveTo(ClientModel client, int targetPosition) async {
    final currentIdx = clients.indexWhere((c) => c.id == client.id);
    if (currentIdx < 0) return;
    final newIdx = (targetPosition - 1).clamp(0, clients.length - 1);
    if (newIdx == currentIdx) return;
    final ordered = [...clients];
    ordered.removeAt(currentIdx);
    ordered.insert(newIdx, client);
    await _clientRepo.updateSortOrders(ordered.map((c) => c.id!).toList());
    await loadClients();
  }

  // ── Profile selection ──────────────────────────────────────────────────────

  Future<void> selectClient(ClientModel client) async {
    selectedBill.value   = null;
    dailyBreakdown.clear();
    selectedClient.value   = client;
    isProfileLoading.value = true;
    monthlyBills.value =
        await _saleRepo.getMonthlyBillsByClient(client.id!);
    isProfileLoading.value = false;
  }

  // ── Monthly → daily drill-down ─────────────────────────────────────────────

  Future<void> selectMonth(MonthlyBillModel bill) async {
    if (selectedBill.value?.monthKey == bill.monthKey) {
      selectedBill.value = null;
      dailyBreakdown.clear();
      return;
    }
    selectedBill.value   = bill;
    isDailyLoading.value = true;
    dailyBreakdown.value = await _saleRepo.getByClientAndMonth(
        selectedClient.value!.id!, bill.year, bill.month);
    isDailyLoading.value = false;
  }

  // ── Export helper ──────────────────────────────────────────────────────────
  Future<List<SaleModel>> getSalesForExport(
          int clientId, int year, int month) =>
      _saleRepo.getByClientAndMonth(clientId, year, month);
}