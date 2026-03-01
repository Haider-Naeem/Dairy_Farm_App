// lib/views/vaccination/vaccination_view.dart
import 'package:dairy_farm_app/app/theme/app_theme.dart';
import 'package:dairy_farm_app/controllers/vaccination_controller.dart';
import 'package:dairy_farm_app/data/models/animal_model.dart';
import 'package:dairy_farm_app/data/models/vaccination_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class VaccinationView extends StatelessWidget {
  const VaccinationView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<VaccinationController>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(children: [
              const Text('Vaccination Records',
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold)),
              const Spacer(),
              // Export button
              Obx(() => OutlinedButton.icon(
                    onPressed: ctrl.isLoading.value
                        ? null
                        : () => ctrl.exportToExcel(),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Export Excel',
                        style: TextStyle(fontSize: 14)),
                  )),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () =>
                    _showAddDialog(context, ctrl),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Record',
                    style: TextStyle(fontSize: 14)),
              ),
            ]),
            const SizedBox(height: 16),

            // ── Filter bar ───────────────────────────────────────────────
            _FilterBar(ctrl: ctrl),
            const SizedBox(height: 16),

            // ── Summary chips ────────────────────────────────────────────
            _SummaryRow(ctrl: ctrl),
            const SizedBox(height: 14),

            // ── Table ────────────────────────────────────────────────────
            Expanded(child: _VaccinationTable(ctrl: ctrl)),
          ],
        ),
      ),
    );
  }

  // ── Add record dialog ────────────────────────────────────────────────────
  static void _showAddDialog(
      BuildContext context, VaccinationController ctrl) {
    final selectedAnimal = Rx<AnimalModel?>(null);
    final vaccineCtrl    = TextEditingController();
    final dateCtrl       = TextEditingController(
        text: DateTime.now().toIso8601String().substring(0, 10));
    final nextDueCtrl = TextEditingController();
    final givenByCtrl = TextEditingController();
    final notesCtrl   = TextEditingController();

    Get.dialog(AlertDialog(
      title: const Text('Add Vaccination Record',
          style: TextStyle(fontSize: 16)),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Obx(() => DropdownButtonFormField<AnimalModel>(
                  value: selectedAnimal.value,
                  isExpanded: true,
                  decoration:
                      const InputDecoration(labelText: 'Animal *'),
                  items: ctrl.animals
                      .map((a) => DropdownMenuItem(
                          value: a,
                          child: Text(
                              '${a.tagNumber}${a.name != null ? " — ${a.name}" : ""}')))
                      .toList(),
                  onChanged: (v) => selectedAnimal.value = v,
                )),
            const SizedBox(height: 12),
            TextField(
                controller: vaccineCtrl,
                decoration:
                    const InputDecoration(labelText: 'Vaccine Name *')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: dateCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Date Given',
                          hintText: 'yyyy-mm-dd'))),
              const SizedBox(width: 12),
              Expanded(
                  child: TextField(
                      controller: nextDueCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Next Due Date',
                          hintText: 'yyyy-mm-dd'))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: givenByCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Given By (Vet)'))),
              const SizedBox(width: 12),
              Expanded(
                  child: TextField(
                      controller: notesCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Notes'))),
            ]),
          ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (selectedAnimal.value == null ||
                vaccineCtrl.text.trim().isEmpty) return;
            ctrl.add(VaccinationModel(
              animalId: selectedAnimal.value!.id!,
              vaccineName: vaccineCtrl.text.trim(),
              vaccinationDate: dateCtrl.text.trim(),
              nextDueDate: nextDueCtrl.text.trim().isEmpty
                  ? null
                  : nextDueCtrl.text.trim(),
              givenBy: givenByCtrl.text.trim().isEmpty
                  ? null
                  : givenByCtrl.text.trim(),
              notes: notesCtrl.text.trim().isEmpty
                  ? null
                  : notesCtrl.text.trim(),
              createdAt: DateTime.now().toIso8601String(),
            ));
            Get.back();
          },
          child: const Text('Add'),
        ),
      ],
    ));
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final VaccinationController ctrl;
  const _FilterBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Obx(() => Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // ── Animal filter ────────────────────────────────────────
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<int?>(
                    value: ctrl.selectedAnimalId.value,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Animal',
                      labelStyle: const TextStyle(fontSize: 13),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All Animals',
                              style: TextStyle(fontSize: 13))),
                      ...ctrl.animals.map((a) => DropdownMenuItem<int?>(
                            value: a.id,
                            child: Text(
                                '${a.tagNumber}${a.name != null ? " — ${a.name}" : ""}',
                                style: const TextStyle(fontSize: 13)),
                          )),
                    ],
                    onChanged: (v) => ctrl.selectedAnimalId.value = v,
                  ),
                ),

                // ── Period filter chips ──────────────────────────────────
                _periodChip(ctrl, VaccPeriod.all, 'All Time'),
                _periodChip(ctrl, VaccPeriod.thisWeek, 'This Week'),
                _periodChip(ctrl, VaccPeriod.thisMonth, 'This Month'),
                _periodChip(ctrl, VaccPeriod.thisYear, 'This Year'),

                // ── Due-only toggle ──────────────────────────────────────
                FilterChip(
                  label: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.warning_amber,
                        size: 14,
                        color: ctrl.showDueOnly.value
                            ? Colors.white
                            : Colors.orange),
                    const SizedBox(width: 4),
                    Text('Due Only',
                        style: TextStyle(
                            fontSize: 12,
                            color: ctrl.showDueOnly.value
                                ? Colors.white
                                : Colors.black87)),
                  ]),
                  selected: ctrl.showDueOnly.value,
                  onSelected: (v) => ctrl.showDueOnly.value = v,
                  selectedColor: Colors.orange.shade600,
                  checkmarkColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                ),

                // ── Custom date range (only when custom period selected) ─
                if (ctrl.selectedPeriod.value == VaccPeriod.custom) ...[
                  _DateRangeField(
                    label: 'From',
                    value: ctrl.customFrom.value,
                    onChanged: (v) => ctrl.customFrom.value = v,
                  ),
                  _DateRangeField(
                    label: 'To',
                    value: ctrl.customTo.value,
                    onChanged: (v) => ctrl.customTo.value = v,
                  ),
                ],
              ],
            )),
      ),
    );
  }

  Widget _periodChip(
      VaccinationController ctrl, VaccPeriod period, String label) {
    return Obx(() {
      final selected = ctrl.selectedPeriod.value == period;
      return ChoiceChip(
        label: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white : Colors.black87)),
        selected: selected,
        selectedColor: AppTheme.primary,
        onSelected: (_) => ctrl.selectedPeriod.value = period,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      );
    });
  }
}

class _DateRangeField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  const _DateRangeField(
      {required this.label,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController(text: value);
    return SizedBox(
      width: 140,
      child: TextField(
        controller: ctrl,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12),
          hintText: 'yyyy-mm-dd',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

// ── Summary row ───────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final VaccinationController ctrl;
  const _SummaryRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final list      = ctrl.filtered;
      final total     = list.length;
      final overdue   = list.where((v) =>
          v.nextDueDate != null &&
          !v.isDone &&
          (DateTime.tryParse(v.nextDueDate!)?.isBefore(DateTime.now()) ??
              false)).length;
      final dueSoon   = list.where((v) =>
          v.nextDueDate != null &&
          !v.isDone &&
          !(DateTime.tryParse(v.nextDueDate!)?.isBefore(DateTime.now()) ??
              false) &&
          (DateTime.tryParse(v.nextDueDate!)?.isBefore(
                  DateTime.now().add(const Duration(days: 7))) ??
              false)).length;
      final done      = list.where((v) => v.isDone).length;

      return Row(children: [
        _chip('Total Records', '$total', AppTheme.primary,
            Icons.vaccines_outlined),
        const SizedBox(width: 10),
        if (overdue > 0)
          _chip('Overdue', '$overdue', Colors.red.shade600,
              Icons.error_outline),
        if (overdue > 0) const SizedBox(width: 10),
        if (dueSoon > 0)
          _chip('Due Soon', '$dueSoon', Colors.orange.shade600,
              Icons.warning_amber),
        if (dueSoon > 0) const SizedBox(width: 10),
        _chip('Done', '$done', Colors.green.shade600,
            Icons.check_circle_outline),
      ]);
    });
  }

  Widget _chip(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style:
                  TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ]),
      ]),
    );
  }
}

// ── Vaccination table ─────────────────────────────────────────────────────────
class _VaccinationTable extends StatelessWidget {
  final VaccinationController ctrl;
  const _VaccinationTable({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(children: [
        // Table header
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFE8F5E9),
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12)),
          ),
          child: Row(children: [
            _hCell('Animal', flex: 2),
            _hCell('Vaccine Name', flex: 3),
            _hCell('Date Given', flex: 2),
            _hCell('Next Due', flex: 2),
            _hCell('Status', flex: 2),
            _hCell('Given By', flex: 2),
            const SizedBox(width: 100, child: Text('Actions', style: _hStyle)),
          ]),
        ),

        Expanded(
          child: Obx(() {
            if (ctrl.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final list = ctrl.filtered;
            if (list.isEmpty) {
              return Center(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.vaccines_outlined,
                          size: 52, color: Colors.black12),
                      const SizedBox(height: 12),
                      const Text('No records match the current filters',
                          style: TextStyle(
                              color: Colors.black38, fontSize: 15)),
                    ]),
              );
            }

            return ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
              itemBuilder: (context, i) =>
                  _VaccinationRow(v: list[i], ctrl: ctrl, index: i),
            );
          }),
        ),
      ]),
    );
  }

  Widget _hCell(String label, {int flex = 1}) => Expanded(
        flex: flex,
        child: Text(label, style: _hStyle),
      );

  static const _hStyle =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 13);
}

// ── Single row ────────────────────────────────────────────────────────────────
class _VaccinationRow extends StatelessWidget {
  final VaccinationModel v;
  final VaccinationController ctrl;
  final int index;
  const _VaccinationRow(
      {required this.v, required this.ctrl, required this.index});

  @override
  Widget build(BuildContext context) {
    final isEven = index % 2 == 0;

    final isDue = v.nextDueDate != null &&
        !v.isDone &&
        (DateTime.tryParse(v.nextDueDate!)?.isBefore(DateTime.now()) ??
            false);
    final isDueSoon = v.nextDueDate != null &&
        !v.isDone &&
        !isDue &&
        (DateTime.tryParse(v.nextDueDate!)?.isBefore(
                DateTime.now().add(const Duration(days: 7))) ??
            false);

    Color rowBg = isEven ? Colors.white : const Color(0xFFFAFAFA);
    if (isDue) rowBg = Colors.red.shade50.withOpacity(0.6);

    return Container(
      color: rowBg,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        // Animal tag
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(v.animalTag ?? '—',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.primary)),
          ),
        ),

        // Vaccine name
        Expanded(
          flex: 3,
          child: Text(v.vaccineName,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  decoration:
                      v.isDone ? TextDecoration.lineThrough : null,
                  color: v.isDone ? Colors.black38 : Colors.black87)),
        ),

        // Date given
        Expanded(
          flex: 2,
          child: Text(v.vaccinationDate,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ),

        // Next due
        Expanded(
          flex: 2,
          child: v.nextDueDate == null
              ? const Text('—',
                  style: TextStyle(color: Colors.black26))
              : Row(children: [
                  if (isDue || isDueSoon)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                          isDue
                              ? Icons.error_outline
                              : Icons.warning_amber,
                          size: 14,
                          color: isDue
                              ? Colors.red.shade600
                              : Colors.orange.shade600),
                    ),
                  Flexible(
                    child: Text(v.nextDueDate!,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: isDue || isDueSoon
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: v.isDone
                                ? Colors.black26
                                : isDue
                                    ? Colors.red.shade700
                                    : isDueSoon
                                        ? Colors.orange.shade700
                                        : Colors.black54)),
                  ),
                ]),
        ),

        // Status chip
        Expanded(
          flex: 2,
          child: _statusChip(v, isDue, isDueSoon),
        ),

        // Given by
        Expanded(
          flex: 2,
          child: Text(v.givenBy ?? '—',
              style: const TextStyle(
                  fontSize: 12, color: Colors.black54)),
        ),

        // Actions
        SizedBox(
          width: 100,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            // Mark done button
            if (!v.isDone && v.nextDueDate != null)
              Tooltip(
                message: 'Mark as done',
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => ctrl.markDone(v),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check,
                              size: 13,
                              color: Colors.green.shade700),
                          const SizedBox(width: 3),
                          Text('Done',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold)),
                        ]),
                  ),
                ),
              ),
            const Spacer(),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                  minWidth: 28, minHeight: 28),
              icon: const Icon(Icons.delete_outline,
                  size: 16, color: AppTheme.danger),
              onPressed: () => ctrl.delete(v.id!),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _statusChip(
      VaccinationModel v, bool isDue, bool isDueSoon) {
    if (v.isDone) {
      return _chip('Done', Colors.green.shade600, Icons.check_circle);
    }
    if (v.nextDueDate == null) {
      return _chip('No Due Date', Colors.grey, Icons.remove_circle_outline);
    }
    if (isDue) {
      return _chip('Overdue', Colors.red.shade600, Icons.error_outline);
    }
    if (isDueSoon) {
      return _chip('Due Soon', Colors.orange.shade600, Icons.warning_amber);
    }
    return _chip('Scheduled', AppTheme.primary, Icons.schedule);
  }

  Widget _chip(String label, Color color, IconData icon) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.bold)),
      ]),
    );
  }
}