import 'package:diary_for_me/common/ui_kit.dart';
import 'package:diary_for_me/DB/db_manager.dart';
import 'package:diary_for_me/DB/diary/diary_model.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:smooth_corner/smooth_corner.dart';

class DiaryEditScreen extends StatefulWidget {
  final int diaryId;

  const DiaryEditScreen({super.key, required this.diaryId});

  @override
  State<DiaryEditScreen> createState() => _DiaryEditScreenState();
}

class _DiaryEditScreenState extends State<DiaryEditScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  Diary? _diary;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _loadDiary();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _loadDiary() async {
    final isar = await DB().instance;
    final diary = await isar.diarys.get(widget.diaryId);

    if (diary != null) {
      _titleController.text = diary.title;
      _contentController.text = diary.content?.text ?? '';
      setState(() {
        _diary = diary;
        _tags = diary.tag.where((t) => t != '@f').toList();
        _isLoading = false;
      });
    } else {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('일기를 찾을 수 없습니다.')),
        );
      }
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isEmpty) return;
    if (_tags.contains(tag)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 존재하는 태그입니다.')),
      );
      return;
    }

    setState(() {
      _tags.add(tag);
      _tagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _saveDiary() async {
    if (_diary == null || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final isar = await DB().instance;

      await isar.writeTxn(() async {
        final updatedContent = DiaryContent(
          text: _contentController.text,
          image: _diary!.content?.image ?? [],
          music: _diary!.content?.music ?? [],
        );

        final hasFavorite = _diary!.tag.contains('@f');
        final updatedTags = [..._tags];
        if (hasFavorite) {
          updatedTags.add('@f');
        }

        _diary!.title = _titleController.text;
        _diary!.content = updatedContent;
        _diary!.tag = updatedTags;

        await isar.diarys.put(_diary!);
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('일기가 저장되었습니다.')),
        );
      }
    } catch (e) {
      print('일기 저장 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: textPrimary, size: 28.0),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('일기 편집', style: appbarTitle()),
        centerTitle: true,
        actions: [
          ContainerButton(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('저장', style: appbarButton(color: themeColor)),
              ),
            ),
            onTap: _isSaving ? () {} : _saveDiary,
          ),
          const SizedBox(width: 4),
        ],
      ),
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('제목', style: contentTitle()),
              const SizedBox(height: 8),
              Container(
                decoration: ShapeDecoration(
                  shape: SmoothRectangleBorder(
                    side: BorderSide(color: themeDeepColor, width: 1.0),
                    borderRadius: BorderRadius.circular(20),
                    smoothness: 0.6,
                  ),
                  color: themePageColor,
                ),
                child: TextField(
                  controller: _titleController,
                  cursorColor: themeColor,
                  style: contentTitle(fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    hintText: '제목을 입력해주세요',
                    hintStyle: contentTitle(color: textTertiary),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text('내용', style: contentTitle()),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(minHeight: 300),
                decoration: ShapeDecoration(
                  shape: SmoothRectangleBorder(
                    side: BorderSide(color: themeDeepColor, width: 1.0),
                    borderRadius: BorderRadius.circular(24),
                    smoothness: 0.6,
                  ),
                  color: themePageColor,
                ),
                child: TextField(
                  controller: _contentController,
                  cursorColor: themeColor,
                  maxLines: null,
                  minLines: 10,
                  style: diaryDetail(fontWeight: FontWeight.w400),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                    hintText: '일기 내용을 입력해주세요',
                    hintStyle: diaryDetail(color: textTertiary),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text('태그', style: contentTitle()),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: ShapeDecoration(
                        shape: SmoothRectangleBorder(
                          side: BorderSide(color: themeDeepColor, width: 1.0),
                          borderRadius: BorderRadius.circular(20),
                          smoothness: 0.6,
                        ),
                        color: themePageColor,
                      ),
                      child: TextField(
                        controller: _tagController,
                        cursorColor: themeColor,
                        style: contentDetail(),
                        onSubmitted: (_) => _addTag(),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          hintText: '태그 입력',
                          hintStyle: contentDetail(color: textTertiary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ContainerButton(
                    onTap: _addTag,
                    color: themeColor,
                    borderRadius: BorderRadius.circular(20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      '추가',
                      style: contentDetail(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: ShapeDecoration(
                        shape: SmoothRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          smoothness: 0.6,
                        ),
                        color: themeColor.withAlpha(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '#$tag',
                            style: contentDetail(
                              color: themeColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _removeTag(tag),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: themeColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 32),
              const SafeArea(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  }
}
