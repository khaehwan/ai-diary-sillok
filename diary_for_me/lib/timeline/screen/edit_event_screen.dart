import 'dart:ui';

import 'package:diary_for_me/timeline/widget/edit_dailydata_section.dart';
import 'package:flutter/material.dart';
import 'package:diary_for_me/common/ui_kit.dart';
import 'package:smooth_corner/smooth_corner.dart';
// [변경] Isar 모델 import (Event가 정의된 위치)
import '../../DB/timeline/timeline_model.dart';
import '../../DB/daily_data/daily_data_model.dart';

class ActivityEditSheet {
  static Future<Event?> show(
    BuildContext context, {
    Event? initialEvent, // 수정할 Event 객체를 받음
  }) async {
    // showModalBottomSheet가 Event?를 반환하도록 타입을 지정
    final Event? result = await showModalBottomSheet<Event?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true, // StreamBuilder/FutureBuilder 내부 context 문제 해결
      builder: (_) => _ActivityEditContent(initialEvent: initialEvent),
      useSafeArea: true,
      shape: SmoothRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        smoothness: 0.6,
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      enableDrag: false,
    );

    return result;
  }
}

class _ActivityEditContent extends StatefulWidget {
  final Event? initialEvent;
  const _ActivityEditContent({
    // super.key,
    this.initialEvent,
  });

  @override
  State<_ActivityEditContent> createState() => _ActivityEditContentState();
}

class _ActivityEditContentState extends State<_ActivityEditContent> {
  final _formKey = GlobalKey<FormState>();

  int newTime = 12 * 60 + 0;

  String location = '서울 중구 동호로 256';

  late Event _resultEvent;

  @override
  void initState() {
    super.initState();

    if (widget.initialEvent != null) {
      // [수정 모드]: 원본의 "복제본"을 생성
      // Isar 모델은 보통 copyWith 대신 clone()을 사용하여 깊은 복사를 수행합니다.
      _resultEvent = widget.initialEvent!.clone();
      // dailydata가 null인 경우 빈 DailyData 생성
      _resultEvent.dailydata ??= DailyData();
    } else {
      // [생성 모드]: "비어있는" 새 객체를 생성
      // Event() 생성자는 기본값으로 초기화됩니다.
      _resultEvent = Event(
        timestamp: DateTime.now(), // 기본 시간 설정
        dailydata: DailyData(), // dailydata 초기화 (RelatedPhotoCard 등에서 필요)
      );
    }

    // 시간 초기화 (Nullable 안전 처리)
    final time = _resultEvent.timestamp ?? DateTime.now();
    newTime = time.hour * 60 + (time.minute ~/ 30) * 30;
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // [수정] DateTime 수정 로직
      // (DateTime은 불변이고 기본 copyWith가 없으므로 생성자로 새로 만듭니다)
      final current = _resultEvent.timestamp ?? DateTime.now();
      _resultEvent.timestamp = DateTime(
        current.year,
        current.month,
        current.day,
        newTime ~/ 60,
        newTime % 60,
      );

      // 2. 모든 변경사항이 적용된 _resultEvent 객체를 반환
      Navigator.of(context).pop(_resultEvent);
    }
  }

  // 취소 버튼 로직
  void _dismissChanges() async {
    final shouldClose = await _showConfirmDiscardDialog();
    if (shouldClose && mounted) Navigator.of(context).pop();
  }

  // 확인 다이얼로그
  Future<bool> _showConfirmDiscardDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('편집 취소'),
          content: const Text('변경사항을 저장하지 않고 닫으시겠어요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('아니요'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('네'),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: themePageColor,
        extendBodyBehindAppBar: true,
        // 상단 바
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                color: Colors.white.withAlpha(249),
                height: 80,
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ContainerButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _dismissChanges(),
                      color: Colors.red.withAlpha(24),
                      child: const Center(
                        child: Text(
                          '취소',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    ContainerButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      borderRadius: BorderRadius.circular(20),
                      onTap: _saveChanges,
                      color: themeDeepColor,
                      child: Center(
                        child: Text(
                          '완료',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 16.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // 활동 정보
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 64),
                      // 제목
                      TextFormField(
                        cursorColor: themeColor,
                        maxLines: 1,
                        style: pageTitle(),
                        decoration: InputDecoration(
                          border: const UnderlineInputBorder(),
                          hintText: '활동 이름을 입력해주세요',
                          contentPadding: EdgeInsets.zero,
                          hintStyle: pageTitle(color: textTertiary),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: themeDeepColor),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: themeDeepColor),
                          ),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return '제목을 입력해주세요';
                          }
                          return null;
                        },
                        initialValue: _resultEvent.title,
                        onSaved: (newValue) {
                          if (newValue != null) {
                            _resultEvent.title = newValue.trim();
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // 활동 시각 및 평가
                      Row(
                        children: [
                          // 활동 시각
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '활동 시각',
                                  style: TextStyle(
                                    color: textTertiary,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 52,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: ShapeDecoration(
                                    shape: SmoothRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      smoothness: 0.6,
                                      side: BorderSide(
                                        color: themeDeepColor,
                                        width: 1.0,
                                      ),
                                    ),
                                    color: themePageColor,
                                  ),
                                  child: DropdownButton<int>(
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    value: newTime,
                                    dropdownColor: Colors.white,
                                    padding: const EdgeInsets.all(0),
                                    elevation: 8,
                                    borderRadius: BorderRadius.circular(16),
                                    items: [
                                      for (int i = 0; i < 1440; i += 30)
                                        DropdownMenuItem(
                                          value: i,
                                          child: Text(
                                            "${(i ~/ 60).toString().padLeft(2, '0')}시 ${(i % 60).toString().padLeft(2, '0')}분",
                                          ),
                                        ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => newTime = v!),
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w400,
                                      color: textPrimary,
                                    ),
                                    icon: const Icon(
                                      Icons.access_time_outlined,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          // 활동 평가
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '활동 평가',
                                  style: TextStyle(
                                    color: textTertiary,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ContainerButton(
                                        color: _resultEvent.feeling == 'good'
                                            ? Colors.redAccent.withAlpha(36)
                                            : themePageColor,
                                        side: BorderSide(
                                          color: _resultEvent.feeling == 'good'
                                              ? Colors.redAccent.withAlpha(48)
                                              : themeDeepColor,
                                          width: 1.0,
                                        ),
                                        height: 52,
                                        onTap: () => setState(
                                          () => _resultEvent.feeling = 'good',
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        child: Center(
                                          child: Icon(
                                            Icons.thumb_up,
                                            color:
                                                _resultEvent.feeling == 'good'
                                                ? Colors.redAccent
                                                : textTertiary,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: ContainerButton(
                                        color: _resultEvent.feeling == 'bad'
                                            ? Colors.blueAccent.withAlpha(36)
                                            : themePageColor,
                                        side: BorderSide(
                                          color: _resultEvent.feeling == 'bad'
                                              ? Colors.blueAccent.withAlpha(48)
                                              : themeDeepColor,
                                          width: 1.0,
                                        ),
                                        height: 52,
                                        onTap: () => setState(
                                          () => _resultEvent.feeling = 'bad',
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        child: Center(
                                          child: Icon(
                                            Icons.thumb_down,
                                            color: _resultEvent.feeling == 'bad'
                                                ? Colors.blueAccent
                                                : textTertiary,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 활동 내용
                      const Text(
                        '활동 내용',
                        style: TextStyle(
                          color: textTertiary,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: ShapeDecoration(
                          shape: SmoothRectangleBorder(
                            side: BorderSide(color: themeDeepColor, width: 1.0),
                            borderRadius: BorderRadius.circular(20),
                            smoothness: 0.6,
                          ),
                          color: themePageColor,
                        ),
                        child: TextFormField(
                          cursorColor: themeColor,
                          minLines: 1,
                          maxLines: null,
                          style: diaryDetail(fontWeight: FontWeight.w400),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(14),
                            hintText: '내용을 입력해주세요.',
                            hintStyle: diaryDetail(color: textTertiary),
                          ),
                          initialValue: _resultEvent.content,
                          onSaved: (newValue) {
                            if (newValue != null) {
                              _resultEvent.content = newValue;
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              // 관련 항목 (DailyData)
              dailyDataEdit(event: _resultEvent),
            ],
          ),
        ),
      ),
    );
  }
}
