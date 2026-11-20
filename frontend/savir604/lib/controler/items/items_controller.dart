// ignore_for_file: override_on_non_overriding_member, overridden_fields

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:tks/controler/search/search_mix_controller.dart';
import 'package:tks/core/class/StatusRequest.dart';
import 'package:tks/core/functions/handingdatacontroller.dart';
import 'package:tks/core/functions/commerce_access_guard.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/data/datasource/model/aleppo_home_model.dart';
import 'package:tks/data/datasource/model/itemsmodel.dart';
import 'package:get/get.dart';
import 'package:tks/data/datasource/remote/items/items_data.dart';

abstract class ItemsController extends GetxController {
  intialData();
  changeCat(int val, String catval);
  getItems(String categoryid);
  goToPageProductDetails(ItemsModel itemsModel);
}

class ItemsControllerImp extends SearchMixController {
  List categories = [];
  String? catid;
  int? selectedCat;

  ItemsData testData = ItemsData(Get.find());
  List data = [];
  @override
  late StatusRequest statusRequest;
  MyServices myServices = Get.find();

  @override
  void onInit() {
    search = TextEditingController();
    intialData();
    super.onInit();
  }

  @override
  intialData() {
    categories = _normalizeCategories(Get.arguments['categories']);
    selectedCat = Get.arguments['selectedcat'];
    catid = Get.arguments['catid'];
    getItems(catid!);
  }

  @override
  changeCat(val, catval) {
    selectedCat = val;
    catid = catval;
    getItems(catid!);
    update();
  }

  @override
  getItems(String categoryid) async {
    data.clear();
    statusRequest = StatusRequest.loading;
    final userId = myServices.sharedPreferences.getInt("id")?.toString() ?? '';
    var response = await testData.getData(categoryid, userId);
    statusRequest = handlingData(response);
    if (StatusRequest.success == statusRequest) {
      if (response['status'] == "success") {
        data.addAll(response['data']);
      } else {
        statusRequest = StatusRequest.failure;
      }
    }
    update();
  }

  @override
  goToPageProductDetails(itemsModel) {
    unawaited(
      CommerceAccessGuard.openProduct(
        itemId: itemsModel.itemsId ?? '',
        arguments: {
          'item_id': itemsModel.itemsId,
          'itemsmodel': itemsModel,
        },
        parameters: {
          'item_id': itemsModel.itemsId ?? '',
        },
      ),
    );
  }

  void syncProductRating(ItemsModel updatedItem) {
    for (var i = 0; i < data.length; i++) {
      final item = ItemsModel.fromJson(Map<String, dynamic>.from(data[i]));
      if (item.itemsId == updatedItem.itemsId) {
        final updatedMap = Map<String, dynamic>.from(data[i]);
        updatedMap['average_rating'] = updatedItem.averageRating;
        updatedMap['ratings_count'] = updatedItem.ratingsCount;
        updatedMap['rating_percentage'] = updatedItem.ratingPercentage;
        updatedMap['is_top_rated'] = updatedItem.isTopRated;
        data[i] = updatedMap;
        break;
      }
    }
    update();
  }

  @override
  void onSearchItems() async {
    String searchQuery = search?.text ?? "";
    var response = await testData.searchData(searchQuery);
    statusRequest = handlingData(response);
    if (StatusRequest.success == statusRequest) {
      if (response['status'] == "success") {
        data = response['data'];
      } else {
        statusRequest = StatusRequest.failure;
      }
    }
    update();
  }
}

List<dynamic> _normalizeCategories(dynamic rawCategories) {
  if (rawCategories is! List) {
    return <dynamic>[];
  }

  return rawCategories.map((category) {
    if (category is Map<String, dynamic>) {
      return category;
    }
    if (category is Map) {
      return Map<String, dynamic>.from(category);
    }
    if (category is AleppoFoodCategoryModel) {
      return <String, dynamic>{
        'categories_id': category.id.toString(),
        'categories_name_en': category.nameEn,
        'categories_name_ar': category.nameAr,
        'categories_image': category.imageUrl,
        'categories_datetime': '',
      };
    }
    return <String, dynamic>{
      'categories_id': '',
      'categories_name_en': '',
      'categories_name_ar': category.toString(),
      'categories_image': '',
      'categories_datetime': '',
    };
  }).toList();
}
