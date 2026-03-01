// lib/views/billing/billing_view.dart
import 'package:dairy_farm_app/app/utils/format_utils.dart'; // ← added import
import 'package:dairy_farm_app/data/models/billing_summary_model.dart';
import 'package:dairy_farm_app/data/models/payment_model.dart';
import 'package:dairy_farm_app/data/models/sale_model.dart';
import 'package:dairy_farm_app/data/repositories/payment_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../app/theme/app_theme.dart';
import '../../controllers/billing_controller.dart';
import '../../controllers/settings_controller.dart';

class BillingView extends StatelessWidget {
  const BillingView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BillingController>();
    final settingsCtrl = Get.find<SettingsController>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Billing Reports',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  onPressed: () => _printAllBills(context, ctrl, settingsCtrl),
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('Print All Bills (A4)'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Obx(() => Row(
                  children: [
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<int>(
                        value: ctrl.selectedMonth.value,
                        decoration: const InputDecoration(labelText: 'Month'),
                        items: List.generate(
                          12,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(DateFormat('MMMM').format(DateTime(2024, i + 1))),
                          ),
                        ),
                        onChanged: (v) => ctrl.changeMonth(ctrl.selectedYear.value, v ?? 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: DropdownButtonFormField<int>(
                        value: ctrl.selectedYear.value,
                        decoration: const InputDecoration(labelText: 'Year'),
                        items: List.generate(
                          5,
                          (i) => DropdownMenuItem(
                            value: DateTime.now().year - i,
                            child: Text('${DateTime.now().year - i}'),
                          ),
                        ),
                        onChanged: (v) => ctrl.changeMonth(
                          v ?? DateTime.now().year,
                          ctrl.selectedMonth.value,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Only payer clients shown · Non-payers excluded from billing',
                      style: TextStyle(color: Colors.black45, fontSize: 13),
                    ),
                  ],
                )),
            const SizedBox(height: 20),

            Expanded(
              child: Card(
                child: Obx(() {
                  if (ctrl.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (ctrl.billingSummary.isEmpty) {
                    return const Center(
                      child: Text(
                        'No billing data for selected month.',
                        style: TextStyle(color: Colors.black45),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      _TableHeader(),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.separated(
                          itemCount: ctrl.billingSummary.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                          itemBuilder: (ctx, i) {
                            final s = ctrl.billingSummary[i];
                            return _BillingRow(
                              summary: s,
                              index: i,
                              onPay: () => _showPayDialog(ctx, ctrl, s),
                              onEditPayments: () => _showEditPaymentsDialog(ctx, ctrl, s),
                            );
                          },
                        ),
                      ),
                      _GrandTotalFooter(ctrl: ctrl),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Record new payment dialog ─────────────────────────────────────────────
  static void _showPayDialog(BuildContext context, BillingController ctrl, BillingSummaryModel s) {
    final amountCtrl = TextEditingController(
      text: s.remainingBalance > 0 ? s.remainingBalance.toStringAsFixed(0) : '',
    );
    final notesCtrl = TextEditingController();
    final monthName = DateFormat('MMMM yyyy').format(
      DateTime(ctrl.selectedYear.value, ctrl.selectedMonth.value),
    );

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.payment, color: AppTheme.primary, size: 22),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Record Payment — ${s.clientName ?? "Client"}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _dialogRow('Month', monthName),
                    _dialogRow('This Month\'s Bill', 'Rs. ${s.currentMonthAmount.toStringAsFixed(0)}'),
                    if (s.previousPending > 0)
                      _dialogRow(
                        'Previous Pending',
                        'Rs. ${s.previousPending.toStringAsFixed(0)}',
                        valueColor: Colors.orange.shade700,
                      ),
                    _dialogRow('Total Due', 'Rs. ${s.totalDue.toStringAsFixed(0)}', bold: true),
                    if (s.amountPaidThisMonth > 0)
                      _dialogRow(
                        'Already Paid This Month',
                        'Rs. ${s.amountPaidThisMonth.toStringAsFixed(0)}',
                        valueColor: Colors.green,
                      ),
                    _dialogRow(
                      'Remaining Balance',
                      'Rs. ${s.remainingBalance.toStringAsFixed(0)}',
                      bold: true,
                      valueColor: s.remainingBalance > 0 ? Colors.red.shade700 : Colors.green,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                autofocus: true,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Payment Amount (Rs.) *',
                  prefixText: 'Rs. ',
                  hintText: '0',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'e.g. cash payment',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(fontSize: 15)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount <= 0) return;
              Get.back();
              await ctrl.addPayment(
                clientId: s.clientId,
                amount: amount,
                notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
              );
              Get.snackbar(
                'Payment Recorded',
                'Rs. ${amount.toStringAsFixed(0)} recorded for ${s.clientName}',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green.shade50,
              );
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Record Payment', style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }

  // ── Edit existing payments dialog ─────────────────────────────────────────
  static Future<void> _showEditPaymentsDialog(
    BuildContext context,
    BillingController ctrl,
    BillingSummaryModel s,
  ) async {
    final repo = PaymentRepository();
    final year = ctrl.selectedYear.value;
    final month = ctrl.selectedMonth.value;
    final monthName = DateFormat('MMMM yyyy').format(DateTime(year, month));

    await Get.dialog(
      StatefulBuilder(
        builder: (ctx, ss) {
          Future<List<PaymentModel>> paymentsFuture =
              repo.getByClientAndMonth(s.clientId, year, month);

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.edit_note, color: AppTheme.primary, size: 22),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Edit Payments — ${s.clientName ?? "Client"} · $monthName',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: FutureBuilder<List<PaymentModel>>(
                future: paymentsFuture,
                builder: (ctx2, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 80,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!snap.hasData || snap.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No payments recorded for this month.',
                        style: TextStyle(color: Colors.black45),
                      ),
                    );
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: snap.data!
                        .map(
                          (p) => _EditablePaymentTile(
                            payment: p,
                            repo: repo,
                            onUpdated: () {
                              ss(() {
                                paymentsFuture = repo.getByClientAndMonth(s.clientId, year, month);
                              });
                              ctrl.changeMonth(year, month);
                            },
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Done', style: TextStyle(fontSize: 15)),
              ),
            ],
          );
        },
      ),
      barrierDismissible: true,
    );
  }

  static Widget _dialogRow(String label, String value,
      {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ── Print all bills ───────────────────────────────────────────────────────
  Future<void> _printAllBills(
    BuildContext context,
    BillingController ctrl,
    SettingsController settingsCtrl,
  ) async {
    if (ctrl.billingSummary.isEmpty) {
      Get.snackbar('No Data', 'No billing data to print', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final monthName = DateFormat('MMMM yyyy').format(
      DateTime(ctrl.selectedYear.value, ctrl.selectedMonth.value),
    );

    final pdf = pw.Document();
    final clients = ctrl.billingSummary;

    const billsPerPage = 6;
    const cols = 2;
    const rows = 3;

    for (int page = 0; page < (clients.length / billsPerPage).ceil(); page++) {
      final pageClients = clients.skip(page * billsPerPage).take(billsPerPage).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(8),
          build: (pw.Context ctx) {
            return pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: List.generate(cols, (col) {
                return pw.Expanded(
                  child: pw.Column(
                    children: List.generate(rows, (row) {
                      final idx = row * cols + col;
                      final hasClient = idx < pageClients.length;
                      return pw.Expanded(
                        child: pw.Container(
                          margin: const pw.EdgeInsets.all(4),
                          padding: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: hasClient
                              ? _buildPdfClientBill(
                                  pageClients[idx],
                                  settingsCtrl.farmName.value,
                                  monthName,
                                  settingsCtrl.ratePerLiter.value,
                                )
                              : pw.SizedBox(),
                        ),
                      );
                    }),
                  ),
                );
              }),
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Bills_${DateFormat('MMM_yyyy').format(
        DateTime(ctrl.selectedYear.value, ctrl.selectedMonth.value),
      )}',
    );
  }

  // ── Individual bill layout in PDF ─────────────────────────────────────────
  pw.Widget _buildPdfClientBill(
    BillingSummaryModel s,
    String farmName,
    String monthName,
    double rate,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Farm name (English)
        pw.Text(
          farmName.isNotEmpty ? farmName : 'Dairy Farm',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.4,
          ),
          textAlign: pw.TextAlign.center,
        ),

        pw.SizedBox(height: 4),

        // Month
        pw.Text(
          monthName,
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),

        pw.SizedBox(height: 8),
        pw.Divider(height: 8, color: PdfColors.grey400),

        // Client name
        pw.Container(
          width: double.infinity,
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(
            s.clientName ?? 'Client',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
        ),

        pw.SizedBox(height: 10),

        // Milk & amount rows
        _pdfRow('Allocated Milk Taken:', '${formatL(s.allocatedLiters)} L'),
        _pdfRow('Extra Liters:', '${formatL(s.extraLiters)} L'),
        _pdfRow('Rate per Liter:', 'Rs. ${rate.toStringAsFixed(0)}'),
        _pdfRow('Extra Amount:', 'Rs. ${s.extraAmount.toStringAsFixed(0)}'),

        pw.Divider(height: 6, color: PdfColors.grey400),

        _pdfRow(
          'TOTAL MILK:',
          '${formatL(s.totalLiters)} L',
          bold: true,
          fontSize: 9.5,
        ),
        _pdfRow(
          'THIS MONTH BILL:',
          'Rs. ${s.currentMonthAmount.toStringAsFixed(0)}',
          bold: true,
          fontSize: 11,
        ),

        if (s.previousPending > 0) ...[
          pw.Divider(height: 6, color: PdfColors.grey300),
          _pdfRow(
            'Previous Pending:',
            'Rs. ${s.previousPending.toStringAsFixed(0)}',
            color: PdfColors.orange800,
            bold: true,
            fontSize: 9,
          ),
          _pdfRow(
            'TOTAL DUE:',
            'Rs. ${s.totalDue.toStringAsFixed(0)}',
            bold: true,
            fontSize: 10.5,
            color: PdfColors.red900,
          ),
        ],

        if (s.amountPaidThisMonth > 0) ...[
          pw.SizedBox(height: 4),
          _pdfRow(
            'Paid This Month:',
            'Rs. ${s.amountPaidThisMonth.toStringAsFixed(0)}',
            color: PdfColors.green800,
          ),
          _pdfRow(
            'BALANCE DUE:',
            'Rs. ${s.remainingBalance.toStringAsFixed(0)}',
            bold: true,
            fontSize: 10.5,
            color: PdfColors.red900,
          ),
        ] else if (s.remainingBalance <= 0 && s.totalDue > 0) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            'Fully Paid ✓',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.green800,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],

        pw.Spacer(),

        pw.Divider(height: 6, color: PdfColors.grey300),
        pw.Text(
          'Signature: ___________________________',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ],
    );
  }

  pw.Widget _pdfRow(
    String label,
    String value, {
    bool bold = false,
    double fontSize = 8.5,
    PdfColor? color,
  }) {
    final style = pw.TextStyle(
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontSize: fontSize,
      color: color,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _EditablePaymentTile  — used in the Edit Payments dialog
// ─────────────────────────────────────────────────────────────────────────────
class _EditablePaymentTile extends StatefulWidget {
  final PaymentModel payment;
  final PaymentRepository repo;
  final VoidCallback onUpdated;

  const _EditablePaymentTile({
    required this.payment,
    required this.repo,
    required this.onUpdated,
  });

  @override
  State<_EditablePaymentTile> createState() =>
      _EditablePaymentTileState();
}

class _EditablePaymentTileState
    extends State<_EditablePaymentTile> {
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
      widget.onUpdated();
    }
    setState(() => _editing = false);
  }

  Future<void> _delete() async {
    if (widget.payment.id == null) return;
    final confirmed = await Get.dialog<bool>(AlertDialog(
      title: const Text('Delete Payment?',
          style: TextStyle(fontSize: 16)),
      content: Text(
          'Remove Rs. ${widget.payment.amountPaid.toStringAsFixed(0)} '
          'from ${widget.payment.paymentDate}?'),
      actions: [
        TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel')),
        ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed: () => Get.back(result: true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white))),
      ],
    ));
    if (confirmed == true) {
      await widget.repo.delete(widget.payment.id!);
      widget.onUpdated();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        // Date
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(widget.payment.paymentDate,
              style: const TextStyle(
                  fontSize: 12, color: Colors.black54)),
        ),
        const SizedBox(width: 12),

        // Amount — static or editable
        _editing
            ? SizedBox(
                width: 130,
                child: TextField(
                  controller: _editCtrl,
                  autofocus: true,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    prefixText: 'Rs. ',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 6, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => _saveEdit(),
                ),
              )
            : Text(
                'Rs. ${widget.payment.amountPaid.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),

        // Notes
        if (widget.payment.notes != null && !_editing) ...[
          const SizedBox(width: 10),
          Text(widget.payment.notes!,
              style: const TextStyle(
                  fontSize: 13, color: Colors.black45)),
        ],

        const Spacer(),

        if (_editing) ...[
          TextButton.icon(
            onPressed: _saveEdit,
            icon: const Icon(Icons.check_circle,
                size: 18, color: Colors.green),
            label: const Text('Save',
                style: TextStyle(color: Colors.green)),
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6)),
          ),
          TextButton(
            onPressed: () {
              _editCtrl.text =
                  widget.payment.amountPaid.toStringAsFixed(0);
              setState(() => _editing = false);
            },
            child: const Text('Cancel',
                style: TextStyle(color: Colors.black45)),
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6)),
          ),
        ] else ...[
          OutlinedButton.icon(
            onPressed: () => setState(() => _editing = true),
            icon: const Icon(Icons.edit_outlined, size: 15),
            label: const Text('Edit',
                style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: BorderSide(
                  color: AppTheme.primary.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline, size: 15),
            label: const Text('Delete',
                style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade600,
              side: BorderSide(color: Colors.red.shade200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ]),
    );
  }
}

// ── Table Header ──────────────────────────────────────────────────────────────
class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFE8F5E9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(children: const [
        SizedBox(width: 36, child: Text('#', style: _hStyle)),
        Expanded(flex: 3, child: Text('Client', style: _hStyle)),
        Expanded(flex: 2, child: Text('Alloc. Taken', style: _hStyle)),
        Expanded(flex: 2, child: Text('Extra L', style: _hStyle)),
        Expanded(flex: 2, child: Text('Extra Rs.', style: _hStyle)),
        Expanded(flex: 2, child: Text('Total Liters', style: _hStyleGreen)),
        Expanded(flex: 2, child: Text('This Month', style: _hStyleGreen)),
        Expanded(flex: 2, child: Text('Prev. Pending', style: _hStyleOrange)),
        Expanded(flex: 2, child: Text('Total Due', style: _hStyleRed)),
        Expanded(flex: 2, child: Text('Paid', style: _hStyle)),
        Expanded(flex: 2, child: Text('Remaining', style: _hStyleRed)),
        SizedBox(width: 120, child: Text('', style: _hStyle)),
      ]),
    );
  }

  static const _hStyle =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 13);
  static const _hStyleGreen = TextStyle(
      fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary);
  static const _hStyleOrange = TextStyle(
      fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange);
  static const _hStyleRed = TextStyle(
      fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red);
}

// ── Billing Row ───────────────────────────────────────────────────────────────
// ── Billing Row ───────────────────────────────────────────────────────────────
class _BillingRow extends StatelessWidget {
  final BillingSummaryModel summary;
  final int index;
  final VoidCallback onPay;
  final VoidCallback onEditPayments;

  const _BillingRow({
    required this.summary,
    required this.index,
    required this.onPay,
    required this.onEditPayments,
  });

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final isEven = index % 2 == 0;
    final isPaid = s.remainingBalance <= 0 && s.totalDue > 0;
    final hasPending = s.previousPending > 0;
    final hasPaid = s.amountPaidThisMonth > 0;

    return Container(
      color: isEven ? Colors.white : const Color(0xFFFAFAFA),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${index + 1}',
              style: const TextStyle(color: Colors.black38, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              s.clientName ?? '—',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatL(s.allocatedLiters),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              s.extraLiters > 0 ? formatL(s.extraLiters) : '—',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              s.extraAmount > 0 ? 'Rs. ${s.extraAmount.toStringAsFixed(0)}' : '—',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatL(s.totalLiters),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Rs. ${s.currentMonthAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: hasPending
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text(
                      'Rs. ${s.previousPending.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  )
                : const Text(
                    '—',
                    style: TextStyle(color: Colors.black38, fontSize: 13),
                  ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Rs. ${s.totalDue.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: s.totalDue > 0 ? Colors.red.shade700 : Colors.black54,
              ),
            ),
          ),

          // Paid column — with Edit button
          Expanded(
            flex: 2,
            child: hasPaid
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Rs. ${s.amountPaidThisMonth.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: onEditPayments,
                        borderRadius: BorderRadius.circular(4),
                        child: Tooltip(
                          message: 'Edit payment',
                          child: Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: Colors.green.shade400,
                          ),
                        ),
                      ),
                    ],
                  )
                : const Text(
                    '—',
                    style: TextStyle(color: Colors.black38, fontSize: 13),
                  ),
          ),

          // Remaining
          Expanded(
            flex: 2,
            child: isPaid
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 15, color: Colors.green),
                      const SizedBox(width: 4),
                      const Text(
                        'Paid',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Rs. ${s.remainingBalance.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: s.remainingBalance > 0 ? Colors.red.shade700 : Colors.green,
                    ),
                  ),
          ),

          // Actions
          SizedBox(
            width: 120,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isPaid)
                  SizedBox(
                    width: 56,
                    child: ElevatedButton(
                      onPressed: onPay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Pay',
                        style: TextStyle(fontSize: 13, color: Colors.white),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 56),
                const SizedBox(width: 6),
                if (hasPaid)
                  SizedBox(
                    width: 56,
                    child: OutlinedButton(
                      onPressed: onEditPayments,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: BorderSide(color: AppTheme.primary.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Edit', style: TextStyle(fontSize: 12)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}// ── Grand Total Footer ────────────────────────────────────────────────────────
// ── Grand Total Footer ────────────────────────────────────────────────────────
class _GrandTotalFooter extends StatelessWidget {
  final BillingController ctrl;
  const _GrandTotalFooter({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFE8F5E9),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'GRAND TOTAL',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const Spacer(),
          _footerChip(
            '${formatL(ctrl.grandTotalLiters)} L',
            AppTheme.primary,
          ),
          const SizedBox(width: 12),
          _footerChip(
            'Bill: Rs. ${ctrl.grandTotalCurrentBill.toStringAsFixed(0)}',
            AppTheme.primary,
          ),
          if (ctrl.grandTotalPreviousPending > 0) ...[
            const SizedBox(width: 12),
            _footerChip(
              'Pending: Rs. ${ctrl.grandTotalPreviousPending.toStringAsFixed(0)}',
              Colors.orange,
            ),
          ],
          const SizedBox(width: 12),
          _footerChip(
            'Due: Rs. ${ctrl.grandTotalDue.toStringAsFixed(0)}',
            Colors.red.shade700,
          ),
          if (ctrl.grandTotalPaid > 0) ...[
            const SizedBox(width: 12),
            _footerChip(
              'Paid: Rs. ${ctrl.grandTotalPaid.toStringAsFixed(0)}',
              Colors.green,
            ),
          ],
          const SizedBox(width: 12),
          _footerChip(
            'Remaining: Rs. ${ctrl.grandTotalRemaining.toStringAsFixed(0)}',
            Colors.red.shade900,
            bold: true,
          ),
        ],
      ),
    );
  }

  static Widget _footerChip(String label, Color color, {bool bold = false}) {
    return Text(
      label,
      style: TextStyle(
        fontWeight: bold ? FontWeight.w900 : FontWeight.bold,
        color: color,
        fontSize: bold ? 15 : 13,
      ),
    );
  }
}