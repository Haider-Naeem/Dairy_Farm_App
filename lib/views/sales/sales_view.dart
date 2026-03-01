// lib/views/sales/sales_view.dart
import 'package:dairy_farm_app/data/models/cash_sale_model.dart';
import 'package:dairy_farm_app/data/models/payment_model.dart';
import 'package:dairy_farm_app/data/models/sale_model.dart';
import 'package:dairy_farm_app/data/repositories/cash_sale_repository.dart';
import 'package:dairy_farm_app/data/repositories/payment_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_theme.dart';
import '../../app/utils/format_utils.dart';
import '../../controllers/billing_controller.dart';
import '../../controllers/sales_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../app/utils/excel_exporter.dart';

const _kRed      = Color(0xFFD32F2F);
const _kRedLight = Color(0xFFFFF0F0);
const _kRedFaint = Color(0xFFF8F9FA);

class SalesView extends StatefulWidget {
  const SalesView({super.key});

  @override
  State<SalesView> createState() => _SalesViewState();
}

class _SalesViewState extends State<SalesView> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController      _listScroll = ScrollController();

  // Keyed by clientId so nodes survive search filter changes
  final Map<int, FocusNode> _litersNodes = {};
  final Map<int, FocusNode> _amountNodes = {};
  final Map<int, GlobalKey> _rowKeys     = {};

  int  _activeClientId   = -1;
  bool _initialFocusDone = false;

  // Ensures nodes exist for every client in the full list,
  // and disposes nodes only for clients fully removed (not just filtered out).
  void _syncFocusNodes(List<SaleModel> filtered, List<SaleModel> allSales) {
    final allIds = allSales.map((s) => s.clientId ?? -1).toSet();

    // Add nodes for any client that doesn't have them yet
    for (final s in filtered) {
      final id = s.clientId ?? -1;
      if (id == -1) continue;
      _litersNodes.putIfAbsent(id, () => FocusNode());
      _amountNodes.putIfAbsent(id, () => FocusNode());
      _rowKeys    .putIfAbsent(id, () => GlobalKey());
    }

    // Dispose nodes only for clients removed from the FULL list
    final staleIds = _litersNodes.keys.toSet().difference(allIds);
    for (final id in staleIds) {
      _litersNodes.remove(id)?.dispose();
      _amountNodes.remove(id)?.dispose();
      _rowKeys    .remove(id);
    }

    // Auto-focus first row on first load
    if (!_initialFocusDone && filtered.isNotEmpty) {
      _initialFocusDone = true;
      final firstId = filtered.first.clientId ?? -1;
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _focusClientId(firstId));
    }
  }

  void _focusClientId(int clientId) {
    final node = _litersNodes[clientId];
    if (node == null || !node.canRequestFocus) return;
    setState(() => _activeClientId = clientId);
    node.requestFocus();
    _scrollToClientId(clientId);
  }

  void _focusRow(int index, List<SaleModel> filtered) {
    if (index < 0 || index >= filtered.length) return;
    _focusClientId(filtered[index].clientId ?? -1);
  }

  void _scrollToClientId(int clientId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _rowKeys[clientId]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          alignment: 0.35,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _listScroll.dispose();
    for (final n in _litersNodes.values) n.dispose();
    for (final n in _amountNodes.values) n.dispose();
    super.dispose();
  }

  // ── Payment dialog ────────────────────────────────────────────────────────
  Future<void> _showPaymentDialog(
      BuildContext context, int clientId, String clientName) async {
    final now = DateTime.now();
    int selYear  = now.month == 1 ? now.year - 1 : now.year;
    int selMonth = now.month == 1 ? 12 : now.month - 1;

    final amountCtrl = TextEditingController();
    final notesCtrl  = TextEditingController();
    final repo       = PaymentRepository();

    await Get.dialog(
      StatefulBuilder(builder: (ctx, ss) {
        Future<List<PaymentModel>> paymentsFuture =
            repo.getByClientAndMonth(clientId, selYear, selMonth);

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Title bar ─────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                  decoration: const BoxDecoration(
                    color: _kRed,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.payment,
                        color: Colors.white, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Payment — $clientName',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close,
                          color: Colors.white70, size: 22),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ]),
                ),

                // ── Body ──────────────────────────────────────────────────
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ── Billing month selector ───────────────────────
                        const Text('Billing Month',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _kRed)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: _kRedLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: _kRed.withOpacity(0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_month,
                                  size: 18, color: _kRed),
                              const SizedBox(width: 10),
                              DropdownButton<int>(
                                value: selMonth,
                                underline: const SizedBox(),
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: _kRed),
                                dropdownColor: Colors.white,
                                items: List.generate(
                                    12,
                                    (i) => DropdownMenuItem(
                                        value: i + 1,
                                        child: Text(
                                            DateFormat('MMMM').format(
                                                DateTime(2024, i + 1)),
                                            style: const TextStyle(
                                                fontSize: 16)))),
                                onChanged: (v) => ss(() {
                                  selMonth = v!;
                                  paymentsFuture =
                                      repo.getByClientAndMonth(
                                          clientId, selYear, selMonth);
                                }),
                              ),
                              const SizedBox(width: 16),
                              DropdownButton<int>(
                                value: selYear,
                                underline: const SizedBox(),
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: _kRed),
                                dropdownColor: Colors.white,
                                items: List.generate(
                                    6,
                                    (i) => DropdownMenuItem(
                                        value: DateTime.now().year - i,
                                        child: Text(
                                            '${DateTime.now().year - i}',
                                            style: const TextStyle(
                                                fontSize: 16)))),
                                onChanged: (v) => ss(() {
                                  selYear = v!;
                                  paymentsFuture =
                                      repo.getByClientAndMonth(
                                          clientId, selYear, selMonth);
                                }),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // ── Amount input ─────────────────────────────────
                        const Text('Payment Amount',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _kRed)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: amountCtrl,
                          autofocus: true,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                          decoration: InputDecoration(
                            prefixText: 'Rs. ',
                            prefixStyle: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: _kRed),
                            hintText: '0',
                            hintStyle: TextStyle(
                                fontSize: 20,
                                color: Colors.black26),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                    color: _kRed.withOpacity(0.3),
                                    width: 1.5)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: _kRed, width: 2.2)),
                          ),
                          keyboardType: TextInputType.number,
                        ),

                        const SizedBox(height: 16),

                        // ── Notes input ──────────────────────────────────
                        const Text('Notes (optional)',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _kRed)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: notesCtrl,
                          style: const TextStyle(
                              fontSize: 17, color: Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'e.g. cash payment',
                            hintStyle: TextStyle(
                                fontSize: 16, color: Colors.black26),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                    color: _kRed.withOpacity(0.3),
                                    width: 1.5)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: _kRed, width: 2.2)),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Existing payments ────────────────────────────
                        FutureBuilder<List<PaymentModel>>(
                          future: paymentsFuture,
                          builder: (ctx2, snap) {
                            if (!snap.hasData || snap.data!.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  const Icon(Icons.receipt_long,
                                      size: 16, color: _kRed),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Recorded for '
                                    '${DateFormat('MMMM yyyy').format(DateTime(selYear, selMonth))}',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: _kRed),
                                  ),
                                ]),
                                const SizedBox(height: 8),
                                ...snap.data!.map((p) => _PaymentListTile(
                                      payment: p,
                                      repo: repo,
                                      onUpdated: () => ss(() {
                                        paymentsFuture =
                                            repo.getByClientAndMonth(
                                                clientId, selYear, selMonth);
                                      }),
                                    )),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // ── Actions ───────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kRed,
                          side: const BorderSide(color: _kRed),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Get.back(),
                        child: const Text('Cancel',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 2,
                        ),
                        onPressed: () async {
                          final amount =
                              double.tryParse(amountCtrl.text.trim()) ?? 0;
                          if (amount <= 0) return;
                          final now2 = DateTime.now();
                          await repo.insert(PaymentModel(
                            clientId:    clientId,
                            year:        selYear,
                            month:       selMonth,
                            amountPaid:  amount,
                            paymentDate:
                                now2.toIso8601String().substring(0, 10),
                            notes: notesCtrl.text.trim().isEmpty
                                ? null
                                : notesCtrl.text.trim(),
                            createdAt: now2.toIso8601String(),
                          ));
                          Get.back();
                          if (Get.isRegistered<BillingController>()) {
                            final bc = Get.find<BillingController>();
                            bc.changeMonth(bc.selectedYear.value,
                                bc.selectedMonth.value);
                          }
                          Get.snackbar(
                            'Payment Recorded',
                            'Rs. ${amount.toStringAsFixed(0)} for $clientName '
                                '(${DateFormat('MMMM yyyy').format(DateTime(selYear, selMonth))})',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.green.shade50,
                            colorText: Colors.black87,
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline,
                            size: 20),
                        label: const Text('Record Payment',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
      barrierDismissible: true,
    );

    amountCtrl.dispose();
    notesCtrl.dispose();
  }
  
   @override
  Widget build(BuildContext context) {
    final ctrl         = Get.find<SalesController>();
    final settingsCtrl = Get.find<SettingsController>();

    return Scaffold(
      backgroundColor: _kRedFaint,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Row(children: [
              const Text('Sales',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _kRed)),
              const Spacer(),
              SizedBox(
                width: 260,
                child: Obx(() => TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(fontSize: 15),
                      onChanged: (v) =>
                          ctrl.searchQuery.value = v.trim().toLowerCase(),
                      decoration: InputDecoration(
                        hintText: 'Search client...',
                        hintStyle: const TextStyle(fontSize: 15),
                        prefixIcon: const Icon(Icons.search,
                            size: 18, color: Colors.black38),
                        suffixIcon: ctrl.searchQuery.value.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close,
                                    size: 16, color: Colors.black38),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  ctrl.searchQuery.value = '';
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: AppTheme.cardBorder)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: AppTheme.cardBorder)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: _kRed, width: 2)),
                      ),
                    )),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _kRed),
                    foregroundColor: _kRed),
                onPressed: () => _showExportDialog(context, ctrl),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export DSR',
                    style: TextStyle(fontSize: 15)),
              ),
            ]),
            const SizedBox(height: 8),

            _buildTopBar(context, ctrl),
            const SizedBox(height: 10),

            _CashSalesCard(ctrl: ctrl, settingsCtrl: settingsCtrl),
            const SizedBox(height: 10),

            Expanded(child: _buildSalesTable(ctrl, settingsCtrl)),
          ],
        ),
      ),
    );
  }

  // ── Date bar + stat chips ─────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, SalesController ctrl) {
    return Obx(() {
      final produced     = ctrl.productionTotalForDate.value;
      final carryOver    = ctrl.previousRemaining.value;
      final available    = ctrl.totalAvailable;
      final clientLiters = ctrl.totalClientLiters;
      final cashLiters   = ctrl.totalCashLiters;
      final creditLiters = ctrl.creditLitersForDate.value;
      final remaining    = ctrl.currentRemaining;
      final isToday      = _isToday(ctrl.selectedDate.value);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: ctrl.selectedDate.value,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) ctrl.loadSalesForDate(picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppTheme.cardBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.calendar_today,
                        size: 17, color: _kRed),
                    const SizedBox(width: 8),
                    Text(
                        DateFormat('dd MMM yyyy')
                            .format(ctrl.selectedDate.value),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16)),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_drop_down, size: 20),
                  ]),
                ),
              ),
              _dateBtn('Today',
                  () => ctrl.loadSalesForDate(DateTime.now()),
                  isToday, Colors.green),
              _statChip(Icons.opacity, 'Produced',
                  '${formatL(produced)} L', AppTheme.primary),
              if (carryOver > 0) ...[
                _statChip(Icons.replay, 'Carry-over',
                    '${formatL(carryOver)} L', Colors.deepOrange),
                _statChip(Icons.water_drop, 'Available',
                    '${formatL(available)} L', Colors.indigo),
              ],
              _statChip(Icons.people_outline, 'Clients',
                  '${formatL(clientLiters)} L', AppTheme.info),
              _statChip(Icons.point_of_sale, 'Cash',
                  '${formatL(cashLiters)} L', Colors.teal),
              if (creditLiters > 0)
                _statChip(Icons.credit_card_outlined, 'Credit',
                    '${formatL(creditLiters)} L', Colors.orange),
              _statChip(
                  Icons.local_drink,
                  'Remaining',
                  '${formatL(remaining)} L',
                  remaining >= 0
                      ? const Color(0xFF6A1B9A)
                      : AppTheme.danger),
            ],
          ),

          if (carryOver > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.deepOrange.withOpacity(0.07),
                border: Border.all(
                    color: Colors.deepOrange.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline,
                    size: 16, color: Colors.deepOrange),
                const SizedBox(width: 8),
                Text(
                  'Yesterday\'s remaining: ${formatL(carryOver)} L  '
                  '+  Today\'s production: ${formatL(produced)} L  '
                  '=  Total available: ${formatL(available)} L',
                  style: const TextStyle(
                      color: Colors.deepOrange,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
              ]),
            ),
          ],

          if (creditLiters > 0) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
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
                  '${formatL(creditLiters)} L given on credit today — '
                  'deducted from remaining milk',
                  style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
              ]),
            ),
          ],
        ],
      );
    });
  }

  Widget _dateBtn(
      String label, VoidCallback onTap, bool isActive, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.15) : Colors.white,
          border:
              Border.all(color: isActive ? color : AppTheme.cardBorder),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(
                color: isActive ? color : Colors.black54,
                fontSize: 14,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _statChip(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text('$label: ',
            style: const TextStyle(fontSize: 13, color: Colors.black54)),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color)),
      ]),
    );
  }

  // ── Client sales table ────────────────────────────────────────────────────
  Widget _buildSalesTable(
      SalesController ctrl, SettingsController settingsCtrl) {
    return Obx(() {
      if (ctrl.isLoading.value) {
        return const Center(
            child: CircularProgressIndicator(color: _kRed));
      }
      if (ctrl.sales.isEmpty) {
        return const Card(
            child: Center(
                child: Text('No clients found. Add clients first.',
                    style: TextStyle(
                        color: Colors.black45, fontSize: 16))));
      }

      final filtered = ctrl.searchQuery.value.isEmpty
          ? ctrl.sales
          : ctrl.sales
              .where((s) => (s.clientName ?? '')
                  .toLowerCase()
                  .contains(ctrl.searchQuery.value))
              .toList();

      // Sync nodes after frame — safe even when list shrinks
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _syncFocusNodes(filtered, ctrl.sales));

      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFFFCDD2)),
        ),
        child: Column(children: [
          // ── Table header ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 9),
            decoration: const BoxDecoration(
              color: _kRedLight,
              borderRadius: BorderRadius.only(
                  topLeft:  Radius.circular(12),
                  topRight: Radius.circular(12)),
            ),
            child: Row(children: const [
              SizedBox(width: 52,  child: Text('#',            style: _hStyle)),
              Expanded(flex: 5,    child: Text('Client Name',  style: _hStyle)),
              Expanded(flex: 1,    child: Text('Alloc.',       style: _hStyle)),
              Expanded(flex: 2,    child: Text('Liters Taken', style: _hStyle)),
              Expanded(flex: 2,    child: Text('Extra Rs',     style: _hStyle)),
              Expanded(flex: 1,    child: Text('Total L',      style: _hStyleRed)),
              Expanded(flex: 2,    child: Text('Total Rs',     style: _hStyleRed)),
              SizedBox(width: 104, child: Text('Payment',      style: _hStyle)),
            ]),
          ),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      const Icon(Icons.search_off,
                          size: 44, color: Colors.black26),
                      const SizedBox(height: 8),
                      Text(
                          'No client matches "${ctrl.searchQuery.value}"',
                          style: const TextStyle(
                              color: Colors.black45, fontSize: 16)),
                    ]),
                  )
                : ListView.separated(
                    controller: _listScroll,
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, color: Color(0xFFEEEEEE)),
                    itemBuilder: (context, i) {
                      final sale     = filtered[i];
                      final clientId = sale.clientId ?? -1;

                      // Eagerly create nodes for this frame in case
                      // addPostFrameCallback hasn't run yet
                      _litersNodes.putIfAbsent(clientId, () => FocusNode());
                      _amountNodes.putIfAbsent(clientId, () => FocusNode());
                      _rowKeys    .putIfAbsent(clientId, () => GlobalKey());

                      final isExpanded = _activeClientId == clientId;

                      return KeyedSubtree(
                        key: _rowKeys[clientId],
                        child: SalesEntryRow(
                          // Stable key: clientId, not index
                          key: ValueKey(
                              '${clientId}_${ctrl.selectedDate.value}'),
                          sale:         sale,
                          index:        i,
                          isExpanded:   isExpanded,
                          canEdit:      true,
                          ratePerLiter: settingsCtrl.ratePerLiter.value,
                          litersNode:   _litersNodes[clientId],
                          amountNode:   _amountNodes[clientId],
                          onFocused: () {
                            setState(() => _activeClientId = clientId);
                            _scrollToClientId(clientId);
                          },
                          onMoveToNext: () => _focusRow(i + 1, filtered),
                          onMoveToPrev: () => _focusRow(i - 1, filtered),
                          onSave: (updated) => ctrl.updateSale(updated),
                          onPay: sale.isPayer
                              ? () => _showPaymentDialog(
                                    context,
                                    clientId,
                                    sale.clientName ?? 'Client',
                                  )
                              : null,
                        ),
                      );
                    },
                  ),
          ),

          const Divider(height: 10, thickness: 1, color: Color(0xFFFFCDD2)),
          const SizedBox(height: 40),

          _buildFooter(filtered),
        ]),
      );
    });
  }

  Widget _buildFooter(List<SaleModel> sales) {
    final totalLiters = sales.fold(0.0, (s, e) => s + e.totalLiters);
    final totalAmount = sales
        .where((e) => e.isPayer)
        .fold(0.0, (s, e) => s + e.totalAmount);
    final freeCount = sales.where((e) => !e.isPayer).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: _kRedLight.withOpacity(0.7),
        borderRadius: const BorderRadius.only(
            bottomLeft:  Radius.circular(12),
            bottomRight: Radius.circular(12)),
      ),
      child: Row(children: [
        const SizedBox(width: 52),
        Expanded(
          flex: 5,
          child: Row(children: [
            const Text('CLIENT TOTALS',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _kRed)),
            if (freeCount > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                    '$freeCount free — no billing',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700)),
              ),
            ],
          ]),
        ),
        const Expanded(flex: 1, child: SizedBox.shrink()),
        const Expanded(flex: 2, child: SizedBox.shrink()),
        const Expanded(flex: 2, child: SizedBox.shrink()),
        Expanded(
            flex: 1,
            child: Text('${formatL(totalLiters)} L',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _kRed,
                    fontSize: 15))),
        Expanded(
            flex: 2,
            child: Text('Rs. ${totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _kRed,
                    fontSize: 15))),
        const SizedBox(width: 104),
      ]),
    );
  }

  void _showExportDialog(BuildContext context, SalesController ctrl) {
    final fromCtrl = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(
            DateTime.now().subtract(const Duration(days: 30))));
    final toCtrl = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(DateTime.now()));

    Get.dialog(AlertDialog(
      title: const Text('Export DSR', style: TextStyle(fontSize: 18)),
      content: SizedBox(
        width: 350,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Select date range to export sales data:',
              style: TextStyle(fontSize: 15, color: Colors.black54)),
          const SizedBox(height: 16),
          TextField(
              controller: fromCtrl,
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(
                  labelText: 'From Date', hintText: 'yyyy-mm-dd')),
          const SizedBox(height: 12),
          TextField(
              controller: toCtrl,
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(
                  labelText: 'To Date', hintText: 'yyyy-mm-dd')),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(fontSize: 15))),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
              backgroundColor: _kRed, foregroundColor: Colors.white),
          onPressed: () async {
            Get.back();
            final from = fromCtrl.text.trim();
            final to   = toCtrl.text.trim();

            final results = await Future.wait([
              ctrl.getSalesByRange(from, to),
              CashSaleRepository().getByDateRange(from, to),
              PaymentRepository().getByDateRange(from, to),
            ]);

            await ExcelExporter.exportDSR(
              results[0] as List<SaleModel>,
              from,
              to,
              cashSales: results[1] as List<CashSaleModel>,
              payments:  results[2] as List<PaymentModel>,
            );
          },
          icon: const Icon(Icons.download, size: 18),
          label: const Text('Export', style: TextStyle(fontSize: 15)),
        ),
      ],
    ));
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year &&
        d.month == now.month &&
        d.day == now.day;
  }

  static const _hStyle =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 14);
  static const _hStyleRed =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _kRed);
}// ─────────────────────────────────────────────────────────────────────────────
// _PaymentListTile — inline-editable payment entry inside the payment dialog
// ─────────────────────────────────────────────────────────────────────────────
class _PaymentListTile extends StatefulWidget {
  final PaymentModel payment;
  final PaymentRepository repo;
  final VoidCallback onUpdated;

  const _PaymentListTile({
    required this.payment,
    required this.repo,
    required this.onUpdated,
  });

  @override
  State<_PaymentListTile> createState() => _PaymentListTileState();
}

class _PaymentListTileState extends State<_PaymentListTile> {
  bool _editing = false;
  late TextEditingController _editCtrl;

  @override
  void initState() {
    super.initState();
    _editCtrl = TextEditingController(
        text: widget.payment.amountPaid.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveEdit() async {
    final newAmount = double.tryParse(_editCtrl.text.trim()) ?? 0;
    if (newAmount > 0 && widget.payment.id != null) {
      await widget.repo.updateAmount(widget.payment.id!, newAmount);
      // Refresh billing if open
      if (Get.isRegistered<BillingController>()) {
        final bc = Get.find<BillingController>();
        bc.changeMonth(bc.selectedYear.value, bc.selectedMonth.value);
      }
      widget.onUpdated();
    }
    setState(() => _editing = false);
  }

  Future<void> _delete() async {
    if (widget.payment.id == null) return;
    await widget.repo.delete(widget.payment.id!);
    if (Get.isRegistered<BillingController>()) {
      final bc = Get.find<BillingController>();
      bc.changeMonth(bc.selectedYear.value, bc.selectedMonth.value);
    }
    widget.onUpdated();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        // Date badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(widget.payment.paymentDate,
              style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ),
        const SizedBox(width: 10),

        // Amount — static or editable
        _editing
            ? SizedBox(
                width: 110,
                child: TextField(
                  controller: _editCtrl,
                  autofocus: true,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    prefixText: 'Rs. ',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  ),
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => _saveEdit(),
                ),
              )
            : Text(
                'Rs. ${widget.payment.amountPaid.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),

        // Notes
        if (widget.payment.notes != null && !_editing) ...[
          const SizedBox(width: 8),
          Text(widget.payment.notes!,
              style: const TextStyle(fontSize: 12, color: Colors.black45)),
        ],

        const Spacer(),

        if (_editing) ...[
          // Save
          IconButton(
            icon: const Icon(Icons.check_circle, size: 20,
                color: Colors.green),
            onPressed: _saveEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Save',
          ),
          const SizedBox(width: 6),
          // Cancel edit
          IconButton(
            icon: const Icon(Icons.cancel, size: 20, color: Colors.grey),
            onPressed: () {
              _editCtrl.text =
                  widget.payment.amountPaid.toStringAsFixed(0);
              setState(() => _editing = false);
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Cancel',
          ),
        ] else ...[
          // Edit
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 17,
                color: Colors.black45),
            onPressed: () => setState(() => _editing = true),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Edit amount',
          ),
          const SizedBox(width: 4),
          // Delete
          IconButton(
            icon: Icon(Icons.delete_outline,
                size: 17, color: Colors.red.shade300),
            onPressed: _delete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Delete payment',
          ),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SalesEntryRow
// ─────────────────────────────────────────────────────────────────────────────
class SalesEntryRow extends StatefulWidget {
  final SaleModel  sale;
  final int        index;
  final bool       isExpanded;
  final bool       canEdit;
  final double     ratePerLiter;
  final FocusNode? litersNode;
  final FocusNode? amountNode;
  final VoidCallback?       onFocused;
  final VoidCallback?       onMoveToNext;
  final VoidCallback?       onMoveToPrev;
  final Function(SaleModel) onSave;
  final VoidCallback?       onPay;   // null for free clients

  const SalesEntryRow({
    super.key,
    required this.sale,
    required this.index,
    this.isExpanded = false,
    required this.canEdit,
    required this.ratePerLiter,
    this.litersNode,
    this.amountNode,
    this.onFocused,
    this.onMoveToNext,
    this.onMoveToPrev,
    required this.onSave,
    this.onPay,
  });

  @override
  State<SalesEntryRow> createState() => _SalesEntryRowState();
}

class _SalesEntryRowState extends State<SalesEntryRow> {
  late TextEditingController _litersCtrl;
  late TextEditingController _extraAmountCtrl;

  bool _savingFromSubmit = false;

  late final FocusNode _ownLitersNode;
  late final FocusNode _ownAmountNode;

  bool get _isFree => !widget.sale.isPayer;

  FocusNode get _lNode => widget.litersNode ?? _ownLitersNode;
  FocusNode get _aNode => widget.amountNode ?? _ownAmountNode;

  void _onLNodeFocus()   { if (_lNode.hasFocus) widget.onFocused?.call(); }
  void _onANodeFocus()   { if (_aNode.hasFocus) widget.onFocused?.call(); }
  void _onLNodeUnfocus() { if (!_lNode.hasFocus && !_savingFromSubmit) _triggerAutoSave(); }
  void _onANodeUnfocus() { if (!_aNode.hasFocus && !_savingFromSubmit) _triggerAutoSave(); }

  void _attachListeners() {
    _lNode.addListener(_onLNodeFocus);
    _lNode.addListener(_onLNodeUnfocus);
    _aNode.addListener(_onANodeFocus);
    _aNode.addListener(_onANodeUnfocus);
  }

  void _detachListeners(FocusNode oldL, FocusNode oldA) {
    oldL.removeListener(_onLNodeFocus);
    oldL.removeListener(_onLNodeUnfocus);
    oldA.removeListener(_onANodeFocus);
    oldA.removeListener(_onANodeUnfocus);
  }

  /// For existing saved rows, reconstruct the displayed value.
  /// For brand-new rows (id == null, nothing recorded), start EMPTY — no prefill.
  String _initialLitersText() {
    final isNewRow = widget.sale.id == null &&
        !widget.sale.takenAllocated &&
        widget.sale.extraLiters == 0.0;

    // No pre-fill for new rows — operator enters the actual amount taken.
    if (isNewRow) return '';

    // Reconstruct actual liters from stored values (preserves old data).
    final recorded = (widget.sale.takenAllocated
            ? widget.sale.allocatedLiters
            : 0.0) +
        widget.sale.extraLiters;
    return recorded > 0 ? formatL(recorded) : '';
  }

  @override
  void initState() {
    super.initState();
    _litersCtrl      = TextEditingController(text: _initialLitersText());
    _extraAmountCtrl = TextEditingController(
        text: widget.sale.extraAmount > 0
            ? widget.sale.extraAmount.toStringAsFixed(0)
            : '');
    _ownLitersNode = FocusNode();
    _ownAmountNode = FocusNode();
    _attachListeners();
  }

  @override
  void didUpdateWidget(covariant SalesEntryRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldL = oldWidget.litersNode ?? _ownLitersNode;
    final oldA = oldWidget.amountNode ?? _ownAmountNode;
    final newL = widget.litersNode    ?? _ownLitersNode;
    final newA = widget.amountNode    ?? _ownAmountNode;
    if (oldL != newL || oldA != newA) {
      _detachListeners(oldL, oldA);
      _attachListeners();
    }
  }

  @override
  void dispose() {
    _litersCtrl.dispose();
    _extraAmountCtrl.dispose();
    _detachListeners(_lNode, _aNode);
    _ownLitersNode.dispose();
    _ownAmountNode.dispose();
    super.dispose();
  }

  Future<void> _triggerAutoSave() async {
    if (!widget.canEdit) return;
    try { await widget.onSave(_buildUpdatedSale()); } catch (_) {}
  }

  SaleModel _buildUpdatedSale() {
    final inputLiters = double.tryParse(_litersCtrl.text.trim()) ?? 0.0;
    final allocated   = widget.sale.allocatedLiters;

    bool   newTaken;
    double newExtraLiters;

    if (inputLiters >= allocated) {
      newTaken       = true;
      newExtraLiters = inputLiters - allocated;
    } else {
      newTaken       = false;
      newExtraLiters = inputLiters;
    }

    final newExtraAmount = _isFree
        ? 0.0
        : (double.tryParse(_extraAmountCtrl.text.trim()) ?? 0.0);

    return SaleModel(
      id:              widget.sale.id,
      clientId:        widget.sale.clientId,
      saleDate:        widget.sale.saleDate,
      allocatedLiters: widget.sale.allocatedLiters,
      takenAllocated:  newTaken,
      extraLiters:     newExtraLiters,
      extraAmount:     newExtraAmount,
      ratePerLiter:    widget.ratePerLiter,
      createdAt:       widget.sale.createdAt,
      clientName:      widget.sale.clientName,
      isPayer:         widget.sale.isPayer,
    );
  }

  double get _inputLiters =>
      double.tryParse(_litersCtrl.text.trim()) ?? 0.0;

  double get _extraAmountLiters {
    if (_isFree) return 0;
    final ea = double.tryParse(_extraAmountCtrl.text.trim()) ?? 0;
    return (widget.ratePerLiter > 0 && ea > 0)
        ? ea / widget.ratePerLiter
        : 0;
  }

  double get _totalLiters  => _inputLiters + _extraAmountLiters;

  double get _totalAmount {
    if (_isFree) return 0;
    return _inputLiters * widget.ratePerLiter +
        (double.tryParse(_extraAmountCtrl.text.trim()) ?? 0.0);
  }

  KeyEventResult _handleFieldKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        widget.onMoveToNext?.call();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        widget.onMoveToPrev?.call();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final expanded  = widget.isExpanded;
    final isEven    = widget.index % 2 == 0;

    final rowPadV   = expanded ? 25.0 : 5.0;
    final nameFSize = expanded ? 40.0 : 14.0;
    final dataFSize = expanded ? 30.0 : 13.0;
    final totFSize  = expanded ? 25.0 : 14.0;
    final inFSize   = expanded ? 30.0 : 13.0;

    final Color secondaryColor =
        expanded ? Colors.black87 : Colors.black54;
    final Color mutedColor =
        expanded ? Colors.black54 : Colors.black38;

    final Color rowBg;
    if (expanded && _isFree) {
      rowBg = Colors.orange.withOpacity(0.08);
    } else if (expanded) {
      rowBg = _kRedLight;
    } else if (_isFree) {
      rowBg = Colors.orange.withOpacity(0.03);
    } else {
      rowBg = isEven ? Colors.white : const Color(0xFFFAFAFA);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: rowBg,
        border: Border(
          left: BorderSide(
              color: expanded ? _kRed : Colors.transparent,
              width: expanded ? 4 : 0),
        ),
        boxShadow: expanded
            ? [
                BoxShadow(
                  color: _kRed.withOpacity(0.07),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ]
            : [],
      ),
      padding: EdgeInsets.fromLTRB(
          expanded ? 10 : 12, rowPadV, 10, rowPadV),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          // ── # ──────────────────────────────────────────────────────────
          SizedBox(
            width: 52,
            child: Text(
              '${widget.index + 1}',
              style: TextStyle(
                color: expanded
                    ? _kRed
                    : (_isFree ? Colors.orange : Colors.black45),
                fontSize: dataFSize,
                fontWeight:
                    expanded ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),

          // ── Client name — flex 5 ───────────────────────────────────────
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.sale.clientName ?? 'Client',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: nameFSize,
                        color: _isFree
                            ? Colors.orange.shade700
                            : (expanded ? _kRed : Colors.black87),
                      ),
                    ),
                  ),
                  if (_isFree) ...[
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('FREE',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Allocated — flex 1 ────────────────────────────────────────
          Expanded(
            flex: 1,
            child: Text(
              '${formatL(widget.sale.allocatedLiters)}L',
              style: TextStyle(
                color: _kRed.withOpacity(0.7),
                fontSize: dataFSize,
                fontWeight:
                    expanded ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),

          // ── Liters Taken input — flex 2 (no hint, no prefill) ─────────
          // Enter always moves to the NEXT row's liters field.
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Focus(
                onKeyEvent: (_, event) => _handleFieldKeyEvent(event),
                child: TextField(
                  controller: _litersCtrl,
                  focusNode: _lNode,
                  style: TextStyle(
                    fontSize: inFSize,
                    color: Colors.black87,
                    fontWeight:
                        expanded ? FontWeight.w600 : FontWeight.normal,
                  ),
                  decoration: InputDecoration(
                    // No hintText — no hint of allocated, no prefill
                    suffixText: 'L',
                    suffixStyle: TextStyle(color: secondaryColor),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: expanded ? 12 : 7),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) async {
                    _savingFromSubmit = true;
                    await _triggerAutoSave();
                    _savingFromSubmit = false;
                    // Always move to NEXT row's liters (not extra Rs)
                    widget.onMoveToNext?.call();
                  },
                ),
              ),
            ),
          ),

          // ── Extra Rs — flex 2 (equal to Liters Taken) ─────────────────
          Expanded(
            flex: 2,
            child: _isFree
                ? Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text('—',
                        style: TextStyle(
                            color: Colors.orange.shade300,
                            fontSize: dataFSize)),
                  )
                : Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Focus(
                          onKeyEvent: (_, event) =>
                              _handleFieldKeyEvent(event),
                          child: TextField(
                            controller: _extraAmountCtrl,
                            focusNode: _aNode,
                            style: TextStyle(
                              fontSize: inFSize,
                              color: Colors.black87,
                              fontWeight: expanded
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle:
                                  TextStyle(color: mutedColor),
                              prefixText: 'Rs.',
                              prefixStyle:
                                  TextStyle(color: secondaryColor),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: expanded ? 12 : 7),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) async {
                              _savingFromSubmit = true;
                              await _triggerAutoSave();
                              _savingFromSubmit = false;
                              widget.onMoveToNext?.call();
                            },
                          ),
                        ),
                        if (_extraAmountLiters > 0)
                          Text(
                            '≈${formatL(_extraAmountLiters)}L',
                            style: TextStyle(
                              fontSize: expanded ? 12.0 : 10.0,
                              color: Colors.teal,
                            ),
                          ),
                      ],
                    ),
                  ),
          ),

          // ── Total liters — flex 1 ──────────────────────────────────────
          Expanded(
            flex: 1,
            child: Text(
              '${formatL(_totalLiters)} L',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _isFree ? Colors.orange.shade700 : _kRed,
                fontSize: totFSize,
              ),
            ),
          ),

          // ── Total amount — flex 2 ──────────────────────────────────────
          Expanded(
            flex: 2,
            child: _isFree
                ? Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.card_giftcard,
                        size: 14, color: Colors.orange.shade400),
                    const SizedBox(width: 3),
                    Text('Free',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade500,
                          fontSize: totFSize,
                        )),
                  ])
                : Text(
                    'Rs.${_totalAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _kRed,
                      fontSize: totFSize,
                    ),
                  ),
          ),

          // ── Payment button — fixed 104px ──────────────────────────────
          SizedBox(
            width: 104,
            child: _isFree
                ? const SizedBox.shrink()
                : OutlinedButton.icon(
                    onPressed: widget.onPay,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: expanded ? _kRed : const Color(0xFFFFCDD2)),
                      foregroundColor: _kRed,
                      backgroundColor: expanded
                          ? _kRed.withOpacity(0.05)
                          : Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 13),
                    label: Text(
                      'Pay',
                      style: TextStyle(
                          fontSize: expanded ? 13 : 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Cash Sales Card ───────────────────────────────────────────────────────────
class _CashSalesCard extends StatefulWidget {
  final SalesController    ctrl;
  final SettingsController settingsCtrl;
  const _CashSalesCard(
      {required this.ctrl, required this.settingsCtrl});

  @override
  State<_CashSalesCard> createState() => _CashSalesCardState();
}

class _CashSalesCardState extends State<_CashSalesCard> {
  final _cashCtrl  = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isAdding   = false;

  @override
  void dispose() {
    _cashCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cashList    = widget.ctrl.cashSales;
      final totalCash   = widget.ctrl.totalCashReceived;
      final totalLiters = widget.ctrl.totalCashLiters;
      final rate        = widget.settingsCtrl.ratePerLiter.value;
      final previewL =
          rate > 0 ? (double.tryParse(_cashCtrl.text) ?? 0) / rate : 0.0;

      return Card(
        child: Theme(
          data: Theme.of(context)
              .copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.point_of_sale,
                  color: Colors.teal, size: 22),
            ),
            title: Row(children: [
              const Text('Cash Sales',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 8),
              const Text('(Milk sold for cash)',
                  style: TextStyle(color: Colors.black45, fontSize: 14)),
              const Spacer(),
              if (cashList.isNotEmpty) ...[
                _cashChip('${formatL(totalLiters)} L deducted',
                    Colors.teal),
                const SizedBox(width: 8),
                _cashChip(
                    'Rs. ${totalCash.toStringAsFixed(0)} received',
                    Colors.green),
              ],
            ]),
            children: [
              const Divider(height: 1),
              Container(
                color: Colors.teal.withOpacity(0.03),
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  SizedBox(
                    width: 210,
                    child: TextField(
                      controller: _cashCtrl,
                      style: const TextStyle(fontSize: 15),
                      decoration: const InputDecoration(
                        labelText: 'Cash Received (Rs.) *',
                        labelStyle: TextStyle(fontSize: 14),
                        prefixText: 'Rs. ',
                        hintText: '0',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.teal.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Liters to Deduct',
                            style: TextStyle(
                                fontSize: 12, color: Colors.black45)),
                        Text('${formatL(previewL)} L',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                                fontSize: 17)),
                        Text('at Rs.${rate.toStringAsFixed(0)}/L',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black38)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 230,
                    child: TextField(
                      controller: _notesCtrl,
                      style: const TextStyle(fontSize: 15),
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                        labelStyle: TextStyle(fontSize: 14),
                        hintText: 'e.g. walk-in buyer',
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                    ),
                    onPressed: () async {
                      final cash =
                          double.tryParse(_cashCtrl.text) ?? 0;
                      if (cash <= 0) return;
                      setState(() => _isAdding = true);
                      await widget.ctrl.addCashSale(CashSaleModel(
                        saleDate: widget.ctrl.selectedDate.value
                            .toIso8601String()
                            .substring(0, 10),
                        cashAmount:   cash,
                        ratePerLiter: rate,
                        notes: _notesCtrl.text.trim().isEmpty
                            ? null
                            : _notesCtrl.text.trim(),
                        createdAt: DateTime.now().toIso8601String(),
                      ));
                      _cashCtrl.clear();
                      _notesCtrl.clear();
                      setState(() => _isAdding = false);
                    },
                    icon: _isAdding
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.add, size: 18),
                    label: const Text('Add',
                        style: TextStyle(fontSize: 15)),
                  ),
                ]),
              ),

              if (cashList.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No cash sales for this date.',
                      style: TextStyle(
                          color: Colors.black45, fontSize: 15)),
                )
              else
                ...cashList.asMap().entries.map((entry) {
                  final i  = entry.key;
                  final cs = entry.value;
                  return Container(
                    color: i % 2 == 0
                        ? Colors.white
                        : const Color(0xFFF9FAFA),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    child: Row(children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Text(cs.notes ?? 'Cash sale',
                              style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14))),
                      const SizedBox(width: 16),
                      _valueCell('Cash Received',
                          'Rs. ${cs.cashAmount.toStringAsFixed(0)}',
                          Colors.green),
                      const SizedBox(width: 24),
                      _valueCell('Liters Deducted',
                          '${formatL(cs.litersFromCash)} L',
                          Colors.teal),
                      const SizedBox(width: 24),
                      _valueCell('Rate Used',
                          'Rs. ${cs.ratePerLiter.toStringAsFixed(0)}/L',
                          Colors.black45),
                      if (cs.id != null) ...[
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: () =>
                              widget.ctrl.deleteCashSale(cs.id!),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppTheme.danger.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.delete_outline,
                                size: 18, color: AppTheme.danger),
                          ),
                        ),
                      ],
                    ]),
                  );
                }),

              if (cashList.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 11),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.only(
                        bottomLeft:  Radius.circular(12),
                        bottomRight: Radius.circular(12)),
                  ),
                  child: Row(children: [
                    const Text('CASH TOTALS',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const Spacer(),
                    Text('${formatL(totalLiters)} L deducted from stock',
                        style: const TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(width: 28),
                    Text('Rs. ${totalCash.toStringAsFixed(0)} total cash',
                        style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ]),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _cashChip(String label, Color color) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      );

  Widget _valueCell(String label, String value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black38)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15, color: color)),
        ],
      );
}