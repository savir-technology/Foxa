import 'dart:typed_data';

import 'package:admin_tks/model/order_model.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class OrderSlipPdfService {
  static const List<String> _arabicRegularAssets = [
    'assets/fonts/Amiri-Regular.ttf',
    'assets/fonts/Jomhuria-Regular.ttf',
  ];

  static const List<String> _arabicBoldAssets = [
    'assets/fonts/Amiri-Bold.ttf',
    'assets/fonts/Amiri-Regular.ttf',
    'assets/fonts/Jomhuria-Regular.ttf',
  ];

  const OrderSlipPdfService();

  Future<Uint8List> buildKitchenSlip({
    required OrderModel order,
    required List<OrderItemDetail> items,
  }) {
    return _buildSlip(
      title: 'Kitchen Slip',
      subtitle: 'Quick copy for kitchen preparation and internal printing',
      order: order,
      items: items,
      includeDeliverySummary: false,
      includeQrCode: false,
    );
  }

  Future<Uint8List> buildCustomerReceipt({
    required OrderModel order,
    required List<OrderItemDetail> items,
  }) {
    return _buildSlip(
      title: 'Customer Receipt',
      subtitle: 'A concise copy showing the order details',
      order: order,
      items: items,
      includeDeliverySummary: true,
      includeQrCode: true,
    );
  }

  Future<Uint8List> _buildSlip({
    required String title,
    required String subtitle,
    required OrderModel order,
    required List<OrderItemDetail> items,
    required bool includeDeliverySummary,
    required bool includeQrCode,
  }) async {
    final baseFont = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();
    final deliveryCode = (order.deliveryCode ?? '').trim();
    final arabicFonts = await _loadArabicFontsIfNeeded([
      title,
      subtitle,
      order.usersName ?? '',
      order.addressCity ?? '',
      order.addressStreet ?? '',
      order.addressPhone ?? '',
      order.orderTypeLabel,
      order.lifecycleLabelAr,
      for (final item in items) ...[
        item.itemName,
        item.prescriptionSummary ?? '',
        item.foodMenuOptionsSummary ?? '',
        item.foodItemNote ?? '',
      ],
      deliveryCode,
    ]);
    final document = pw.Document();

    final orderNumber = order.ordersId?.toString() ?? '-';
    final orderDate = _formatDateTime(order.orderDateTime);
    final customerName =
        _safeText(order.usersName, fallback: 'Unknown customer');
    final customerPhone = _safeText(order.addressPhone, fallback: '-');
    final customerLocation = _joinParts([
      order.addressCity,
      order.addressStreet,
    ]);
    final orderModeLabel = _orderModeLabelEn(order);
    final statusLabel = _orderStatusLabelEn(order);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(18),
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.ltr,
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green900,
                    borderRadius: pw.BorderRadius.circular(18),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      _autoText(
                        title,
                        baseFont: baseFont,
                        boldFont: boldFont,
                        arabicFonts: arabicFonts,
                        fontSize: 24,
                        color: PdfColors.white,
                        bold: true,
                      ),
                      pw.SizedBox(height: 4),
                      _autoText(
                        subtitle,
                        baseFont: baseFont,
                        boldFont: boldFont,
                        arabicFonts: arabicFonts,
                        fontSize: 12,
                        color: PdfColors.white,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: _infoCard(
                        baseFont,
                        boldFont,
                        'Order #',
                        orderNumber,
                        PdfColors.blue800,
                        arabicFonts: arabicFonts,
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: _infoCard(
                        baseFont,
                        boldFont,
                        'Order time',
                        orderDate,
                        PdfColors.teal800,
                        arabicFonts: arabicFonts,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: _infoCard(
                        baseFont,
                        boldFont,
                        'Customer',
                        customerName,
                        PdfColors.orange800,
                        arabicFonts: arabicFonts,
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: _infoCard(
                        baseFont,
                        boldFont,
                        'Phone',
                        customerPhone,
                        PdfColors.indigo800,
                        arabicFonts: arabicFonts,
                      ),
                    ),
                  ],
                ),
                if (includeDeliverySummary) ...[
                  pw.SizedBox(height: 10),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(14),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(14),
                      border: pw.Border.all(color: PdfColors.grey400),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        _autoText(
                          'Delivery details',
                          baseFont: baseFont,
                          boldFont: boldFont,
                          arabicFonts: arabicFonts,
                          fontSize: 14,
                          color: PdfColors.black,
                          bold: true,
                        ),
                        pw.SizedBox(height: 6),
                        _labelValueRow(
                          label: 'Location',
                          value:
                              customerLocation.isEmpty ? '-' : customerLocation,
                          baseFont: baseFont,
                          boldFont: boldFont,
                          arabicFonts: arabicFonts,
                        ),
                        _labelValueRow(
                          label: 'Order type',
                          value: orderModeLabel,
                          baseFont: baseFont,
                          boldFont: boldFont,
                          arabicFonts: arabicFonts,
                        ),
                        _labelValueRow(
                          label: 'Estimated preparation',
                          value: '${order.ordersEstimatedMinutes ?? 0} min',
                          baseFont: baseFont,
                          boldFont: boldFont,
                          arabicFonts: arabicFonts,
                        ),
                      ],
                    ),
                  ),
                ],
                pw.SizedBox(height: 10),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(14),
                    border: pw.Border.all(color: PdfColors.grey400),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      _autoText(
                        'Items',
                        baseFont: baseFont,
                        boldFont: boldFont,
                        arabicFonts: arabicFonts,
                        fontSize: 16,
                        color: PdfColors.black,
                        bold: true,
                      ),
                      pw.SizedBox(height: 10),
                      pw.TableHelper.fromTextArray(
                        headers: const ['Item', 'Qty', 'Total'],
                        headerStyle: pw.TextStyle(
                          font: boldFont,
                          fontSize: 11,
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        cellStyle: pw.TextStyle(
                          font: baseFont,
                          fontSize: 10.5,
                          color: PdfColors.black,
                        ),
                        cellPadding: const pw.EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 5,
                        ),
                        headerPadding: const pw.EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        headerDecoration: const pw.BoxDecoration(
                          color: PdfColors.green800,
                        ),
                        oddRowDecoration: const pw.BoxDecoration(
                          color: PdfColors.grey50,
                        ),
                        border: pw.TableBorder.all(
                          color: PdfColors.grey400,
                          width: 0.7,
                        ),
                        headerAlignment: pw.Alignment.centerLeft,
                        cellAlignments: const {
                          0: pw.Alignment.centerLeft,
                          1: pw.Alignment.center,
                          2: pw.Alignment.centerRight,
                        },
                        tableDirection: pw.TextDirection.ltr,
                        cellBuilder: (index, data, rowNum) {
                          final text = data.toString();
                          final isArabic = _containsArabic(text);
                          final font = isArabic
                              ? arabicFonts?.regular ?? baseFont
                              : baseFont;
                          return pw.Text(
                            text,
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 10.5,
                              color: PdfColors.black,
                            ),
                            textDirection: isArabic
                                ? pw.TextDirection.rtl
                                : pw.TextDirection.ltr,
                            textAlign: index == 1
                                ? pw.TextAlign.center
                                : index == 2
                                    ? pw.TextAlign.right
                                    : pw.TextAlign.left,
                          );
                        },
                        columnWidths: const {
                          0: pw.FlexColumnWidth(3),
                          1: pw.FlexColumnWidth(1),
                          2: pw.FlexColumnWidth(1.3),
                        },
                        data: items.isEmpty
                            ? [
                                ['No items', '-', '-'],
                              ]
                            : items
                                .map(
                                  (item) => [
                                    item.itemName,
                                    '${item.quantity}',
                                    _money(item.lineTotal),
                                  ],
                                )
                                .toList(),
                      ),
                    ],
                  ),
                ),
                if (_hasItemNotes(items)) ...[
                  pw.SizedBox(height: 10),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(14),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(14),
                      border: pw.Border.all(color: PdfColors.grey400),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text(
                          'Item notes',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        ...items
                            .where(
                              (item) =>
                                  (item.prescriptionSummary
                                          ?.trim()
                                          .isNotEmpty ??
                                      false) ||
                                  item.hasFoodNote ||
                                  item.hasFoodOptions,
                            )
                            .map(
                              (item) => pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 5),
                                child: _autoText(
                                  _itemNotesLine(item),
                                  baseFont: baseFont,
                                  boldFont: boldFont,
                                  arabicFonts: arabicFonts,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
                pw.SizedBox(height: 10),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: _infoCard(
                        baseFont,
                        boldFont,
                        'Total',
                        '${_money(order.totalPriceValue)} SAR',
                        PdfColors.green800,
                        arabicFonts: arabicFonts,
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: _infoCard(
                        baseFont,
                        boldFont,
                        'Status',
                        statusLabel,
                        PdfColors.blue800,
                        arabicFonts: arabicFonts,
                      ),
                    ),
                  ],
                ),
                if (deliveryCode.isNotEmpty) ...[
                  pw.SizedBox(height: 10),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(14),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.orange50,
                      borderRadius: pw.BorderRadius.circular(14),
                      border: pw.Border.all(color: PdfColors.orange200),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 42,
                          height: 42,
                          alignment: pw.Alignment.center,
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.orange700,
                            shape: pw.BoxShape.circle,
                          ),
                          child: _autoText(
                            'PIN',
                            baseFont: baseFont,
                            boldFont: boldFont,
                            arabicFonts: arabicFonts,
                            fontSize: 11,
                            color: PdfColors.white,
                            bold: true,
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              _autoText(
                                'Delivery code',
                                baseFont: baseFont,
                                boldFont: boldFont,
                                arabicFonts: arabicFonts,
                                fontSize: 12,
                                color: PdfColors.orange900,
                                bold: true,
                              ),
                              pw.SizedBox(height: 3),
                              _autoText(
                                deliveryCode,
                                baseFont: baseFont,
                                boldFont: boldFont,
                                arabicFonts: arabicFonts,
                                fontSize: 20,
                                color: PdfColors.black,
                                bold: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (includeQrCode) ...[
                  pw.SizedBox(height: 10),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(14),
                      border: pw.Border.all(color: PdfColors.grey400),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              _autoText(
                                'Order tracking QR',
                                baseFont: baseFont,
                                boldFont: boldFont,
                                arabicFonts: arabicFonts,
                                fontSize: 12,
                                bold: true,
                              ),
                              pw.SizedBox(height: 4),
                              _autoText(
                                'Scan the QR code or use the order number to track this receipt.',
                                baseFont: baseFont,
                                boldFont: boldFont,
                                arabicFonts: arabicFonts,
                                fontSize: 8.5,
                              ),
                              if (deliveryCode.isNotEmpty) ...[
                                pw.SizedBox(height: 3),
                                _autoText(
                                  'Delivery code: $deliveryCode',
                                  baseFont: baseFont,
                                  boldFont: boldFont,
                                  arabicFonts: arabicFonts,
                                  fontSize: 9,
                                  bold: true,
                                ),
                              ],
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data:
                              'https://savir-technology.online/roaqv2/order/$orderNumber',
                          width: 70,
                          height: 70,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _infoCard(pw.Font font, pw.Font boldFont, String label,
      String value, PdfColor color,
      {required _ArabicFonts? arabicFonts}) {
    final labelIsArabic = _containsArabic(label);
    final labelFont = labelIsArabic
        ? arabicFonts?.bold ?? arabicFonts?.regular ?? boldFont
        : boldFont;
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(14),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: labelFont,
              fontSize: 12,
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            textDirection:
                labelIsArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          ),
          pw.SizedBox(height: 5),
          _autoText(
            value,
            baseFont: font,
            boldFont: boldFont,
            arabicFonts: arabicFonts,
            fontSize: 14,
            color: PdfColors.white,
            bold: false,
          ),
        ],
      ),
    );
  }

  pw.Widget _labelValueRow({
    required String label,
    required String value,
    required pw.Font baseFont,
    required pw.Font boldFont,
    required _ArabicFonts? arabicFonts,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$label: ',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 11.5,
              color: PdfColors.black,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Expanded(
            child: _autoText(
              value,
              baseFont: baseFont,
              boldFont: boldFont,
              arabicFonts: arabicFonts,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _autoText(
    String text, {
    required pw.Font baseFont,
    required pw.Font boldFont,
    required _ArabicFonts? arabicFonts,
    required double fontSize,
    PdfColor? color,
    bool bold = false,
  }) {
    final hasArabic = _containsArabic(text);
    final font = hasArabic
        ? (bold
            ? arabicFonts?.bold ?? arabicFonts?.regular ?? boldFont
            : arabicFonts?.regular ?? baseFont)
        : (bold ? boldFont : baseFont);
    return pw.Text(
      text,
      style: pw.TextStyle(
        font: font,
        fontSize: fontSize,
        color: color,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
      textDirection: hasArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
    );
  }

  Future<_ArabicFonts?> _loadArabicFontsIfNeeded(List<String> texts) async {
    if (!texts.any(_containsArabic)) {
      return null;
    }

    final regular = await _loadFirstAvailableFont(_arabicRegularAssets);
    final bold = await _loadFirstAvailableFont(_arabicBoldAssets);
    return _ArabicFonts(regular: regular, bold: bold);
  }

  Future<pw.Font> _loadFirstAvailableFont(List<String> assets) async {
    for (final asset in assets) {
      try {
        final fontData = await rootBundle.load(asset);
        return pw.Font.ttf(fontData);
      } catch (_) {
        // Try the next bundled font.
      }
    }

    return pw.Font.helvetica();
  }

  bool _containsArabic(String text) {
    for (final rune in text.runes) {
      if (_isArabicRune(rune)) {
        return true;
      }
    }
    return false;
  }

  bool _isArabicRune(int rune) {
    return (rune >= 0x0600 && rune <= 0x06FF) ||
        (rune >= 0x0750 && rune <= 0x077F) ||
        (rune >= 0x08A0 && rune <= 0x08FF) ||
        (rune >= 0xFB50 && rune <= 0xFDFF) ||
        (rune >= 0xFE70 && rune <= 0xFEFF);
  }

  bool _hasItemNotes(List<OrderItemDetail> items) {
    return items.any(
      (item) =>
          (item.prescriptionSummary?.trim().isNotEmpty ?? false) ||
          item.hasFoodNote ||
          item.hasFoodOptions,
    );
  }

  String _itemNotesLine(OrderItemDetail item) {
    final parts = <String>[item.itemName];
    final prescription = item.prescriptionSummary?.trim();
    final options = item.foodMenuOptionsSummary?.trim();
    final note = item.foodItemNote?.trim();

    if (prescription != null && prescription.isNotEmpty) {
      parts.add('Notes: $prescription');
    }
    if (item.hasFoodOptions && options != null && options.isNotEmpty) {
      parts.add('Options: $options');
    }
    if (item.hasFoodNote && note != null && note.isNotEmpty) {
      parts.add('Customer note: $note');
    }

    return parts.join(' | ');
  }

  String _orderModeLabelEn(OrderModel order) {
    if (order.isPickup) return 'Pickup';
    final mode = (order.orderMode ?? '').trim().toLowerCase();
    if (mode == 'scheduled') return 'Scheduled';
    if (mode == 'preorder') return 'Preorder';
    if (order.isScheduledOrder) return 'Scheduled';
    return 'Regular';
  }

  String _orderStatusLabelEn(OrderModel order) {
    switch (order.lifecycleBucket) {
      case 'scheduled':
        return 'Scheduled';
      case 'preparing':
        return 'Preparing';
      case 'in_delivery':
        return 'In delivery';
      case 'delivered':
        return 'Delivered';
      case 'canceled':
        return 'Canceled';
      default:
        return 'New';
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  String _joinParts(List<String?> parts) {
    final cleaned = parts
        .map((part) => part?.trim() ?? '')
        .where((part) => part.isNotEmpty)
        .toList();
    return cleaned.join(', ');
  }

  String _safeText(String? value, {required String fallback}) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _money(double value) {
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }
}

class _ArabicFonts {
  const _ArabicFonts({
    required this.regular,
    required this.bold,
  });

  final pw.Font regular;
  final pw.Font bold;
}
