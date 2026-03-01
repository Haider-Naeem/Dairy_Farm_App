// lib/views/ledger/ledger_view.dart
import 'package:dairy_farm_app/app/theme/app_theme.dart';
import 'package:dairy_farm_app/app/utils/excel_exporter.dart';
import 'package:dairy_farm_app/app/utils/format_utils.dart';
import 'package:dairy_farm_app/controllers/ledger_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class LedgerView extends StatelessWidget {
  const LedgerView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<LedgerController>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Row(
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Monthly Ledger',
                      style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold)),
                  Obx(() => Text(
                        'Financial summary for ${ctrl.monthLabel}',
                        style: const TextStyle(
                            color: Colors.black45, fontSize: 14),
                      )),
                ]),
                const Spacer(),
                // Month nav
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left,
                          color: Colors.black54),
                      onPressed: ctrl.previousMonth,
                    ),
                    Obx(() => Text(ctrl.monthLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14))),
                    IconButton(
                      icon: const Icon(Icons.chevron_right,
                          color: Colors.black54),
                      onPressed: ctrl.nextMonth,
                    ),
                  ]),
                ),
                const SizedBox(width: 12),
                Obx(() {
                  final s = ctrl.summary.value;
                  return ElevatedButton.icon(
                    onPressed: s == null
                        ? null
                        : () => ExcelExporter.exportMonthlyLedger(
                            s, ctrl.monthLabel),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Export Month'),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10)),
                  );
                }),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showRangeExportDialog(context, ctrl),
                  icon: const Icon(Icons.date_range, size: 16),
                  label: const Text('Export Range'),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Content ───────────────────────────────────────────────────
            Expanded(
              child: Obx(() {
                if (ctrl.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final s = ctrl.summary.value;
                if (s == null) {
                  return const Center(child: Text('No data'));
                }
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IntrinsicHeight(
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                  child: _SectionCard(
                                title: 'Income',
                                icon: Icons.trending_up,
                                iconColor: Colors.green,
                                bg: Colors.green.shade50,
                                children: [
                                  _StatRow(
                                    label: 'Client Billing',
                                    value:
                                        'Rs. ${s.totalClientBilling.toStringAsFixed(0)}',
                                    valueColor: Colors.green.shade700,
                                    icon: Icons.people_outline,
                                  ),
                                  _StatRow(
                                    label: 'Cash Sales',
                                    value:
                                        'Rs. ${s.totalCashSales.toStringAsFixed(0)}',
                                    valueColor: Colors.green.shade700,
                                    icon: Icons.point_of_sale_outlined,
                                  ),
                                  if (s.totalCreditPayments > 0)
                                    _StatRow(
                                      label: 'Credit Payments Received',
                                      value:
                                          'Rs. ${s.totalCreditPayments.toStringAsFixed(0)}',
                                      valueColor: Colors.teal.shade700,
                                      icon: Icons.payments_outlined,
                                    ),
                                  const Divider(height: 20),
                                  _StatRow(
                                    label: 'Total Revenue',
                                    value:
                                        'Rs. ${s.grossRevenue.toStringAsFixed(0)}',
                                    valueColor: Colors.green.shade800,
                                    icon: Icons.attach_money,
                                    bold: true,
                                  ),
                                ],
                              )),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: _SectionCard(
                                title: 'Expenses',
                                icon: Icons.trending_down,
                                iconColor: AppTheme.danger,
                                bg: Colors.red.shade50,
                                children: [
                                  _StatRow(
                                    label: 'Total Expenses',
                                    value:
                                        'Rs. ${s.totalExpenses.toStringAsFixed(0)}',
                                    valueColor: AppTheme.danger,
                                    icon: Icons.receipt_outlined,
                                    bold: true,
                                  ),
                                  const SizedBox(height: 12),
                                  _NetProfitBox(netProfit: s.netProfit),
                                ],
                              )),
                            ]),
                      ),
                      const SizedBox(height: 16),
                      IntrinsicHeight(
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                  child: _SectionCard(
                                title: 'Milk Produced & Sold',
                                icon: Icons.opacity,
                                iconColor: AppTheme.primary,
                                bg: const Color(0xFFE8F5E9),
                                children: [
                                  _StatRow(
                                    label: 'Total Produced',
                                    value:
                                        '${formatL(s.totalMilkProduced)} L',
                                    valueColor: AppTheme.primary,
                                    icon: Icons.opacity,
                                    bold: true,
                                  ),
                                  _StatRow(
                                    label: 'Sold to Clients',
                                    value:
                                        '${formatL(s.totalMilkSoldClients)} L',
                                    valueColor: Colors.black87,
                                    icon: Icons.people_outline,
                                  ),
                                  _StatRow(
                                    label: 'Cash Sales',
                                    value:
                                        '${formatL(s.totalMilkCash)} L',
                                    valueColor: Colors.black87,
                                    icon: Icons.point_of_sale_outlined,
                                  ),
                                  if (s.totalMilkCredit > 0)
                                    _StatRow(
                                      label: 'Given on Credit',
                                      value:
                                          '${formatL(s.totalMilkCredit)} L',
                                      valueColor: Colors.orange.shade700,
                                      icon: Icons.credit_card_outlined,
                                    ),
                                  _StatRow(
                                    label: 'Given Free',
                                    value:
                                        '${formatL(s.freeMilkGiven)} L',
                                    valueColor: Colors.orange.shade700,
                                    icon: Icons.card_giftcard,
                                  ),
                                ],
                              )),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: _SectionCard(
                                title: 'Clients',
                                icon: Icons.people,
                                iconColor: AppTheme.primary,
                                bg: const Color(0xFFE8F5E9),
                                children: [
                                  _StatRow(
                                    label: 'Active Paying',
                                    value:
                                        '${s.activePayingClients} clients',
                                    valueColor: Colors.black87,
                                    icon: Icons.person_outline,
                                  ),
                                  _StatRow(
                                    label: 'Active Free',
                                    value:
                                        '${s.activeFreeClients} clients',
                                    valueColor: Colors.orange.shade700,
                                    icon: Icons.card_giftcard,
                                  ),
                                  _StatRow(
                                    label: 'Total Active',
                                    value:
                                        '${s.activePayingClients + s.activeFreeClients} clients',
                                    valueColor: AppTheme.primary,
                                    icon: Icons.people,
                                    bold: true,
                                  ),
                                ],
                              )),
                            ]),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRangeExportDialog(
      BuildContext context, LedgerController ctrl) async {
    final now = DateTime.now();
    DateTime fromDate = DateTime(now.year, now.month - 2, 1);
    DateTime toDate   = DateTime(now.year, now.month, 1);

    final fmt = DateFormat('MMM yyyy');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.date_range, color: AppTheme.primary),
            SizedBox(width: 10),
            Text('Export Date Range'),
          ]),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select a month range to aggregate and export a combined ledger report.',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: _MonthPickerTile(
                      label: 'From',
                      value: fmt.format(fromDate),
                      onTap: () async {
                        final picked = await _pickMonth(ctx, fromDate);
                        if (picked != null) {
                          setDialogState(() => fromDate = picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.arrow_forward,
                      color: Colors.black38, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MonthPickerTile(
                      label: 'To',
                      value: fmt.format(toDate),
                      onTap: () async {
                        final picked = await _pickMonth(ctx, toDate);
                        if (picked != null) {
                          setDialogState(() => toDate = picked);
                        }
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                if (fromDate.isAfter(toDate))
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: const Row(children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 14, color: Colors.red),
                      SizedBox(width: 6),
                      Text('"From" must be before "To"',
                          style: TextStyle(color: Colors.red, fontSize: 12)),
                    ]),
                  ),
                const SizedBox(height: 8),
                if (!fromDate.isAfter(toDate))
                  Builder(builder: (_) {
                    int months = (toDate.year - fromDate.year) * 12 +
                        (toDate.month - fromDate.month) + 1;
                    return Text(
                      'Will aggregate $months month${months == 1 ? "" : "s"} of data',
                      style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    );
                  }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            Obx(() => ElevatedButton.icon(
                  onPressed: fromDate.isAfter(toDate) ||
                          ctrl.isRangeLoading.value
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          final s =
                              await ctrl.loadRangeSummary(fromDate, toDate);
                          if (s != null) {
                            final label =
                                '${fmt.format(fromDate)} – ${fmt.format(toDate)}';
                            await ExcelExporter.exportMonthlyLedger(
                                s, label);
                          }
                        },
                  icon: ctrl.isRangeLoading.value
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.download, size: 16),
                  label: Text(ctrl.isRangeLoading.value
                      ? 'Building...'
                      : 'Export'),
                )),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _pickMonth(
      BuildContext context, DateTime initial) async {
    int selectedYear  = initial.year;
    int selectedMonth = initial.month;
    final now = DateTime.now();

    final result = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Select Month'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setState(() => selectedYear--),
                    ),
                    Text('$selectedYear',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: selectedYear >= now.year
                          ? null
                          : () => setState(() => selectedYear++),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.6,
                  children: List.generate(12, (i) {
                    final m     = i + 1;
                    final label = DateFormat('MMM')
                        .format(DateTime(selectedYear, m));
                    final isFuture = DateTime(selectedYear, m)
                        .isAfter(DateTime(now.year, now.month));
                    final isSelected = m == selectedMonth;

                    return GestureDetector(
                      onTap: isFuture
                          ? null
                          : () => setState(() => selectedMonth = m),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary
                              : isFuture
                                  ? Colors.grey.shade100
                                  : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : isFuture
                                    ? Colors.grey.shade400
                                    : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                  ctx, DateTime(selectedYear, selectedMonth, 1)),
              child: const Text('Select'),
            ),
          ],
        ),
      ),
    );
    return result;
  }
}

// ── Net Profit Box ────────────────────────────────────────────────────────────
class _NetProfitBox extends StatelessWidget {
  final double netProfit;
  const _NetProfitBox({required this.netProfit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: netProfit >= 0 ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: netProfit >= 0
                ? Colors.green.shade200
                : Colors.red.shade200),
      ),
      child: Column(children: [
        Text(
          netProfit >= 0 ? 'NET PROFIT' : 'NET LOSS',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: netProfit >= 0
                  ? Colors.green.shade700
                  : Colors.red.shade700,
              letterSpacing: 1),
        ),
        const SizedBox(height: 4),
        Text(
          'Rs. ${netProfit.abs().toStringAsFixed(0)}',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: netProfit >= 0
                  ? Colors.green.shade800
                  : Colors.red.shade800),
        ),
      ]),
    );
  }
}

// ── Month Picker Tile ─────────────────────────────────────────────────────────
class _MonthPickerTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _MonthPickerTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Row(children: [
              Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              const Icon(Icons.expand_more, size: 16, color: Colors.black45),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color bg;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.bg,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12)),
            ),
            child: Row(children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Row ──────────────────────────────────────────────────────────────────
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;
  final bool bold;

  const _StatRow({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(icon, size: 15, color: Colors.black38),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight:
                        bold ? FontWeight.bold : FontWeight.normal))),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                color: valueColor)),
      ]),
    );
  }
}