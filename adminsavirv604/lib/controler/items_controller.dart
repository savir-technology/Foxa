import 'package:admin_tks/model/model_items.dart';
import 'package:admin_tks/remote/items_data.dart';
import 'package:get/get.dart';

class ItemsController extends GetxController {
  var itemsList = <ItemsModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchItems();
  }

  // جلب البيانات من قاعدة البيانات
  void fetchItems() async {
    isLoading.value = true;
    try {
      var items = await ItemsData().getItems();
      itemsList.value = items ?? <ItemsModel>[];
    } catch (e) {
      print("Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // تحديث بيانات المنتج
  void updateItem(ItemsModel item) async {
    try {
      bool success = await ItemsData().updateItem(item); // استدعاء دالة التحديث
      if (success) {
        int index = itemsList.indexWhere((i) => i.itemsId == item.itemsId);
        if (index != -1) {
          itemsList[index] = item; // تحديث البيانات المحلية
          // تحديث القائمة بعد التعديل
          itemsList.refresh();
        }
      } else {
        print("Failed to update item in local list.");
      }
    } catch (e) {
      print("Error updating item: $e");
    }
  }

  // حذف المنتج نهائيًا من قاعدة البيانات
  void deleteItem(String itemId, String imagename) async {
    try {
      var response = await ItemsData().deleteItem(itemId, imagename);

      if (response != null && response['status'] == 'success') {
        itemsList.removeWhere((item) =>
            item.itemsId.toString() == itemId); // تحديث القائمة المحلية
        itemsList.refresh(); // تحديث القائمة بعد الحذف
      } else {
        print("Failed to delete item: ${response?['status']}");
      }
    } catch (e) {
      print("Error deleting item: $e");
    }
  }

  void addItem(ItemsModel newItem) async {
    try {
      bool success = await ItemsData().addItem(newItem); // استدعاء دالة الإضافة
      if (success) {
        itemsList.add(newItem); // إضافة المنتج الجديد إلى القائمة المحلية
      } else {
        print("Failed to add item to local list.");
      }
    } catch (e) {
      print("Error adding item: $e");
    }
  }
}
