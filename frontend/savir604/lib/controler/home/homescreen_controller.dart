import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/controler/home/home_controller.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/view/screen/cart.dart';
import 'package:tks/view/screen/home.dart';
import 'package:tks/view/screen/orders/pending.dart';
import 'package:tks/view/screen/setting.dart';

abstract class HomeScreenController extends GetxController {
  void changePage(int currentpage);
}

class HomeScreenControllerImp extends HomeScreenController {
  int currentpage = 0;
  late List<Widget> listPage;

  final MyServices myServices = Get.find();

  @override
  void onInit() {
    super.onInit();
    if (!Get.isRegistered<HomeControllerImp>()) {
      Get.put(HomeControllerImp());
    }
    listPage = [
      const HomePage(),
      Cart(),
      const OrdersPending(),
      const Settings(),
    ];
  }

  @override
  void changePage(int i) {
    if (currentpage == i) {
      return;
    }
    currentpage = i;
    update();
  }

  List<Map<String, dynamic>> bottomappbar = [
    {'title': 'home', 'icon': Icons.home},
    {'title': 'cart_tab', 'icon': Icons.shopping_cart_outlined},
    {'title': 'my_orders_tab', 'icon': Icons.receipt_long_outlined},
    {'title': 'account_tab', 'icon': Icons.person_outline_rounded},
  ];
}
