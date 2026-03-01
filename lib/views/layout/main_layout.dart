// lib/views/layout/main_layout.dart
import 'package:dairy_farm_app/Expenses/billing/billing_view.dart';
import 'package:dairy_farm_app/Expenses/settings/settings_view.dart';
import 'package:dairy_farm_app/views/cash_sales_billing/cash_sales_billing_view.dart';
import 'package:dairy_farm_app/views/credit/credit_view.dart';
import 'package:dairy_farm_app/views/ledger/ledger_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme/app_theme.dart';
import '../../controllers/navigation_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/production_controller.dart';
import '../../controllers/sales_controller.dart';
import '../../controllers/client_controller.dart';
import '../../controllers/ledger_controller.dart';
import '../dashboard/dashboard_view.dart';
import '../clients/clients_view.dart';
import '../sales/sales_view.dart';
import '../production/production_view.dart';
import '../animals/animals_view.dart';
import '../vaccination/vaccination_view.dart';
import '../expenses/expenses_view.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final navCtrl      = Get.find<NavigationController>();
    final settingsCtrl = Get.find<SettingsController>();

    return Scaffold(
      body: Row(
        children: [
          SidebarWidget(navCtrl: navCtrl, settingsCtrl: settingsCtrl),
          Container(width: 1, color: Colors.black12),
          Expanded(
            child: Obx(() => _buildContent(navCtrl.currentTab.value)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(NavTab tab) {
    switch (tab) {
      case NavTab.dashboard:
        return const DashboardView();
      case NavTab.clients:
        return const ClientsView();
      case NavTab.sales:
        return const SalesView();
      case NavTab.production:
        return const ProductionView();
      case NavTab.animals:
        return const AnimalsView();
      case NavTab.vaccination:
        return const VaccinationView();
      case NavTab.expenses:
        return const ExpensesView();
      case NavTab.billing:
        return const BillingView();
      case NavTab.cashSalesBilling:
        return const CashSalesBillingView();
      case NavTab.credit:
        return const CreditView();
      case NavTab.ledger:
        return const LedgerView();
      case NavTab.settings:
        return const SettingsView();
    }
  }
}

class SidebarWidget extends StatelessWidget {
  final NavigationController navCtrl;
  final SettingsController settingsCtrl;

  const SidebarWidget(
      {super.key, required this.navCtrl, required this.settingsCtrl});

  void _onTabTap(NavTab tab) {
    navCtrl.navigateTo(tab);
    _refreshTab(tab);
  }

  void _refreshTab(NavTab tab) {
    switch (tab) {
      case NavTab.dashboard:
        _tryRefresh(() => Get.find<DashboardController>().loadDashboard());
        _tryRefresh(() => Get.find<ProductionController>().refreshToday());
        _tryRefresh(() => Get.find<SalesController>().loadSalesForDate(DateTime.now()));
        break;
      case NavTab.clients:
        _tryRefresh(() => Get.find<ClientController>().loadClients());
        break;
      case NavTab.sales:
        _tryRefresh(() => Get.find<SalesController>().loadSalesForDate(DateTime.now()));
        _tryRefresh(() => Get.find<ClientController>().loadClients());
        break;
      case NavTab.production:
        _tryRefresh(() => Get.find<ProductionController>().loadProductionForDate(DateTime.now()));
        _tryRefresh(() => Get.find<ProductionController>().refreshToday());
        break;
      case NavTab.ledger:
        _tryRefresh(() => Get.find<LedgerController>()
            .loadMonth(Get.find<LedgerController>().selectedMonth.value));
        break;
      case NavTab.animals:
      case NavTab.vaccination:
      case NavTab.expenses:
      case NavTab.billing:
      case NavTab.cashSalesBilling:
      case NavTab.credit:
      case NavTab.settings:
        break;
    }
  }

  void _tryRefresh(VoidCallback fn) {
    try {
      fn();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppTheme.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.agriculture,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Obx(() => Expanded(
                        child: Text(
                          settingsCtrl.farmName.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                ]),
                const SizedBox(height: 6),
                const Text('Management System',
                    style: TextStyle(
                        color: AppTheme.sidebarText, fontSize: 11)),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),

          // Nav items
          Expanded(
            child: Obx(() {
              final current = navCtrl.currentTab.value;
              return ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                children: [
                  _sidebarSection('OVERVIEW'),
                  _navItem(Icons.dashboard_outlined, 'Dashboard',
                      NavTab.dashboard, current),
                  const SizedBox(height: 8),
                  _sidebarSection('OPERATIONS'),
                  _navItem(Icons.people_outline, 'Clients',
                      NavTab.clients, current),
                  _navItem(Icons.shopping_cart_outlined, 'Sales',
                      NavTab.sales, current),
                  _navItem(Icons.opacity_outlined, 'Production',
                      NavTab.production, current),
                  const SizedBox(height: 8),
                  _sidebarSection('LIVESTOCK'),
                  _navItem(Icons.pets_outlined, 'Animals',
                      NavTab.animals, current),
                  _navItem(Icons.vaccines_outlined, 'Vaccination',
                      NavTab.vaccination, current),
                  const SizedBox(height: 8),
                  _sidebarSection('FINANCE'),
                  _navItem(Icons.account_balance_wallet_outlined,
                      'Expenses', NavTab.expenses, current),
                  _navItem(Icons.receipt_long_outlined, 'Billing',
                      NavTab.billing, current),
                  _navItem(Icons.point_of_sale_outlined, 'Cash Sales',
                      NavTab.cashSalesBilling, current),
                  _navItem(Icons.credit_card_outlined,
                      'Credit / Misc', NavTab.credit, current),
                  _navItem(Icons.bar_chart_outlined, 'Monthly Ledger',
                      NavTab.ledger, current),
                  const SizedBox(height: 8),
                  _sidebarSection('SYSTEM'),
                  _navItem(Icons.settings_outlined, 'Settings',
                      NavTab.settings, current),
                ],
              );
            }),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            child: const Text('v1.0.0 • Offline Mode',
                style:
                    TextStyle(color: Colors.white30, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _sidebarSection(String label) => Padding(
        padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
        child: Text(label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            )),
      );

  Widget _navItem(
      IconData icon, String label, NavTab tab, NavTab current) {
    final isActive = tab == current;
    return GestureDetector(
      onTap: () => _onTabTap(tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.sidebarActive : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(icon,
              size: 18,
              color:
                  isActive ? Colors.white : AppTheme.sidebarText),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                color: isActive ? Colors.white : AppTheme.sidebarText,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              )),
          if (isActive) ...[
            const Spacer(),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ]),
      ),
    );
  }
}