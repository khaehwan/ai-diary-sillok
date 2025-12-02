// import 'dart:ffi';
import 'package:diary_for_me/common/ui_kit.dart';
// import 'package:diary_for_me/my_library/widgets/tag_box.dart';
// import 'package:diary_for_me/my_library/test_diary.dart';
import 'write_draft_screen.dart';
import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:smooth_corner/smooth_corner.dart';
import 'package:flutter/cupertino.dart';

List<Map<String, dynamic>> emotions = [
  {'img': '😢', 'text': '슬픔', 'color': Colors.blueAccent.withAlpha(65)},
  {'img': '😢', 'text': '화남', 'color': Colors.redAccent.withAlpha(65)},
  {'img': '😢', 'text': '보통', 'color': Colors.grey.withAlpha(65)},
  {'img': '😢', 'text': '기쁨', 'color': Colors.cyanAccent.withAlpha(65)},
  {'img': '😢', 'text': '즐거움', 'color': Colors.deepOrangeAccent.withAlpha(65)},
];

class SelectMoodScreen extends StatefulWidget {
  final int timelineId;
  const SelectMoodScreen({super.key, required this.timelineId});

  @override
  State<SelectMoodScreen> createState() => _SelectMoodScreenState();
}

class _SelectMoodScreenState extends State<SelectMoodScreen> {
  final PageController _controller = PageController(initialPage: 2);
  int _currentIndex = 2;
  int _selectedIndex = 2;
  bool _isChanging = false;

  double startPadding = 20; // Row 맨 앞 SizedBox(width: 20)
  double endPadding = 16;

  // 스크롤 컨트롤러 선언
  final ScrollController _scrollController = ScrollController();

  void _scrollToCenter(int index) {
    const double itemWidth = 86; // 각 아이템의 고정 폭
    const double itemMargin = 4; // 오른쪽 여백
    // Row 맨 끝 SizedBox(width: 16)

    // 전체 아이템의 폭(간격 포함)
    final double totalItemWidth = itemWidth + itemMargin;

    // 화면 너비
    final double screenWidth = MediaQuery.of(context).size.width;

    // 이동해야 할 목표 offset (아이템의 중앙이 화면 중앙에 오도록)
    double targetOffset =
        startPadding +
        (index * totalItemWidth + itemWidth / 2) -
        (screenWidth / 2);

    // 범위 제한
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (targetOffset < 0) targetOffset = 0;
    if (targetOffset > maxScroll) targetOffset = maxScroll;

    // 부드럽게 스크롤
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 350),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCenter(2);
    });
    // _scrollToCenter(2);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _controller.dispose();

    super.dispose();
  }

  void _goToPage(int index) {
    _controller.animateToPage(
      index,
      duration: Duration(milliseconds: 600),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white, size: 28.0),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        actions: [
          Text('2', style: appbarButton(color: Colors.white)),
          Text('/3', style: appbarButton(color: Colors.white.withAlpha(128))),
          SizedBox(width: 20),
        ],
      ),
      backgroundColor: Colors.black,
      body: AnimatedContainer(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, emotions[_currentIndex]['color']],
          ),
        ),
        height: double.infinity,
        width: double.infinity,
        duration: const Duration(milliseconds: 700),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SafeArea(bottom: false, child: SizedBox.shrink()),
            SizedBox(height: 16),
            Text('오늘 하루는 어땠나요?', style: pageTitle(color: Colors.white)),
            SizedBox(height: 8),
            Text(
              '오늘 하루동안 느꼈던 감정을 선택해주세요.',
              style: cardDetail(color: Colors.white.withAlpha(128)),
            ),
            // 감정 이모티콘
            Expanded(
              child: PageView(
                physics: BouncingScrollPhysics(),
                controller: _controller,
                onPageChanged: (int index) {
                  setState(() {
                    _currentIndex = index;
                    if (!_isChanging) {
                      _scrollToCenter(index);
                      _selectedIndex = _currentIndex;
                    }
                    if (_currentIndex == _selectedIndex) {
                      _isChanging = false;
                    }
                  });
                },
                children:
                    ['😢', '😡', '😑', '😊', '🤣']
                        .map(
                          (e) => Center(
                            child: Text(
                              e,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 225.0,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
            SizedBox(height: 16),
            // 감정 선택창
            SingleChildScrollView(
              controller: _scrollController, // 스크롤 컨트롤러 연결
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  ...emotions.asMap().entries.map((e) {
                    int index = e.key;
                    var item = e.value;
                    bool isSelected = _selectedIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                          _isChanging = true;
                        });
                        _goToPage(index);
                        _scrollToCenter(index); // 선택 시 중앙으로 스크롤
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 4),
                        width: 86,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color: isSelected ? Colors.white : Colors.transparent,
                        ),
                        child: Center(
                          child: Text(
                            item['text'],
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? textPrimary
                                      : Colors.white.withAlpha(128),
                              fontSize: 16.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 16),
                ],
              ),
            ),

            SizedBox(height: 16),
            // 다음 페이지
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: ContainerButton(
                borderRadius: BorderRadius.circular(24),
                height: 68,
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => WriteDraftScreen(emotion: emotions[_currentIndex]['text'], timelineId: widget.timelineId,),
                    ),
                  );
                },
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('다음으로', style: mainButton()),
                      Icon(Icons.navigate_next, size: 24, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            SafeArea(top: false, child: SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
