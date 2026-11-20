import 'package:get/get.dart';
import 'package:admin_tks/model/accounting_entry.dart';
import 'package:admin_tks/model/expense_model.dart';
import 'package:admin_tks/remote/accounting_data.dart';

class AccountingController extends GetxController {
  var ledgerList = <AccountingEntry>[].obs;
  var expensesList = <ExpenseModel>[].obs;
  var isLoading = false.obs;
  final AccountingData _accountingData = AccountingData();

  @override
  void onInit() {
    super.onInit();
    fetchLedger();
    fetchExpenses();
  }

  /// جلب بيانات القيد المحاسبي
  Future<void> fetchLedger() async {
    isLoading.value = true;
    try {
      var data = await _accountingData.getLedger();
      if (data != null) {
        ledgerList.value = data;
      }
    } catch (e) {
      print('fetchLedger error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// جلب بيانات المصاريف
  Future<void> fetchExpenses() async {
    isLoading.value = true;
    try {
      var data = await _accountingData.getExpenses();
      if (data != null) {
        expensesList.value = data;
      }
    } catch (e) {
      print('fetchExpenses error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// جلب بيانات القيد المحاسبي حسب الأوردر
  Future<List<AccountingEntry>?> getLedgerByOrder(String orderId) async {
    try {
      return await _accountingData.getLedgerByOrder(orderId);
    } catch (e) {
      print('getLedgerByOrder error: $e');
    }
    return null;
  }

  /// إضافة مصروف جديد
  Future<bool> addExpense(String title, String amount) async {
    try {
      bool success = await _accountingData.addExpense(title, amount);
      if (success) {
        await fetchExpenses(); // تحديث البيانات
      }
      return success;
    } catch (e) {
      print('addExpense error: $e');
    }
    return false;
  }

  /// تحديث المصروف
  Future<bool> updateExpense(String id, String title, String amount) async {
    try {
      bool success = await _accountingData.updateExpense(id, title, amount);
      if (success) {
        // تحديث البيانات المحلية
        int index = expensesList.indexWhere((e) => e.expenseId == id);
        if (index != -1) {
          // تحديث العنصر مباشرة إذا أردنا
          // لكن الأفضل أن نعيد تحميل البيانات كاملة
        }
        await fetchExpenses(); // تحديث البيانات
      }
      return success;
    } catch (e) {
      print('updateExpense error: $e');
    }
    return false;
  }

  /// حذف المصروف
  Future<bool> deleteExpense(String id) async {
    try {
      bool success = await _accountingData.deleteExpense(id);
      if (success) {
        // حذف من البيانات المحلية
        expensesList.removeWhere((e) => e.expenseId == id);
        // تحديث البيانات
        await fetchExpenses();
      }
      return success;
    } catch (e) {
      print('deleteExpense error: $e');
    }
    return false;
  }

  /// حذف قيد محاسبي
  Future<bool> deleteAccountingEntry(String entryId) async {
    try {
      bool success = await _accountingData.deleteAccountingEntry(entryId);
      if (success) {
        // حذف من البيانات المحلية
        ledgerList.removeWhere((e) => e.entryId == entryId);
        // تحديث البيانات
        await fetchLedger();
      }
      return success;
    } catch (e) {
      print('deleteAccountingEntry error: $e');
    }
    return false;
  }
}
