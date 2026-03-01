// lib/views/expenses/expenses_view.dart
import 'package:dairy_farm_app/app/theme/app_theme.dart';
import 'package:dairy_farm_app/controllers/expense_controller.dart';
import 'package:dairy_farm_app/data/models/expense_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ExpensesView extends StatelessWidget {
  const ExpensesView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ExpenseController>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Expenses',
                    style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold)),
                Obx(() => Text(
                      ctrl.monthLabel,
                      style: const TextStyle(
                          color: Colors.black45, fontSize: 14),
                    )),
              ]),
              const Spacer(),
              // ── Month navigation ────────────────────────────────────────
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
                    tooltip: 'Previous month',
                  ),
                  Obx(() => Text(ctrl.monthLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14))),
                  IconButton(
                    icon: const Icon(Icons.chevron_right,
                        color: Colors.black54),
                    onPressed: ctrl.nextMonth,
                    tooltip: 'Next month',
                  ),
                ]),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showAddDialog(context, ctrl),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Expense',
                    style: TextStyle(fontSize: 15)),
              ),
            ]),
            const SizedBox(height: 16),

            // ── Body ──────────────────────────────────────────────────────
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── LEFT: category summary card ─────────────────────────
                  SizedBox(
                    width: 260,
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.pie_chart_outline,
                                size: 16, color: AppTheme.danger),
                            const SizedBox(width: 8),
                            const Text('By Category',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ]),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: Obx(() {
                            if (ctrl.isLoading.value) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            final cats = ctrl.categoryTotals;
                            if (cats.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                        Icons.receipt_long_outlined,
                                        size: 40,
                                        color: Colors.black12),
                                    const SizedBox(height: 8),
                                    Text(
                                        'No expenses in ${ctrl.monthLabel}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: Colors.black38,
                                            fontSize: 13)),
                                  ],
                                ),
                              );
                            }
                            return ListView(
                              padding: EdgeInsets.zero,
                              children: [
                                ...cats.entries.map((e) =>
                                    _CategoryTile(
                                        category: e.key,
                                        amount: e.value,
                                        total: ctrl.monthTotal)),
                                const Divider(height: 1),
                                _totalRow(ctrl),
                              ],
                            );
                          }),
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // ── RIGHT: daily expense list ───────────────────────────
                  Expanded(
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.list_alt_outlined,
                                size: 16, color: AppTheme.danger),
                            const SizedBox(width: 8),
                            const Text('Daily Expenses',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            const Spacer(),
                            Obx(() => Text(
                                  '${ctrl.monthlyExpenses.length} entries',
                                  style: const TextStyle(
                                      color: Colors.black45,
                                      fontSize: 13),
                                )),
                          ]),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: Obx(() {
                            if (ctrl.isLoading.value) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            final grouped = ctrl.groupedByDate;
                            if (grouped.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                        Icons.receipt_long_outlined,
                                        size: 56,
                                        color: Colors.black12),
                                    const SizedBox(height: 12),
                                    const Text('No expenses this month',
                                        style: TextStyle(
                                            color: Colors.black38,
                                            fontSize: 15)),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _showAddDialog(context, ctrl),
                                      icon: const Icon(Icons.add,
                                          size: 16),
                                      label: const Text('Add Expense'),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: grouped.length,
                              itemBuilder: (ctx, i) {
                                final date =
                                    grouped.keys.elementAt(i);
                                final entries = grouped[date]!;
                                return _DayGroup(
                                  date: date,
                                  entries: entries,
                                  onDelete: ctrl.delete,
                                );
                              },
                            );
                          }),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(ExpenseController ctrl) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFFFF3E0),
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12)),
        ),
        child: Row(children: [
          const Text('TOTAL',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const Spacer(),
          Obx(() => Text(
                'Rs. ${ctrl.monthTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.danger),
              )),
        ]),
      );

  // ── Add expense dialog ──────────────────────────────────────────────────
  void _showAddDialog(BuildContext context, ExpenseController ctrl) {
    final selectedCategory = ctrl.categories.first.obs;
    final descCtrl         = TextEditingController();
    final amountCtrl       = TextEditingController();
    final selectedDate     = DateTime.now().obs;

    // Pre-select to the currently viewed month if it's in the past
    final viewMonth = ctrl.selectedMonth.value;
    final now       = DateTime.now();
    if (viewMonth.year == now.year && viewMonth.month == now.month) {
      selectedDate.value = now;
    } else {
      // default to last day of viewed month
      selectedDate.value =
          DateTime(viewMonth.year, viewMonth.month + 1, 0);
    }

    Get.dialog(AlertDialog(
      title: const Row(children: [
        Icon(Icons.add_card, color: AppTheme.danger, size: 22),
        SizedBox(width: 10),
        Text('Add Expense', style: TextStyle(fontSize: 17)),
      ]),
      content: SizedBox(
        width: 400,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Date picker row
          Obx(() => GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate.value,
                    firstDate: DateTime(viewMonth.year, viewMonth.month, 1),
                    lastDate: DateTime(
                        viewMonth.year, viewMonth.month + 1, 0),
                  );
                  if (picked != null) selectedDate.value = picked;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: AppTheme.primary),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('dd MMM yyyy')
                          .format(selectedDate.value),
                      style: const TextStyle(fontSize: 15),
                    ),
                    const Spacer(),
                    const Icon(Icons.edit_calendar_outlined,
                        size: 16, color: Colors.black38),
                  ]),
                ),
              )),
          const SizedBox(height: 14),
          Obx(() => DropdownButtonFormField<String>(
                value: selectedCategory.value,
                decoration: const InputDecoration(
                    labelText: 'Category *',
                    labelStyle: TextStyle(fontSize: 15)),
                items: ctrl.categories
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    selectedCategory.value = v ?? ctrl.categories.first,
              )),
          const SizedBox(height: 12),
          TextField(
            controller: descCtrl,
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              labelText: 'Description',
              labelStyle: TextStyle(fontSize: 15),
              prefixIcon: Icon(Icons.notes_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountCtrl,
            style: const TextStyle(fontSize: 15),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Amount (Rs.) *',
              labelStyle: TextStyle(fontSize: 15),
              prefixText: 'Rs. ',
              prefixIcon:
                  Icon(Icons.currency_rupee_outlined, size: 20),
            ),
            keyboardType: TextInputType.number,
          ),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back(),
            child:
                const Text('Cancel', style: TextStyle(fontSize: 15))),
        ElevatedButton(
          onPressed: () {
            if (amountCtrl.text.isEmpty) return;
            ctrl.add(ExpenseModel(
              expenseDate: selectedDate.value
                  .toIso8601String()
                  .substring(0, 10),
              category: selectedCategory.value,
              description: descCtrl.text.trim().isEmpty
                  ? null
                  : descCtrl.text.trim(),
              amount: double.tryParse(amountCtrl.text) ?? 0,
              createdAt: DateTime.now().toIso8601String(),
            ));
            Get.back();
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger),
          child: const Text('Add Expense',
              style: TextStyle(fontSize: 15, color: Colors.white)),
        ),
      ],
    ));
  }
}

// ── Category summary tile ─────────────────────────────────────────────────────
class _CategoryTile extends StatelessWidget {
  final String category;
  final double amount;
  final double total;
  const _CategoryTile(
      {required this.category,
      required this.amount,
      required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? amount / total : 0.0;
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(category,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600))),
          Text('Rs. ${amount.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.danger)),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: Colors.black38,
                valueColor:
                    const AlwaysStoppedAnimation(AppTheme.danger),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${(pct * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                  color: Colors.black45, fontSize: 11)),
        ]),
      ]),
    );
  }
}

// ── Day group ─────────────────────────────────────────────────────────────────
class _DayGroup extends StatelessWidget {
  final String date;
  final List<ExpenseModel> entries;
  final Future<void> Function(int) onDelete;

  const _DayGroup({
    required this.date,
    required this.entries,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dt        = DateTime.tryParse(date);
    final formatted = dt != null
        ? DateFormat('EEEE, dd MMM yyyy').format(dt)
        : date;
    final dayTotal  = entries.fold(0.0, (s, e) => s + e.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFFFAFAFA),
          child: Row(children: [
            const Icon(Icons.calendar_today,
                size: 13, color: Colors.black38),
            const SizedBox(width: 6),
            Text(formatted,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black54)),
            const Spacer(),
            Text('Rs. ${dayTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.danger)),
          ]),
        ),
        // Expense rows
        ...entries.map((e) => _ExpenseRow(
              expense: e,
              onDelete: () => onDelete(e.id!),
            )),
        const Divider(height: 1),
      ],
    );
  }
}

// ── Single expense row ────────────────────────────────────────────────────────
class _ExpenseRow extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback onDelete;

  const _ExpenseRow({required this.expense, required this.onDelete});

  static const _catIcons = <String, IconData>{
    'Feed': Icons.grass_outlined,
    'Medicine': Icons.medical_services_outlined,
    'Labor': Icons.person_outline,
    'Maintenance': Icons.build_outlined,
    'Electricity': Icons.bolt_outlined,
    'Fuel': Icons.local_gas_station_outlined,
    'Veterinary': Icons.vaccines_outlined,
    'Other': Icons.category_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _catIcons[expense.category] ?? Icons.category_outlined;
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Colors.orange.shade700),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(expense.category,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              if (expense.description != null)
                Text(expense.description!,
                    style: const TextStyle(
                        color: Colors.black45, fontSize: 12)),
            ],
          ),
        ),
        Text('Rs. ${expense.amount.toStringAsFixed(0)}',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.danger)),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.delete_outline,
              size: 18, color: Colors.black26),
          onPressed: onDelete,
          tooltip: 'Delete',
          padding: EdgeInsets.zero,
          constraints:
              const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ]),
    );
  }
}