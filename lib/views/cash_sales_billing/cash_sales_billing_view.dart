// ============================================================
// lib/views/cash_sales_billing/cash_sales_billing_view.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../app/theme/app_theme.dart';
import '../../app/utils/excel_exporter.dart';
import '../../controllers/cash_sales_billing_controller.dart';
import '../../controllers/settings_controller.dart';

class CashSalesBillingView extends StatelessWidget {
  const CashSalesBillingView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CashSalesBillingController>();
    final settingsCtrl = Get.find<SettingsController>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Row(
              children: [
                const Text('Cash Sales Report',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () =>
                      _showExportDialog(context, ctrl),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Export Excel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary),
                  onPressed: () =>
                      _printReport(context, ctrl, settingsCtrl),
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('Print Report'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Month / Year selector ───────────────────────────────────────
            Obx(() => Row(children: [
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<int>(
                      value: ctrl.selectedMonth.value,
                      decoration: const InputDecoration(labelText: 'Month'),
                      items: List.generate(
                          12,
                          (i) => DropdownMenuItem(
                              value: i + 1,
                              child: Text(DateFormat('MMMM')
                                  .format(DateTime(2024, i + 1))))),
                      onChanged: (v) =>
                          ctrl.changeMonth(ctrl.selectedYear.value, v ?? 1),
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
                              child: Text('${DateTime.now().year - i}'))),
                      onChanged: (v) => ctrl.changeMonth(
                          v ?? DateTime.now().year, ctrl.selectedMonth.value),
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Text('Daily summary of cash milk sales',
                      style: TextStyle(color: Colors.black45)),
                ])),
            const SizedBox(height: 16),

            // ── KPI row ─────────────────────────────────────────────────────
            Obx(() => Row(children: [
                  _kpiCard(
                      'Total Cash Received',
                      'Rs. ${ctrl.totalCashReceived.toStringAsFixed(0)}',
                      Icons.payments_outlined,
                      Colors.green),
                  const SizedBox(width: 16),
                  _kpiCard(
                      'Total Liters Deducted',
                      '${ctrl.totalLitersDeducted.toStringAsFixed(1)} L',
                      Icons.opacity,
                      Colors.teal),
                  const SizedBox(width: 16),
                  _kpiCard(
                      'Sale Days',
                      '${ctrl.totalDaysWithSales}',
                      Icons.calendar_today_outlined,
                      AppTheme.info),
                  const SizedBox(width: 16),
                  _kpiCard(
                      'Avg. Cash / Day',
                      'Rs. ${ctrl.avgDailyCash.toStringAsFixed(0)}',
                      Icons.trending_up,
                      AppTheme.accent),
                ])),
            const SizedBox(height: 16),

            // ── Daily summary table ─────────────────────────────────────────
            Expanded(
              child: Card(
                child: Obx(() {
                  if (ctrl.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (ctrl.dailySummary.isEmpty) {
                    return const Center(
                        child: Text('No cash sales for selected month.',
                            style: TextStyle(color: Colors.black45)));
                  }

                  return Column(
                    children: [
                      // Table header
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 11),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE0F2F1),
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12)),
                        ),
                        child: Row(children: const [
                          SizedBox(
                              width: 40,
                              child: Text('#', style: _hStyle)),
                          Expanded(
                              flex: 2,
                              child: Text('Date', style: _hStyle)),
                          Expanded(
                              flex: 2,
                              child: Text('Day', style: _hStyle)),
                          Expanded(
                              flex: 2,
                              child: Text('Entries', style: _hStyle)),
                          Expanded(
                              flex: 3,
                              child: Text('Cash Received (Rs.)',
                                  style: _hStyleTeal)),
                          Expanded(
                              flex: 3,
                              child: Text('Liters Deducted',
                                  style: _hStyleTeal)),
                          Expanded(
                              flex: 2,
                              child: Text('Rate Used', style: _hStyle)),
                        ]),
                      ),

                      // Rows
                      Expanded(
                        child: ListView.separated(
                          itemCount: ctrl.dailySummary.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: Color(0xFFEEEEEE)),
                          itemBuilder: (context, i) {
                            final cs = ctrl.dailySummary[i];
                            final date = DateTime.tryParse(cs.saleDate);
                            final dayName = date != null
                                ? DateFormat('EEE').format(date)
                                : '';
                            final formattedDate = date != null
                                ? DateFormat('dd MMM yyyy').format(date)
                                : cs.saleDate;
                            final isEven = i % 2 == 0;
                            return Container(
                              color: isEven
                                  ? Colors.white
                                  : const Color(0xFFF5FFFE),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              child: Row(children: [
                                SizedBox(
                                    width: 40,
                                    child: Text('${i + 1}',
                                        style: const TextStyle(
                                            color: Colors.black38,
                                            fontSize: 12))),
                                Expanded(
                                    flex: 2,
                                    child: Text(formattedDate,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13))),
                                Expanded(
                                    flex: 2,
                                    child: Text(dayName,
                                        style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 13))),
                                Expanded(
                                    flex: 2,
                                    child: Text(cs.notes ?? '1 sale',
                                        style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 13))),
                                Expanded(
                                    flex: 3,
                                    child: Text(
                                        'Rs. ${cs.cashAmount.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                            fontSize: 13))),
                                Expanded(
                                    flex: 3,
                                    child: Text(
                                        '${cs.litersFromCash.toStringAsFixed(2)} L',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal,
                                            fontSize: 13))),
                                Expanded(
                                    flex: 2,
                                    child: Text(
                                        'Rs. ${cs.ratePerLiter.toStringAsFixed(0)}/L',
                                        style: const TextStyle(
                                            color: Colors.black45,
                                            fontSize: 12))),
                              ]),
                            );
                          },
                        ),
                      ),

                      // Footer totals
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFB2DFDB),
                          borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12)),
                        ),
                        child: Row(children: [
                          const Expanded(
                              flex: 6,
                              child: Text('MONTHLY TOTALS',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13))),
                          Expanded(
                              flex: 3,
                              child: Text(
                                  'Rs. ${ctrl.totalCashReceived.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                      fontSize: 14))),
                          Expanded(
                              flex: 3,
                              child: Text(
                                  '${ctrl.totalLitersDeducted.toStringAsFixed(2)} L',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                      fontSize: 14))),
                          const Expanded(flex: 2, child: SizedBox()),
                        ]),
                      ),
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

  // ── KPI card ───────────────────────────────────────────────────────────────
  Widget _kpiCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Excel export dialog ────────────────────────────────────────────────────
  void _showExportDialog(
      BuildContext context, CashSalesBillingController ctrl) {
    final fromCtrl = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(DateTime(
            ctrl.selectedYear.value, ctrl.selectedMonth.value, 1)));
    final toCtrl = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(DateTime(
            ctrl.selectedYear.value, ctrl.selectedMonth.value + 1, 0)));

    Get.dialog(AlertDialog(
      title: const Text('Export Cash Sales to Excel'),
      content: SizedBox(
        width: 350,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Select date range:',
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          TextField(
              controller: fromCtrl,
              decoration: const InputDecoration(
                  labelText: 'From Date', hintText: 'yyyy-mm-dd')),
          const SizedBox(height: 12),
          TextField(
              controller: toCtrl,
              decoration: const InputDecoration(
                  labelText: 'To Date', hintText: 'yyyy-mm-dd')),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton.icon(
          onPressed: () async {
            Get.back();
            final sales = await ctrl.getCashSalesByRange(
                fromCtrl.text, toCtrl.text);
            await ExcelExporter.exportCashSales(
                sales, fromCtrl.text, toCtrl.text);
          },
          icon: const Icon(Icons.download, size: 16),
          label: const Text('Export'),
        ),
      ],
    ));
  }

  // ── PDF print ──────────────────────────────────────────────────────────────
  Future<void> _printReport(BuildContext context,
      CashSalesBillingController ctrl, SettingsController settingsCtrl) async {
    if (ctrl.dailySummary.isEmpty) {
      Get.snackbar('No Data', 'No cash sales data to print',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final monthName = DateFormat('MMMM yyyy').format(
        DateTime(ctrl.selectedYear.value, ctrl.selectedMonth.value));

    final pdf = pw.Document();
    final rows = ctrl.dailySummary;

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context ctx) => [
        // Header
        pw.Text('${settingsCtrl.farmName.value} — Cash Sales Report',
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.Text(monthName,
            style: const pw.TextStyle(fontSize: 12)),
        pw.SizedBox(height: 16),

        // Summary
        pw.Row(children: [
          pw.Text(
              'Total Cash: Rs. ${ctrl.totalCashReceived.toStringAsFixed(0)}   |   '
              'Total Liters: ${ctrl.totalLitersDeducted.toStringAsFixed(2)} L   |   '
              'Days: ${ctrl.totalDaysWithSales}',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 11)),
        ]),
        pw.SizedBox(height: 12),

        // Table
        pw.Table(
          border: pw.TableBorder.all(width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(30),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(2.5),
            4: const pw.FlexColumnWidth(2.5),
            5: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.teal100),
              children: [
                _pdfCell('#', bold: true),
                _pdfCell('Date', bold: true),
                _pdfCell('Entries', bold: true),
                _pdfCell('Cash Received', bold: true),
                _pdfCell('Liters Deducted', bold: true),
                _pdfCell('Rate', bold: true),
              ],
            ),
            // Data rows
            ...rows.asMap().entries.map((e) {
              final i = e.key;
              final cs = e.value;
              final date = DateTime.tryParse(cs.saleDate);
              final formattedDate = date != null
                  ? DateFormat('dd MMM yyyy').format(date)
                  : cs.saleDate;
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                    color: i % 2 == 0 ? PdfColors.white : PdfColors.grey50),
                children: [
                  _pdfCell('${i + 1}'),
                  _pdfCell(formattedDate),
                  _pdfCell(cs.notes ?? '1'),
                  _pdfCell('Rs. ${cs.cashAmount.toStringAsFixed(0)}'),
                  _pdfCell(
                      '${cs.litersFromCash.toStringAsFixed(2)} L'),
                  _pdfCell(
                      'Rs. ${cs.ratePerLiter.toStringAsFixed(0)}/L'),
                ],
              );
            }),
            // Totals row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.teal100),
              children: [
                _pdfCell('', bold: true),
                _pdfCell('TOTAL', bold: true),
                _pdfCell('', bold: true),
                _pdfCell(
                    'Rs. ${ctrl.totalCashReceived.toStringAsFixed(0)}',
                    bold: true),
                _pdfCell(
                    '${ctrl.totalLitersDeducted.toStringAsFixed(2)} L',
                    bold: true),
                _pdfCell('', bold: true),
              ],
            ),
          ],
        ),
      ],
    ));

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name:
          'CashSales_${DateFormat('MMM_yyyy').format(DateTime(ctrl.selectedYear.value, ctrl.selectedMonth.value))}',
    );
  }

  pw.Widget _pdfCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(text,
          style: pw.TextStyle(
              fontSize: 9,
              fontWeight:
                  bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }

  static const _hStyle =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
  static const _hStyleTeal = TextStyle(
      fontWeight: FontWeight.bold, fontSize: 12, color: Colors.teal);
}