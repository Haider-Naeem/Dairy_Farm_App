// lib/app/utils/excel_exporter.dart
import 'dart:io';
import 'dart:ui';
import 'package:dairy_farm_app/controllers/credit_controller.dart';
import 'package:dairy_farm_app/controllers/ledger_controller.dart';
import 'package:dairy_farm_app/data/models/cash_sale_model.dart';
import 'package:dairy_farm_app/data/models/credit_model.dart';
import 'package:dairy_farm_app/data/models/payment_model.dart';
import 'package:dairy_farm_app/data/models/production_model.dart';
import 'package:dairy_farm_app/data/models/sale_model.dart';
import 'package:dairy_farm_app/data/models/vaccination_model.dart';
import 'package:excel/excel.dart';
import 'package:open_file/open_file.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExcelExporter {

  // ────────────────────────────────────────────────────────────────────────────
  // CREDIT REPORT
  // ────────────────────────────────────────────────────────────────────────────
  static Future<void> exportCreditReport(
    List<CreditModel> entries,
    List<PersonBalance> balances,
    String periodLabel,
  ) async {
    if (entries.isEmpty && balances.isEmpty) {
      Get.snackbar('No Data', 'No credit entries to export',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final excel = Excel.createExcel();
    final now   = DateTime.now();

    final balSheet = excel['Outstanding Balances'];
    excel.delete('Sheet1');

    _mergedTitle(balSheet, 'CREDIT REPORT — Outstanding Balances', 0, 6);
    balSheet.cell(CellIndex.indexByString('A2')).value =
        TextCellValue('Period: $periodLabel');
    balSheet.cell(CellIndex.indexByString('A3')).value = TextCellValue(
        'Exported: ${DateFormat('dd MMM yyyy HH:mm').format(now)}');

    const bHdrRow = 4;
    final bHeaders = [
      'Person Name', 'Phone', 'Total Credit (Rs.)',
      'Total Paid (Rs.)', 'Total Liters (L)', 'Balance (Rs.)', 'Status',
    ];
    for (int i = 0; i < bHeaders.length; i++) {
      final cell = balSheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: bHdrRow));
      cell.value = TextCellValue(bHeaders[i]);
      cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#E3F2FD'));
    }

    int bRow = bHdrRow + 1;
    double grandBalance = 0;
    for (int i = 0; i < balances.length; i++) {
      final b         = balances[i];
      final isSettled = b.balance <= 0;
      final rowBg     = isSettled ? '#E8F5E9' : (i % 2 == 0 ? '#FAFAFA' : '#FFFFFF');

      final cells = [
        b.personName, b.phone ?? '—',
        b.totalCredit.toStringAsFixed(0),
        b.totalPaid.toStringAsFixed(0),
        b.totalLiters.toStringAsFixed(2),
        b.balance.toStringAsFixed(0),
        isSettled ? 'SETTLED ✓' : 'UNPAID',
      ];
      for (int c = 0; c < cells.length; c++) {
        final cell = balSheet.cell(
            CellIndex.indexByColumnRow(columnIndex: c, rowIndex: bRow));
        cell.value = TextCellValue(cells[c]);
        cell.cellStyle = CellStyle(
          backgroundColorHex: ExcelColor.fromHexString(rowBg),
          fontColorHex: c == 6
              ? ExcelColor.fromHexString(isSettled ? '#1B5E20' : '#B71C1C')
              : ExcelColor.fromHexString('#000000'),
          bold: c == 6,
        );
      }
      if (b.balance > 0) grandBalance += b.balance;
      bRow++;
    }

    bRow++;
    balSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: bRow))
      ..value = TextCellValue('TOTAL OUTSTANDING')
      ..cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#FFCDD2'));
    balSheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: bRow))
      ..value = TextCellValue('Rs. ${grandBalance.toStringAsFixed(0)}')
      ..cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#FFCDD2'),
          fontColorHex: ExcelColor.fromHexString('#B71C1C'));

    balSheet.setColumnWidth(0, 22);
    balSheet.setColumnWidth(1, 16);
    balSheet.setColumnWidth(2, 20);
    balSheet.setColumnWidth(3, 18);
    balSheet.setColumnWidth(4, 16);
    balSheet.setColumnWidth(5, 18);
    balSheet.setColumnWidth(6, 14);

    final txSheet = excel['All Transactions'];

    _mergedTitle(txSheet, 'CREDIT — All Transactions', 0, 7);
    txSheet.cell(CellIndex.indexByString('A2')).value =
        TextCellValue('Period: $periodLabel');

    const tHdrRow = 3;
    final tHeaders = [
      'Date', 'Person', 'Phone', 'Type',
      'Amount (Rs.)', 'Liters (L)', 'Note', 'Status',
    ];
    for (int i = 0; i < tHeaders.length; i++) {
      final cell = txSheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: tHdrRow));
      cell.value = TextCellValue(tHeaders[i]);
      cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#E3F2FD'));
    }

    final Map<String, double> runningBalance = {};
    final sorted = List<CreditModel>.from(entries)
      ..sort((a, b) => a.entryDate.compareTo(b.entryDate));

    int tRow = tHdrRow + 1;
    double totalCreditRs = 0;
    double totalPaidRs   = 0;
    double totalCreditL  = 0;

    for (int i = 0; i < sorted.length; i++) {
      final e = sorted[i];
      runningBalance.putIfAbsent(e.personName, () => 0.0);

      final isCredit = e.isCredit;
      if (isCredit) {
        runningBalance[e.personName] = runningBalance[e.personName]! + e.amount;
        totalCreditRs += e.amount;
        totalCreditL  += e.liters;
      } else {
        runningBalance[e.personName] = runningBalance[e.personName]! - e.amount;
        totalPaidRs += e.amount;
      }

      final personBalance = runningBalance[e.personName]!;
      final isPaid        = personBalance <= 0;
      final rowBg = isCredit
          ? (i % 2 == 0 ? '#FFF8F8' : '#FFFFFF')
          : (i % 2 == 0 ? '#F0FFF4' : '#FFFFFF');

      final cells = [
        e.entryDate,
        e.personName,
        e.phone ?? '—',
        isCredit ? 'CREDIT' : 'PAYMENT',
        isCredit
            ? '+ Rs. ${e.amount.toStringAsFixed(0)}'
            : '− Rs. ${e.amount.toStringAsFixed(0)}',
        e.liters > 0 ? '${e.liters.toStringAsFixed(2)} L' : '—',
        e.description ?? '—',
        isPaid ? 'Settled ✓' : 'Balance: Rs. ${personBalance.toStringAsFixed(0)}',
      ];

      for (int c = 0; c < cells.length; c++) {
        final cell = txSheet.cell(
            CellIndex.indexByColumnRow(columnIndex: c, rowIndex: tRow));
        cell.value = TextCellValue(cells[c]);
        Color? fgColor;
        if (c == 3) {
          fgColor = isCredit ? const Color(0xFFB71C1C) : const Color(0xFF1B5E20);
        } else if (c == 4) {
          fgColor = isCredit ? const Color(0xFFB71C1C) : const Color(0xFF1B5E20);
        } else if (c == 7) {
          fgColor = isPaid ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C);
        }
        cell.cellStyle = CellStyle(
          backgroundColorHex: ExcelColor.fromHexString(rowBg),
          bold: c == 3 || c == 4,
          fontColorHex: fgColor != null
              ? ExcelColor.fromHexString(
                  '#${fgColor.value.toRadixString(16).substring(2).toUpperCase()}')
              : ExcelColor.fromHexString('#000000'),
        );
      }
      tRow++;
    }

    tRow++;
    txSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: tRow))
      ..value = TextCellValue('TOTALS')
      ..cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#E3F2FD'));
    final summaryItems = [
      (3, 'Credits: ${sorted.where((e) => e.isCredit).length}'),
      (4, 'Rs. ${totalCreditRs.toStringAsFixed(0)} credited'),
      (5, '${totalCreditL.toStringAsFixed(2)} L'),
    ];
    for (final item in summaryItems) {
      txSheet.cell(CellIndex.indexByColumnRow(
              columnIndex: item.$1, rowIndex: tRow))
        ..value = TextCellValue(item.$2)
        ..cellStyle = CellStyle(
            bold: true,
            backgroundColorHex: ExcelColor.fromHexString('#E3F2FD'));
    }

    tRow++;
    txSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: tRow))
      ..value = TextCellValue('PAYMENTS')
      ..cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#E8F5E9'));
    txSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: tRow))
      ..value = TextCellValue('Rs. ${totalPaidRs.toStringAsFixed(0)} received')
      ..cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#E8F5E9'),
          fontColorHex: ExcelColor.fromHexString('#1B5E20'));

    txSheet.setColumnWidth(0, 14);
    txSheet.setColumnWidth(1, 20);
    txSheet.setColumnWidth(2, 14);
    txSheet.setColumnWidth(3, 12);
    txSheet.setColumnWidth(4, 20);
    txSheet.setColumnWidth(5, 14);
    txSheet.setColumnWidth(6, 22);
    txSheet.setColumnWidth(7, 24);

    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    await _saveAndOpen(excel, 'CreditReport_$dateStr.xlsx');
  }

  // ────────────────────────────────────────────────────────────────────────────
  // VACCINATION REPORT (VXR)
  // ────────────────────────────────────────────────────────────────────────────
  static Future<void> exportVaccinations(
    List<VaccinationModel> records, {
    String? animalTag,
    String periodLabel = 'All Time',
  }) async {
    if (records.isEmpty) {
      Get.snackbar('No Data', 'No vaccination records to export',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final excel = Excel.createExcel();
    final sheet = excel['Vaccinations'];
    excel.delete('Sheet1');

    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('G1'));
    sheet.cell(CellIndex.indexByString('A1')).value =
        TextCellValue('VACCINATION REPORT (VXR)');
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
        bold: true, fontSize: 14, horizontalAlign: HorizontalAlign.Center);

    sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue(
        'Period: $periodLabel'
        '${animalTag != null ? "  ·  Animal: $animalTag" : ""}');
    sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue(
        'Exported: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}');

    const hRow = 4;
    final headers = [
      'Animal Tag', 'Vaccine Name', 'Date Given',
      'Next Due Date', 'Status', 'Given By', 'Notes',
    ];
    for (int i = 0; i < headers.length; i++) {
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: hRow));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#E8F5E9'));
    }

    final now  = DateTime.now();
    final soon = now.add(const Duration(days: 7));
    int row = hRow + 1;
    int doneCount = 0, overdueCount = 0, dueSoonCount = 0;

    for (int i = 0; i < records.length; i++) {
      final v = records[i];
      String status;
      String? rowBg;

      if (v.isDone) {
        status = 'Done';
        doneCount++;
      } else if (v.nextDueDate == null) {
        status = 'No Due Date';
      } else {
        final due = DateTime.tryParse(v.nextDueDate!);
        if (due == null) {
          status = 'Unknown';
        } else if (due.isBefore(now)) {
          status = 'Overdue';
          rowBg  = '#FFEBEE';
          overdueCount++;
        } else if (due.isBefore(soon)) {
          status = 'Due Soon';
          rowBg  = '#FFF8E1';
          dueSoonCount++;
        } else {
          status = 'Scheduled';
        }
      }

      final values = [
        v.animalTag ?? '—', v.vaccineName, v.vaccinationDate,
        v.nextDueDate ?? '—', status, v.givenBy ?? '—', v.notes ?? '—',
      ];
      for (int col = 0; col < values.length; col++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
        cell.value = TextCellValue(values[col]);
        if (rowBg != null) {
          cell.cellStyle = CellStyle(
              backgroundColorHex: ExcelColor.fromHexString(rowBg));
        } else if (i % 2 == 0) {
          cell.cellStyle = CellStyle(
              backgroundColorHex: ExcelColor.fromHexString('#FAFAFA'));
        }
      }
      row++;
    }

    row += 2;
    final sumLabel =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    sumLabel.value = TextCellValue('SUMMARY');
    sumLabel.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#E8F5E9'));
    row++;

    void sumRow(String lbl, String val, {String? valColor}) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(lbl);
      final c = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
      c.value = TextCellValue(val);
      if (valColor != null) {
        c.cellStyle = CellStyle(
            bold: true,
            fontColorHex: ExcelColor.fromHexString(valColor));
      }
    }

    sumRow('Total Records', '${records.length}');       row++;
    sumRow('Done',          '$doneCount');               row++;
    sumRow('Overdue',       '$overdueCount',
        valColor: overdueCount > 0 ? '#C62828' : null); row++;
    sumRow('Due Soon (<=7 days)', '$dueSoonCount',
        valColor: dueSoonCount > 0 ? '#E65100' : null);

    sheet.setColumnWidth(0, 14);
    sheet.setColumnWidth(1, 24);
    sheet.setColumnWidth(2, 14);
    sheet.setColumnWidth(3, 14);
    sheet.setColumnWidth(4, 14);
    sheet.setColumnWidth(5, 18);
    sheet.setColumnWidth(6, 24);

    final dateStr  = DateFormat('yyyy-MM-dd').format(now);
    final safeTag  = animalTag?.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final filename = safeTag != null
        ? 'VXR_${safeTag}_$dateStr.xlsx'
        : 'VXR_All_$dateStr.xlsx';

    await _saveAndOpen(excel, filename);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // DSR — CLIENT BILLING = milk delivery records (informational)
  //       PAYMENTS RECEIVED = actual dues paid (from PaymentModel, by paymentDate)
  //       CASH SALES = cash received today
  //       GRAND TOTAL = Payments Received + Cash Sales (actual cash in hand)
  // ────────────────────────────────────────────────────────────────────────────
  static Future<void> exportDSR(
    List<SaleModel> sales,
    String fromDate,
    String toDate, {
    List<CashSaleModel> cashSales = const [],
    List<PaymentModel> payments = const [],
  }) async {
    if (sales.isEmpty && cashSales.isEmpty && payments.isEmpty) {
      Get.snackbar('No Data', 'No sales data in selected range',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final excel = Excel.createExcel();
    final sheet = excel['DSR'];
    excel.delete('Sheet1');

    // ── Title ────────────────────────────────────────────────────────────────
    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('I1'));
    sheet.cell(CellIndex.indexByString('A1')).value =
        TextCellValue('DAILY SALES REPORT (DSR)');
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
        bold: true, fontSize: 14, horizontalAlign: HorizontalAlign.Center);
    sheet.cell(CellIndex.indexByString('A2')).value =
        TextCellValue('Period: $fromDate to $toDate');

    // ── SECTION 1: CLIENT MILK DELIVERY (informational records) ──────────────
    sheet.merge(CellIndex.indexByString('A3'), CellIndex.indexByString('I3'));
    sheet.cell(CellIndex.indexByString('A3')).value =
        TextCellValue('CLIENT MILK DELIVERY (Records — not cash received)');
    sheet.cell(CellIndex.indexByString('A3')).cellStyle = CellStyle(
        bold: true,
        fontSize: 12,
        backgroundColorHex: ExcelColor.fromHexString('#E8F5E9'),
        horizontalAlign: HorizontalAlign.Left);

    final milkHeaders = [
      'Date', 'Client Name', 'Allocated (L)', 'Taken',
      'Extra Liters (L)', 'Extra Amount (Rs.)',
      'Total Liters (L)', 'Total Amount (Rs.)', 'Notes',
    ];
    for (int i = 0; i < milkHeaders.length; i++) {
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 4));
      cell.value = TextCellValue(milkHeaders[i]);
      cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#C8E6C9'));
    }

    int row = 5;
    double grandMilkL       = 0;
    double grandMilkBilling = 0;

    final Map<String, List<SaleModel>> byDate = {};
    for (final s in sales) byDate.putIfAbsent(s.saleDate, () => []).add(s);

    for (final date in byDate.keys.toList()..sort()) {
      for (final s in byDate[date]!) {
        if (!s.isPayer) continue;
        _writeRow(sheet, row, [
          s.saleDate,
          s.clientName ?? '—',
          s.allocatedLiters.toStringAsFixed(1),
          s.takenAllocated ? 'Yes' : 'No',
          s.extraLiters.toStringAsFixed(1),
          s.extraAmount.toStringAsFixed(0),
          s.totalLiters.toStringAsFixed(1),
          s.totalAmount.toStringAsFixed(0),
          '',
        ]);
        grandMilkL       += s.totalLiters;
        grandMilkBilling += s.totalAmount;
        row++;
      }

      final dl = byDate[date]!
          .where((s) => s.isPayer)
          .fold(0.0, (s, e) => s + e.totalLiters);
      final da = byDate[date]!
          .where((s) => s.isPayer)
          .fold(0.0, (s, e) => s + e.totalAmount);
      if (dl > 0) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          ..value = TextCellValue('$date TOTAL')
          ..cellStyle = CellStyle(
              bold: true,
              backgroundColorHex: ExcelColor.fromHexString('#F1F8E9'));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
          ..value = TextCellValue('${dl.toStringAsFixed(1)} L')
          ..cellStyle = CellStyle(
              bold: true,
              backgroundColorHex: ExcelColor.fromHexString('#F1F8E9'));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
          ..value = TextCellValue('Rs. ${da.toStringAsFixed(0)}')
          ..cellStyle = CellStyle(
              bold: true,
              backgroundColorHex: ExcelColor.fromHexString('#F1F8E9'));
        row++;
      }
    }

    // Milk delivery total
    row++;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue('MILK DELIVERY TOTAL (Outstanding Dues)')
      ..cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#A5D6A7'));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
      ..value = TextCellValue('${grandMilkL.toStringAsFixed(1)} L')
      ..cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#A5D6A7'));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
      ..value = TextCellValue('Rs. ${grandMilkBilling.toStringAsFixed(0)}')
      ..cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#A5D6A7'),
          fontColorHex: ExcelColor.fromHexString('#1B5E20'));
    row += 2;

    // ── SECTION 2: PAYMENTS RECEIVED (actual dues paid by clients) ────────────
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue(
          'PAYMENTS RECEIVED (Dues paid by clients — actual cash received)')
      ..cellStyle = CellStyle(
          bold: true,
          fontSize: 12,
          backgroundColorHex: ExcelColor.fromHexString('#E3F2FD'),
          horizontalAlign: HorizontalAlign.Left);
    row++;

    double grandPayments = 0;

    if (payments.isEmpty) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue('No payments received in this period.');
      row += 2;
    } else {
      final payHeaders = [
        'Payment Date', 'Client', 'For Month', 'Amount Paid (Rs.)', 'Notes',
      ];
      for (int i = 0; i < payHeaders.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          ..value = TextCellValue(payHeaders[i])
          ..cellStyle = CellStyle(
              bold: true,
              backgroundColorHex: ExcelColor.fromHexString('#BBDEFB'));
      }
      row++;

      // Group payments by paymentDate
      final Map<String, List<PaymentModel>> payByDate = {};
      for (final p in payments) {
        payByDate.putIfAbsent(p.paymentDate, () => []).add(p);
      }

      for (final date in payByDate.keys.toList()..sort()) {
        for (final p in payByDate[date]!) {
          final forMonth = DateFormat('MMMM yyyy')
              .format(DateTime(p.year, p.month));
          _writeRow(sheet, row, [
            p.paymentDate,
            p.clientName ?? 'Client #${p.clientId}',
            forMonth,
            p.amountPaid.toStringAsFixed(0),
            p.notes ?? '—',
          ]);
          grandPayments += p.amountPaid;
          row++;
        }

        final dayTotal = payByDate[date]!
            .fold(0.0, (s, e) => s + e.amountPaid);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          ..value = TextCellValue('$date TOTAL')
          ..cellStyle = CellStyle(
              bold: true,
              backgroundColorHex: ExcelColor.fromHexString('#E3F2FD'));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          ..value = TextCellValue('Rs. ${dayTotal.toStringAsFixed(0)}')
          ..cellStyle = CellStyle(
              bold: true,
              backgroundColorHex: ExcelColor.fromHexString('#E3F2FD'));
        row++;
      }

      row++;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        ..value = TextCellValue('PAYMENTS RECEIVED TOTAL')
        ..cellStyle = CellStyle(
            bold: true,
            backgroundColorHex: ExcelColor.fromHexString('#1565C0'),
            fontColorHex: ExcelColor.fromHexString('#FFFFFF'));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
        ..value = TextCellValue('Rs. ${grandPayments.toStringAsFixed(0)}')
        ..cellStyle = CellStyle(
            bold: true,
            backgroundColorHex: ExcelColor.fromHexString('#1565C0'),
            fontColorHex: ExcelColor.fromHexString('#FFFFFF'));
      row += 2;
    }

    // ── SECTION 3: CASH SALES ─────────────────────────────────────────────────
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue('CASH SALES (Milk sold for cash — received immediately)')
      ..cellStyle = CellStyle(
          bold: true,
          fontSize: 12,
          backgroundColorHex: ExcelColor.fromHexString('#E0F2F1'),
          horizontalAlign: HorizontalAlign.Left);
    row++;

    double grandCash  = 0;
    double grandCashL = 0;

    if (cashSales.isEmpty) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue('No cash sales in this period.');
      row += 2;
    } else {
      final csHeaders = [
        'Date', 'Notes / Buyer', 'Cash Received (Rs.)',
        'Rate per Liter (Rs.)', 'Liters Deducted (L)', 'Time',
      ];
      for (int i = 0; i < csHeaders.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          ..value = TextCellValue(csHeaders[i])
          ..cellStyle = CellStyle(
              bold: true,
              backgroundColorHex: ExcelColor.fromHexString('#B2DFDB'));
      }
      row++;

      final Map<String, List<CashSaleModel>> csByDate = {};
      for (final cs in cashSales) {
        csByDate.putIfAbsent(cs.saleDate, () => []).add(cs);
      }

      for (final date in csByDate.keys.toList()..sort()) {
        for (final cs in csByDate[date]!) {
          String time = '—';
          try {
            final dt = DateTime.parse(cs.createdAt);
            time =
                '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          } catch (_) {}
          _writeRow(sheet, row, [
            cs.saleDate,
            cs.notes ?? 'Cash sale',
            cs.cashAmount.toStringAsFixed(0),
            cs.ratePerLiter.toStringAsFixed(0),
            cs.litersFromCash.toStringAsFixed(2),
            time,
          ]);
          grandCash  += cs.cashAmount;
          grandCashL += cs.litersFromCash;
          row++;
        }

        final dc = csByDate[date]!.fold(0.0, (s, e) => s + e.cashAmount);
        final dl = csByDate[date]!.fold(0.0, (s, e) => s + e.litersFromCash);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          ..value = TextCellValue('$date TOTAL')
          ..cellStyle = CellStyle(
              bold: true,
              backgroundColorHex: ExcelColor.fromHexString('#E0F7FA'));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          ..value = TextCellValue('Rs. ${dc.toStringAsFixed(0)}')
          ..cellStyle = CellStyle(
              bold: true,
              backgroundColorHex: ExcelColor.fromHexString('#E0F7FA'));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          ..value = TextCellValue('${dl.toStringAsFixed(2)} L')
          ..cellStyle = CellStyle(
              bold: true,
              backgroundColorHex: ExcelColor.fromHexString('#E0F7FA'));
        row++;
      }

      row++;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        ..value = TextCellValue('CASH SALES TOTAL')
        ..cellStyle = CellStyle(
            bold: true,
            backgroundColorHex: ExcelColor.fromHexString('#00796B'),
            fontColorHex: ExcelColor.fromHexString('#FFFFFF'));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
        ..value = TextCellValue('Rs. ${grandCash.toStringAsFixed(0)}')
        ..cellStyle = CellStyle(
            bold: true,
            backgroundColorHex: ExcelColor.fromHexString('#00796B'),
            fontColorHex: ExcelColor.fromHexString('#FFFFFF'));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
        ..value = TextCellValue('${grandCashL.toStringAsFixed(2)} L')
        ..cellStyle = CellStyle(
            bold: true,
            backgroundColorHex: ExcelColor.fromHexString('#00796B'),
            fontColorHex: ExcelColor.fromHexString('#FFFFFF'));
      row += 2;
    }

    // ── SECTION 4: GRAND SUMMARY (actual cash received) ───────────────────────
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue('GRAND SUMMARY — ACTUAL CASH RECEIVED')
      ..cellStyle = CellStyle(
          bold: true,
          fontSize: 13,
          backgroundColorHex: ExcelColor.fromHexString('#FFF9C4'),
          horizontalAlign: HorizontalAlign.Left);
    row++;

    final summaryHeaders = ['Item', 'Amount (Rs.)', 'Note'];
    for (int i = 0; i < summaryHeaders.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
        ..value = TextCellValue(summaryHeaders[i])
        ..cellStyle = CellStyle(
            bold: true,
            backgroundColorHex: ExcelColor.fromHexString('#FFF9C4'));
    }
    row++;

    // Payments received row
    _writeRow(sheet, row, [
      'Payments Received (Client Dues Paid)',
      'Rs. ${grandPayments.toStringAsFixed(0)}',
      'Actual money received for previous/current month dues',
    ]);
    for (int c = 0; c < 3; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row))
          .cellStyle = CellStyle(
              backgroundColorHex: ExcelColor.fromHexString('#E3F2FD'));
    }
    row++;

    // Cash sales row
    _writeRow(sheet, row, [
      'Cash Sales',
      'Rs. ${grandCash.toStringAsFixed(0)}',
      '${grandCashL.toStringAsFixed(2)} L sold for cash',
    ]);
    for (int c = 0; c < 3; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row))
          .cellStyle = CellStyle(
              backgroundColorHex: ExcelColor.fromHexString('#E0F2F1'));
    }
    row++;

    // Grand total
    final grandTotal = grandPayments + grandCash;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue('TOTAL CASH RECEIVED')
      ..cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#F57F17'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
      ..value = TextCellValue('Rs. ${grandTotal.toStringAsFixed(0)}')
      ..cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#F57F17'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
      ..value = TextCellValue(
          'Payments: Rs. ${grandPayments.toStringAsFixed(0)}'
          '  +  Cash Sales: Rs. ${grandCash.toStringAsFixed(0)}')
      ..cellStyle = CellStyle(
          bold: true,
          italic: true,
          backgroundColorHex: ExcelColor.fromHexString('#F57F17'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'));
    row++;

    // Milk delivery note (outstanding dues, not yet cash)
    row++;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue(
            'NOTE: Outstanding milk dues (not yet received): '
            'Rs. ${grandMilkBilling.toStringAsFixed(0)} '
            '(${grandMilkL.toStringAsFixed(1)} L delivered to paying clients)');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = CellStyle(
            italic: true,
            fontColorHex: ExcelColor.fromHexString('#E65100'));

    sheet.setColumnWidth(0, 18);
    sheet.setColumnWidth(1, 24);
    sheet.setColumnWidth(2, 28);
    for (int i = 3; i <= 8; i++) sheet.setColumnWidth(i, 16);

    await _saveAndOpen(excel, 'DSR_${fromDate}_$toDate.xlsx');
  }

  // ────────────────────────────────────────────────────────────────────────────
  // DMR — landscape A4 PDF, 1 page, supports 15+ animal columns
  // Font sizes increased by +2
  // ────────────────────────────────────────────────────────────────────────────
  static Future<void> exportDMR(
      List<ProductionModel> prods, String fromDate, String toDate) async {
    if (prods.isEmpty) {
      Get.snackbar('No Data', 'No production data in selected range',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final seenIds = <int>{};
    final animals = <({int id, String tag, String name})>[];
    for (final p in prods) {
      if (seenIds.add(p.animalId)) {
        animals.add((
          id:   p.animalId,
          tag:  p.animalTag  ?? 'A${p.animalId}',
          name: p.animalName ?? '',
        ));
      }
    }

    final Map<String, Map<int, ProductionModel>> lookup = {};
    for (final p in prods) {
      lookup.putIfAbsent(p.productionDate, () => {})[p.animalId] = p;
    }
    final sortedDates = lookup.keys.toList()..sort();

    const pageW   = 841.89;
    const pageH   = 595.28;
    const margin  = 18.0;
    const usableW = pageW - margin * 2;

    const fixedW    = 20.0 + 52.0 + 22.0;
    const totalColW = 44.0;
    final animalColW = animals.isEmpty
        ? 44.0
        : ((usableW - fixedW - totalColW) / animals.length)
            .clamp(30.0, 58.0);

    final naturalW = fixedW + animals.length * animalColW + totalColW;
    final scale    = naturalW > usableW ? usableW / naturalW : 1.0;

    final scaledAnimalW = animalColW * scale;
    final scaledTotalW  = totalColW  * scale;

    // Font sizes +2 from original
    const titleFs  = 12.0;
    const hdrFs    = 8.5;
    const dataFs   = 8.2;
    const totFs    = 8.5;
    const headerH  = 40.0;
    const dataRowH = 15.0;
    const footerH  = 18.0;

    final headerBg  = PdfColor.fromHex('#2E7D32');
    final altRowBg  = PdfColor.fromHex('#F1F8E9');
    final totalRowBg = PdfColor.fromHex('#C8E6C9');
    final totalFg   = PdfColor.fromHex('#1B5E20');

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(pageW, pageH, marginAll: margin),
        orientation: pw.PageOrientation.landscape,
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Title row
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('DAILY MILK RECORD (DMR)',
                        style: pw.TextStyle(
                            fontSize: titleFs,
                            fontWeight: pw.FontWeight.bold)),
                    pw.Text('Period: $fromDate  to  $toDate',
                        style: pw.TextStyle(
                            fontSize: 8.0, color: PdfColors.grey700)),
                    pw.Text(
                        'Exported: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
                        style: pw.TextStyle(
                            fontSize: 8.0, color: PdfColors.grey600)),
                  ],
                ),
              ),

              // Header row
              pw.Container(
                height: headerH,
                color: headerBg,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 20 * scale,
                      alignment: pw.Alignment.center,
                      child: pw.Text('#',
                          style: pw.TextStyle(
                              fontSize: hdrFs,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white)),
                    ),
                    pw.Container(
                      width: 52 * scale,
                      alignment: pw.Alignment.center,
                      child: pw.Text('DATE',
                          style: pw.TextStyle(
                              fontSize: hdrFs,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white)),
                    ),
                    pw.Container(
                      width: 22 * scale,
                      alignment: pw.Alignment.center,
                      child: pw.Text('DAY',
                          style: pw.TextStyle(
                              fontSize: hdrFs,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white)),
                    ),
                    ...animals.map((a) => pw.Container(
                          width: scaledAnimalW,
                          alignment: pw.Alignment.center,
                          padding: const pw.EdgeInsets.symmetric(horizontal: 1),
                          child: pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(a.tag,
                                  style: pw.TextStyle(
                                      fontSize: hdrFs,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.white),
                                  textAlign: pw.TextAlign.center),
                              if (a.name.isNotEmpty)
                                pw.Text(a.name,
                                    style: pw.TextStyle(
                                        fontSize: hdrFs - 1.5,
                                        color: PdfColors.green100),
                                    textAlign: pw.TextAlign.center),
                            ],
                          ),
                        )),
                    pw.Container(
                      width: scaledTotalW,
                      alignment: pw.Alignment.center,
                      child: pw.Text('TOTAL\n(L)',
                          style: pw.TextStyle(
                              fontSize: hdrFs,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.yellow100),
                          textAlign: pw.TextAlign.center),
                    ),
                  ],
                ),
              ),

              // Data rows
              pw.Expanded(
                child: pw.Column(
                  children: [
                    ...sortedDates.asMap().entries.map((entry) {
                      final di      = entry.key;
                      final date    = entry.value;
                      final dayData = lookup[date]!;
                      final dt      = DateTime.tryParse(date);
                      final day = dt != null
                          ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                              [dt.weekday - 1]
                          : '';
                      final isSat  = dt?.weekday == 6;
                      final isSun  = dt?.weekday == 7;
                      final isEven = di % 2 == 0;
                      final PdfColor? rowBg = isSun
                          ? PdfColor.fromHex('#FFF8E1')
                          : isSat
                              ? PdfColor.fromHex('#F3E5F5')
                              : isEven ? null : altRowBg;

                      double rowTotal = 0;
                      for (final a in animals) {
                        rowTotal += dayData[a.id]?.total ?? 0;
                      }

                      return pw.Container(
                        height: dataRowH,
                        color: rowBg,
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Container(
                              width: 20 * scale,
                              alignment: pw.Alignment.center,
                              child: pw.Text('${di + 1}',
                                  style: pw.TextStyle(
                                      fontSize: dataFs,
                                      color: PdfColors.grey600)),
                            ),
                            pw.Container(
                              width: 52 * scale,
                              alignment: pw.Alignment.center,
                              child: pw.Text(date,
                                  style: pw.TextStyle(
                                      fontSize: dataFs,
                                      fontWeight: pw.FontWeight.bold)),
                            ),
                            pw.Container(
                              width: 22 * scale,
                              alignment: pw.Alignment.center,
                              child: pw.Text(day,
                                  style: pw.TextStyle(
                                      fontSize: dataFs,
                                      color: isSun
                                          ? PdfColors.orange700
                                          : isSat
                                              ? PdfColors.purple700
                                              : PdfColors.grey600)),
                            ),
                            ...animals.map((a) {
                              final total = dayData[a.id]?.total ?? 0.0;
                              return pw.Container(
                                width: scaledAnimalW,
                                alignment: pw.Alignment.center,
                                child: pw.Text(
                                    total > 0
                                        ? total.toStringAsFixed(1)
                                        : '—',
                                    style: pw.TextStyle(
                                        fontSize: dataFs,
                                        color: total > 0
                                            ? PdfColors.black
                                            : PdfColors.grey400)),
                              );
                            }),
                            pw.Container(
                              width: scaledTotalW,
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                  rowTotal > 0
                                      ? rowTotal.toStringAsFixed(1)
                                      : '—',
                                  style: pw.TextStyle(
                                      fontSize: totFs,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.green800)),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Footer totals row
                    pw.Container(
                      height: footerH,
                      color: totalRowBg,
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Container(
                            width: (20 + 52 + 22) * scale,
                            alignment: pw.Alignment.centerRight,
                            padding: const pw.EdgeInsets.only(right: 4),
                            child: pw.Text('TOTAL',
                                style: pw.TextStyle(
                                    fontSize: totFs,
                                    fontWeight: pw.FontWeight.bold,
                                    color: totalFg)),
                          ),
                          ...animals.map((a) {
                            final colTotal = sortedDates.fold(
                                0.0,
                                (s, date) =>
                                    s + (lookup[date]![a.id]?.total ?? 0.0));
                            return pw.Container(
                              width: scaledAnimalW,
                              alignment: pw.Alignment.center,
                              child: pw.Text(colTotal.toStringAsFixed(1),
                                  style: pw.TextStyle(
                                      fontSize: totFs,
                                      fontWeight: pw.FontWeight.bold,
                                      color: totalFg)),
                            );
                          }),
                          pw.Container(
                            width: scaledTotalW,
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                                sortedDates
                                    .fold(
                                        0.0,
                                        (s, date) =>
                                            s +
                                            animals.fold(
                                                0.0,
                                                (ss, a) =>
                                                    ss +
                                                    (lookup[date]![a.id]
                                                            ?.total ??
                                                        0.0)))
                                    .toStringAsFixed(1),
                                style: pw.TextStyle(
                                    fontSize: totFs + 1,
                                    fontWeight: pw.FontWeight.bold,
                                    color: totalFg)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text(
                    'Values in Liters (L)  |  '
                    'Total animals: ${animals.length}  |  '
                    'Days recorded: ${sortedDates.length}',
                    style: const pw.TextStyle(
                        fontSize: 7.0, color: PdfColors.grey600)),
              ),
            ],
          );
        },
      ),
    );

    await _saveAndOpenPdf(pdf, 'DMR_${fromDate}_$toDate.pdf');
  }

  // ────────────────────────────────────────────────────────────────────────────
  // DMR single animal, monthly — Excel
  // ────────────────────────────────────────────────────────────────────────────
  static Future<void> exportAnimalMonthlyDMR(
    List<ProductionModel> history,
    String animalTag,
    String animalName,
    int year,
    int month,
  ) async {
    if (history.isEmpty) {
      Get.snackbar('No Data', 'No production records to export',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final excel = Excel.createExcel();
    final sheet = excel['DMR'];
    excel.delete('Sheet1');

    final monthLabel = DateFormat('MMMM yyyy').format(DateTime(year, month));

    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('G1'));
    sheet.cell(CellIndex.indexByString('A1')).value =
        TextCellValue('ANIMAL MONTHLY MILK RECORD');
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
        bold: true, fontSize: 14, horizontalAlign: HorizontalAlign.Center);
    sheet.cell(CellIndex.indexByString('A2')).value =
        TextCellValue('Animal: $animalTag — $animalName');
    sheet.cell(CellIndex.indexByString('A2')).cellStyle =
        CellStyle(bold: true, fontSize: 12);
    sheet.cell(CellIndex.indexByString('A3')).value =
        TextCellValue('Month: $monthLabel');

    const hRow = 4;
    final headers = [
      '#', 'Date', 'Day', 'Morning (L)', 'Afternoon (L)',
      'Evening (L)', 'Total (L)',
    ];
    for (int i = 0; i < headers.length; i++) {
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: hRow));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#E8F5E9'));
    }

    final sorted = List<ProductionModel>.from(history)
      ..sort((a, b) => a.productionDate.compareTo(b.productionDate));

    int row = hRow + 1;
    double tM = 0, tA = 0, tE = 0, tT = 0;

    for (int i = 0; i < sorted.length; i++) {
      final p   = sorted[i];
      final dt  = DateTime.tryParse(p.productionDate);
      final day = dt != null
          ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dt.weekday - 1]
          : '';
      _writeRow(sheet, row, [
        '${i + 1}', p.productionDate, day,
        p.morning.toStringAsFixed(1), p.afternoon.toStringAsFixed(1),
        p.evening.toStringAsFixed(1), p.total.toStringAsFixed(1),
      ]);
      if (i % 2 == 0) {
        for (int col = 0; col < 7; col++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
              .cellStyle = CellStyle(
                  backgroundColorHex: ExcelColor.fromHexString('#FAFAFA'));
        }
      }
      tM += p.morning; tA += p.afternoon;
      tE += p.evening; tT += p.total;
      row++;
    }

    final n = sorted.isEmpty ? 1 : sorted.length;
    row++;

    for (final pair in [
      ['MONTHLY TOTAL', '#C8E6C9', tM, tA, tE, tT, true],
      ['DAILY AVERAGE', '#E8F5E9', tM / n, tA / n, tE / n, tT / n, false],
    ]) {
      final label = pair[0] as String;
      final bg    = pair[1] as String;
      final vals  = [pair[2], pair[3], pair[4], pair[5]] as List;
      final bold  = pair[6] as bool;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        ..value = TextCellValue(label)
        ..cellStyle = CellStyle(
            bold: bold,
            backgroundColorHex: ExcelColor.fromHexString(bg));
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row),
      );
      for (int i = 0; i < vals.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3 + i, rowIndex: row))
          ..value = TextCellValue('${(vals[i] as double).toStringAsFixed(2)} L')
          ..cellStyle = CellStyle(
              bold: bold,
              backgroundColorHex: ExcelColor.fromHexString(bg));
      }
      row++;
    }

    sheet.setColumnWidth(0, 6);
    sheet.setColumnWidth(1, 14);
    sheet.setColumnWidth(2, 8);
    for (int i = 3; i <= 6; i++) sheet.setColumnWidth(i, 14);

    final safeTag  = animalTag.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final monthStr = DateFormat('yyyy_MM').format(DateTime(year, month));
    await _saveAndOpen(excel, 'DMR_${safeTag}_$monthStr.xlsx');
  }

  // ────────────────────────────────────────────────────────────────────────────
  // DMR single animal, monthly — PDF (portrait A4)
  // Font sizes +2, slightly lighter alternating rows
  // ────────────────────────────────────────────────────────────────────────────
  // ════════════════════════════════════════════════════════════════════════════
// REPLACE the existing exportAnimalMonthlyDMRPdf method
// ADD the new exportAllAnimalsDMRPdf method
// Both go inside the ExcelExporter class in excel_exporter.dart
// ════════════════════════════════════════════════════════════════════════════

  // ────────────────────────────────────────────────────────────────────────────
  // DMR single animal, monthly — PDF
  // Now uses 2-up landscape layout (animal on left half, empty right half)
  // Calls the shared multi-animal method internally.
  // ────────────────────────────────────────────────────────────────────────────
  static Future<void> exportAnimalMonthlyDMRPdf(
    List<ProductionModel> history,
    String animalTag,
    String animalName,
    int year,
    int month,
  ) async {
    if (history.isEmpty) {
      Get.snackbar('No Data', 'No production records to export',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    await exportAllAnimalsDMRPdf(
      [(history: history, tag: animalTag, name: animalName)],
      year,
      month,
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // DMR — ALL animals, monthly — landscape A4 PDF, 2 animals per page
  // ────────────────────────────────────────────────────────────────────────────
  static Future<void> exportAllAnimalsDMRPdf(
    List<({List<ProductionModel> history, String tag, String name})> animals,
    int year,
    int month,
  ) async {
    if (animals.isEmpty) {
      Get.snackbar('No Data', 'No production records to export',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final monthLabel = DateFormat('MMMM yyyy').format(DateTime(year, month));

    // ── Page geometry ────────────────────────────────────────────────────────
    const pageW   = 841.89;
    const pageH   = 595.28;
    const margin  = 18.0;
    const gap     = 10.0; // gap between the two halves
    const usableW = pageW - margin * 2;
    const halfW   = (usableW - gap) / 2; // ≈ 397.9

    // ── Column widths inside each half (8pt padding each side → 16pt total) ─
    const pad   = 8.0;
    const inner = halfW - pad * 2; // ≈ 381.9
    const cNum  = 16.0;
    const cDate = 58.0;
    const cDay  = 22.0;
    const cM    = (inner - cNum - cDate - cDay - 4) / 4; // ≈ 70.5 each
    // cM is reused for Afternoon, Evening, Total

    // ── Font / row sizes ─────────────────────────────────────────────────────
    const titleFs   = 9.5;
    const subFs     = 8.5;
    const hdrFs     = 8.0;
    const dataFs    = 7.8;
    const totFs     = 8.0;
    const statsH    = 36.0; // title block height
    const hdrH      = 20.0;
    const dataRowH  = 13.5;
    const footerH   = 15.0;

    // ── Colors ───────────────────────────────────────────────────────────────
    final headerBg   = PdfColor.fromHex('#2E7D32');
    final altRowBg   = PdfColor.fromHex('#F4FBF4');
    final totalRowBg = PdfColor.fromHex('#C8E6C9');
    final avgRowBg   = PdfColor.fromHex('#E8F5E9');
    final totalFg    = PdfColor.fromHex('#1B5E20');
    final dividerBg  = PdfColor.fromHex('#E0E0E0');

    // ── Helper: header cell ───────────────────────────────────────────────────
    pw.Widget hCell(String t, double w, {bool accent = false}) =>
        pw.Container(
          width: w,
          alignment: pw.Alignment.center,
          child: pw.Text(t,
              style: pw.TextStyle(
                  fontSize: hdrFs,
                  fontWeight: pw.FontWeight.bold,
                  color: accent ? PdfColors.yellow100 : PdfColors.white),
              textAlign: pw.TextAlign.center),
        );

    // ── Helper: data cell ─────────────────────────────────────────────────────
    pw.Widget dCell(String t, double w,
        {bool bold = false, PdfColor? color}) =>
        pw.Container(
          width: w,
          alignment: pw.Alignment.center,
          child: pw.Text(t,
              style: pw.TextStyle(
                  fontSize: dataFs,
                  fontWeight:
                      bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: color ?? PdfColors.black),
              textAlign: pw.TextAlign.center),
        );

    // ── Helper: footer cell ───────────────────────────────────────────────────
    pw.Widget fCell(String t, double w,
        {bool bold = true, PdfColor? color}) =>
        pw.Container(
          width: w,
          alignment: pw.Alignment.center,
          child: pw.Text(t,
              style: pw.TextStyle(
                  fontSize: totFs,
                  fontWeight:
                      bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: color ?? totalFg),
              textAlign: pw.TextAlign.center),
        );

    // ── Helper: build one animal half ─────────────────────────────────────────
    pw.Widget buildHalf(
        List<ProductionModel> history, String tag, String name) {
      final sorted = List<ProductionModel>.from(history)
        ..sort((a, b) => a.productionDate.compareTo(b.productionDate));

      double tM = 0, tA = 0, tE = 0, tT = 0;
      for (final p in sorted) {
        tM += p.morning;
        tA += p.afternoon;
        tE += p.evening;
        tT += p.total;
      }
      final n   = sorted.isEmpty ? 1 : sorted.length;
      final avg = tT / n;

      return pw.Container(
        width: halfW,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ── Title block ─────────────────────────────────────────────
            pw.Container(
              height: statsH,
              padding: pw.EdgeInsets.symmetric(horizontal: pad, vertical: 4),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#E8F5E9'),
                borderRadius: pw.BorderRadius.only(
                    topLeft: const pw.Radius.circular(4),
                    topRight: const pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('$tag  —  $name',
                          style: pw.TextStyle(
                              fontSize: titleFs,
                              fontWeight: pw.FontWeight.bold,
                              color: totalFg)),
                      pw.Text(monthLabel,
                          style: pw.TextStyle(
                              fontSize: subFs - 1,
                              color: PdfColors.grey700)),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Days: ${sorted.length}',
                          style: pw.TextStyle(
                              fontSize: subFs - 1,
                              fontWeight: pw.FontWeight.bold,
                              color: totalFg)),
                      pw.Text('Total: ${tT.toStringAsFixed(1)} L',
                          style: pw.TextStyle(
                              fontSize: subFs - 1,
                              fontWeight: pw.FontWeight.bold,
                              color: totalFg)),
                      pw.Text('Avg: ${avg.toStringAsFixed(2)} L',
                          style: pw.TextStyle(
                              fontSize: subFs - 1,
                              fontWeight: pw.FontWeight.bold,
                              color: totalFg)),
                    ],
                  ),
                ],
              ),
            ),

            // ── Table header ────────────────────────────────────────────
            pw.Container(
              height: hdrH,
              color: headerBg,
              padding: pw.EdgeInsets.symmetric(horizontal: pad),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  hCell('#',           cNum),
                  hCell('Date',        cDate),
                  hCell('Day',         cDay),
                  hCell('Morning (L)', cM),
                  hCell('Afternoon (L)', cM),
                  hCell('Evening (L)', cM),
                  hCell('Total (L)',   cM, accent: true),
                ],
              ),
            ),

            // ── Data rows ────────────────────────────────────────────────
            pw.Column(
              children: sorted.asMap().entries.map((e) {
                final i   = e.key;
                final p   = e.value;
                final dt  = DateTime.tryParse(p.productionDate);
                final day = dt != null
                    ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                        [dt.weekday - 1]
                    : '';
                final isSun  = dt?.weekday == 7;
                final isSat  = dt?.weekday == 6;

                final PdfColor? rowBg = isSun
                    ? PdfColor.fromHex('#FFF8E1')
                    : isSat
                        ? PdfColor.fromHex('#F3E5F5')
                        : i % 2 != 0 ? altRowBg : null;

                return pw.Container(
                  height: dataRowH,
                  color: rowBg,
                  padding: pw.EdgeInsets.symmetric(horizontal: pad),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      dCell('${i + 1}',                          cNum,  color: PdfColors.grey600),
                      dCell(p.productionDate,                     cDate, bold: true),
                      dCell(day,                                   cDay,
                          color: isSun
                              ? PdfColors.orange700
                              : isSat ? PdfColors.purple700 : PdfColors.grey600),
                      dCell('${p.morning.toStringAsFixed(1)}',    cM,
                          color: PdfColor.fromHex('#E65100')),
                      dCell('${p.afternoon.toStringAsFixed(1)}',  cM,
                          color: PdfColor.fromHex('#37474F')),
                      dCell('${p.evening.toStringAsFixed(1)}',    cM,
                          color: PdfColor.fromHex('#283593')),
                      dCell('${p.total.toStringAsFixed(1)}',      cM,
                          bold: true, color: PdfColors.green800),
                    ],
                  ),
                );
              }).toList(),
            ),

            // ── Monthly total row ────────────────────────────────────────
            pw.Container(
              height: footerH,
              color: totalRowBg,
              padding: pw.EdgeInsets.symmetric(horizontal: pad),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    width: cNum + cDate + cDay,
                    alignment: pw.Alignment.centerRight,
                    padding: const pw.EdgeInsets.only(right: 4),
                    child: pw.Text('TOTAL',
                        style: pw.TextStyle(
                            fontSize: totFs,
                            fontWeight: pw.FontWeight.bold,
                            color: totalFg)),
                  ),
                  fCell('${tM.toStringAsFixed(2)}', cM),
                  fCell('${tA.toStringAsFixed(2)}', cM),
                  fCell('${tE.toStringAsFixed(2)}', cM),
                  fCell('${tT.toStringAsFixed(2)}', cM,
                      color: PdfColors.green900),
                ],
              ),
            ),

            // ── Daily avg row ────────────────────────────────────────────
            pw.Container(
              height: footerH - 2,
              color: avgRowBg,
              padding: pw.EdgeInsets.symmetric(horizontal: pad),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    width: cNum + cDate + cDay,
                    alignment: pw.Alignment.centerRight,
                    padding: const pw.EdgeInsets.only(right: 4),
                    child: pw.Text('AVG/DAY',
                        style: pw.TextStyle(
                            fontSize: totFs - 0.5,
                            fontWeight: pw.FontWeight.bold,
                            color: totalFg)),
                  ),
                  fCell('${(tM / n).toStringAsFixed(2)}', cM, bold: false),
                  fCell('${(tA / n).toStringAsFixed(2)}', cM, bold: false),
                  fCell('${(tE / n).toStringAsFixed(2)}', cM, bold: false),
                  fCell('${avg.toStringAsFixed(2)}',       cM),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── Build PDF: pair up animals 2 per page ────────────────────────────────
    final pdf = pw.Document();
    final now = DateTime.now();

    // Walk through animals in steps of 2
    for (int i = 0; i < animals.length; i += 2) {
      final left  = animals[i];
      final right = i + 1 < animals.length ? animals[i + 1] : null;

      pdf.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(pageW, pageH, marginAll: margin),
          orientation: pw.PageOrientation.landscape,
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // ── Page title bar ─────────────────────────────────────
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('ANIMAL MONTHLY MILK RECORD (DMR)',
                          style: pw.TextStyle(
                              fontSize: 10.0,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text('Month: $monthLabel',
                          style: pw.TextStyle(
                              fontSize: 8.0, color: PdfColors.grey700)),
                      pw.Text(
                          'Page ${(i ~/ 2) + 1} of ${((animals.length - 1) ~/ 2) + 1}'
                          '  |  Exported: ${DateFormat('dd MMM yyyy HH:mm').format(now)}',
                          style: pw.TextStyle(
                              fontSize: 7.5, color: PdfColors.grey600)),
                    ],
                  ),
                ),

                // ── Two-up content ─────────────────────────────────────
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Left animal
                      buildHalf(left.history, left.tag, left.name),

                      // Divider
                      pw.Container(
                        width: gap,
                        child: pw.Center(
                          child: pw.Container(
                            width: 1,
                            color: dividerBg,
                          ),
                        ),
                      ),

                      // Right animal (or empty placeholder)
                      if (right != null)
                        buildHalf(right.history, right.tag, right.name)
                      else
                        pw.Container(width: halfW), // empty right half
                    ],
                  ),
                ),

                // ── Footer note ────────────────────────────────────────
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 3),
                  child: pw.Text(
                      'Values in Liters (L)  |  '
                      'Animals on this page: '
                      '${left.tag}${right != null ? "  &  ${right.tag}" : ""}',
                      style: const pw.TextStyle(
                          fontSize: 7.0, color: PdfColors.grey500)),
                ),
              ],
            );
          },
        ),
      );
    }

    // ── Save ─────────────────────────────────────────────────────────────────
    final safeMonth = DateFormat('yyyy_MM').format(DateTime(year, month));
    final filename = animals.length == 1
        ? 'DMR_${animals.first.tag.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_$safeMonth.pdf'
        : 'DMR_All_Animals_$safeMonth.pdf';

    await _saveAndOpenPdf(pdf, filename);
  }
  // ────────────────────────────────────────────────────────────────────────────
  // Cash Sales Report
  // ────────────────────────────────────────────────────────────────────────────
  static Future<void> exportCashSales(
      List<CashSaleModel> sales, String fromDate, String toDate) async {
    if (sales.isEmpty) {
      Get.snackbar('No Data', 'No cash sales data in selected range',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final excel = Excel.createExcel();
    final sheet = excel['Cash Sales'];
    excel.delete('Sheet1');

    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('F1'));
    sheet.cell(CellIndex.indexByString('A1')).value =
        TextCellValue('CASH SALES REPORT (CSR)');
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
        bold: true, fontSize: 14, horizontalAlign: HorizontalAlign.Center);
    sheet.cell(CellIndex.indexByString('A2')).value =
        TextCellValue('Period: $fromDate to $toDate');

    final headers = [
      'Date', 'Notes / Buyer', 'Cash Received (Rs.)',
      'Rate per Liter (Rs.)', 'Liters Deducted (L)', 'Time Recorded',
    ];
    for (int i = 0; i < headers.length; i++) {
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#E0F2F1'));
    }

    int row = 4;
    double grandC = 0, grandL = 0;
    final Map<String, List<CashSaleModel>> byDate = {};
    for (final s in sales) byDate.putIfAbsent(s.saleDate, () => []).add(s);

    for (final date in byDate.keys.toList()..sort()) {
      for (final s in byDate[date]!) {
        String time = '—';
        try {
          final dt = DateTime.parse(s.createdAt);
          time =
              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        } catch (_) {}
        _writeRow(sheet, row, [
          s.saleDate, s.notes ?? 'Cash sale',
          s.cashAmount.toStringAsFixed(0),
          s.ratePerLiter.toStringAsFixed(0),
          s.litersFromCash.toStringAsFixed(2), time,
        ]);
        grandC += s.cashAmount;
        grandL += s.litersFromCash;
        row++;
      }
      final dc = byDate[date]!.fold(0.0, (s, e) => s + e.cashAmount);
      final dl = byDate[date]!.fold(0.0, (s, e) => s + e.litersFromCash);
      for (final pair in [
        (0, '$date TOTAL →'),
        (2, dc.toStringAsFixed(0)),
        (4, dl.toStringAsFixed(2)),
      ]) {
        sheet.cell(CellIndex.indexByColumnRow(
                columnIndex: pair.$1, rowIndex: row))
          ..value = TextCellValue(pair.$2)
          ..cellStyle = CellStyle(
              bold: true,
              backgroundColorHex: ExcelColor.fromHexString('#F0F4C3'));
      }
      row++;
    }

    row++;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue('GRAND TOTAL')
      ..cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#B2DFDB'));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
      ..value = TextCellValue('Rs. ${grandC.toStringAsFixed(0)}')
      ..cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#B2DFDB'));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
      ..value = TextCellValue('${grandL.toStringAsFixed(2)} L')
      ..cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#B2DFDB'));

    sheet.setColumnWidth(0, 14);
    sheet.setColumnWidth(1, 22);
    sheet.setColumnWidth(2, 20);
    sheet.setColumnWidth(3, 20);
    sheet.setColumnWidth(4, 18);
    sheet.setColumnWidth(5, 16);
    await _saveAndOpen(excel, 'CSR_${fromDate}_$toDate.xlsx');
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Client Bills
  // ────────────────────────────────────────────────────────────────────────────
  static Future<void> exportClientBills(List<SaleModel> sales,
      String clientName, String fromDate, String toDate) async {
    if (sales.isEmpty) {
      Get.snackbar('No Data', 'No sales data to export',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final excel = Excel.createExcel();
    final sheet = excel['Client Bills'];
    excel.delete('Sheet1');

    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('I1'));
    sheet.cell(CellIndex.indexByString('A1')).value =
        TextCellValue('CLIENT BILL REPORT — $clientName');
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
        bold: true, fontSize: 14, horizontalAlign: HorizontalAlign.Center);
    sheet.cell(CellIndex.indexByString('A2')).value =
        TextCellValue('Period: $fromDate to $toDate');

    final headers = [
      '#', 'Date', 'Day', 'Allocated (L)', 'Taken',
      'Extra Liters (L)', 'Extra Amount (Rs.)',
      'Total Liters (L)', 'Total Amount (Rs.)',
    ];
    for (int i = 0; i < headers.length; i++) {
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#E8F5E9'));
    }

    int row = 4;
    double grandL = 0, grandA = 0;
    for (int i = 0; i < sales.length; i++) {
      final s   = sales[i];
      final dt  = DateTime.tryParse(s.saleDate);
      final day = dt != null
          ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dt.weekday - 1]
          : '';
      _writeRow(sheet, row, [
        '${i + 1}', s.saleDate, day,
        s.allocatedLiters.toStringAsFixed(1),
        s.takenAllocated ? 'Yes' : 'No',
        s.extraLiters.toStringAsFixed(1),
        s.extraAmount.toStringAsFixed(0),
        s.totalLiters.toStringAsFixed(1),
        s.totalAmount.toStringAsFixed(0),
      ]);
      grandL += s.totalLiters;
      grandA += s.totalAmount;
      row++;
    }

    row++;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue('TOTAL')
      ..cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#C8E6C9'));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
      ..value = TextCellValue('${grandL.toStringAsFixed(1)} L')
      ..cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#C8E6C9'));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row))
      ..value = TextCellValue('Rs. ${grandA.toStringAsFixed(0)}')
      ..cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#C8E6C9'));

    sheet.setColumnWidth(0, 6);
    sheet.setColumnWidth(1, 14);
    sheet.setColumnWidth(2, 8);
    for (int i = 3; i <= 8; i++) sheet.setColumnWidth(i, 16);

    final safeName = clientName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    await _saveAndOpen(excel, 'Bill_${safeName}_${fromDate}_$toDate.xlsx');
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Monthly Ledger Export
  // ────────────────────────────────────────────────────────────────────────────
  static Future<void> exportMonthlyLedger(
      LedgerSummary s, String monthLabel) async {
    final excel = Excel.createExcel();
    final sheet = excel['Monthly Ledger'];
    excel.delete('Sheet1');

    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('C1'));
    sheet.cell(CellIndex.indexByString('A1')).value =
        TextCellValue('MONTHLY LEDGER — $monthLabel');
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
        bold: true, fontSize: 14, horizontalAlign: HorizontalAlign.Center);
    sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue(
        'Exported: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}');
    sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue(
        'Rate per Liter: Rs. ${s.ratePerLiter.toStringAsFixed(0)}');

    int row = 4;

    void section(String title, String bg) {
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row),
      );
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        ..value = TextCellValue(title)
        ..cellStyle = CellStyle(
            bold: true,
            backgroundColorHex: ExcelColor.fromHexString(bg),
            fontSize: 12);
      row++;
    }

    void dataRow(
      String label,
      String value, {
      bool bold = false,
      String? valueBg,
      String? valueColor,
      String labelPrefix = '  ',
    }) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        ..value = TextCellValue('$labelPrefix$label')
        ..cellStyle = CellStyle(bold: bold);

      final valCell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row));
      valCell.value = TextCellValue(value);

      var style = CellStyle(bold: bold, horizontalAlign: HorizontalAlign.Right);
      if (valueBg != null && valueColor != null) {
        style = CellStyle(
          bold: bold,
          horizontalAlign: HorizontalAlign.Right,
          backgroundColorHex: ExcelColor.fromHexString(valueBg),
          fontColorHex: ExcelColor.fromHexString(valueColor),
        );
      } else if (valueBg != null) {
        style = CellStyle(
          bold: bold,
          horizontalAlign: HorizontalAlign.Right,
          backgroundColorHex: ExcelColor.fromHexString(valueBg),
        );
      } else if (valueColor != null) {
        style = CellStyle(
          bold: bold,
          horizontalAlign: HorizontalAlign.Right,
          fontColorHex: ExcelColor.fromHexString(valueColor),
        );
      }
      valCell.cellStyle = style;
      row++;
    }

    void blankRow() => row++;

    void thinDivider() {
      final dividerStyle = CellStyle(
          backgroundColorHex: ExcelColor.fromHexString('#EEEEEE'));
      for (int c = 0; c < 3; c++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row))
            .cellStyle = dividerStyle;
      }
      row++;
    }

    section('INCOME', '#C8E6C9');
    dataRow('Client Billing',
        'Rs. ${s.totalClientBilling.toStringAsFixed(0)}');
    dataRow('Cash Sales', 'Rs. ${s.totalCashSales.toStringAsFixed(0)}');
    if (s.totalCreditPayments > 0) {
      dataRow('Credit Payments Received',
          'Rs. ${s.totalCreditPayments.toStringAsFixed(0)}',
          valueColor: '#00695C');
    }
    final freeMilkRs = s.freeMilkValue;
    dataRow(
      'Free Milk Deduction  '
      '(${s.freeMilkGiven.toStringAsFixed(1)} L x Rs. ${s.ratePerLiter.toStringAsFixed(0)}/L)',
      '- Rs. ${freeMilkRs.toStringAsFixed(0)}',
      valueColor: '#C62828',
    );
    thinDivider();
    dataRow('Gross Revenue  (Billing + Cash + Credit Payments)',
        'Rs. ${s.grossRevenue.toStringAsFixed(0)}');
    dataRow('Net Revenue  (after free milk)',
        'Rs. ${s.netRevenue.toStringAsFixed(0)}',
        bold: true, valueBg: '#E8F5E9');
    blankRow();

    section('EXPENSES', '#FFCDD2');
    dataRow('Total Expenses',
        'Rs. ${s.totalExpenses.toStringAsFixed(0)}', bold: true);
    blankRow();

    final isProfit = s.netProfit >= 0;
    section(isProfit ? 'NET PROFIT' : 'NET LOSS',
        isProfit ? '#A5D6A7' : '#EF9A9A');
    dataRow(
      isProfit
          ? 'Net Profit  (Net Revenue - Expenses)'
          : 'Net Loss  (Expenses - Net Revenue)',
      'Rs. ${s.netProfit.abs().toStringAsFixed(0)}',
      bold: true,
      valueColor: isProfit ? '#1B5E20' : '#B71C1C',
    );
    blankRow();

    section('MILK PRODUCTION & SALES', '#E8F5E9');
    dataRow('Total Produced', '${s.totalMilkProduced.toStringAsFixed(1)} L');
    dataRow('Sold to Clients (paying)',
        '${s.totalMilkSoldClients.toStringAsFixed(1)} L');
    dataRow('Cash Sales', '${s.totalMilkCash.toStringAsFixed(1)} L');
    if (s.totalMilkCredit > 0) {
      dataRow('Given on Credit',
          '${s.totalMilkCredit.toStringAsFixed(1)} L  (pending payment)',
          valueColor: '#E65100');
    }
    dataRow(
      'Given Free',
      '${s.freeMilkGiven.toStringAsFixed(1)} L  '
      '(approx Rs. ${freeMilkRs.toStringAsFixed(0)})',
      valueColor: '#E65100',
    );
    blankRow();

    section('CLIENTS', '#E8F5E9');
    dataRow('Active Paying', '${s.activePayingClients}');
    dataRow('Active Free',   '${s.activeFreeClients}');
    dataRow('Total Active',
        '${s.activePayingClients + s.activeFreeClients}', bold: true);

    sheet.setColumnWidth(0, 52);
    sheet.setColumnWidth(1, 4);
    sheet.setColumnWidth(2, 26);

    final String datePart;
    if (s.rangeFrom != null && s.rangeTo != null) {
      final f = DateFormat('yyyy_MM').format(s.rangeFrom!);
      final t = DateFormat('yyyy_MM').format(s.rangeTo!);
      datePart = '${f}_to_$t';
    } else {
      datePart = DateFormat('yyyy_MM').format(DateTime(s.year, s.month));
    }

    await _saveAndOpen(excel, 'Ledger_$datePart.xlsx');
  }

  // ────────────────────────────────────────────────────────────────────────────
  // PDF helper widgets
  // ────────────────────────────────────────────────────────────────────────────
  static pw.Widget _pdfHdrCell(String text, double width, double fs,
      {bool accent = false}) {
    return pw.Container(
      width: width,
      alignment: pw.Alignment.center,
      child: pw.Text(text,
          style: pw.TextStyle(
              fontSize: fs,
              fontWeight: pw.FontWeight.bold,
              color: accent ? PdfColors.yellow100 : PdfColors.white),
          textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _pdfDataCell(String text, double width, double fs,
      {bool bold = false, PdfColor? color}) {
    return pw.Container(
      width: width,
      alignment: pw.Alignment.center,
      child: pw.Text(text,
          style: pw.TextStyle(
              fontSize: fs,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? PdfColors.black),
          textAlign: pw.TextAlign.center),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Shared helpers
  // ────────────────────────────────────────────────────────────────────────────
  static void _mergedTitle(
      Sheet sheet, String title, int firstCol, int lastCol) {
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: firstCol, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: lastCol, rowIndex: 0),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: firstCol, rowIndex: 0))
      ..value = TextCellValue(title)
      ..cellStyle = CellStyle(
          bold: true, fontSize: 14, horizontalAlign: HorizontalAlign.Center);
  }

  static void _writeRow(Sheet sheet, int row, List<String> values) {
    for (int col = 0; col < values.length; col++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
          .value = TextCellValue(values[col]);
    }
  }

  static Future<void> _saveAndOpen(Excel excel, String filename) async {
    try {
      const exportsPath = r'C:\dairyfarm\exports';
      final exportsDir  = Directory(exportsPath);
      if (!await exportsDir.exists()) {
        await exportsDir.create(recursive: true);
      }
      final filePath = '$exportsPath\\$filename';
      final bytes    = excel.save();
      if (bytes != null) {
        await File(filePath).writeAsBytes(bytes);
        await OpenFile.open(filePath);
        Get.snackbar('Exported', 'Saved to: $filePath',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 4));
      }
    } catch (e) {
      Get.snackbar('Export Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  static Future<void> _saveAndOpenPdf(pw.Document pdf, String filename) async {
    try {
      const exportsPath = r'C:\dairyfarm\exports';
      final exportsDir  = Directory(exportsPath);
      if (!await exportsDir.exists()) {
        await exportsDir.create(recursive: true);
      }
      final filePath = '$exportsPath\\$filename';
      final bytes    = await pdf.save();
      await File(filePath).writeAsBytes(bytes);
      await OpenFile.open(filePath);
      Get.snackbar('Exported', 'Saved to: $filePath',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4));
    } catch (e) {
      Get.snackbar('Export Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}