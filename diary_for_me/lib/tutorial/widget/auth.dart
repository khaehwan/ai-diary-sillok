// import 'dart:io' show Platform;
// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';

// import 'package:diary_for_me/main/home_screen.dart';

// // SetCollectionScreen State 내부에 넣을 함수
// Future<void> _handleStartPressed() async {
//   // 1) 선택 상태 디버그
//   debugPrint('선택상태: $_selected');

//   // 2) 권한 요청 결과를 저장할 맵
//   final Map<String, bool> consentResult = {};

//   // 헬퍼: 단일 Permission 요청 후 granted 여부 반환
//   Future<bool> requestPermission(Permission permission) async {
//     final status = await permission.status;
//     if (status.isGranted) return true;

//     final result = await permission.request();

//     if (result.isGranted) return true;

//     if (result.isPermanentlyDenied) {
//       // 사용자에게 설정 열기를 권유
//       final open = await showDialog<bool>(
//         context: context,
//         builder:
//             (ctx) => AlertDialog(
//               title: const Text('권한 필요'),
//               content: const Text('이 권한은 앱의 핵심 기능에 필요합니다. 설정에서 허용하시겠어요?'),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.of(ctx).pop(false),
//                   child: const Text('취소'),
//                 ),
//                 TextButton(
//                   onPressed: () => Navigator.of(ctx).pop(true),
//                   child: const Text('설정 열기'),
//                 ),
//               ],
//             ),
//       );
//       if (open == true) {
//         await openAppSettings();
//       }
//       return false;
//     }

//     // denied 혹은 기타 경우
//     return false;
//   }

//   // 3) 갤러리 권한 요청 (플랫폼별)
//   if (_selected['gallery'] == true) {
//     bool granted = false;
//     if (Platform.isIOS) {
//       granted = await requestPermission(Permission.photos);
//     } else {
//       // Android: 외부 저장소 접근 (Android 13 이상은 별도 권한 필요할 수 있음)
//       granted = await requestPermission(Permission.storage);
//     }
//     consentResult['gallery'] = granted;
//     if (!granted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('갤러리 접근 권한이 없어 사진 수집이 제한됩니다.')),
//       );
//     }
//   } else {
//     consentResult['gallery'] = false;
//   }

//   // 4) 알림(푸시) 권한 요청
//   if (_selected['push'] == true) {
//     // Permission.notification은 Android & iOS 지원
//     final granted = await requestPermission(Permission.notification);
//     consentResult['push'] = granted;
//     if (!granted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('알림 권한이 없어 푸시 정보 수집이 제한됩니다.')),
//       );
//     }
//   } else {
//     consentResult['push'] = false;
//   }

//   // 5) 위치 권한 요청
//   if (_selected['location'] == true) {
//     // 위치는 foreground 위치 권한으로 요청
//     final granted = await requestPermission(Permission.locationWhenInUse);
//     consentResult['location'] = granted;
//     if (!granted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('위치 권한이 없어 위치 기반 기능이 제한됩니다.')),
//       );
//     }
//   } else {
//     consentResult['location'] = false;
//   }

//   // 6) 사용자 정보(프로필 같은 내부 데이터) 동의는 앱 내부 동의로 처리
//   consentResult['user'] = _selected['user'] ?? false;

//   // 7) SharedPreferences에 저장
//   try {
//     final prefs = await SharedPreferences.getInstance();

//     // 동의 플래그 저장 (원하면 저장 키 통일)
//     await prefs.setBool('consent_push', consentResult['push'] ?? false);
//     await prefs.setBool('consent_gallery', consentResult['gallery'] ?? false);
//     await prefs.setBool('consent_location', consentResult['location'] ?? false);
//     await prefs.setBool('consent_user', consentResult['user'] ?? false);

//     // 사용자가 정보를 입력했다는 플래그 (이미 profile에서 저장했더라도 안전하게 표시)
//     await prefs.setBool('hasUserInfo', true);

//     debugPrint('권한 저장 완료: $consentResult');
//   } catch (e) {
//     debugPrint('SharedPreferences 저장 오류: $e');
//     if (!mounted) return;
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text('동의 저장 중 오류가 발생했습니다.')));
//     return;
//   }

//   // 8) 모든 흐름 끝나면 홈으로 이동
//   if (!mounted) return;
//   Navigator.of(
//     context,
//   ).pushReplacement(MaterialPageRoute(builder: (context) => const HomePage()));
// }
