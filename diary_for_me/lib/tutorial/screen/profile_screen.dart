import 'package:diary_for_me/common/text_style.dart';
import 'package:diary_for_me/common/ui_kit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // date 포맷을 위함
import 'package:diary_for_me/common/colors.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_corner/smooth_corner.dart';
import 'set_collection_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController(); // 이름
  DateTime? _selectedDate; // 생년월일
  String? _gender; // 성별

  // 입력창
  Widget _roundedInput({required String category, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category,
          style: const TextStyle(
            fontSize: 18,
            color: textPrimary,
            fontWeight: FontWeight.w500,
            height: 1.2
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 68,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: ShapeDecoration(
            shape: SmoothRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              smoothness: 0.6,
              side: BorderSide(
                color: themeDeepColor,
                width: 1.0
              )
            ),
            color: Colors.white,
          ),
          child: child,
        ),
      ],
    );
  }

  // 생년월일 선택 함수
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 100);
    final lastDate = now;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(now.year - 20),
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          // 여기에서 원하는 테마를 새로 정의합니다.
          data: ThemeData.light().copyWith(
            primaryColor: themeColor,
            dividerColor: Colors.transparent,
            colorScheme: const ColorScheme.light(primary: themeColor),
            datePickerTheme: DatePickerThemeData(
              dayShape: MaterialStateProperty.all<OutlinedBorder?>( // <--- 수정된 부분
                SmoothRectangleBorder(
                  borderRadius: BorderRadius.circular(14.0),
                  smoothness: 1,
                ),
              ),
              dividerColor: Colors.transparent,
              shape: SmoothRectangleBorder(
                borderRadius: BorderRadius.circular(32),
                smoothness: 0.6
              ),
              headerBackgroundColor: Colors.white,
              headerForegroundColor: textPrimary,
            ),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> handleNextPressed() async {
    debugPrint('이름: ${_nameController.text}');
    debugPrint('생년월일: $_selectedDate');
    debugPrint('성별: $_gender');

    try {
      final prefs = await SharedPreferences.getInstance();

      // 사용자 정보 저장
      await prefs.setString('name', _nameController.text.trim());
      final dateStr = _selectedDate?.toIso8601String() ?? '';
      await prefs.setString('date', dateStr);
      await prefs.setString('gender', _gender ?? '');

      // 저장 성공 후 원하는 화면으로 이동
      if (!mounted) return;
      Navigator.of(context).push(
        CupertinoPageRoute(builder: (context) => const SetCollectionScreen()),
      );
    } catch (e) {
      debugPrint('SharedPreferences 저장 오류: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 중 오류가 발생했습니다. 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themePageColor,
      appBar: AppBar(
        iconTheme: IconThemeData(color: textPrimary, size: 28.0),
        backgroundColor: themePageColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        actions: [
          Text('1', style: appbarButton(color: textPrimary)),
          Text('/2', style: appbarButton(color: textPrimary.withAlpha(128))),
          SizedBox(width: 20),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 본문
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목
                      Text(
                        '정보를 입력해 주세요',
                        style: pageTitle(),
                      ),
                      const SizedBox(height: 16),

                      // 이름 입력 (둥근 박스)
                      _roundedInput(
                        category: '이름',
                        child: TextField(
                          style: TextStyle(
                            fontSize: 16.0,
                            color: textPrimary,
                            fontWeight: FontWeight.w400
                          ),
                          controller: _nameController,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: '예) 홍길동',
                            hintStyle: TextStyle(
                              fontSize: 16.0,
                              color: textTertiary,
                              fontWeight: FontWeight.w400
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 생년월일 / 성별 (가로 배치)
                      Row(
                        children: [
                          // 생년월일
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _pickDate,
                                  child: _roundedInput(
                                    category: '생년월일',
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _selectedDate == null
                                                ? '선택해 주세요'
                                                : DateFormat.yMMMMd(
                                                  'ko',
                                                ).format(_selectedDate!),
                                            style: TextStyle(
                                              fontSize: 16.0,
                                              color:
                                                  _selectedDate == null
                                                      ? textTertiary
                                                      : textPrimary,
                                              fontWeight: FontWeight.w400
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.calendar_today_outlined,
                                          size: 16,
                                          color: textTertiary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // 성별
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                _roundedInput(
                                  category: '성별',
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      elevation: 8,
                                      borderRadius: BorderRadius.circular(20),
                                      dropdownColor: Colors.white,
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        color: textPrimary,
                                        fontWeight: FontWeight.w400
                                      ),
                                      value: _gender,
                                      isExpanded: true,
                                      isDense: true,
                                      hint: const Text(
                                        '선택해 주세요',
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          color: textTertiary,
                                          fontWeight: FontWeight.w400
                                        ),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'male',
                                          child: Text('남성'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'female',
                                          child: Text('여성'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'other',
                                          child: Text('선택 안 함'),
                                        ),
                                      ],
                                      onChanged:
                                          (v) => setState(() => _gender = v),
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // 안내 문구
                      const Text(
                        '입력한 정보들은 일기생성을 위해 AI에 활용될 수 있습니다.',
                        style: TextStyle(fontSize: 14, color: textTertiary),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.18,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 하단의 "다음으로 →" 텍스트 버튼 (가운데 정렬)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Center(
                child: ContainerButton(
                  borderRadius: BorderRadius.circular(24),
                  height: 68,
                  onTap: () {
                    // 다음 버튼 동작: 이름만 필수 입력
                    if (_nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('이름을 입력해 주세요')),
                      );
                      return;
                    }
                    handleNextPressed();
                  },
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('다음으로', style: mainButton(color: textPrimary)),
                        Icon(Icons.navigate_next, size: 24, color: textPrimary),
                      ],
                    ),
                  ),
                ),
                /*
                child: TextButton(
                  onPressed: () {
                    // 다음 버튼 동작: 이름만 필수 입력
                    if (_nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('이름을 입력해 주세요')),
                      );
                      return;
                    }
                    handleNextPressed();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    '다음으로  →',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                 */
              ),
            ),
          ],
        ),
      ),
    );
  }
}
