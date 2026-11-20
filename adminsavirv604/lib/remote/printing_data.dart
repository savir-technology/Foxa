import 'dart:convert';

import 'package:admin_tks/core/services/dashboard_api_client.dart';
import 'package:admin_tks/model/printing_model.dart';

class PrintingData {
  static const String _baseUrl = '${DashboardApiConfig.dashBaseUrl}/printing';
  static const String _dashboardUrl = '$_baseUrl/get_dashboard.php';
  static const String _savePrinterUrl = '$_baseUrl/save_printer.php';
  static const String _deletePrinterUrl = '$_baseUrl/delete_printer.php';
  static const String _saveTemplateUrl = '$_baseUrl/save_template.php';
  static const String _deleteTemplateUrl = '$_baseUrl/delete_template.php';
  static const String _saveSettingsUrl = '$_baseUrl/save_settings.php';
  static const String _recordPrintJobUrl = '$_baseUrl/record_print_job.php';

  Future<PrintingDashboardSnapshot> fetchDashboard() async {
    final response = await DashboardApiClient.getUrl(_dashboardUrl);
    return _decodeSnapshot(response.statusCode, response.bodyBytes);
  }

  Future<PrintingDashboardSnapshot> savePrinter(VendorPrinter printer) async {
    final response = await DashboardApiClient.postJsonUrl(
      _savePrinterUrl,
      body: printer.toPayload(),
    );
    return _decodeSnapshot(response.statusCode, response.bodyBytes);
  }

  Future<PrintingDashboardSnapshot> deletePrinter(int printerId) async {
    final response = await DashboardApiClient.postJsonUrl(
      _deletePrinterUrl,
      body: {'printer_id': printerId},
    );
    return _decodeSnapshot(response.statusCode, response.bodyBytes);
  }

  Future<PrintingDashboardSnapshot> saveTemplate(
    InvoiceTemplate template,
  ) async {
    final response = await DashboardApiClient.postJsonUrl(
      _saveTemplateUrl,
      body: template.toPayload(),
    );
    return _decodeSnapshot(response.statusCode, response.bodyBytes);
  }

  Future<PrintingDashboardSnapshot> deleteTemplate(int templateId) async {
    final response = await DashboardApiClient.postJsonUrl(
      _deleteTemplateUrl,
      body: {'template_id': templateId},
    );
    return _decodeSnapshot(response.statusCode, response.bodyBytes);
  }

  Future<PrintingDashboardSnapshot> saveSettings(
    PrintSettings settings,
  ) async {
    final response = await DashboardApiClient.postJsonUrl(
      _saveSettingsUrl,
      body: settings.toPayload(),
    );
    return _decodeSnapshot(response.statusCode, response.bodyBytes);
  }

  Future<PrintingDashboardSnapshot> recordPrintJob({
    int? printerId,
    int? templateId,
    int? orderId,
    String jobType = 'test',
    Map<String, dynamic>? payload,
  }) async {
    final response = await DashboardApiClient.postJsonUrl(
      _recordPrintJobUrl,
      body: {
        if (printerId != null) 'printer_id': printerId,
        if (templateId != null) 'template_id': templateId,
        if (orderId != null) 'order_id': orderId,
        'job_type': jobType,
        'job_payload': payload ?? const <String, dynamic>{},
      },
    );
    return _decodeSnapshot(response.statusCode, response.bodyBytes);
  }

  PrintingDashboardSnapshot _decodeSnapshot(int statusCode, List<int> bytes) {
    final decoded = json.decode(utf8.decode(bytes));
    if (statusCode != 200 ||
        decoded is! Map ||
        decoded['status'] != 'success') {
      final message = decoded is Map
          ? decoded['message']?.toString()
          : 'تعذر تحميل بيانات الطباعة';
      throw Exception(message ?? 'تعذر تحميل بيانات الطباعة');
    }

    return PrintingDashboardSnapshot.fromJson(
      decoded.cast<String, dynamic>(),
    );
  }
}
