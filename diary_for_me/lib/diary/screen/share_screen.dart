import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:blur/blur.dart';
import 'package:diary_for_me/DB/diary/diary_model.dart';
import 'package:diary_for_me/common/colors.dart';
import 'package:diary_for_me/common/path_util.dart' show isNetworkUrl;
import 'package:diary_for_me/common/text_style.dart';
import 'package:diary_for_me/common/ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smooth_corner/smooth_corner.dart';

class ShareScreen extends StatefulWidget {
  final Diary diary;

  const ShareScreen({super.key, required this.diary});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  // 1. 캡처할 영역을 지정하기 위한 키
  final GlobalKey _captureKey = GlobalKey();


  // String testUrl = 'https://picsum.photos/200/300';

  String imagePath = '';

  // 캡처 및 공유 함수
  Future<void> captureAndShare() async {
    try {
      // 2. RepaintBoundary 찾기
      RenderRepaintBoundary? boundary =
      _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) return;

      // 3. 이미지로 변환 (pixelRatio: 3.0은 고화질을 의미함)
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        Uint8List pngBytes = byteData.buffer.asUint8List();

        // 4. 임시 파일로 저장
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/shared_image.png');
        await file.writeAsBytes(pngBytes);

        // 5. share_plus로 공유 실행
        // 아이폰/안드로이드 기본 공유창이 뜨고 여기서 'Instagram' 선택 가능
        // await Share.shareXFiles([XFile(file.path)], text: '내 앱에서 공유한 이미지!');
        final params = ShareParams(
          text: 'Great picture',
          files: [XFile(file.path)],
        );

        final result = await SharePlus.instance.share(params);

        if (result.status == ShareResultStatus.success) {
          print('Thank you for sharing the picture!');
        }
      }
    } catch (e) {
      print('에러 발생: $e');
    }
  }


  @override
  void initState() {
    final images = widget.diary.content?.image;
    imagePath = (images != null && images.isNotEmpty)
        ? images.first
        : '';
    // imagePath = testUrl;


    super.initState();
  }

  // URL 경로를 전체 URL로 변환
  String _getFullUrl(String path) {
    if (path.startsWith('/api/')) {
      final baseUrl = dotenv.env['BASE_URL'] ?? '';
      return '$baseUrl$path';
    }
    return path;
  }

  /// 이미지 위젯 빌드
  Widget _image() {
    if (isNetworkUrl(imagePath)) {
      final url = _getFullUrl(imagePath);
      return Image.network(
        width: double.infinity,
        height: 220,
        url,
        fit: BoxFit.cover,
      );
    } else {
      return Container(
        height: 220,
        color: Colors.grey,
        child: const Center(
          child: Icon(Icons.image, size: 48, color: Colors.grey),
        ),
      );
    }
  }

  Widget _background() {
    if (isNetworkUrl(imagePath)) {
      final url = _getFullUrl(imagePath);
      return Image.network(
        width: double.infinity,
        height: double.infinity,
        url,
        fit: BoxFit.cover,
      ).blurred(
        blurColor: Colors.black,
        colorOpacity: 0.4,
        blur: 100

      );
    } else {
      return Container(
        color: Colors.black45,
        child: const Center(
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white, size: 28.0),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ★ 핵심: 캡처하고 싶은 위젯을 RepaintBoundary로 감싼다
              RepaintBoundary(
                key: _captureKey,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  width: 288,
                  height: 512,
                  decoration: ShapeDecoration(
                    shape: SmoothRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      smoothness: 0.6
                    ),
                    color: Colors.grey
                  ),
                  child: Stack(
                    children: [
                      _background(),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SmoothClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              smoothness: 0.6,
                              child: _image(),
                            ),
                            SizedBox(height: 12,),
                            Text(widget.diary.title, style: cardTitle(color: Colors.white),),
                            SizedBox(height: 12,),
                            Text(
                              maxLines: 7,
                              overflow: TextOverflow.ellipsis,
                              widget.diary.content?.text ?? '',
                              style: diaryDetail(fontSize: 12, color: Colors.white),
                            )
                          ],
                        ),
                      ),
                    ],
                  )
                ),
              ),
              SizedBox(height: 32),
              Center(
                child: IntrinsicWidth(
                  child: ContainerButton(
                    borderRadius: BorderRadius.circular(22),
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    height: 44,
                    color: Colors.white,
                    onTap: captureAndShare,
                    child: Center(child: Text('공유하기', style: mainButton(color: Colors.black),)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}