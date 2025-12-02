import 'dart:ui';

import 'package:diary_for_me/DB/diary/diary_model.dart';
import 'package:diary_for_me/common/ui_kit.dart';
import 'package:diary_for_me/common/path_util.dart';
import 'package:diary_for_me/DB/db_manager.dart';
import 'package:diary_for_me/my_library/widgets/tag_box.dart';
import 'package:diary_for_me/diary/screen/share_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:smooth_corner/smooth_corner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:diary_for_me/diary/screen/diary_edit_screen.dart';

class DiaryScreen extends StatefulWidget {
  final int diaryId;

  const DiaryScreen({super.key, required this.diaryId});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  late Future<Isar> _dbFuture;

  bool _isPlaying = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _dbFuture = DB().instance;
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String _getFullUrl(String path) {
    if (path.startsWith('/api/')) {
      final baseUrl = dotenv.env['BASE_URL'] ?? '';
      return '$baseUrl$path';
    }
    return path;
  }

  Future<void> _toggleMusic(List<String> musicList) async {
    if (musicList.isEmpty) {
      print('음악 리스트가 비어있습니다.');
      return;
    }

    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      final musicUrl = _getFullUrl(musicList.first);
      print('음악 재생 시도: $musicUrl');
      try {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(musicUrl));
        setState(() => _isPlaying = true);
        print('음악 재생 시작됨');
      } catch (e) {
        print('음악 재생 오류: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('음악 재생 실패: $e')),
          );
        }
      }
    }
  }

  Widget _buildImageWidget(String imagePath) {
    if (isNetworkUrl(imagePath)) {
      final url = _getFullUrl(imagePath);
      return Container(
        color: themePageColor,
        child: Center(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, stack) {
              return const Icon(Icons.broken_image, size: 48, color: Colors.grey);
            },
            loadingBuilder: (ctx, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: themeColor,
              );
            },
          ),
        ),
      );
    } else {
      return Container(
        color: themePageColor,
        child: const Center(
          child: Icon(Icons.image, size: 48, color: Colors.grey),
        ),
      );
    }
  }

  Widget _buildImageSection(Diary diary) {
    final images = diary.content?.image ?? [];
    final music = diary.content?.music ?? [];
    final hasImages = images.isNotEmpty;
    final hasMusic = music.isNotEmpty;

    return contents(
      children: [
        Container(
          width: double.infinity,
          height: 280,
          decoration: ShapeDecoration(
            shape: SmoothRectangleBorder(
              smoothness: 0.6,
              borderRadius: BorderRadius.circular(32),
            ),
            color: themePageColor,
          ),
          child: Stack(
            children: [
              if (hasImages)
                SmoothClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  smoothness: 0.6,
                  child: images.length == 1
                      ? _buildImageWidget(images.first)
                      : PageView.builder(
                          controller: _pageController,
                          itemCount: images.length,
                          onPageChanged: (index) {
                            setState(() => _currentImageIndex = index);
                          },
                          itemBuilder: (context, index) {
                            return _buildImageWidget(images[index]);
                          },
                        ),
                )
              else
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_outlined, size: 48, color: textTertiary),
                      const SizedBox(height: 8),
                      Text('이미지 없음', style: contentDetail()),
                    ],
                  ),
                ),

              if (hasImages && images.length > 1)
                Positioned(
                  bottom: hasMusic ? 70 : 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(images.length, (index) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentImageIndex == index
                              ? Colors.white
                              : Colors.white.withAlpha(128),
                        ),
                      );
                    }),
                  ),
                ),

              if (hasMusic)
                Positioned(
                  bottom: 18,
                  right: 18,
                  child: SmoothClipRRect(
                    borderRadius: BorderRadius.circular(23),
                    smoothness: 0.6,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: GestureDetector(
                        onTap: () => _toggleMusic(music),
                        child: Container(
                          color: Colors.black.withAlpha(32),
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 30,
                                height: 30,
                                child: Icon(
                                  Icons.music_note,
                                  color: Colors.white,
                                  size: 23,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: Colors.black.withAlpha(64),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  size: 24,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showDeleteDialog(Isar isar, Diary diary) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일기 삭제'),
        content: const Text('정말로 이 일기를 삭제하시겠습니까?\n삭제된 일기는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await _deleteDiary(isar, diary);
    }
  }

  Future<void> _deleteDiary(Isar isar, Diary diary) async {
    try {
      await isar.writeTxn(() async {
        await isar.diarys.delete(diary.id);
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('일기가 삭제되었습니다.')),
        );
      }
    } catch (e) {
      print('일기 삭제 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Isar>(
      future: _dbFuture,
      builder: (context, dbSnapshot) {
        if (!dbSnapshot.hasData) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isar = dbSnapshot.data!;

        return StreamBuilder<Diary?>(
          stream: isar.diarys.watchObject(
            widget.diaryId,
            fireImmediately: true,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return const Scaffold(
                backgroundColor: Colors.white,
                body: Center(child: Text("삭제된 일기이거나 불러올 수 없습니다.")),
              );
            }

            final diary = snapshot.data!;
            final date = diary.timeline.value?.date ?? DateTime.now();

            return Scaffold(
              extendBodyBehindAppBar: true,
              appBar: blurryAppBar(
                color: Colors.white,
                title: Text(
                  DateFormat('yyyy.MM.dd(E)').format(date),
                  style: appbarTitle(),
                ),
                centerTitle: true,
                actions: [
                  ContainerButton(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(child: Text('편집', style: appbarButton())),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => DiaryEditScreen(
                            diaryId: widget.diaryId,
                          ),
                        ),
                      );
                    },
                  ),
                  ContainerButton(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text('삭제', style: appbarButton(color: Colors.red)),
                      ),
                    ),
                    onTap: () => _showDeleteDialog(isar, diary),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              backgroundColor: Colors.white,
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SafeArea(bottom: false, child: SizedBox()),

                      _buildImageSection(diary),

                      contents(
                        children: [
                          Text(diary.title, style: pageTitle()),
                          const SizedBox(height: 16),
                          Text(
                            diary.content?.text ?? '',
                            style: diaryDetail(),
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          const SizedBox(width: 20),
                          Text('태그 :', style: contentSubTitle()),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ...diary.tag.map((tagData) {
                                    return tagBox(
                                      text: '#$tagData',
                                      activated: false,
                                    );
                                  }),
                                  const SizedBox(width: 14),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      contents(
                        children: [
                          const SizedBox(height: 32),
                          borderHorizontal(),
                          const SizedBox(height: 32),
                        ],
                      ),

                      contents(
                          children: [
                            IntrinsicWidth(
                              child: ContainerButton(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                borderRadius: BorderRadius.circular(22),
                                height: 44,
                                color: themeColor.withAlpha(24),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) => ShareScreen(
                                        diary: diary,
                                      ),
                                    ),
                                  );
                                },
                                child: Center(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.ios_share,
                                        color: themeColor,
                                        size: 20,
                                      ),
                                      SizedBox(width: 4,),
                                      Text(
                                        '공유하기',
                                        style: mainButton(color: themeColor),
                                      ),

                                    ],
                                  ),
                                ),
                              ),
                            )
                          ]
                      ),
                      const SafeArea(top: false, child: SizedBox()),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
