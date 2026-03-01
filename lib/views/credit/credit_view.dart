// lib/views/credit/credit_view.dart
import 'package:dairy_farm_app/app/theme/app_theme.dart';
import 'package:dairy_farm_app/app/utils/excel_exporter.dart';
import 'package:dairy_farm_app/app/utils/format_utils.dart';
import 'package:dairy_farm_app/controllers/credit_controller.dart';
import 'package:dairy_farm_app/data/models/credit_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CreditView extends StatelessWidget {
  const CreditView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CreditController>();

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
                const Text('Credit / Miscellaneous',
                    style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold)),
                Obx(() => Text(
                      ctrl.monthLabel,
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
                onPressed: () => _showAddDialog(context, ctrl, 'credit'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Credit',
                    style: TextStyle(fontSize: 15)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showAddDialog(context, ctrl, 'debit'),
                icon: Icon(Icons.payments_outlined,
                    size: 18, color: Colors.green.shade700),
                label: Text('Record Payment',
                    style: TextStyle(
                        fontSize: 15, color: Colors.green.shade700)),
                style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.green.shade400)),
              ),
              const SizedBox(width: 8),
              // ── Export Credit Report ───────────────────────────────────
              OutlinedButton.icon(
                onPressed: () async {
                  final entries = await ctrl.getAllEntries();
                  final balances = ctrl.personBalances;
                  await ExcelExporter.exportCreditReport(
                      entries, balances, ctrl.monthLabel);
                },
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Export Credit',
                    style: TextStyle(fontSize: 15)),
                style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.blue.shade400)),
              ),
            ]),
            const SizedBox(height: 8),
            // ── Info banner ───────────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(children: [
                Icon(Icons.info_outline,
                    size: 15, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Credit = someone took milk & will pay later. '
                    'Liters are deducted from daily production.  '
                    'Payment = they paid their balance (recorded as income in ledger).  '
                    'Liters are NOT added back on payment.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.blue.shade800),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // ── Body ──────────────────────────────────────────────────────
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── LEFT: person balances ───────────────────────────────
                  SizedBox(
                    width: 300,
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 11),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.people_outline,
                                size: 15, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Text('Outstanding Balances',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            const Spacer(),
                            Obx(() {
                              final total = ctrl.totalOutstanding;
                              return Text(
                                  'Rs. ${total.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.red));
                            }),
                          ]),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: Obx(() {
                            if (ctrl.isLoading.value) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            final balances = ctrl.personBalances;
                            if (balances.isEmpty) {
                              return const Center(
                                child: Text('No credit entries yet',
                                    style: TextStyle(
                                        color: Colors.black38,
                                        fontSize: 14)),
                              );
                            }
                            return ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: balances.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (ctx, i) => _PersonTile(
                                balance: balances[i],
                                ctrl: ctrl,
                                onAddCredit: () => _showAddDialog(
                                    context, ctrl, 'credit',
                                    person: balances[i].personName),
                                onAddPayment: () => _showAddDialog(
                                    context, ctrl, 'debit',
                                    person: balances[i].personName,
                                    maxAmount: balances[i].balance),
                              ),
                            );
                          }),
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // ── RIGHT: monthly entries / person detail ──────────────
                  Expanded(
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Obx(() {
                        final person = ctrl.selectedPerson.value;

                        if (person != null) {
                          return _PersonDetail(ctrl: ctrl);
                        }

                        // ── Monthly entries ────────────────────────────────
                        return Column(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 11),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.history,
                                  size: 15, color: Colors.blue),
                              const SizedBox(width: 8),
                              Obx(() => Text(
                                    '${ctrl.monthLabel} Entries',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  )),
                              const Spacer(),
                              Obx(() => Row(children: [
                                    _summaryChip(
                                        'Credit',
                                        'Rs. ${ctrl.monthCreditTotal.toStringAsFixed(0)}',
                                        Colors.red.shade50,
                                        Colors.red),
                                    const SizedBox(width: 6),
                                    _summaryChip(
                                        'Credit Liters',
                                        '${formatL(ctrl.monthCreditLiters)} L',
                                        Colors.orange.shade50,
                                        Colors.orange),
                                    const SizedBox(width: 6),
                                    _summaryChip(
                                        'Paid',
                                        'Rs. ${ctrl.monthDebitTotal.toStringAsFixed(0)}',
                                        Colors.green.shade50,
                                        Colors.green),
                                  ])),
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
                                          Icons.credit_card_outlined,
                                          size: 56,
                                          color: Colors.black12),
                                      const SizedBox(height: 12),
                                      const Text(
                                          'No credit entries this month',
                                          style: TextStyle(
                                              color: Colors.black38,
                                              fontSize: 15)),
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
                                  return _CreditDayGroup(
                                    date: date,
                                    entries: entries,
                                    onDelete: ctrl.deleteEntry,
                                  );
                                },
                              );
                            }),
                          ),
                        ]);
                      }),
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

  Widget _summaryChip(
      String label, String value, Color bg, Color fg) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text('$label: $value',
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  void _showAddDialog(
    BuildContext context,
    CreditController ctrl,
    String type, {
    String? person,
    double? maxAmount,
  }) {
    final nameCtrl   = TextEditingController(text: person ?? '');
    final phoneCtrl  = TextEditingController();
    final amountCtrl = TextEditingController();
    final litersCtrl = TextEditingController();
    final descCtrl   = TextEditingController();
    final selectedDate = DateTime.now().obs;
    final isCredit   = type == 'credit';

    bool updatingFromLiters = false;
    bool updatingFromAmount = false;

    final rate = ctrl.ratePerLiter;

    litersCtrl.addListener(() {
      if (updatingFromAmount) return;
      updatingFromLiters = true;
      final l = double.tryParse(litersCtrl.text);
      if (l != null && rate > 0) {
        final rs = (l * rate).toStringAsFixed(0);
        if (amountCtrl.text != rs) amountCtrl.text = rs;
      }
      updatingFromLiters = false;
    });

    amountCtrl.addListener(() {
      if (updatingFromLiters) return;
      updatingFromAmount = true;
      final rs = double.tryParse(amountCtrl.text);
      if (rs != null && rate > 0) {
        // Use formatL so auto-filled liters don't show extra decimals
        final l = formatL(rs / rate);
        if (litersCtrl.text != l) litersCtrl.text = l;
      }
      updatingFromAmount = false;
    });

    Get.dialog(AlertDialog(
      title: Row(children: [
        Icon(
          isCredit ? Icons.add_shopping_cart : Icons.payments_outlined,
          color: isCredit ? Colors.red : Colors.green,
          size: 22,
        ),
        const SizedBox(width: 10),
        Text(isCredit ? 'Add Credit Entry' : 'Record Payment',
            style: const TextStyle(fontSize: 17)),
      ]),
      content: SizedBox(
        width: 440,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Outstanding balance banner for debit
          if (!isCredit && maxAmount != null && maxAmount > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Outstanding balance: Rs. ${maxAmount.toStringAsFixed(0)}',
                style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600),
              ),
            ),

          // Rate info banner for credit entries
          if (isCredit)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(children: [
                Icon(Icons.info_outline, size: 14, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  'Rate: Rs. ${rate.toStringAsFixed(0)}/L — enter Rs. or Liters, '
                  'the other field auto-fills.',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                ),
              ]),
            ),

          // Date picker
          Obx(() => GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate.value,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
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
                  ]),
                ),
              )),
          const SizedBox(height: 12),

          // Person name
          TextField(
            controller: nameCtrl,
            autofocus: person == null,
            readOnly: person != null,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Person Name *',
              labelStyle: const TextStyle(fontSize: 15),
              prefixIcon: const Icon(Icons.person_outline, size: 20),
              filled: person != null,
              fillColor: person != null ? Colors.grey.shade100 : null,
            ),
          ),
          const SizedBox(height: 12),

          // Phone
          TextField(
            controller: phoneCtrl,
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              labelText: 'Phone (optional)',
              labelStyle: TextStyle(fontSize: 15),
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),

          // Amount (Rs.) — required
          TextField(
            controller: amountCtrl,
            autofocus: person != null && !isCredit,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              labelText: isCredit
                  ? 'Amount (Rs.) *'
                  : 'Payment Amount (Rs.) *',
              labelStyle: const TextStyle(fontSize: 15),
              prefixText: 'Rs. ',
              prefixIcon: const Icon(Icons.currency_rupee_outlined, size: 20),
              helperText: maxAmount != null
                  ? 'Max: Rs. ${maxAmount.toStringAsFixed(0)}'
                  : null,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),

          // Liters — required for credit, auto-calculated but editable
          TextField(
            controller: litersCtrl,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              labelText: isCredit ? 'Liters *' : 'Liters (auto)',
              labelStyle: const TextStyle(fontSize: 15),
              suffixText: 'L',
              prefixIcon: const Icon(Icons.opacity, size: 20),
              helperText: isCredit
                  ? 'Auto-filled from Rs. — deducted from production'
                  : null,
              helperStyle: const TextStyle(color: Colors.orange),
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            readOnly: !isCredit,
          ),
          const SizedBox(height: 12),

          // Note
          TextField(
            controller: descCtrl,
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              labelStyle: TextStyle(fontSize: 15),
              prefixIcon: Icon(Icons.notes_outlined, size: 20),
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(fontSize: 15))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: isCredit ? Colors.red : Colors.green),
          onPressed: () {
            final name   = nameCtrl.text.trim();
            final amount = double.tryParse(amountCtrl.text);
            final liters = double.tryParse(litersCtrl.text) ?? 0.0;

            if (name.isEmpty || amount == null || amount <= 0) return;
            if (isCredit && liters <= 0) {
              Get.snackbar('Validation', 'Liters must be greater than 0',
                  snackPosition: SnackPosition.BOTTOM);
              return;
            }

            ctrl.addEntry(CreditModel(
              personName:  name,
              phone:       phoneCtrl.text.trim().isEmpty
                  ? null
                  : phoneCtrl.text.trim(),
              entryType:   type,
              amount:      amount,
              liters:      liters,
              description: descCtrl.text.trim().isEmpty
                  ? null
                  : descCtrl.text.trim(),
              entryDate:   selectedDate.value
                  .toIso8601String()
                  .substring(0, 10),
              createdAt:   DateTime.now().toIso8601String(),
            ));
            Get.back();
          },
          child: Text(isCredit ? 'Add Credit' : 'Record Payment',
              style: const TextStyle(fontSize: 15, color: Colors.white)),
        ),
      ],
    ));
  }
}

// ── Person balance tile ───────────────────────────────────────────────────────
class _PersonTile extends StatelessWidget {
  final PersonBalance balance;
  final CreditController ctrl;
  final VoidCallback onAddCredit;
  final VoidCallback onAddPayment;

  const _PersonTile({
    required this.balance,
    required this.ctrl,
    required this.onAddCredit,
    required this.onAddPayment,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSelected =
          ctrl.selectedPerson.value == balance.personName;
      return InkWell(
        onTap: () => isSelected
            ? ctrl.clearPersonSelection()
            : ctrl.selectPerson(balance.personName),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: isSelected
              ? Colors.blue.withOpacity(0.07)
              : Colors.transparent,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: balance.balance > 0
                    ? Colors.red.shade50
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  balance.personName.isNotEmpty
                      ? balance.personName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: balance.balance > 0
                          ? Colors.red.shade700
                          : Colors.green.shade700),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(balance.personName,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isSelected
                              ? Colors.blue.shade700
                              : Colors.black87)),
                  Text(
                    balance.balance > 0
                        ? 'Owes Rs. ${balance.balance.toStringAsFixed(0)}  ·  ${formatL(balance.totalLiters)} L total'
                        : 'Settled ✓',
                    style: TextStyle(
                        fontSize: 12,
                        color: balance.balance > 0
                            ? Colors.red.shade600
                            : Colors.green.shade600),
                  ),
                ],
              ),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              InkWell(
                onTap: onAddCredit,
                child: const Icon(Icons.add_circle_outline,
                    size: 18, color: Colors.black38),
              ),
              const SizedBox(height: 2),
              InkWell(
                onTap: balance.balance > 0 ? onAddPayment : null,
                child: Icon(Icons.payments_outlined,
                    size: 18,
                    color: balance.balance > 0
                        ? Colors.green
                        : Colors.black12),
              ),
            ]),
          ]),
        ),
      );
    });
  }
}

// ── Person detail panel ───────────────────────────────────────────────────────
class _PersonDetail extends StatelessWidget {
  final CreditController ctrl;
  const _PersonDetail({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final person  = ctrl.selectedPerson.value!;
      final entries = ctrl.personEntries;
      final bal     = ctrl.personBalances
          .firstWhereOrNull((p) => p.personName == person);
      final balance = bal?.balance ?? 0;

      return Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFE3F2FD),
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12)),
          ),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 18),
              onPressed: ctrl.clearPersonSelection,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(person,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    balance > 0
                        ? 'Owes Rs. ${balance.toStringAsFixed(0)}'
                        : 'Fully settled',
                    style: TextStyle(
                        fontSize: 13,
                        color: balance > 0
                            ? Colors.red.shade600
                            : Colors.green.shade600),
                  ),
                ],
              ),
            ),
            if (bal != null) ...[
              _statChip('Credit',
                  'Rs. ${bal.totalCredit.toStringAsFixed(0)}',
                  Colors.red.shade50, Colors.red),
              const SizedBox(width: 6),
              _statChip('Liters',
                  '${formatL(bal.totalLiters)} L',
                  Colors.orange.shade50, Colors.orange),
              const SizedBox(width: 6),
              _statChip('Paid',
                  'Rs. ${bal.totalPaid.toStringAsFixed(0)}',
                  Colors.green.shade50, Colors.green),
            ],
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: entries.isEmpty
              ? const Center(
                  child: Text('No entries',
                      style: TextStyle(color: Colors.black38)))
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) => _CreditEntryRow(
                    entry: entries[i],
                    onDelete: () => ctrl.deleteEntry(entries[i].id!),
                  ),
                ),
        ),
      ]);
    });
  }

  Widget _statChip(String label, String value, Color bg, Color fg) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text('$label: $value',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
      );
}

// ── Credit day group ──────────────────────────────────────────────────────────
class _CreditDayGroup extends StatelessWidget {
  final String date;
  final List<CreditModel> entries;
  final Future<void> Function(int) onDelete;

  const _CreditDayGroup(
      {required this.date,
      required this.entries,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dt        = DateTime.tryParse(date);
    final formatted = dt != null
        ? DateFormat('EEEE, dd MMM yyyy').format(dt)
        : date;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: const Color(0xFFF5F5F5),
        child: Text(formatted,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black54)),
      ),
      ...entries.map((e) =>
          _CreditEntryRow(entry: e, onDelete: () => onDelete(e.id!))),
      const Divider(height: 1),
    ]);
  }
}

// ── Single credit entry row ───────────────────────────────────────────────────
class _CreditEntryRow extends StatelessWidget {
  final CreditModel entry;
  final VoidCallback onDelete;

  const _CreditEntryRow(
      {required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isCredit = entry.isCredit;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isCredit ? Colors.red.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isCredit
                ? Icons.add_shopping_cart
                : Icons.payments_outlined,
            size: 18,
            color: isCredit ? Colors.red : Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isCredit
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(isCredit ? 'CREDIT' : 'PAYMENT',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isCredit
                              ? Colors.red.shade700
                              : Colors.green.shade700)),
                ),
                const SizedBox(width: 8),
                Text(entry.personName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ]),
              if (entry.description != null)
                Text(entry.description!,
                    style: const TextStyle(
                        color: Colors.black45, fontSize: 12)),
              if (isCredit && entry.liters > 0)
                Text('${formatL(entry.liters)} L deducted from production',
                    style: TextStyle(
                        color: Colors.orange.shade700, fontSize: 12)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              isCredit
                  ? '+ Rs. ${entry.amount.toStringAsFixed(0)}'
                  : '− Rs. ${entry.amount.toStringAsFixed(0)}',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isCredit ? Colors.red : Colors.green),
            ),
            if (isCredit && entry.liters > 0)
              Text('${formatL(entry.liters)} L',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade600,
                      fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.delete_outline,
              size: 18, color: Colors.black26),
          onPressed: onDelete,
          padding: EdgeInsets.zero,
          constraints:
              const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ]),
    );
  }
}