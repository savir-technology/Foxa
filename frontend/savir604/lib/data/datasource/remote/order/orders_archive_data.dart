// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tks/data/datasource/model/orders_archive_model.dart';
import 'package:tks/linkapi/linkapi.dart';

class OrdersArchiveData {
  Future<List<OrdersArchiveModel>> getOrdersArchive(int userId) async {
    try {
      final response = await http.post(
        Uri.parse(AppLink.ordersarchive),
        body: {'userid': userId.toString()},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final List orders = data['data'];
          return orders.map((e) => OrdersArchiveModel.fromJson(e)).toList();
        } else {
          print("No archive data available for user $userId");
        }
      } else {
        print("HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in getOrdersArchive: $e");
    }
    return [];
  }
}
