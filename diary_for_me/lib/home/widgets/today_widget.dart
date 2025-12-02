import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:diary_for_me/timeline/screen/timeline_list_screen.dart';
import 'package:isar/isar.dart';
import '../../common/ui_kit.dart';
import '../../DB/db_manager.dart';
import '../../DB/timeline/timeline_model.dart';
import 'dart:async';

class TodayWidget extends StatefulWidget {
  const TodayWidget({super.key});

  @override
  State<TodayWidget> createState() => TodayWidgetState();
}

class TodayWidgetState extends State<TodayWidget> with WidgetsBindingObserver {
  late Timer _timer;
  late double _progress;
  late bool _isReady;
  TimeLine? _todayTimeline;

  final int _targetSec = 21 * 3600;

  /// 외부에서 타임라인 상태를 갱신할 때 호출
  void refresh() {
    _checkTodayTimeline();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _updateTime();
    _checkTodayTimeline();
    _timer = Timer.periodic(Duration(seconds: 1), (Timer t) => _updateTime());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkTodayTimeline();
    }
  }

  Future<void> _checkTodayTimeline() async {
    final isar = await DB().instance;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    final searchStart = now.hour < 12
        ? todayStart.subtract(const Duration(days: 1))
        : todayStart;

    final timeline = await isar.timeLines
        .filter()
        .dateBetween(searchStart, tomorrowStart, includeUpper: false)
        .findFirst();

    if (mounted) {
      setState(() {
        _todayTimeline = timeline;
        _isReady = _todayTimeline != null;
      });
    }
  }

  void _updateTime() {
    final now = DateTime.now();
    final int nowSec = now.hour * 3600 + now.minute * 60 + now.second;

    if (mounted) {
      setState(() {
        _progress = nowSec / _targetSec;
        _isReady = _todayTimeline != null;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady == false) {
      return contentsCard(
        children: [
          contents(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'lib/common/resource/collecting_info.png',
                width: 160,
                height: 160,
                fit: BoxFit.cover,
              ),
              SizedBox(height: 16),
              Text('사관이 정보를 수집중이에요', style: contentTitle()),
              SizedBox(height: 8),
              Text(
                '정보 수집이 끝나면 오늘의 실록을 만들 수 있어요.\n준비가 완료되면 알림을 보내드려요.',
                textAlign: TextAlign.center,
                style: contentDetail(),
              ),
              SizedBox(height: 16),
              Container(
                clipBehavior: Clip.antiAlias,
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: themeColor,
                ),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: themeDeepColor,
                  color: themeColor,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return contentsCard(
        children: [
          contents(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'lib/common/resource/collecting_finish.png',
                width: 160,
                height: 160,
                fit: BoxFit.cover,
              ),
              SizedBox(height: 16),
              Text('실록을 만들 준비를 마쳤어요.', style: contentTitle()),
              SizedBox(height: 8),
              Text(
                '사관이 정보 수집을 끝냈어요. 이제 일기를 생성해 보세요.',
                style: contentDetail(),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ContainerButton(
                borderRadius: BorderRadius.circular(20),
                color: themeColor,
                height: 56,
                shadows: [
                  BoxShadow(
                    color: themeColor.withAlpha(128),
                    spreadRadius: -12,
                    blurRadius: 18,
                    offset: Offset(0, 18),
                  ),
                ],
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const TimelineListScreen(),
                    ),
                  );
                },
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('일기 생성하기', style: mainButton()),
                      Icon(Icons.navigate_next, size: 24, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
  }
}
