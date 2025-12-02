import 'package:diary_for_me/common/ui_kit.dart';
import 'package:diary_for_me/home/screen/home_screen.dart';
import 'package:diary_for_me/new_diary/screen/finish_generation_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smooth_corner/smooth_corner.dart';

// [필수] DB 매니저 및 모델 import
import '../../DB/db_manager.dart';
import '../../DB/diary/diary_model.dart';
import '../../DB/timeline/timeline_model.dart';
import '../../api_service/api_service.dart';

class WriteDraftScreen extends StatefulWidget {
  // [변경] timelineKey(String) -> timelineId(int)
  final int timelineId;
  final String emotion;

  const WriteDraftScreen({
    super.key,
    required this.timelineId,
    required this.emotion,
  });

  @override
  State<WriteDraftScreen> createState() => _WriteDraftScreenState();
}

class _WriteDraftScreenState extends State<WriteDraftScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  bool _generateImage = true;
  bool _generateMusic = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Timeline 객체를 API 요청용 JSON으로 변환
  Map<String, dynamic> _timelineToJson(TimeLine timeline) {
    return {
      'id': timeline.serverId.isNotEmpty ? timeline.serverId : 'timeline-${timeline.id}',
      'title': timeline.title,
      'date': DateFormat('yyyy-MM-dd').format(timeline.date),
      'events': timeline.events.map((e) => _eventToJson(e)).toList(),
      'selfsurvey': timeline.selfsurvey != null
          ? {
              'mood': timeline.selfsurvey!.mood ?? '',
              'draft': timeline.selfsurvey!.draft ?? '',
            }
          : null,
    };
  }

  /// Event 객체를 JSON으로 변환
  Map<String, dynamic> _eventToJson(Event event) {
    return {
      'id': event.id,
      'timestamp': event.timestamp?.toIso8601String(),
      'title': event.title,
      'content': event.content,
      'feeling': event.feeling.isNotEmpty ? event.feeling : null,
      'dailydata': event.dailydata != null
          ? {
              'gallery': event.dailydata!.gallery
                  .map((url) => {
                        'url': url,
                        'timestamp': event.timestamp?.toIso8601String(),
                      })
                  .toList(),
              'location': event.dailydata!.location
                  .map((loc) => {
                        'lat': loc.lat,
                        'lng': loc.lng,
                        'timestamp': loc.timestamp?.toIso8601String(),
                      })
                  .toList(),
              'appnoti': event.dailydata!.appnoti
                  .map((noti) => {
                        'appname': noti.appname,
                        'text': noti.text,
                        'timestamp': noti.timestamp?.toIso8601String(),
                      })
                  .toList(),
            }
          : null,
    };
  }

  /// API 응답에서 Diary 저장
  Future<int?> _saveDiaryFromResponse(
    Map<String, dynamic> response,
    TimeLine timeline,
  ) async {
    final isar = await DB().instance;

    if (response['success'] != true || response['data'] == null) {
      return null;
    }

    final diaryData = response['data'];
    final contentData = diaryData['content'];

    int? newDiaryId;

    await isar.writeTxn(() async {
      // 타임라인 상태 완료로 변경
      timeline.status = TimelineStatus.completed;
      await isar.timeLines.put(timeline);

      // 일기 생성
      // API 응답의 content 필드: images (복수형), music
      final newDiary = Diary(
        serverId: diaryData['id'] ?? '',
        title: diaryData['title'] ?? '새 일기',
        content: DiaryContent(
          text: contentData?['text'] ?? '',
          image: contentData?['images'] != null
              ? List<String>.from(contentData['images'])
              : [],
          music: contentData?['music'] != null
              ? List<String>.from(contentData['music'])
              : [],
        ),
        tag: diaryData['tag'] != null
            ? List<String>.from(diaryData['tag'])
            : [],
      );

      // 타임라인과 연결
      newDiary.timeline.value = timeline;

      // 일기 저장
      newDiaryId = await isar.diarys.put(newDiary);

      // IsarLink 저장
      await newDiary.timeline.save();
    });

    return newDiaryId;
  }

  // [핵심] 일기 생성 로직 (API 연동)
  Future<void> _generateDiary() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // 1. DB 인스턴스 및 타임라인 가져오기
      final isar = await DB().instance;
      final timeline = await isar.timeLines.get(widget.timelineId);

      if (timeline == null) {
        _showErrorSnackBar('타임라인을 찾을 수 없습니다.');
        return;
      }

      // 2. 타임라인에 selfsurvey 업데이트
      await isar.writeTxn(() async {
        timeline.selfsurvey ??= SelfSurvey();
        timeline.selfsurvey!.draft = _controller.text;
        timeline.selfsurvey!.mood = widget.emotion;
        timeline.status = TimelineStatus.processing;
        await isar.timeLines.put(timeline);
      });

      // 3. Timeline을 JSON으로 변환
      final timelineJson = _timelineToJson(timeline);

      // 4. API 호출
      final apiService = DailyLogApiService();
      final response = await apiService.getDiaryFromAPI(
        timelineJson: timelineJson,
        generateImage: _generateImage,
        generateMusic: _generateMusic,
      );

      if (response == null) {
        _showErrorSnackBar('서버 연결에 실패했습니다.');
        // 상태 롤백
        await isar.writeTxn(() async {
          timeline.status = TimelineStatus.pending;
          await isar.timeLines.put(timeline);
        });
        return;
      }

      // 5. 응답에서 일기 저장
      final newDiaryId = await _saveDiaryFromResponse(response, timeline);

      if (newDiaryId == null) {
        _showErrorSnackBar('일기 저장에 실패했습니다.');
        return;
      }

      // 6. 화면 이동
      if (!mounted) return;

      // 홈 화면으로 스택 초기화 후 이동
      Navigator.pushAndRemoveUntil(
        context,
        CupertinoPageRoute(builder: (context) => const HomePage()),
        (Route<dynamic> route) => false,
      );

      // 완료 화면으로 이동
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => FinishGenerationScreen(diaryId: newDiaryId),
        ),
      );
    } catch (e) {
      print('일기 생성 오류: $e');
      _showErrorSnackBar('일기 생성 중 오류가 발생했습니다.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: textPrimary, size: 28.0),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        actions: [
          Text('3', style: appbarButton(color: textPrimary)),
          Text('/3', style: appbarButton(color: textTertiary)),
          const SizedBox(width: 20),
        ],
      ),
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('일기 초안을 작성해 볼까요?', style: pageTitle()),
              const SizedBox(height: 8),
              Text('오늘의 하루를 적어보세요', style: cardDetail()),
              const SizedBox(height: 16),
              // 입력 필드
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: ShapeDecoration(
                      shape: SmoothRectangleBorder(
                        side: BorderSide(color: themeDeepColor, width: 1.0),
                        borderRadius: BorderRadius.circular(32),
                        smoothness: 0.6,
                      ),
                      color: themePageColor,
                    ),
                    child: TextField(
                      controller: _controller,
                      onChanged: (text) {
                        setState(() {});
                      },
                      cursorColor: themeColor,
                      minLines: 3,
                      maxLines: null,
                      style: diaryDetail(fontWeight: FontWeight.w400),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                        hintText: '내용을 입력해주세요.',
                        hintStyle: diaryDetail(color: textTertiary),
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: _controller.text.isEmpty
                    ? Text(
                        textAlign: TextAlign.center,
                        '일기 초안이 없어도 AI가 일기를 생성할 수 있지만,\n결과가 정확하지 않을 수 있어요.',
                        style: contentDetail(),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              // 이미지/음악 생성 옵션
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: ShapeDecoration(
                  shape: SmoothRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    smoothness: 0.6,
                    side: BorderSide(color: themeDeepColor, width: 1.0),
                  ),
                  color: themePageColor,
                ),
                child: Column(
                  children: [
                    // 이미지 생성 옵션
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.image_outlined, color: textSecondary, size: 20),
                            const SizedBox(width: 8),
                            Text('AI 이미지 생성', style: contentTitle()),
                          ],
                        ),
                        Switch(
                          value: _generateImage,
                          onChanged: _isLoading ? null : (value) {
                            setState(() => _generateImage = value);
                          },
                          activeColor: themeColor,
                        ),
                      ],
                    ),
                    Divider(color: themeDeepColor, height: 1),
                    // 음악 생성 옵션
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.music_note_outlined, color: textSecondary, size: 20),
                            const SizedBox(width: 8),
                            Text('AI 음악 생성', style: contentTitle()),
                          ],
                        ),
                        Switch(
                          value: _generateMusic,
                          onChanged: _isLoading ? null : (value) {
                            setState(() => _generateMusic = value);
                          },
                          activeColor: themeColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 버튼 (로딩 중일 때는 로딩 인디케이터 표시)
              _isLoading
                  ? ContainerButton(
                      key: const ValueKey('loading'),
                      borderRadius: BorderRadius.circular(24),
                      color: themeColor.withAlpha(128),
                      height: 68,
                      onTap: () {}, // 로딩 중에는 비활성화
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              '일기 생성 중...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _controller.text.isEmpty
                      ? ContainerButton(
                          key: const ValueKey('empty'),
                          borderRadius: BorderRadius.circular(24),
                          color: themeColor.withAlpha(24),
                          height: 68,
                          onTap: _generateDiary,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '건너뛰고 일기 생성하기',
                                  style: mainButton(color: themeColor),
                                ),
                                Icon(
                                  Icons.navigate_next,
                                  size: 24,
                                  color: themeColor,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ContainerButton(
                          key: const ValueKey('fill'),
                          borderRadius: BorderRadius.circular(24),
                          color: themeColor.withAlpha(255),
                          height: 68,
                          shadows: [
                            BoxShadow(
                              color: themeColor.withAlpha(128),
                              spreadRadius: -20,
                              blurRadius: 30,
                              offset: const Offset(0, 30),
                            ),
                          ],
                          onTap: _generateDiary,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('일기 생성하기', style: mainButton()),
                                const Icon(
                                  Icons.navigate_next,
                                  size: 24,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
              // 안전영역
              const SafeArea(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  }
}
