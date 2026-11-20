// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:tks/core/class/StatusRequest.dart';
import 'package:tks/core/functions/checkinternet.dart';

class Crud {
  Future<Either<StatusRequest, Map>> postData(
    String linkurl,
    Map data, {
    Map<String, String>? headers,
    bool allowHttpErrorBody = false,
  }) async {
    if (await checkInternet()) {
      final Map<String, String> bodyMap = data.map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
      );

      print("Sending data: $bodyMap");
      // Ensure proper URL-encoding and UTF-8 charset (important for non-ASCII comments)
      final String bodyString = bodyMap.entries
          .map((e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');
      print("Raw body: $bodyString");
      final mergedHeaders = <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        ...?headers,
      };

      http.Response response;
      try {
        response = await http.post(
          Uri.parse(linkurl),
          body: bodyString,
          headers: mergedHeaders,
        );
      } on http.ClientException catch (e) {
        print("HTTP client exception: $e");
        return const Left(StatusRequest.serverfailure);
      } on SocketException catch (e) {
        print("Socket exception: $e");
        return const Left(StatusRequest.serverfailure);
      } catch (e) {
        print("Unexpected request error: $e");
        return const Left(StatusRequest.serverfailure);
      }

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      try {
        final decoded = jsonDecode(
          utf8.decode(response.bodyBytes, allowMalformed: true)
              .replaceFirst('\uFEFF', ''),
        );
        final normalized = <String, dynamic>{
          'statusCode': response.statusCode,
        };

        // --------------- أهم جزء هنا ----------------
        // لو الناتج List → حوّله إلى Map حتى لا ينهار باقي التطبيق
        if (decoded is List) {
          normalized['data'] = decoded;
        } else if (decoded is Map) {
          normalized.addAll(Map<String, dynamic>.from(decoded));
        } else {
          // أي نوع آخر → رجّعه جوه Map
          normalized['data'] = decoded;
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          return Right(normalized);
        }

        if (allowHttpErrorBody) {
          return Right(normalized);
        }

        return const Left(StatusRequest.serverfailure);
      } catch (e) {
        print("JSON decode error: $e");
        return const Left(StatusRequest.serverfailure);
      }
    } else {
      return const Left(StatusRequest.offlinefailure);
    }
  }
}
