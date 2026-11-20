import 'package:get/get.dart';
import 'package:tks/core/class/StatusRequest.dart';
import 'package:tks/core/functions/handingdatacontroller.dart';
import 'package:tks/data/datasource/model/ratingmodel.dart';
import 'package:tks/data/datasource/remote/ratings/restaurant_ratings_data.dart';

class RestaurantRatingsController extends GetxController {
  final RestaurantRatingsData remote = RestaurantRatingsData(Get.find());

  StatusRequest statusRequest = StatusRequest.loading;
  int vendorId = 0;
  String restaurantName = '';
  String restaurantLogo = '';
  String restaurantCover = '';
  double averageRating = 0;
  int ratingsCount = 0;
  int ratingPercentage = 0;
  List<RatingModel> ratings = [];

  bool get isArabic => Get.locale?.languageCode == 'ar';

  @override
  void onInit() async {
    _resolveArguments();
    await fetchRatings();
    super.onInit();
  }

  void _resolveArguments() {
    final args = Get.arguments;
    if (args is! Map) {
      return;
    }

    vendorId = int.tryParse('${args['vendor_id'] ?? args['vendorId'] ?? 0}') ?? 0;
    restaurantName = '${args['restaurant_name'] ?? args['restaurantName'] ?? ''}';
    restaurantLogo = '${args['restaurant_logo'] ?? args['restaurantLogo'] ?? ''}';
    restaurantCover = '${args['restaurant_cover'] ?? args['restaurantCover'] ?? ''}';
    averageRating =
        double.tryParse('${args['average_rating'] ?? args['averageRating'] ?? 0}') ??
            0;
    ratingsCount =
        int.tryParse('${args['reviews_count'] ?? args['reviewsCount'] ?? 0}') ?? 0;
  }

  Future<void> fetchRatings() async {
    statusRequest = StatusRequest.loading;
    update();

    if (vendorId <= 0) {
      statusRequest = StatusRequest.failure;
      update();
      return;
    }

    final response = await remote.getRatings(vendorId: vendorId.toString());
    statusRequest = handlingData(response);

    if (statusRequest == StatusRequest.success &&
        response is Map &&
        response['status'] == 'success') {
      averageRating =
          double.tryParse(response['average_rating'].toString()) ?? 0.0;
      ratingsCount = int.tryParse(response['total_reviews'].toString()) ?? 0;
      ratingPercentage =
          int.tryParse(response['rating_percentage'].toString()) ?? 0;
      ratings = ((response['ratings'] as List?) ?? [])
          .whereType<Map>()
          .map(
            (entry) => RatingModel.fromJson(
              Map<String, dynamic>.from(entry),
            ),
          )
          .toList();
    } else {
      if (ratings.isEmpty) {
        ratingsCount = 0;
        ratingPercentage = 0;
      }
      ratings = [];
    }

    update();
  }

  Future<void> retryFetch() => fetchRatings();
}
