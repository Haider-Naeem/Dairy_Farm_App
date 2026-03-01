// lib/controllers/navigation_controller.dart
import 'package:get/get.dart';

enum NavTab {
  dashboard,
  clients,
  sales,
  production,
  animals,
  vaccination,
  expenses,
  billing,
  cashSalesBilling,
  credit,
  ledger,
  settings,
}

class NavigationController extends GetxController {
  final currentTab = NavTab.dashboard.obs;

  void navigateTo(NavTab tab) {
    currentTab.value = tab;
  }
}