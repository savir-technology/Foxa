import 'dart:convert';

import 'package:admin_tks/core/services/dashboard_api_client.dart';
import 'package:admin_tks/model/accounting_entry.dart';
import 'package:admin_tks/model/expense_model.dart';
import 'package:admin_tks/model/report_models.dart';
import 'package:admin_tks/model/waste_model.dart';
import 'package:http/http.dart' as http;

class AccountingData {
  final String baseUrl =
      'https://savir-technology.online/roaqv2/dash/accounting/';
  final String inventoryCountUrl =
      'https://savir-technology.online/roaqv2/dash/items/count/items_count.php';

  dynamic _decodeBody(http.Response response) {
    return json.decode(utf8.decode(response.bodyBytes));
  }

  Future<List<AccountingEntry>?> getLedger() async {
    try {
      final res =
          await DashboardApiClient.getUrl('${baseUrl}ledger/get_all.php');
      if (res.statusCode == 200) {
        final jsonBody = _decodeBody(res);
        final data = jsonBody['data'] as List<dynamic>? ?? [];
        return data.map((e) => AccountingEntry.fromJson(e)).toList();
      }
    } catch (e) {
      // ignore: avoid_print
      print('getLedger error: $e');
    }
    return null;
  }

  Future<List<AccountingEntry>?> getLedgerByOrder(String orderId) async {
    try {
      final uri = Uri.parse(
        '${baseUrl}ledger/get_by_order.php?order_id=${Uri.encodeComponent(orderId)}',
      );
      final res = await DashboardApiClient.getUrl(uri.toString());
      if (res.statusCode == 200) {
        final jsonBody = _decodeBody(res);
        final data = jsonBody['data'] as List<dynamic>? ?? [];
        return data.map((e) => AccountingEntry.fromJson(e)).toList();
      }
    } catch (e) {
      // ignore: avoid_print
      print('getLedgerByOrder error: $e');
    }
    return null;
  }

  Future<SalesReportResponse?> getSalesReport() async {
    try {
      final res =
          await DashboardApiClient.getUrl('${baseUrl}reports/sales_report.php');
      if (res.statusCode == 200) {
        final jsonBody = _decodeBody(res);
        if (jsonBody['status'] != 'success') return null;

        final summaryJson =
            (jsonBody['summary'] as Map?)?.cast<String, dynamic>() ?? {};
        final rowsJson =
            (jsonBody['data'] as List<dynamic>?) ?? const <dynamic>[];

        return SalesReportResponse(
          summary: SalesReportSummary.fromJson(summaryJson),
          rows: rowsJson
              .map((e) =>
                  SalesReportRow.fromJson((e as Map).cast<String, dynamic>()))
              .toList(),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('getSalesReport error: $e');
    }
    return null;
  }

  Future<ProfitReport?> getProfitReport() async {
    try {
      final res = await DashboardApiClient.getUrl(
          '${baseUrl}reports/profit_report.php');
      if (res.statusCode == 200) {
        final jsonBody = _decodeBody(res);
        final data = jsonBody['data'];
        if (jsonBody['status'] == 'success' && data is Map<String, dynamic>) {
          return ProfitReport.fromJson(data);
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('getProfitReport error: $e');
    }
    return null;
  }

  Future<List<ExpenseModel>?> getExpenses() async {
    try {
      final res = await DashboardApiClient.getUrl(
          '${baseUrl}expenses/get_expenses.php');
      if (res.statusCode == 200) {
        final jsonBody = _decodeBody(res);
        final data = jsonBody['data'] as List<dynamic>? ?? [];
        return data.map((e) => ExpenseModel.fromJson(e)).toList();
      }
    } catch (e) {
      // ignore: avoid_print
      print('getExpenses error: $e');
    }
    return null;
  }

  Future<bool> addExpense(String title, String amount) async {
    try {
      final res = await DashboardApiClient.postUrl(
        '${baseUrl}expenses/add_expense.php',
        body: {'title': title, 'amount': amount},
      );
      if (res.statusCode == 200) {
        final jsonBody = _decodeBody(res);
        return jsonBody['status'] == 'success';
      }
    } catch (e) {
      // ignore: avoid_print
      print('addExpense error: $e');
    }
    return false;
  }

  Future<bool> updateExpense(String id, String title, String amount) async {
    try {
      final res = await DashboardApiClient.postUrl(
        '${baseUrl}expenses/update_expense.php',
        body: {'id': id, 'title': title, 'amount': amount},
      );
      if (res.statusCode == 200) {
        final jsonBody = _decodeBody(res);
        return jsonBody['status'] == 'success';
      }
    } catch (e) {
      // ignore: avoid_print
      print('updateExpense error: $e');
    }
    return false;
  }

  Future<bool> deleteExpense(String id) async {
    try {
      final res = await DashboardApiClient.postUrl(
        '${baseUrl}expenses/delete_expense.php',
        body: {'id': id},
      );
      if (res.statusCode == 200) {
        final jsonBody = _decodeBody(res);
        return jsonBody['status'] == 'success';
      }
    } catch (e) {
      // ignore: avoid_print
      print('deleteExpense error: $e');
    }
    return false;
  }

  Future<bool> deleteAccountingEntry(String entryId) async {
    try {
      final res = await DashboardApiClient.postUrl(
        '${baseUrl}ledger/delete_accounting_entry.php',
        body: {'id': entryId},
      );
      if (res.statusCode == 200) {
        final jsonBody = _decodeBody(res);
        return jsonBody['status'] == 'success';
      }
    } catch (e) {
      // ignore: avoid_print
      print('deleteAccountingEntry error: $e');
    }
    return false;
  }

  Future<WasteLedgerResponse?> getWasteLedger() async {
    try {
      final res =
          await DashboardApiClient.getUrl('${baseUrl}waste/get_waste.php');
      if (res.statusCode == 200) {
        final jsonBody = _decodeBody(res);
        if (jsonBody['status'] != 'success') return null;

        final summaryJson =
            (jsonBody['summary'] as Map?)?.cast<String, dynamic>() ?? {};
        final rowsJson =
            (jsonBody['data'] as List<dynamic>?) ?? const <dynamic>[];

        return WasteLedgerResponse(
          summary: WasteSummary.fromJson(summaryJson),
          rows: rowsJson
              .map((e) =>
                  WasteRecord.fromJson((e as Map).cast<String, dynamic>()))
              .toList(),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('getWasteLedger error: $e');
    }
    return null;
  }

  Future<bool> addWasteEntry({
    required int itemId,
    int? variantId,
    required int quantity,
    required double costPerUnit,
    required String reason,
    String? notes,
    String? wasteDate,
  }) async {
    try {
      final body = <String, String>{
        'item_id': '$itemId',
        'quantity': '$quantity',
        'cost_per_unit': costPerUnit.toStringAsFixed(2),
        'reason': reason.trim(),
      };
      if (variantId != null) {
        body['variant_id'] = '$variantId';
      }
      if (notes != null && notes.trim().isNotEmpty) {
        body['notes'] = notes.trim();
      }
      if (wasteDate != null && wasteDate.trim().isNotEmpty) {
        body['waste_date'] = wasteDate.trim();
      }

      final res = await DashboardApiClient.postUrl(
        '${baseUrl}waste/add_waste.php',
        body: body,
      );
      if (res.statusCode == 200) {
        final jsonBody = _decodeBody(res);
        return jsonBody['status'] == 'success';
      }
    } catch (e) {
      // ignore: avoid_print
      print('addWasteEntry error: $e');
    }
    return false;
  }

  Future<bool> deleteWasteEntry(int id) async {
    try {
      final res = await DashboardApiClient.postUrl(
        '${baseUrl}waste/delete_waste.php',
        body: {'id': '$id'},
      );
      if (res.statusCode == 200) {
        final jsonBody = _decodeBody(res);
        return jsonBody['status'] == 'success';
      }
    } catch (e) {
      // ignore: avoid_print
      print('deleteWasteEntry error: $e');
    }
    return false;
  }

  Future<List<InventoryVariantOption>> getInventoryVariantsForWaste() async {
    try {
      final res = await DashboardApiClient.getUrl(inventoryCountUrl);
      if (res.statusCode == 200) {
        final jsonBody = _decodeBody(res);
        if (jsonBody is! Map || jsonBody['status'] != 'success') {
          return <InventoryVariantOption>[];
        }
        final data = (jsonBody['data'] as List<dynamic>?) ?? const <dynamic>[];
        return data
            .map((e) => InventoryVariantOption.fromJson(
                (e as Map).cast<String, dynamic>()))
            .where((row) => row.itemId > 0 && row.variantId > 0)
            .toList();
      }
    } catch (e) {
      // ignore: avoid_print
      print('getInventoryVariantsForWaste error: $e');
    }
    return <InventoryVariantOption>[];
  }
}
