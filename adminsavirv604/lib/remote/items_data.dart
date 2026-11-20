import 'dart:convert';

import 'package:admin_tks/core/services/dashboard_api_client.dart';
import 'package:admin_tks/model/model_items.dart';

class ItemsData {
  final String apiUrl =
      "https://savir-technology.online/roaqv2/dash/items/get/get_items.php";
  final String updateApiUrl =
      "https://savir-technology.online/roaqv2/dash/items/update/update_item.php";
  final String editDataApiUrl =
      "https://savir-technology.online/roaqv2/dash/items/get/get_item_edit_data.php";
  final String attributesApiUrl =
      "https://savir-technology.online/roaqv2/dash/items/attributes/save.php";

  Future<List<ItemsModel>?> getItems() async {
    try {
      final response = await DashboardApiClient.getUrl(apiUrl);
      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> items = decoded is List
            ? decoded
            : (decoded is Map && decoded['data'] is List)
                ? decoded['data'] as List<dynamic>
                : const <dynamic>[];
        return items
            .whereType<Map>()
            .map((item) => ItemsModel.fromJson(item.cast<String, dynamic>()))
            .toList();
      }
      print("Failed to load items: ${response.statusCode}");
      return null;
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }

  Future<bool> updateItem(ItemsModel item) async {
    try {
      final response = await DashboardApiClient.postJsonUrl(
        updateApiUrl,
        body: item.toJson(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error updating item: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> deleteItem(
    String itemId,
    String imagename,
  ) async {
    try {
      final response = await DashboardApiClient.postUrl(
        'https://savir-technology.online/roaqv2/dash/items/remove/delete_item.php',
        body: {'id': itemId},
      );
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }
      print('Failed to delete item: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Error deleting item: $e');
      return null;
    }
  }

  Future<bool> addItem(ItemsModel newItem) async {
    try {
      final response = await DashboardApiClient.postJsonUrl(
        'https://savir-technology.online/roaqv2/dash/items/add/add_item.php',
        body: newItem.toJson(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error adding item: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> duplicateItem(String itemId) async {
    try {
      final response = await DashboardApiClient.postJsonUrl(
        'https://savir-technology.online/roaqv2/dash/items/add/duplicate_item.php',
        body: {'item_id': int.tryParse(itemId)},
      );
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error duplicating item: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getItemEditData(String itemId) async {
    try {
      final response = await DashboardApiClient.getUrl(
        '$editDataApiUrl?item_id=$itemId',
      );
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }
      print("Failed to load item edit data: ${response.statusCode}");
      return null;
    } catch (e) {
      print("Error loading item edit data: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateItemPayload(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await DashboardApiClient.postJsonUrl(
        updateApiUrl,
        body: payload,
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }

      print("Failed to update item payload: ${response.statusCode}");
      print(response.body);
      return null;
    } catch (e) {
      print("Error updating item payload: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> saveItemAttributes(
    String itemId,
    List<Map<String, dynamic>> attributes,
  ) async {
    try {
      final response = await DashboardApiClient.postJsonUrl(
        attributesApiUrl,
        body: {'item_id': int.tryParse(itemId), 'attributes': attributes},
      );
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error saving item attributes: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> addItemPayload(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await DashboardApiClient.postJsonUrl(
        'https://savir-technology.online/roaqv2/dash/items/add/add_item.php',
        body: payload,
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }

      print("Failed to add item payload: ${response.statusCode}");
      print(response.body);
      return null;
    } catch (e) {
      print("Error adding item payload: $e");
      return null;
    }
  }
}
