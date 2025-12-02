import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_notification_listener_plus/flutter_notification_listener_plus.dart';

import 'package:diary_for_me/collect/notification.dart';

import 'collect/background_timer.dart';
import 'home/screen/home_screen.dart';
import 'tutorial/screen/first_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);

  final prefs = await SharedPreferences.getInstance();
  final bool hasUserInfo = prefs.getBool('hasUserInfo') ?? false;

  await dotenv.load(fileName: ".env");
  String clientId = dotenv.env['NAVER_CLIENT_ID'] ?? '';

  // 네이버 지도 SDK 초기화
  await FlutterNaverMap().init(
    clientId: clientId,
    onAuthFailed: (ex) {
      switch (ex) {
        case NQuotaExceededException(:final message):
          debugPrint("사용량 초과 (message: $message)");
          break;
        case NUnauthorizedClientException() ||
            NClientUnspecifiedException() ||
            NAnotherAuthFailedException():
          debugPrint("인증 실패: $ex");
          break;
      }
    },
  );

  // 알림 리스너 초기화 및 콜백 등록
  await NotificationsListener.initialize();
  await NotificationsListener.registerEventHandle(backgroundCallback);

  await initializeService();

  runApp(MyApp(hasUserInfo: hasUserInfo));
}

const notificationChannelId = 'my_foreground';

const notificationId = 888;

class MyApp extends StatelessWidget {
  final bool hasUserInfo;
  const MyApp({super.key, required this.hasUserInfo});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diary for me',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: hasUserInfo ? const HomePage() : const FirstScreen(),
    );
  }
}

/// Flutter 기본 템플릿 (사용하지 않음)
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
