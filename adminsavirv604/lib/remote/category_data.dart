import 'dart:convert';
import 'package:admin_tks/core/services/dashboard_api_client.dart';
import '../model/model_category.dart';
import '../model/categories_model.dart';

class CategoryData {
  final String apiUrl =
      'https://savir-technology.online/roaqv2/dash/sections/get/get_categories.php';
  final String addApiUrl =
      'https://savir-technology.online/roaqv2/dash/sections/add/addcategories.php';

  Future<List<cat>> getCategories({
    bool authorized = true,
  }) async {
    try {
      final response = await DashboardApiClient.getUrl(
        apiUrl,
        authorized: authorized,
      );

      if (response.statusCode != 200) {
        print('Failed to load categories: ${response.statusCode}');
        return [];
      }

      final decoded = json.decode(utf8.decode(response.bodyBytes));
      final List<dynamic> rows = decoded is List
          ? decoded
          : decoded is Map && decoded['data'] is List
              ? decoded['data'] as List<dynamic>
              : const <dynamic>[];

      return rows
          .whereType<Map>()
          .map((entry) => cat.fromJson(entry.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      print('Error loading categories: $e');
      return [];
    }
  }

  // إضافة قسم
  Future<bool> addCategory(CategoryModel category) async {
    try {
      final data = <String, dynamic>{
        'categories_name_ar': category.categoryNameAr,
        'categories_name_en': category.categoryNameEn,
        'categories_image': category.categoryImage ?? '',
      };

      final response = await DashboardApiClient.postJsonUrl(
        addApiUrl,
        body: data,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonResponse is Map && jsonResponse['status'] == 'success';
      } else {
        print('فشل الاتصال بالسيرفر، كود الخطأ: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('خطأ في دالة addCategory: $e');
      return false;
    }
  }

  // 🗑️ حذف قسم
  Future<bool> deleteCategory(String id) async {
    try {
      final response = await DashboardApiClient.getUrl(
        "https://savir-technology.online/roaqv2/dash/sections/remove/deletecategories.php?id=$id",
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data is Map && data['status'] == 'success';
      } else {
        print("فشل الحذف، كود: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("خطأ في deleteCategory: $e");
      return false;
    }
  }
}
