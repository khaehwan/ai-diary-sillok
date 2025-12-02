// import 'dart:ui';
// import 'dart:io';
// import 'package:diary_for_me/DB/timeline/timeline_model.dart';
// import 'package:flutter/material.dart';

// import 'package:image_picker/image_picker.dart';
// import 'package:diary_for_me/timeline/widget/edit_event_cards/section_card.dart';
// import 'package:diary_for_me/common/ui_kit.dart';
// import 'package:smooth_corner/smooth_corner.dart';

// import 'package:diary_for_me/common/path_util.dart'; // 추가

// // [변경] Isar 모델 import

// class RelatedPhotoCard extends StatefulWidget {
//   final Event event;
//   final VoidCallback? onChanged; // 추가: 변경 발생시 호출

//   const RelatedPhotoCard({super.key, required this.event, this.onChanged});

//   @override
//   State<RelatedPhotoCard> createState() => _RelatedPhotoCardState();
// }

// class _RelatedPhotoCardState extends State<RelatedPhotoCard> {
//   // 1. AnimatedList를 제어하기 위한 GlobalKey 선언
//   final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

//   // [수정] 편의를 위해 갤러리 리스트 게터(getter) 사용 (Null Safety 적용)
//   // dailydata가 null이면 빈 리스트 반환
//   List<String> get _gallery => widget.event.dailydata?.gallery ?? [];

//   void _removePicture(int index, String picture) {
//     // 2. 리스트에서 삭제 애니메이션 실행
//     _listKey.currentState?.removeItem(
//       index,
//       (context, animation) =>
//           _buildPhotoItem(picture, animation), // 사라질 때 보여줄 위젯
//       duration: const Duration(milliseconds: 300), // 애니메이션 속도
//     );

//     // 3. 실제 데이터 삭제
//     // (Event 모델 내부의 removePicture가 null 체크를 수행하므로 안전함)
//     widget.event.removePicture(picture);
//     widget.onChanged?.call(); // 변경 알림
//   }

//   void _addPicture() async {
//     final ImagePicker picker = ImagePicker();

//     // 갤러리에서 이미지 선택
//     final XFile? pickedFile = await picker.pickImage(
//       source: ImageSource.gallery,
//     );

//     if (pickedFile == null) return; // 취소 시 종료

//     final String filePath = pickedFile.path;
//     debugPrint(filePath);

//     // 1. 데이터 추가
//     // (Event 모델 내부의 addPicture가 dailydata가 없으면 생성해주므로 안전함)
//     final int newIndex = _gallery.length;
//     widget.event.addPicture(filePath);

//     // 2. AnimatedList 애니메이션
//     _listKey.currentState?.insertItem(
//       newIndex,
//       duration: const Duration(milliseconds: 300),
//     );

//     setState(() {}); // 데이터가 추가되었으므로 UI 갱신 (특히 dailydata가 새로 생성된 경우 필요)
//   }

//   final double imageSize = 120;

//   // 개별 사진 아이템을 빌드하는 메서드 (애니메이션 적용)
//   Widget _buildPhotoItem(String picture, Animation<double> animation) {
//     final curvedAnimation = CurvedAnimation(
//       parent: animation,
//       curve: Curves.easeOutQuad,
//       reverseCurve: Curves.easeInQuad,
//     );

//     ImageProvider provider;
//     if (isNetworkUrl(picture)) {
//       provider = NetworkImage(picture);
//     } else if (isAssetPath(picture)) {
//       provider = AssetImage(assetPathToAssetFile(picture));
//     } else {
//       provider = FileImage(File(picture));
//     }

//     return SizeTransition(
//       axis: Axis.horizontal,
//       axisAlignment: 0.0,
//       sizeFactor: curvedAnimation,
//       child: ScaleTransition(
//         scale: curvedAnimation,
//         child: Padding(
//           padding: const EdgeInsets.only(right: 10),
//           child: SizedBox(
//             width: imageSize,
//             child: Stack(
//               children: [
//                 SmoothClipRRect(
//                   borderRadius: BorderRadius.circular(22),
//                   smoothness: 0.6,
//                   child: Image(
//                     image: provider,
//                     // image: picture.startsWith('http')
//                     //     ? NetworkImage(picture)
//                     //     : FileImage(File(picture)) as ImageProvider,
//                     width: imageSize,
//                     height: imageSize,
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//                 // Container(
//                 //   padding: const EdgeInsets.all(8),
//                 //   alignment: Alignment.topRight,
//                 //   decoration: ShapeDecoration(
//                 //     shape: SmoothRectangleBorder(
//                 //       borderRadius: BorderRadius.circular(22),
//                 //       smoothness: 0.6,
//                 //       side: BorderSide(
//                 //         color: Colors.black.withAlpha(24),
//                 //         width: 1.0,
//                 //       ),
//                 //     ),
//                 //   ),
//                 //   child: GestureDetector(
//                 //     // 삭제 시 인덱스가 필요하므로 수정
//                 //     onTap: () {
//                 //       // 현재 데이터상의 인덱스를 찾아서 넘겨줌
//                 //       final index = _gallery.indexOf(picture);
//                 //       if (index != -1) {
//                 //         _removePicture(index, picture);
//                 //       }
//                 //     },
//                 //     child: ClipOval(
//                 //       child: BackdropFilter(
//                 //         filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
//                 //         child: Container(
//                 //           decoration: const BoxDecoration(
//                 //             color: Colors.black38,
//                 //             shape: BoxShape.circle,
//                 //           ),
//                 //           padding: const EdgeInsets.all(4),
//                 //           child: const Icon(
//                 //             Icons.close,
//                 //             size: 22,
//                 //             color: Colors.white,
//                 //           ),
//                 //         ),
//                 //       ),
//                 //     ),
//                 //   ),
//                 // ),
//                 // 삭제 버튼
//                 Positioned(
//                   top: 6,
//                   right: 6,
//                   child: GestureDetector(
//                     onTap: () {
//                       final index = _gallery.indexOf(picture);
//                       if (index != -1) _removePicture(index, picture);
//                     },
//                     child: ClipOval(
//                       child: BackdropFilter(
//                         filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
//                         child: Container(
//                           decoration: const BoxDecoration(
//                             color: Colors.black38,
//                             shape: BoxShape.circle,
//                           ),
//                           padding: const EdgeInsets.all(4),
//                           child: const Icon(
//                             Icons.close,
//                             size: 22,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     // 갤러리 리스트 가져오기 (Null일 경우 빈 리스트)
//     final galleryList = _gallery;

//     return SectionCard(
//       title: '관련 사진',
//       children: [
//         const SizedBox(height: 16),
//         SizedBox(
//           height: imageSize, // 리스트의 높이 고정
//           child: AnimatedList(
//             key: _listKey,
//             scrollDirection: Axis.horizontal,
//             physics: const BouncingScrollPhysics(),
//             padding: const EdgeInsets.only(left: 20), // 시작 여백
//             // 아이템 개수: 사진 개수 + 추가 버튼(1개)
//             initialItemCount: galleryList.length + 1,
//             itemBuilder: (context, index, animation) {
//               if (index == galleryList.length) {
//                 return Padding(
//                   padding: const EdgeInsets.only(right: 20), // 끝 여백
//                   child: ContainerButton(
//                     onTap: _addPicture,
//                     color: themePageColor,
//                     side: BorderSide(color: themeDeepColor, width: 1.0),
//                     width: imageSize,
//                     height: imageSize,
//                     borderRadius: BorderRadius.circular(24),
//                     child: const Center(
//                       child: Text(
//                         "사진\n추가하기\n+",
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           fontSize: 15,
//                           color: textSecondary,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ),
//                 );
//               }

//               // 그 외에는 사진 아이템
//               return _buildPhotoItem(galleryList[index], animation);
//             },
//           ),
//         ),
//         const SizedBox(height: 8),
//       ],
//     );
//   }
// }
import 'dart:ui';
import 'dart:io';
import 'package:diary_for_me/DB/timeline/timeline_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:image_picker/image_picker.dart';
import 'package:diary_for_me/timeline/widget/edit_event_cards/section_card.dart';
import 'package:diary_for_me/common/ui_kit.dart';
import 'package:smooth_corner/smooth_corner.dart';

import 'package:diary_for_me/common/path_util.dart';

class RelatedPhotoCard extends StatefulWidget {
  final Event event;
  final VoidCallback? onChanged;

  const RelatedPhotoCard({super.key, required this.event, this.onChanged});

  @override
  State<RelatedPhotoCard> createState() => _RelatedPhotoCardState();
}

class _RelatedPhotoCardState extends State<RelatedPhotoCard> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  // 안전한 로컬 복사본을 사용해서 AnimatedList와 원본을 일관성 있게 유지
  late List<String> _galleryLocal;

  final double imageSize = 120;

  @override
  void initState() {
    super.initState();

    // 1) dailydata가 null이면 빈 DailyData 생성 (안전)
    // widget.event.dailydata ??= DailyData();

    // 2) 로컬 가변 리스트를 만들자 (AnimatedList 조작용)
    //    이 리스트는 widget.event.dailydata!.gallery와 동일한 참조가 되도록
    //    새 리스트를 생성 후 원본 리스트 내용을 복사한다.
    _galleryLocal = List<String>.from(widget.event.dailydata!.gallery);

    // 3) (옵션) 이미지 프리캐시: 너무 무거우면 주석처리 가능
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   for (final p in _galleryLocal) {
    //     final provider = _imageProviderFromPath(p);
    //     if (provider != null) precacheImage(provider, context);
    //   }
    // });
  }

  ImageProvider? _imageProviderFromPath(String picture) {
    if (isNetworkUrl(picture)) {
      // 상대 경로(/api/...)인 경우 BASE_URL을 붙여서 전체 URL로 변환
      String url = picture;
      if (picture.startsWith('/api/')) {
        final baseUrl = dotenv.env['BASE_URL'] ?? '';
        url = '$baseUrl$picture';
        print('>>${url}');
      }
      return NetworkImage(url);
    } else if (isAssetPath(picture)) {
      try {
        return AssetImage(assetPathToAssetFile(picture));
      } catch (_) {
        return null;
      }
    } else {
      try {
        return FileImage(File(picture));
      } catch (_) {
        return null;
      }
    }
  }

  void _removePicture(int index) {
    if (index < 0 || index >= _galleryLocal.length) return;

    final removed = _galleryLocal[index];

    // 1. 먼저 로컬 리스트에서 제거
    setState(() {
      _galleryLocal.removeAt(index);
    });

    // 2. AnimatedList에 제거 애니메이션 트리거
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildPhotoItem(removed, animation),
      duration: const Duration(milliseconds: 300),
    );

    // 3. 원본 객체에도 반영 (Isar 저장은 ActivityEditSheet에서 수행)
    widget.event.dailydata!.gallery.remove(removed);

    // 4. 변경 콜백
    widget.onChanged?.call();
  }

  void _addPicture() async {
    final ImagePicker picker = ImagePicker();

    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) return;

    final String filePath = pickedFile.path;

    // 1. 새 아이템 인덱스는 로컬 리스트 길이
    final int insertIndex = _galleryLocal.length;

    // 2. 로컬 리스트에 삽입 및 AnimatedList에 알림
    setState(() {
      _galleryLocal.insert(insertIndex, filePath);
    });

    _listKey.currentState?.insertItem(
      insertIndex,
      duration: const Duration(milliseconds: 300),
    );

    // 3. 원본에도 반영
    widget.event.dailydata!.gallery.insert(insertIndex, filePath);

    // 4. 변경 콜백
    widget.onChanged?.call();
  }

  // 개별 사진 아이템
  Widget _buildPhotoItem(String picture, Animation<double> animation) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutQuad,
      reverseCurve: Curves.easeInQuad,
    );

    final provider = _imageProviderFromPath(picture);

    return SizeTransition(
      axis: Axis.horizontal,
      axisAlignment: 0.0,
      sizeFactor: curvedAnimation,
      child: ScaleTransition(
        scale: curvedAnimation,
        child: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: SizedBox(
            width: imageSize,
            child: Stack(
              children: [
                SmoothClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  smoothness: 0.6,
                  child: provider != null
                      ? Image(
                          image: provider,
                          width: imageSize,
                          height: imageSize,
                          fit: BoxFit.cover,
                          // 다운스케일 힌트(가능한 경우) — 렌더링 부담 완화
                          filterQuality: FilterQuality.low,
                          errorBuilder: (ctx, err, stack) {
                            return Container(
                              width: imageSize,
                              height: imageSize,
                              color: themePageColor,
                              child: const Icon(
                                Icons.broken_image,
                                size: 36,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : Container(
                          width: imageSize,
                          height: imageSize,
                          color: themePageColor,
                          child: const Icon(
                            Icons.broken_image,
                            size: 36,
                            color: Colors.grey,
                          ),
                        ),
                ),

                // 삭제 버튼
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () {
                      final index = _galleryLocal.indexOf(picture);
                      if (index != -1) _removePicture(index);
                    },
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.close,
                            size: 22,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '관련 사진',
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: imageSize,
          child: AnimatedList(
            key: _listKey,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 20),
            initialItemCount: _galleryLocal.length + 1,
            itemBuilder: (context, index, animation) {
              if (index == _galleryLocal.length) {
                return Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: ContainerButton(
                    onTap: _addPicture,
                    color: themePageColor,
                    side: BorderSide(color: themeDeepColor, width: 1.0),
                    width: imageSize,
                    height: imageSize,
                    borderRadius: BorderRadius.circular(24),
                    child: const Center(
                      child: Text(
                        "사진\n추가하기\n+",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }

              final picture = _galleryLocal[index];
              return _buildPhotoItem(picture, animation);
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
