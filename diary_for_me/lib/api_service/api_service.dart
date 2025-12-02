import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 백엔드 API 서비스
class DailyLogApiService {
  final Dio _dio = Dio();
  late String baseUrl;

  /// 타임라인 생성 API 호출
  Future<Map<String, dynamic>?> getTimelineFromAPI(Map<String, dynamic> jsonData) async {
    baseUrl = dotenv.env['BASE_URL'] ?? '';

    try {
      print('####################JSON 데이터 전송 시도(${baseUrl})####################');

      Response response = await _dio.post(
        '$baseUrl/api/v1/timeline',
        data: jsonData,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(minutes: 5),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      if (response.statusCode == 200) {
        print('[타임라인 생성 성공]: ${response.statusCode}');
        final responseData = response.data as Map<String, dynamic>;
        print('####################수신받은 JSON 데이터####################');
        print(const JsonEncoder.withIndent('  ').convert(responseData));
        print('############################################################');
        return responseData;
      } else {
        print('[서버 응답 오류]: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[업로드 에러]: $e');
      return null;
    }
  }

  /// 일기 생성 API 호출
  Future<Map<String, dynamic>?> getDiaryFromAPI({
    required Map<String, dynamic> timelineJson,
    bool generateImage = true,
    bool generateMusic = true,
  }) async {
    baseUrl = dotenv.env['BASE_URL'] ?? '';

    final requestData = {
      'timeline': timelineJson,
      'generate_image': generateImage,
      'generate_music': generateMusic,
    };

    try {
      print('####################Diary 생성 요청(${baseUrl})####################');
      print(const JsonEncoder.withIndent('  ').convert(requestData));
      print('############################################################');

      Response response = await _dio.post(
        '$baseUrl/api/v1/diary',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 10),
        ),
      );

      if (response.statusCode == 200) {
        print('[일기 생성 성공]: ${response.statusCode}');
        final responseData = response.data as Map<String, dynamic>;
        print('####################수신받은 Diary JSON####################');
        print(const JsonEncoder.withIndent('  ').convert(responseData));
        print('############################################################');
        return responseData;
      } else {
        print('[❌서버 응답 오류]: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[❌일기 생성 에러]: $e');
      return null;
    }
  }
}
