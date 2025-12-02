import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:diary_for_me/common/colors.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:diary_for_me/tutorial/widget/consent_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diary_for_me/home/screen/home_screen.dart';

import '../../common/ui_kit.dart';

class SetCollectionScreen extends StatefulWidget {
  const SetCollectionScreen({super.key});

  @override
  State<SetCollectionScreen> createState() => _SetCollectionScreenState();
}

class _SetCollectionScreenState extends State<SetCollectionScreen> {
  // 선택 상태들을 저장 (푸쉬 알림, 갤러리, 위치, 사용자)
  final Map<String, bool> _selected = {
    'push': false,
    'gallery': false,
    'location': false,
    'user': true,
  };

  void _toggle(String key) {
    setState(() {
      _selected[key] = !(_selected[key] ?? false);
    });
  }

  // Future<void> handleStartPressed() async {
  //   // 디버깅 로그 (개발모드에서만)
  //   debugPrint('선택상태: $_selected');

  //   try {
  //     final prefs = await SharedPreferences.getInstance();

  //     // 최소한의 플래그 저장: 사용자가 이미 정보 입력했음을 표시
  //     await prefs.setBool('hasUserInfo', true);

  //     // 각 항목의 선택 상태 저장
  //     await prefs.setBool('consent_push', _selected['push'] ?? false);
  //     await prefs.setBool('consent_gallery', _selected['gallery'] ?? false);
  //     await prefs.setBool('consent_location', _selected['location'] ?? false);
  //     await prefs.setBool('consent_user', _selected['user'] ?? false);

  //     // 저장 성공 후 HomePage로 이동 (현재 화면을 대체)
  //     if (!mounted) return;
  //     Navigator.of(context).pushReplacement(
  //       MaterialPageRoute(builder: (context) => const HomePage()),
  //     );
  //   } catch (e) {
  //     debugPrint('SharedPreferences 저장 오류: $e');
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('저장 중 오류가 발생했습니다. 다시 시도해 주세요.')),
  //     );
  //   }
  // }

  Future<void> handleStartPressed() async {
    // 1) 선택 상태 디버그
    debugPrint('선택상태: $_selected');

    // 2) 권한 요청 결과를 저장할 맵
    final Map<String, bool> consentResult = {};

    // 헬퍼: 단일 Permission 요청 후 granted 여부 반환
    Future<bool> requestPermission(Permission permission) async {
      final status = await permission.status;
      if (status.isGranted) return true;

      final result = await permission.request();

      if (result.isGranted) return true;

      if (result.isPermanentlyDenied) {
        // 사용자에게 설정 열기를 권유
        final open = await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('권한 필요'),
                content: const Text('이 권한은 앱의 핵심 기능에 필요합니다. 설정에서 허용하시겠어요?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('설정 열기'),
                  ),
                ],
              ),
        );
        if (open == true) {
          await openAppSettings();
        }
        return false;
      }

      // denied 혹은 기타 경우
      return false;
    }

    // 3) 갤러리 권한 요청 (플랫폼별)
    if (_selected['gallery'] == true) {
      bool granted = false;
      if (Platform.isIOS) {
        granted = await requestPermission(Permission.photos);
      } else {
        // Android: 외부 저장소 접근 (Android 13 이상은 별도 권한 필요할 수 있음)
        granted = await requestPermission(Permission.storage);
      }
      consentResult['gallery'] = granted;
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('갤러리 접근 권한이 없어 사진 수집이 제한됩니다.')),
        );
      }
    } else {
      consentResult['gallery'] = false;
    }

    // 4) 알림(푸시) 권한 요청
    if (_selected['push'] == true) {
      // Permission.notification은 Android & iOS 지원
      final granted = await requestPermission(Permission.notification);
      consentResult['push'] = granted;
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알림 권한이 없어 푸시 정보 수집이 제한됩니다.')),
        );
      }
    } else {
      consentResult['push'] = false;
    }

    // 5) 위치 권한 요청
    if (_selected['location'] == true) {
      // 위치는 foreground 위치 권한으로 요청
      final granted = await requestPermission(Permission.locationWhenInUse);
      consentResult['location'] = granted;
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 권한이 없어 위치 기반 기능이 제한됩니다.')),
        );
      }
    } else {
      consentResult['location'] = false;
    }

    // 6) 사용자 정보(프로필 같은 내부 데이터) 동의는 앱 내부 동의로 처리
    consentResult['user'] = _selected['user'] ?? false;

    // 7) SharedPreferences에 저장
    try {
      final prefs = await SharedPreferences.getInstance();

      // 동의 플래그 저장 (원하면 저장 키 통일)
      await prefs.setBool('consent_push', consentResult['push'] ?? false);
      await prefs.setBool('consent_gallery', consentResult['gallery'] ?? false);
      await prefs.setBool(
        'consent_location',
        consentResult['location'] ?? false,
      );
      await prefs.setBool('consent_user', consentResult['user'] ?? false);

      // 사용자가 정보를 입력했다는 플래그 (이미 profile에서 저장했더라도 안전하게 표시)
      await prefs.setBool('hasUserInfo', true);

      debugPrint('권한 저장 완료: $consentResult');
    } catch (e) {
      debugPrint('SharedPreferences 저장 오류: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('동의 저장 중 오류가 발생했습니다.')));
      return;
    }

    // 8) 모든 흐름 끝나면 홈으로 이동
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute(builder: (context) => const HomePage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: textPrimary, size: 28.0),
        backgroundColor: themePageColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        actions: [
          Text('2', style: appbarButton(color: textPrimary)),
          Text('/2', style: appbarButton(color: textTertiary)),
          SizedBox(width: 20),
        ],
      ),
      backgroundColor: themePageColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // 본문
              Text(
                '일기 생성에 사용할 항목을\n골라주세요',
                style: pageTitle()
              ),

              SizedBox(height: 16,),

              //const SizedBox(height: 12),

              Expanded(
                child: Row(
                  children: [
                    ConsentCard(
                      title: '푸쉬 알림',
                      subtitle: '앱의 알림들을\n수집합니다.',
                      icon: Icons.notifications_none,
                      selected: _selected['push'] ?? false,
                      onTap: () => _toggle('push'),
                    ),
                    SizedBox(width: 12,),
                    ConsentCard(
                      title: '갤러리',
                      subtitle: '갤러리 내의 사진을\n수집합니다.',
                      icon: Icons.image_outlined,
                      selected: _selected['gallery'] ?? false,
                      onTap: () => _toggle('gallery'),
                    ),
                  ],
                )
              ),

              SizedBox(height: 12,),
              Expanded(
                child: Row(
                  children: [
                    ConsentCard(
                      title: '위치 정보',
                      subtitle: 'GPS 정보를\n수집합니다.',
                      icon: Icons.location_on_outlined,
                      selected: _selected['location'] ?? false,
                      onTap: () => _toggle('location'),
                    ),
                    SizedBox(width: 12,),
                    ConsentCard(
                      title: '사용자 정보',
                      subtitle: '사용자의 성별과\n나이를 수집합니다.',
                      icon: Icons.person_outline,
                      selected: _selected['user'] ?? false,
                      onTap: () => _toggle('user'),
                    ),
                  ],
                )
              ),
              const SizedBox(height: 16),
              // 안내 문구
              Center(
                child: Text(
                  '선택 시 민감정보수집 및 활용에 동의하는 것으로 간주됩니다.',
                  style: TextStyle(color: infoText, fontSize: 14),
                ),
              ),

              const SizedBox(height: 48),

              // 시작하기 버튼
              ContainerButton(
                borderRadius: BorderRadius.circular(24),
                color: themeColor.withAlpha(255),
                height: 68,
                shadows: [
                  BoxShadow(
                    color: themeColor.withAlpha(128),
                    spreadRadius: -20,
                    blurRadius: 30,
                    offset: Offset(0, 30),
                  ),
                ],
                onTap: () {
                  debugPrint('선택상태: $_selected');
                  handleStartPressed();
                },
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('시작하기', style: mainButton()),
                      Icon(
                        Icons.navigate_next,
                        size: 24,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),

              /*
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () {
                      debugPrint('선택상태: $_selected');
                      handleStartPressed();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 10,
                      shadowColor: mainColor,
                    ),
                    child: const Text(
                      '시작하기',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),

               */
            ],
          ),
        ),
      ),
    );
  }
}
