// lib/views/dashboard/dashboard_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme/app_theme.dart';
import '../../app/utils/format_utils.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/production_controller.dart';
import '../../controllers/settings_controller.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<DashboardController>().loadDashboard();
      Get.find<ProductionController>().refreshToday();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl     = Get.find<DashboardController>();
    final settings = Get.find<SettingsController>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: () async {
            await ctrl.loadDashboard();
            await Get.find<ProductionController>().refreshToday();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────────
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(() => Text(
                              settings.farmName.value,
                              style: const TextStyle(
                                  fontSize: 26, fontWeight: FontWeight.bold),
                            )),
                        Text(
                          'Dashboard — ${_todayFormatted()}',
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 15),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await ctrl.loadDashboard();
                        await Get.find<ProductionController>().refreshToday();
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── KPI Cards ─────────────────────────────────────────────
                LayoutBuilder(builder: (context, constraints) {
                  if (constraints.maxWidth < 900) {
                    return Column(children: [
                      Row(children: [
                        _kpiCard('Daily Production',
                            '${formatL(ctrl.dailyProduction.value)} L',
                            Icons.opacity, AppTheme.primary,
                            subtitle: 'Today\'s total milk'),
                        const SizedBox(width: 12),
                        _kpiCard('Carry-Over',
                            '${formatL(ctrl.previousRemaining.value)} L',
                            Icons.replay, Colors.deepOrange,
                            subtitle: 'From yesterday'),
                        const SizedBox(width: 12),
                        _kpiCard('Total Available',
                            '${formatL(ctrl.totalAvailable.value)} L',
                            Icons.water_drop, Colors.indigo,
                            subtitle: 'Production + carry-over'),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        _kpiCard('Client Sales',
                            '${formatL(ctrl.dailySales.value)} L',
                            Icons.people_outline, AppTheme.info,
                            subtitle: 'Allocated to clients'),
                        const SizedBox(width: 12),
                        _kpiCard('Cash Sales',
                            '${formatL(ctrl.dailyCashLiters.value)} L',
                            Icons.point_of_sale, Colors.teal,
                            subtitle:
                                'Rs. ${ctrl.dailyCashReceived.value.toStringAsFixed(0)} received'),
                        const SizedBox(width: 12),
                        _kpiCard('Credit Milk',
                            '${formatL(ctrl.dailyCreditLiters.value)} L',
                            Icons.credit_card_outlined, Colors.orange,
                            subtitle: 'Given on credit today'),
                        const SizedBox(width: 12),
                        _kpiCard('Remaining Milk',
                            '${formatL(ctrl.remainingMilk.value)} L',
                            Icons.local_drink,
                            ctrl.remainingMilk.value >= 0
                                ? const Color(0xFF6A1B9A)
                                : AppTheme.danger,
                            subtitle: 'After all sales'),
                        const SizedBox(width: 12),
                        _kpiCard('Active Clients', '${ctrl.totalClients.value}',
                            Icons.people, AppTheme.accent,
                            subtitle: 'Total registered'),
                      ]),
                    ]);
                  }
                  // Wide layout
                  return Row(children: [
                    _kpiCard('Daily Production',
                        '${formatL(ctrl.dailyProduction.value)} L',
                        Icons.opacity, AppTheme.primary,
                        subtitle: 'Today\'s total milk'),
                    const SizedBox(width: 12),
                    _kpiCard('Carry-Over',
                        '${formatL(ctrl.previousRemaining.value)} L',
                        Icons.replay, Colors.deepOrange,
                        subtitle: 'From yesterday'),
                    const SizedBox(width: 12),
                    _kpiCard('Total Available',
                        '${formatL(ctrl.totalAvailable.value)} L',
                        Icons.water_drop, Colors.indigo,
                        subtitle: 'Prod + carry-over'),
                    const SizedBox(width: 12),
                    _kpiCard('Client Sales',
                        '${formatL(ctrl.dailySales.value)} L',
                        Icons.people_outline, AppTheme.info,
                        subtitle: 'To clients'),
                    const SizedBox(width: 12),
                    _kpiCard('Cash Sales',
                        '${formatL(ctrl.dailyCashLiters.value)} L',
                        Icons.point_of_sale, Colors.teal,
                        subtitle:
                            'Rs. ${ctrl.dailyCashReceived.value.toStringAsFixed(0)}'),
                    const SizedBox(width: 12),
                    _kpiCard('Credit Milk',
                        '${formatL(ctrl.dailyCreditLiters.value)} L',
                        Icons.credit_card_outlined, Colors.orange,
                        subtitle: 'Given on credit'),
                    const SizedBox(width: 12),
                    _kpiCard('Remaining',
                        '${formatL(ctrl.remainingMilk.value)} L',
                        Icons.local_drink,
                        ctrl.remainingMilk.value >= 0
                            ? const Color(0xFF6A1B9A)
                            : AppTheme.danger,
                        subtitle: 'After all sales'),
                    const SizedBox(width: 12),
                    _kpiCard('Clients', '${ctrl.totalClients.value}',
                        Icons.people, AppTheme.accent,
                        subtitle: 'Registered'),
                  ]);
                }),
                const SizedBox(height: 20),

                // ── Sales summary ─────────────────────────────────────────
                _buildSalesSummaryCard(ctrl),
                const SizedBox(height: 20),

                // ── Animal production ─────────────────────────────────────
                _animalProductionSummary(),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── Sales breakdown card ─────────────────────────────────────────────────
  Widget _buildSalesSummaryCard(DashboardController ctrl) {
    return Obx(() {
      final produced  = ctrl.dailyProduction.value;
      final carryOver = ctrl.previousRemaining.value;
      final available = ctrl.totalAvailable.value;
      final clientL   = ctrl.dailySales.value;
      final cashL     = ctrl.dailyCashLiters.value;
      final creditL   = ctrl.dailyCreditLiters.value;
      final totalSold = clientL + cashL + creditL;
      final remaining = ctrl.remainingMilk.value;
      final cashRs    = ctrl.dailyCashReceived.value;

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Today's Milk Summary",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              const SizedBox(height: 16),

              // Carry-over banner
              if (carryOver > 0) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withOpacity(0.07),
                    border: Border.all(
                        color: Colors.deepOrange.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const Icon(Icons.replay,
                        size: 16, color: Colors.deepOrange),
                    const SizedBox(width: 8),
                    Text(
                      'Carry-over from yesterday: '
                      '${formatL(carryOver)} L  →  '
                      'Total available today: ${formatL(available)} L',
                      style: const TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
              ],

              // Credit banner
              if (creditL > 0) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.07),
                    border: Border.all(
                        color: Colors.orange.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Icon(Icons.credit_card_outlined,
                        size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Text(
                      '${formatL(creditL)} L given on credit today — '
                      'deducted from remaining milk',
                      style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
              ],

              // Summary items row
              LayoutBuilder(builder: (ctx, box) {
                final items = [
                  _summaryItem('Produced', '${formatL(produced)} L',
                      AppTheme.primary, Icons.opacity),
                  if (carryOver > 0)
                    _summaryItem('Carry-Over',
                        '${formatL(carryOver)} L',
                        Colors.deepOrange, Icons.replay),
                  _summaryItem('Available',
                      '${formatL(available)} L',
                      Colors.indigo, Icons.water_drop),
                  _summaryItem('Client Sales',
                      '${formatL(clientL)} L',
                      AppTheme.info, Icons.people_outline),
                  _summaryItem('Cash Sales',
                      '${formatL(cashL)} L',
                      Colors.teal, Icons.point_of_sale),
                  if (creditL > 0)
                    _summaryItem('Credit Milk',
                        '${formatL(creditL)} L',
                        Colors.orange, Icons.credit_card_outlined),
                  _summaryItem('Cash Received',
                      'Rs. ${cashRs.toStringAsFixed(0)}',
                      Colors.green, Icons.payments_outlined),
                  _summaryItem('Total Sold',
                      '${formatL(totalSold)} L',
                      Colors.orange, Icons.shopping_cart_outlined),
                  _summaryItem(
                      'Remaining',
                      '${formatL(remaining)} L',
                      remaining >= 0
                          ? const Color(0xFF6A1B9A)
                          : AppTheme.danger,
                      Icons.local_drink_outlined),
                ];

                return Wrap(
                  spacing: 0,
                  runSpacing: 12,
                  children: [
                    for (int i = 0; i < items.length; i++) ...[
                      SizedBox(
                        width: (box.maxWidth / items.length)
                            .clamp(110.0, 170.0),
                        child: items[i],
                      ),
                      if (i < items.length - 1)
                        Container(
                            height: 36,
                            width: 1,
                            color: Colors.black12,
                            margin: const EdgeInsets.symmetric(horizontal: 4)),
                    ],
                  ],
                );
              }),

              if (produced > 0) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 12,
                    child: Row(children: [
                      if (carryOver > 0)
                        Flexible(
                          flex: (carryOver * 1000).toInt(),
                          child: Container(
                              color: Colors.deepOrange.withOpacity(0.5)),
                        ),
                      Flexible(
                        flex: (clientL * 1000).toInt(),
                        child: Container(
                            color: AppTheme.info.withOpacity(0.7)),
                      ),
                      Flexible(
                        flex: (cashL * 1000).toInt(),
                        child: Container(color: Colors.teal.withOpacity(0.7)),
                      ),
                      if (creditL > 0)
                        Flexible(
                          flex: (creditL * 1000).toInt(),
                          child: Container(
                              color: Colors.orange.withOpacity(0.7)),
                        ),
                      Flexible(
                        flex: (remaining.clamp(0, double.infinity) * 1000)
                            .toInt(),
                        child: Container(
                            color:
                                const Color(0xFF6A1B9A).withOpacity(0.2)),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(spacing: 16, runSpacing: 4, children: [
                  if (carryOver > 0)
                    _legendDot(Colors.deepOrange.withOpacity(0.7),
                        'Carry-over'),
                  _legendDot(AppTheme.info, 'Client sales'),
                  _legendDot(Colors.teal, 'Cash sales'),
                  if (creditL > 0)
                    _legendDot(Colors.orange, 'Credit milk'),
                  _legendDot(
                      const Color(0xFF6A1B9A).withOpacity(0.4), 'Remaining'),
                ]),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _legendDot(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      );

  Widget _summaryItem(
      String label, String value, Color color, IconData icon) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black45)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    ]);
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color,
      {String? subtitle}) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 14),
              Text(value,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              if (subtitle != null)
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.black45, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _animalProductionSummary() {
    final prodCtrl = Get.find<ProductionController>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text("Today's Animal Production",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 17)),
              const Spacer(),
              Obx(() => Text(
                    'Total: ${formatL(prodCtrl.todayTotal.value)} L',
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  )),
            ]),
            const SizedBox(height: 16),
            Obx(() {
              final prods = prodCtrl.todayProductions;
              if (prods.isEmpty) {
                return const Text('No production data for today',
                    style: TextStyle(color: Colors.black45, fontSize: 14));
              }
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: prods.map((p) {
                  return Container(
                    width: 148,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.cardBorder),
                      borderRadius: BorderRadius.circular(8),
                      color: p.total > 0
                          ? AppTheme.primary.withOpacity(0.05)
                          : Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.animalTag ?? 'Animal',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        Row(children: [
                          const Icon(Icons.wb_sunny,
                              size: 12, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text('M: ${formatL(p.morning)} L',
                              style: const TextStyle(fontSize: 12)),
                        ]),
                        Row(children: [
                          const Icon(Icons.wb_cloudy,
                              size: 12, color: Colors.blueGrey),
                          const SizedBox(width: 4),
                          Text('A: ${formatL(p.afternoon)} L',
                              style: const TextStyle(fontSize: 12)),
                        ]),
                        Row(children: [
                          const Icon(Icons.nightlight,
                              size: 12, color: Colors.indigo),
                          const SizedBox(width: 4),
                          Text('E: ${formatL(p.evening)} L',
                              style: const TextStyle(fontSize: 12)),
                        ]),
                        const Divider(height: 10),
                        Text('${formatL(p.total)} L',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.primary)),
                      ],
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _todayFormatted() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}