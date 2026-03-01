// lib/app/bindings/initial_binding.dart
import 'package:dairy_farm_app/controllers/cash_sales_billing_controller.dart';
import 'package:dairy_farm_app/controllers/credit_controller.dart';
import 'package:dairy_farm_app/controllers/ledger_controller.dart';
import 'package:dairy_farm_app/data/repositories/animal_event_repository.dart';
import 'package:dairy_farm_app/data/repositories/cash_sale_repository.dart';
import 'package:dairy_farm_app/data/repositories/credit_repository.dart';
import 'package:dairy_farm_app/data/repositories/payment_repository.dart';
import 'package:get/get.dart';

// Repositories
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/sale_repository.dart';
import '../../data/repositories/animal_repository.dart';
import '../../data/repositories/production_repository.dart';
import '../../data/repositories/vaccination_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/settings_repository.dart';

// Controllers
import '../../controllers/navigation_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/client_controller.dart';
import '../../controllers/sales_controller.dart';
import '../../controllers/production_controller.dart';
import '../../controllers/animal_controller.dart';
import '../../controllers/vaccination_controller.dart';
import '../../controllers/expense_controller.dart';
import '../../controllers/billing_controller.dart';
import '../../controllers/settings_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // ── Repositories ────────────────────────────────────────────────────────
    Get.lazyPut<ClientRepository>(() => ClientRepository(), fenix: true);
    Get.lazyPut<CashSaleRepository>(() => CashSaleRepository(), fenix: true);
    Get.lazyPut<SaleRepository>(() => SaleRepository(), fenix: true);
    Get.lazyPut<AnimalRepository>(() => AnimalRepository(), fenix: true);
    Get.lazyPut<ProductionRepository>(() => ProductionRepository(), fenix: true);
    Get.lazyPut<VaccinationRepository>(() => VaccinationRepository(), fenix: true);
    Get.lazyPut<AnimalEventRepository>(() => AnimalEventRepository(), fenix: true);
    Get.lazyPut<ExpenseRepository>(() => ExpenseRepository(), fenix: true);
    Get.lazyPut<SettingsRepository>(() => SettingsRepository(), fenix: true);
    Get.lazyPut<PaymentRepository>(() => PaymentRepository(), fenix: true);
    Get.lazyPut<CreditRepository>(() => CreditRepository(), fenix: true);

    // ── Controllers ─────────────────────────────────────────────────────────
    Get.lazyPut<NavigationController>(() => NavigationController(), fenix: true);
    Get.lazyPut<SettingsController>(() => SettingsController(), fenix: true);
    Get.lazyPut<DashboardController>(() => DashboardController(), fenix: true);
    Get.lazyPut<ClientController>(() => ClientController(), fenix: true);
    Get.lazyPut<SalesController>(() => SalesController(), fenix: true);
    Get.lazyPut<ProductionController>(() => ProductionController(), fenix: true);
    Get.lazyPut<AnimalController>(() => AnimalController(), fenix: true);
    Get.lazyPut<VaccinationController>(() => VaccinationController(), fenix: true);
    Get.lazyPut<ExpenseController>(() => ExpenseController(), fenix: true);
    Get.lazyPut<BillingController>(() => BillingController(), fenix: true);
    Get.lazyPut<CashSalesBillingController>(
        () => CashSalesBillingController(), fenix: true);
    Get.lazyPut<CreditController>(() => CreditController(), fenix: true);
    Get.lazyPut<LedgerController>(() => LedgerController(), fenix: true);
  }
}

