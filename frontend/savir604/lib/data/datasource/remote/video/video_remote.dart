import 'package:flutter/foundation.dart';
import 'package:tks/core/class/crud.dart';
import 'package:tks/data/datasource/model/comment_model.dart';
import 'package:tks/data/datasource/model/video_model.dart';
import 'package:tks/linkapi/linkapi.dart';

class VideoRemote {
  final Crud crud;

  VideoRemote(this.crud);

  // ===================== GET VIDEOS =====================
  Future<List<VideoModel>> fetchVideos() async {
    final res = await crud.postData(AppLink.getVideos, {});

    return res.fold(
      (l) => <VideoModel>[],
      (r) {
        final dynamic raw = r;

        if (raw is List) {
          return raw.map((e) => VideoModel.fromJson(e)).toList();
        }

        if (raw is Map && raw['data'] is List) {
          return (raw['data'] as List)
              .map((e) => VideoModel.fromJson(e))
              .toList();
        }

        debugPrint('Unexpected videos response: $raw');
        return <VideoModel>[];
      },
    );
  }

  // ===================== LIKE VIDEO =====================
  Future<Map<String, dynamic>> addLike({
    required int videoId,
    required int userId,
  }) async {
    final res = await crud.postData(AppLink.addLike, {
      'videoid': videoId.toString(),
      'userid': userId.toString(),
    });

    return res.fold(
      (l) => {'status': 'error'},
      (r) => Map<String, dynamic>.from(r),
    );
  }

  // ===================== VIEW COUNTER =====================
  Future<void> increaseView({required int videoId, int? userId}) async {
    await crud.postData(AppLink.increaseView, {
      'videoid': videoId.toString(),
      'userid': userId?.toString() ?? '',
    });
  }

  // ===================== GET COMMENTS =====================
  Future<List<CommentModel>> getComments({required int videoId}) async {
    final res = await crud.postData(AppLink.getComments, {
      'videoid': videoId.toString(),
    });

    return res.fold(
      (l) => <CommentModel>[],
      (r) {
        final dynamic raw = r;

        if (raw is Map &&
            raw['status'] == 'success' &&
            raw['data'] is List) {
          return (raw['data'] as List)
              .map((e) => CommentModel.fromJson(e))
              .toList();
        }

        debugPrint('Unexpected comments response: $raw');
        return <CommentModel>[];
      },
    );
  }

  // ===================== ADD COMMENT =====================
  Future<Map<String, dynamic>> addComment({
    required int videoId,
    required int userId,
    required String comment,
    int? parentId,
  }) async {
    final Map<String, String> data = {
      'videoid': videoId.toString(),
      'userid': userId.toString(),
      'comment': comment,
    };

    if (parentId != null) {
      data['parentid'] = parentId.toString();
    }

    debugPrint('addComment sending data: $data');
    final res = await crud.postData(AppLink.addComment, data);

    return res.fold(
      (l) => {'status': 'error'},
      (r) => Map<String, dynamic>.from(r),
    );
  }

  // ===================== LIKE COMMENT =====================
  Future<Map<String, dynamic>> likeComment({
    required int commentId,
    required int userId,
  }) async {
    final res = await crud.postData(AppLink.likeComment, {
      'commentid': commentId.toString(),
      'userid': userId.toString(),
    });

    return res.fold(
      (l) => {'status': 'error'},
      (r) => Map<String, dynamic>.from(r),
    );
  }
}
