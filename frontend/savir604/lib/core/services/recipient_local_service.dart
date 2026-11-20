import 'dart:convert';

import 'package:get/get.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/data/datasource/model/recipient_model.dart';

class RecipientLocalService {
  RecipientLocalService({MyServices? myServices})
      : _myServices = myServices ?? Get.find<MyServices>();

  static const String _recipientsKey = 'aleppo_saved_recipients';
  final MyServices _myServices;

  List<RecipientModel> loadRecipients() {
    final raw = _myServices.sharedPreferences.getString(_recipientsKey);
    if (raw == null || raw.trim().isEmpty) {
      return <RecipientModel>[];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map(
            (item) => RecipientModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      return <RecipientModel>[];
    }
  }

  Future<void> saveRecipients(List<RecipientModel> recipients) async {
    final encoded = jsonEncode(
      recipients.map((recipient) => recipient.toJson()).toList(),
    );
    await _myServices.sharedPreferences.setString(_recipientsKey, encoded);
  }
}
