// lib/views/production/production_view.dart
import 'package:dairy_farm_app/data/models/animal_model.dart';
import 'package:dairy_farm_app/data/models/production_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_theme.dart';
import '../../app/utils/format_utils.dart';
import '../../controllers/production_controller.dart';
import '../../controllers/animal_controller.dart';
import '../../app/utils/excel_exporter.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kRed         = Color(0xFFD32F2F);
const _kRedDark     = Color(0xFFB71C1C);
const _kMorning     = Color(0xFFE65100);
const _kMorningBg   = Color(0xFFFFF3E0);
const _kAfternoon   = Color(0xFF37474F);
const _kAfternoonBg = Color(0xFFECEFF1);
const _kEvening     = Color(0xFF283593);
const _kEveningBg   = Color(0xFFE8EAF6);
const _kGrandBg     = Color(0xFFF5F5F5);
const _kColHdrBg    = Color(0xFFF3F4F6);
const _kFocusBg     = Color(0xFFFFF3F3);

// ═════════════════════════════════════════════════════════════════════════════
class ProductionView extends StatefulWidget {
  const ProductionView({super.key});

  @override
  State<ProductionView> createState() => _ProductionViewState();
}

class _ProductionViewState extends State<ProductionView> {
  final RxBool _editMorning   = true.obs;
  final RxBool _editAfternoon = true.obs;
  final RxBool _editEvening   = true.obs;

  DateTime? _lastInitDate;
  Worker?   _loadingWorker;

  @override
  void initState() {
    super.initState();
    final ctrl = Get.find<ProductionController>();
    _loadingWorker = ever(ctrl.isLoading, (bool loading) {
      if (!loading) _computeInitialStates(ctrl);
    });
    if (!ctrl.isLoading.value) _computeInitialStates(ctrl);
  }

  void _computeInitialStates(ProductionController ctrl) {
    final date = ctrl.selectedDate.value;
    if (_lastInitDate == date) return;
    _lastInitDate = date;

    final prods = ctrl.productions;
    _editMorning.value   = prods.fold(0.0, (s, p) => s + p.morning)   == 0;
    _editAfternoon.value = prods.fold(0.0, (s, p) => s + p.afternoon) == 0;
    _editEvening.value   = prods.fold(0.0, (s, p) => s + p.evening)   == 0;
  }

  @override
  void dispose() {
    _loadingWorker?.dispose();
    super.dispose();
  }

  void _toggleSession(RxBool flag, BuildContext ctx) {
    if (flag.value) {
      FocusScope.of(ctx).unfocus();
      flag.value = false;
    } else {
      flag.value = true;
    }
  }

  void _autoLockMorning()   => _editMorning.value   = false;
  void _autoLockAfternoon() => _editAfternoon.value = false;
  void _autoLockEvening()   => _editEvening.value   = false;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ProductionController>();

    return Scaffold(
      backgroundColor: const Color(0xFFEEF0F3),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── STICKY HEADER ────────────────────────────────────────────────
          Material(
            elevation: 7,
            shadowColor: Colors.black.withOpacity(0.14),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Title + buttons
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Production',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0D1117),
                          letterSpacing: -2.0,
                          height: 0.95,
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () => _showHistoryDialog(context, ctrl),
                        icon: const Icon(Icons.history, size: 15),
                        label: const Text('History', style: TextStyle(fontSize: 14)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _showExportDialog(context, ctrl),
                        icon: const Icon(Icons.download, size: 15),
                        label: const Text('Export DMR', style: TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Row 2: 3 session blocks + grand total
                  Obx(() {
                    final prods  = ctrl.productions;
                    final mTotal = prods.fold(0.0, (s, p) => s + p.morning);
                    final aTotal = prods.fold(0.0, (s, p) => s + p.afternoon);
                    final eTotal = prods.fold(0.0, (s, p) => s + p.evening);
                    final grand  = ctrl.dailyTotal.value;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _SessionTotalBlock(
                              icon:         Icons.wb_sunny_rounded,
                              label:        'MORNING',
                              total:        mTotal,
                              accentColor:  _kMorning,
                              bgColor:      _kMorningBg,
                              isEditing:    _editMorning.value,
                              onToggleEdit: () =>
                                  _toggleSession(_editMorning, context),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _SessionTotalBlock(
                              icon:         Icons.wb_cloudy_rounded,
                              label:        'AFTERNOON',
                              total:        aTotal,
                              accentColor:  _kAfternoon,
                              bgColor:      _kAfternoonBg,
                              isEditing:    _editAfternoon.value,
                              onToggleEdit: () =>
                                  _toggleSession(_editAfternoon, context),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _SessionTotalBlock(
                              icon:         Icons.nightlight_round,
                              label:        'EVENING',
                              total:        eTotal,
                              accentColor:  _kEvening,
                              bgColor:      _kEveningBg,
                              isEditing:    _editEvening.value,
                              onToggleEdit: () =>
                                  _toggleSession(_editEvening, context),
                            ),
                          ),
                          const SizedBox(width: 14),
                          _GrandTotalBlock(total: grand),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 18),

                  // Row 3: Date picker
                  _DatePicker(
                    ctrl: ctrl,
                    onDateChanging: () {
                      _lastInitDate = null;
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Column label strip ───────────────────────────────────────────
          const _ColumnLabelRow(),

          // ── Scrollable data rows ─────────────────────────────────────────
          Expanded(
            child: _ProductionTable(
              ctrl:                ctrl,
              editMorning:         _editMorning,
              editAfternoon:       _editAfternoon,
              editEvening:         _editEvening,
              onMorningComplete:   _autoLockMorning,
              onAfternoonComplete: _autoLockAfternoon,
              onEveningComplete:   _autoLockEvening,
            ),
          ),
        ],
      ),
    );
  }

  // ── History Dialog ────────────────────────────────────────────────────────
 // ════════════════════════════════════════════════════════════════════════════
// REPLACE _showHistoryDialog in production_view.dart with this version.
// Changes:
//   • "Export Excel" button kept as-is
//   • "Export PDF"  button added  (single selected animal, 2-up layout)
//   • "Export All PDF" button added (all animals for the selected month)
// ════════════════════════════════════════════════════════════════════════════

  void _showHistoryDialog(BuildContext context, ProductionController ctrl) {
    final animalCtrl     = Get.find<AnimalController>();
    final selectedAnimal = Rx<AnimalModel?>(null);
    final selectedYear   = DateTime.now().year.obs;
    final selectedMonth  = DateTime.now().month.obs;
    final history        = <ProductionModel>[].obs;

    // Separate busy flags for each export action
    final isExportingExcel  = false.obs;
    final isExportingPdf    = false.obs;
    final isExportingAllPdf = false.obs;

    Get.dialog(Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth:  MediaQuery.of(context).size.width * 0.92,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ────────────────────────────────────────────────
              Row(children: [
                const Text(
                  'Animal Production History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),

                // ── Export Excel (single animal) ───────────────────────────
                Obx(() => history.isEmpty
                    ? const SizedBox.shrink()
                    : Obx(() => ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                          ),
                          onPressed: isExportingExcel.value
                              ? null
                              : () async {
                                  if (selectedAnimal.value == null) return;
                                  isExportingExcel.value = true;
                                  try {
                                    final a = selectedAnimal.value!;
                                    await ExcelExporter.exportAnimalMonthlyDMR(
                                      history,
                                      a.tagNumber,
                                      a.name ?? a.tagNumber,
                                      selectedYear.value,
                                      selectedMonth.value,
                                    );
                                  } finally {
                                    isExportingExcel.value = false;
                                  }
                                },
                          icon: isExportingExcel.value
                              ? const SizedBox(
                                  width: 14, height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.table_chart_outlined, size: 16),
                          label: Text(
                              isExportingExcel.value ? 'Exporting...' : 'Excel',
                              style: const TextStyle(fontSize: 13)),
                        ))),

                const SizedBox(width: 8),

                // ── Export PDF (single selected animal) ────────────────────
                Obx(() => history.isEmpty
                    ? const SizedBox.shrink()
                    : Obx(() => ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                          ),
                          onPressed: isExportingPdf.value
                              ? null
                              : () async {
                                  if (selectedAnimal.value == null) return;
                                  isExportingPdf.value = true;
                                  try {
                                    final a = selectedAnimal.value!;
                                    await ExcelExporter.exportAnimalMonthlyDMRPdf(
                                      history,
                                      a.tagNumber,
                                      a.name ?? a.tagNumber,
                                      selectedYear.value,
                                      selectedMonth.value,
                                    );
                                  } finally {
                                    isExportingPdf.value = false;
                                  }
                                },
                          icon: isExportingPdf.value
                              ? const SizedBox(
                                  width: 14, height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.picture_as_pdf_outlined, size: 16),
                          label: Text(
                              isExportingPdf.value ? 'Exporting...' : 'PDF',
                              style: const TextStyle(fontSize: 13)),
                        ))),

                const SizedBox(width: 8),

                // ── Export All Animals PDF ─────────────────────────────────
                Obx(() => isExportingAllPdf.value
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade700,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white)),
                          SizedBox(width: 8),
                          Text('Exporting all...',
                              style: TextStyle(fontSize: 13, color: Colors.white)),
                        ]),
                      )
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade700,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                        onPressed: () async {
                          isExportingAllPdf.value = true;
                          try {
                            // Load data for every active animal
                            final allAnimals = animalCtrl.animals
                                .where((a) => a.isActive && a.id != null)
                                .toList();

                            if (allAnimals.isEmpty) {
                              Get.snackbar('No Animals',
                                  'No active animals found.',
                                  snackPosition: SnackPosition.BOTTOM);
                              return;
                            }

                            final records = <({
                              List<ProductionModel> history,
                              String tag,
                              String name,
                            })>[];

                            for (final a in allAnimals) {
                              final h = await ctrl.getAnimalHistory(
                                a.id!,
                                selectedYear.value,
                                selectedMonth.value,
                              );
                              if (h.isNotEmpty) {
                                records.add((
                                  history: h,
                                  tag:     a.tagNumber,
                                  name:    a.name ?? a.tagNumber,
                                ));
                              }
                            }

                            if (records.isEmpty) {
                              Get.snackbar('No Data',
                                  'No production records found for any animal '
                                  'in the selected month.',
                                  snackPosition: SnackPosition.BOTTOM);
                              return;
                            }

                            await ExcelExporter.exportAllAnimalsDMRPdf(
                              records,
                              selectedYear.value,
                              selectedMonth.value,
                            );
                          } finally {
                            isExportingAllPdf.value = false;
                          }
                        },
                        icon: const Icon(Icons.picture_as_pdf, size: 16),
                        label: const Text('All Animals PDF',
                            style: TextStyle(fontSize: 13)),
                      )),

                const SizedBox(width: 8),

                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back()),
              ]),

              const SizedBox(height: 16),

              // ── Filter row ────────────────────────────────────────────────
              Row(children: [
                Expanded(
                  flex: 3,
                  child: Obx(() => DropdownButtonFormField<AnimalModel>(
                        value: selectedAnimal.value,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Select Animal',
                            labelStyle: TextStyle(fontSize: 14)),
                        items: animalCtrl.animals
                            .map((a) => DropdownMenuItem(
                                  value: a,
                                  child: Text(
                                      '${a.tagNumber} — ${a.name ?? ""}',
                                      style: const TextStyle(fontSize: 14)),
                                ))
                            .toList(),
                        onChanged: (v) => selectedAnimal.value = v,
                      )),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 150,
                  child: Obx(() => DropdownButtonFormField<int>(
                        value: selectedMonth.value,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Month',
                            labelStyle: TextStyle(fontSize: 14)),
                        items: List.generate(
                            12,
                            (i) => DropdownMenuItem(
                                  value: i + 1,
                                  child: Text(
                                      DateFormat('MMMM')
                                          .format(DateTime(2024, i + 1)),
                                      style: const TextStyle(fontSize: 14)),
                                )),
                        onChanged: (v) => selectedMonth.value = v ?? 1,
                      )),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: Obx(() => DropdownButtonFormField<int>(
                        value: selectedYear.value,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Year',
                            labelStyle: TextStyle(fontSize: 14)),
                        items: List.generate(
                            5,
                            (i) => DropdownMenuItem(
                                  value: DateTime.now().year - i,
                                  child: Text(
                                      '${DateTime.now().year - i}',
                                      style: const TextStyle(fontSize: 14)),
                                )),
                        onChanged: (v) =>
                            selectedYear.value = v ?? DateTime.now().year,
                      )),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedAnimal.value?.id == null) return;
                    history.value = await ctrl.getAnimalHistory(
                        selectedAnimal.value!.id!,
                        selectedYear.value,
                        selectedMonth.value);
                  },
                  child: const Text('Load', style: TextStyle(fontSize: 14)),
                ),
              ]),

              const SizedBox(height: 16),

              // ── Table area ────────────────────────────────────────────────
              Expanded(
                child: Obx(() {
                  if (history.isEmpty) {
                    return const Center(
                        child: Text(
                            'Select an animal and tap Load.'
                            '  Use "All Animals PDF" to export everyone at once.',
                            style: TextStyle(
                                color: Colors.black45, fontSize: 14),
                            textAlign: TextAlign.center));
                  }
                  final avg   = history.fold(0.0, (s, p) => s + p.total) /
                      history.length;
                  final total = history.fold(0.0, (s, p) => s + p.total);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Stats bar
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(children: [
                          const Icon(Icons.analytics_outlined,
                              size: 16, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Text('Daily Average: ${formatL(avg)} L',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                  fontSize: 14)),
                          const SizedBox(width: 24),
                          Text('${history.length} days recorded',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black54)),
                          const Spacer(),
                          Text('Monthly Total: ${formatL(total)} L',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                        ]),
                      ),

                      const SizedBox(height: 12),

                      Expanded(
                        child: SingleChildScrollView(
                          child: SizedBox(
                            width: double.infinity,
                            child: DataTable(
                              columnSpacing:    24,
                              horizontalMargin: 16,
                              headingRowHeight: 48,
                              headingRowColor: WidgetStateProperty.all(
                                  const Color(0xFFE8F5E9)),
                              dataRowMinHeight: 44,
                              dataRowMaxHeight: 52,
                              columns: const [
                                DataColumn(
                                    label: Text('Date',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18))),
                                DataColumn(
                                    label: Text('Morning',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: _kMorning))),
                                DataColumn(
                                    label: Text('Afternoon',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: _kAfternoon))),
                                DataColumn(
                                    label: Text('Evening',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: _kEvening))),
                                DataColumn(
                                    label: Text('Total',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: AppTheme.primary))),
                              ],
                              rows: history
                                  .map((p) => DataRow(cells: [
                                        DataCell(Text(p.productionDate,
                                            style: const TextStyle(
                                                fontSize: 13))),
                                        DataCell(Text(
                                            '${formatL(p.morning)} L',
                                            style: const TextStyle(
                                                fontSize: 13))),
                                        DataCell(Text(
                                            '${formatL(p.afternoon)} L',
                                            style: const TextStyle(
                                                fontSize: 13))),
                                        DataCell(Text(
                                            '${formatL(p.evening)} L',
                                            style: const TextStyle(
                                                fontSize: 13))),
                                        DataCell(Text(
                                            '${formatL(p.total)} L',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: AppTheme.primary))),
                                      ]))
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    ));
  }
  // ── Export Dialog ─────────────────────────────────────────────────────────
  void _showExportDialog(BuildContext context, ProductionController ctrl) {
    final fromCtrl = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(
            DateTime.now().subtract(const Duration(days: 30))));
    final toCtrl = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(DateTime.now()));

    Get.dialog(AlertDialog(
      title: const Text('Export DMR (Daily Milk Record)',
          style: TextStyle(fontSize: 16)),
      content: SizedBox(
        width: 350,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Select date range to export production data:',
              style: TextStyle(color: Colors.black54, fontSize: 14)),
          const SizedBox(height: 16),
          TextField(
              controller: fromCtrl,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                  labelText: 'From Date', hintText: 'yyyy-mm-dd')),
          const SizedBox(height: 12),
          TextField(
              controller: toCtrl,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                  labelText: 'To Date', hintText: 'yyyy-mm-dd')),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(fontSize: 14))),
        ElevatedButton.icon(
          onPressed: () async {
            Get.back();
            final prods =
                await ctrl.getByRange(fromCtrl.text, toCtrl.text);
            await ExcelExporter.exportDMR(
                prods, fromCtrl.text, toCtrl.text);
          },
          icon: const Icon(Icons.download, size: 16),
          label: const Text('Export', style: TextStyle(fontSize: 14)),
        ),
      ],
    ));
  }
}

// ── Session Total Block ───────────────────────────────────────────────────────
class _SessionTotalBlock extends StatelessWidget {
  final IconData icon;
  final String   label;
  final double   total;
  final Color    accentColor;
  final Color    bgColor;
  final bool     isEditing;
  final VoidCallback onToggleEdit;

  const _SessionTotalBlock({
    required this.icon,
    required this.label,
    required this.total,
    required this.accentColor,
    required this.bgColor,
    required this.isEditing,
    required this.onToggleEdit,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: isEditing ? accentColor.withOpacity(0.10) : bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEditing ? accentColor : accentColor.withOpacity(0.22),
          width: isEditing ? 2.2 : 1.2,
        ),
        boxShadow: isEditing
            ? [
                BoxShadow(
                    color: accentColor.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: accentColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                  letterSpacing: 0.7,
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onToggleEdit,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isEditing ? accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor, width: 1.4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isEditing
                          ? Icons.lock_open_outlined
                          : Icons.edit_outlined,
                      size: 13,
                      color: isEditing ? Colors.white : accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isEditing ? 'Save' : 'Edit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isEditing ? Colors.white : accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),

          const SizedBox(height: 12),

          Text(
            '${formatL(total)} L',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: accentColor,
              letterSpacing: -1.0,
              height: 1.0,
            ),
          ),

          const SizedBox(height: 4),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isEditing
                ? Row(
                    key: const ValueKey('editing'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                            color: accentColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Editing',
                        style: TextStyle(
                            fontSize: 11,
                            color: accentColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  )
                : Row(
                    key: const ValueKey('locked'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline,
                          size: 11, color: accentColor.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text(
                        'Locked',
                        style: TextStyle(
                            fontSize: 11,
                            color: accentColor.withOpacity(0.5),
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Grand Total Block ─────────────────────────────────────────────────────────
class _GrandTotalBlock extends StatelessWidget {
  final double total;
  const _GrandTotalBlock({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 170),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: _kGrandBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDDDDD), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: const [
            Icon(Icons.water_drop_outlined, size: 16, color: Colors.black45),
            SizedBox(width: 6),
            Text(
              'GRAND TOTAL',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.black45,
                letterSpacing: 0.7,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Text(
            '${formatL(total)} L',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A2E),
              letterSpacing: -1.0,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Daily',
            style: TextStyle(
                fontSize: 11,
                color: Colors.black38,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Date Picker ───────────────────────────────────────────────────────────────
class _DatePicker extends StatelessWidget {
  final ProductionController ctrl;
  final VoidCallback onDateChanging;

  const _DatePicker({required this.ctrl, required this.onDateChanging});

  @override
  Widget build(BuildContext context) {
    return Obx(() => GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: ctrl.selectedDate.value,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              onDateChanging();
              ctrl.loadProductionForDate(picked);
            }
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFDDE2E8)),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 15, color: _kRed),
                const SizedBox(width: 10),
                Text(
                  DateFormat('EEEE, dd MMM yyyy')
                      .format(ctrl.selectedDate.value),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF0D1117),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_drop_down,
                    size: 20, color: Colors.black45),
              ],
            ),
          ),
        ));
  }
}

// ── Column label strip ────────────────────────────────────────────────────────
class _ColumnLabelRow extends StatelessWidget {
  const _ColumnLabelRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kColHdrBg,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: const Row(children: [
        SizedBox(width: 44, child: Text('#', style: _kLbl)),
        Expanded(flex: 2, child: Text('ANIMAL TAG', style: _kLbl)),
        Expanded(flex: 2, child: Text('NAME',       style: _kLbl)),
        Expanded(
            flex: 3,
            child: Text('MORNING',
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: _kMorning,
                    letterSpacing: 0.5))),
        SizedBox(width: 10),
        Expanded(
            flex: 3,
            child: Text('AFTERNOON',
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: _kMorning,
                    letterSpacing: 0.5))),
        SizedBox(width: 10),
        Expanded(
            flex: 3,
            child: Text('EVENING',
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: _kMorning,
                    letterSpacing: 0.5))),
        // ── No status spacer ─────────────────────────────────────────────
      ]),
    );
  }
}

const _kLbl = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.bold,
  color: Color(0xFF546E7A),
  letterSpacing: 0.6,
);

// ── Production Table ──────────────────────────────────────────────────────────
class _ProductionTable extends StatefulWidget {
  final ProductionController ctrl;
  final RxBool editMorning;
  final RxBool editAfternoon;
  final RxBool editEvening;
  final VoidCallback onMorningComplete;
  final VoidCallback onAfternoonComplete;
  final VoidCallback onEveningComplete;

  const _ProductionTable({
    required this.ctrl,
    required this.editMorning,
    required this.editAfternoon,
    required this.editEvening,
    required this.onMorningComplete,
    required this.onAfternoonComplete,
    required this.onEveningComplete,
  });

  @override
  State<_ProductionTable> createState() => _ProductionTableState();
}

class _ProductionTableState extends State<_ProductionTable> {
  final List<List<FocusNode>> _nodes   = [];
  final List<GlobalKey>       _rowKeys = [];
  int  _lastCount       = 0;
  int  _focusedRowIndex = -1;

  void _ensureNodes(int count) {
    if (count == _lastCount) return;

    for (int i = count; i < _nodes.length; i++) {
      for (final fn in _nodes[i]) fn.dispose();
    }

    if (count > _nodes.length) {
      for (int i = _nodes.length; i < count; i++) {
        final rowIdx   = i;
        final rowNodes = List.generate(3, (_) => FocusNode());
        for (final fn in rowNodes) {
          fn.addListener(() {
            if (fn.hasFocus && mounted) {
              setState(() => _focusedRowIndex = rowIdx);
              _scrollToRow(rowIdx);
            } else if (!fn.hasFocus && mounted) {
              final any = _nodes[rowIdx].any((n) => n.hasFocus);
              if (!any && _focusedRowIndex == rowIdx) {
                setState(() => _focusedRowIndex = -1);
              }
            }
          });
        }
        _nodes.add(rowNodes);
        _rowKeys.add(GlobalKey());
      }
    } else {
      _nodes.removeRange(count, _nodes.length);
      _rowKeys.removeRange(count, _rowKeys.length);
    }

    _lastCount = count;
  }

  void _scrollToRow(int idx) {
    if (idx < 0 || idx >= _rowKeys.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _rowKeys[idx].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            alignment: 0.2);
      }
    });
  }

  @override
  void dispose() {
    for (final row in _nodes) {
      for (final fn in row) fn.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (widget.ctrl.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: _kRed));
      }

      final prods = widget.ctrl.productions;
      _ensureNodes(prods.length);

      if (prods.isEmpty) {
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.opacity_outlined,
                size: 56, color: Colors.black.withOpacity(0.12)),
            const SizedBox(height: 14),
            const Text('No production data for this date',
                style: TextStyle(color: Colors.black38, fontSize: 16)),
          ]),
        );
      }

      final lastIndex = prods.length - 1;

      return ListView.separated(
        padding: const EdgeInsets.only(bottom: 40),
        itemCount: prods.length,
        separatorBuilder: (_, __) => const Divider(
            height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
        itemBuilder: (context, index) {
          final nextM = index + 1 < _nodes.length ? _nodes[index + 1][0] : null;
          final nextA = index + 1 < _nodes.length ? _nodes[index + 1][1] : null;
          final nextE = index + 1 < _nodes.length ? _nodes[index + 1][2] : null;
          final isLast = index == lastIndex;

          return KeyedSubtree(
            key: _rowKeys[index],
            child: ProductionEntryRow(
              key: ValueKey(
                  '${prods[index].animalId}_${widget.ctrl.selectedDate.value}'),
              production:        prods[index],
              index:             index,
              isFocused:         _focusedRowIndex == index,
              editMorning:       widget.editMorning,
              editAfternoon:     widget.editAfternoon,
              editEvening:       widget.editEvening,
              morningNode:       _nodes[index][0],
              afternoonNode:     _nodes[index][1],
              eveningNode:       _nodes[index][2],
              nextMorningNode:   nextM,
              nextAfternoonNode: nextA,
              nextEveningNode:   nextE,
              onLastMorningSubmit:
                  isLast ? widget.onMorningComplete : null,
              onLastAfternoonSubmit:
                  isLast ? widget.onAfternoonComplete : null,
              onLastEveningSubmit:
                  isLast ? widget.onEveningComplete : null,
              onSave: (p) => widget.ctrl.updateProduction(p),
            ),
          );
        },
      );
    });
  }
}

// ── Production Entry Row ──────────────────────────────────────────────────────
class ProductionEntryRow extends StatefulWidget {
  final ProductionModel production;
  final int   index;
  final bool  isFocused;
  final RxBool editMorning;
  final RxBool editAfternoon;
  final RxBool editEvening;
  final Function(ProductionModel) onSave;
  final FocusNode  morningNode;
  final FocusNode  afternoonNode;
  final FocusNode  eveningNode;
  final FocusNode? nextMorningNode;
  final FocusNode? nextAfternoonNode;
  final FocusNode? nextEveningNode;
  final VoidCallback? onLastMorningSubmit;
  final VoidCallback? onLastAfternoonSubmit;
  final VoidCallback? onLastEveningSubmit;

  const ProductionEntryRow({
    super.key,
    required this.production,
    required this.index,
    required this.isFocused,
    required this.editMorning,
    required this.editAfternoon,
    required this.editEvening,
    required this.onSave,
    required this.morningNode,
    required this.afternoonNode,
    required this.eveningNode,
    this.nextMorningNode,
    this.nextAfternoonNode,
    this.nextEveningNode,
    this.onLastMorningSubmit,
    this.onLastAfternoonSubmit,
    this.onLastEveningSubmit,
  });

  @override
  State<ProductionEntryRow> createState() => _ProductionEntryRowState();
}

class _ProductionEntryRowState extends State<ProductionEntryRow> {
  late TextEditingController morningCtrl;
  late TextEditingController afternoonCtrl;
  late TextEditingController eveningCtrl;
  bool _mFocused = false;
  bool _aFocused = false;
  bool _eFocused = false;

  @override
  void initState() {
    super.initState();
    morningCtrl = TextEditingController(
        text: widget.production.morning > 0
            ? formatL(widget.production.morning)
            : '');
    afternoonCtrl = TextEditingController(
        text: widget.production.afternoon > 0
            ? formatL(widget.production.afternoon)
            : '');
    eveningCtrl = TextEditingController(
        text: widget.production.evening > 0
            ? formatL(widget.production.evening)
            : '');

    _wire(widget.morningNode, morningCtrl,
        onF: () => setState(() => _mFocused = true),
        onB: () {
          setState(() => _mFocused = false);
          _save();
        });
    _wire(widget.afternoonNode, afternoonCtrl,
        onF: () => setState(() => _aFocused = true),
        onB: () {
          setState(() => _aFocused = false);
          _save();
        });
    _wire(widget.eveningNode, eveningCtrl,
        onF: () => setState(() => _eFocused = true),
        onB: () {
          setState(() => _eFocused = false);
          _save();
        });
  }

  void _wire(FocusNode n, TextEditingController c,
      {required VoidCallback onF, required VoidCallback onB}) {
    n.addListener(() {
      if (n.hasFocus) {
        onF();
        c.selection =
            TextSelection(baseOffset: 0, extentOffset: c.text.length);
      } else {
        onB();
      }
    });
  }

  @override
  void dispose() {
    morningCtrl.dispose();
    afternoonCtrl.dispose();
    eveningCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!mounted) return;
    await widget.onSave(ProductionModel(
      id:             widget.production.id,
      animalId:       widget.production.animalId,
      productionDate: widget.production.productionDate,
      morning:        double.tryParse(morningCtrl.text)   ?? 0,
      afternoon:      double.tryParse(afternoonCtrl.text) ?? 0,
      evening:        double.tryParse(eveningCtrl.text)   ?? 0,
      createdAt:      widget.production.createdAt,
      animalTag:      widget.production.animalTag,
      animalName:     widget.production.animalName,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final focused = widget.isFocused;
    final isEven  = widget.index % 2 == 0;

    return Obx(() {
      final editM = widget.editMorning.value;
      final editA = widget.editAfternoon.value;
      final editE = widget.editEvening.value;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        color: focused
            ? _kFocusBg
            : (isEven ? Colors.white : const Color(0xFFFAFAFA)),
        padding: EdgeInsets.symmetric(
            horizontal: 28, vertical: focused ? 20 : 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // #
            SizedBox(
              width: 44,
              child: Text(
                '${widget.index + 1}',
                style: TextStyle(
                  fontSize: focused ? 17 : 13,
                  fontWeight:
                      focused ? FontWeight.bold : FontWeight.normal,
                  color:
                      focused ? _kRed.withOpacity(0.45) : Colors.black38,
                ),
              ),
            ),

            // Tag
            Expanded(
              flex: 2,
              child: Text(
                widget.production.animalTag ?? 'Animal ${widget.index + 1}',
                style: TextStyle(
                  fontSize: focused ? 20 : 14,
                  fontWeight: FontWeight.bold,
                  color: focused ? _kRedDark : const Color(0xFF1A1A2E),
                ),
              ),
            ),

            // Name
            Expanded(
              flex: 2,
              child: Text(
                widget.production.animalName ?? '—',
                style: TextStyle(
                  fontSize: focused ? 17 : 13,
                  fontWeight:
                      focused ? FontWeight.w600 : FontWeight.normal,
                  color: focused ? _kRed.withOpacity(0.7) : Colors.black54,
                ),
              ),
            ),

            // Morning
            Expanded(
              flex: 3,
              child: _field(
                ctrl:     morningCtrl,
                node:     widget.morningNode,
                color:    _kMorning,
                editing:  editM,
                focused:  _mFocused,
                nextNode: widget.nextMorningNode,
                onSubmit: () => widget.onLastMorningSubmit?.call(),
              ),
            ),

            const SizedBox(width: 10),

            // Afternoon
            Expanded(
              flex: 3,
              child: _field(
                ctrl:     afternoonCtrl,
                node:     widget.afternoonNode,
                color:    _kAfternoon,
                editing:  editA,
                focused:  _aFocused,
                nextNode: widget.nextAfternoonNode,
                onSubmit: () => widget.onLastAfternoonSubmit?.call(),
              ),
            ),

            const SizedBox(width: 10),

            // Evening
            Expanded(
              flex: 3,
              child: _field(
                ctrl:     eveningCtrl,
                node:     widget.eveningNode,
                color:    _kEvening,
                editing:  editE,
                focused:  _eFocused,
                nextNode: widget.nextEveningNode,
                onSubmit: () => widget.onLastEveningSubmit?.call(),
              ),
            ),
            // ── Status column removed ─────────────────────────────────────
          ],
        ),
      );
    });
  }

  Widget _field({
    required TextEditingController ctrl,
    required FocusNode node,
    required Color color,
    required bool editing,
    required bool focused,
    FocusNode? nextNode,
    VoidCallback? onSubmit,
  }) {
    if (!editing) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Text(
          '${ctrl.text.isEmpty ? "0" : ctrl.text} L',
          style: const TextStyle(fontSize: 14, color: Colors.black45),
        ),
      );
    }

    return TextField(
      controller: ctrl,
      focusNode:  node,
      style: TextStyle(
        fontSize:   focused ? 36 : 15,
        fontWeight: focused ? FontWeight.w900 : FontWeight.normal,
        color:      focused ? color : const Color(0xFF222222),
      ),
      decoration: InputDecoration(
        hintText:    '0',
        suffixText:  'L',
        suffixStyle: TextStyle(
          color:      color,
          fontSize:   focused ? 18 : 11,
          fontWeight: focused ? FontWeight.bold : FontWeight.normal,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical:   focused ? 26 : 10,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: color.withOpacity(0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: color, width: 2.5),
        ),
        filled:    true,
        fillColor: focused ? color.withOpacity(0.07) : Colors.white,
      ),
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) {
        if (nextNode != null) {
          FocusScope.of(context).requestFocus(nextNode);
        } else {
          FocusScope.of(context).unfocus();
          onSubmit?.call();
        }
      },
    );
  }
}