// lib/data/models/video_model.dart
import 'package:tks/linkapi/linkapi.dart';

class VideoModel {
  final int videoId;
  final String? videoTitle;
  final String? videoDesc;
  final String videoUrl;
  final String? videoThumbnail;
  final int? videoProductId;
  final String? videoTargetType;
  final int? videoTargetId;
  int videoViews;
  int videoLikes;
  final int? videoUserId;
  final String? videoDate;
  final String? uploaderName;
  final String? productNameAr;
  final String? productImage;
  final String? restaurantName;
  final String? restaurantLogo;

  VideoModel({
    required this.videoId,
    required this.videoUrl,
    this.videoTitle,
    this.videoDesc,
    this.videoThumbnail,
    this.videoProductId,
    this.videoTargetType,
    this.videoTargetId,
    required this.videoViews,
    required this.videoLikes,
    this.videoUserId,
    this.videoDate,
    this.uploaderName,
    this.productNameAr,
    this.productImage,
    this.restaurantName,
    this.restaurantLogo,
  });

  String? get normalizedTargetType {
    final rawType = videoTargetType?.trim().toLowerCase() ?? '';
    if (rawType == 'item') {
      return 'product';
    }
    if (rawType == 'restaurant' || rawType == 'product') {
      return rawType;
    }
    if ((videoProductId ?? 0) > 0) {
      return 'product';
    }
    return null;
  }

  int get resolvedTargetId {
    final targetType = normalizedTargetType;
    if (targetType == 'restaurant') {
      return videoTargetId ?? 0;
    }

    if (targetType == 'product') {
      final explicitTargetId = videoTargetId ?? 0;
      if (explicitTargetId > 0) {
        return explicitTargetId;
      }
      return videoProductId ?? 0;
    }

    return 0;
  }

  bool get hasInternalTarget =>
      normalizedTargetType != null && resolvedTargetId > 0;

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      videoId: int.parse(json['video_id'].toString()),
      videoUrl: AppLink.normalizeUrl(json['video_url']?.toString()),
      videoTitle: json['video_title'],
      videoDesc: json['video_desc'],
      videoThumbnail: AppLink.normalizeUrl(json['video_thumbnail']?.toString()),
      videoProductId: json['video_product_id'] != null
          ? int.tryParse(json['video_product_id'].toString())
          : null,
      videoTargetType: json['video_target_type']?.toString(),
      videoTargetId: json['video_target_id'] != null
          ? int.tryParse(json['video_target_id'].toString())
          : null,
      videoViews: int.tryParse(json['video_views'].toString()) ?? 0,
      videoLikes: int.tryParse(json['video_likes'].toString()) ?? 0,
      videoUserId: json['video_userid'] != null
          ? int.tryParse(json['video_userid'].toString())
          : null,
      videoDate: json['video_date'],
      uploaderName: json['uploader_name'],
      productNameAr: json['product_name_ar'],
      productImage: json['product_image'],
      restaurantName: json['restaurant_name'],
      restaurantLogo: json['restaurant_logo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'video_id': videoId,
      'video_url': videoUrl,
      'video_title': videoTitle,
      'video_desc': videoDesc,
      'video_thumbnail': videoThumbnail,
      'video_product_id': videoProductId,
      'video_target_type': videoTargetType,
      'video_target_id': videoTargetId,
      'video_views': videoViews,
      'video_likes': videoLikes,
      'video_userid': videoUserId,
      'video_date': videoDate,
      'uploader_name': uploaderName,
      'product_name_ar': productNameAr,
      'product_image': productImage,
      'restaurant_name': restaurantName,
      'restaurant_logo': restaurantLogo,
    };
  }
}
