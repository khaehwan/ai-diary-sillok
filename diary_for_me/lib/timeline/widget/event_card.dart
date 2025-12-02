import 'package:diary_for_me/common/ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// [변경] Isar 모델 import
import '../../DB/timeline/timeline_model.dart';

class EventCard extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Event event;

  const EventCard({super.key, this.onEdit, this.onDelete, required this.event});

  @override
  Widget build(BuildContext context) {
    // timestamp가 null일 경우 안전하게 현재 시간 표시
    final eventTime = event.timestamp ?? DateTime.now();

    return ContainerButton(
      color: themePageColor,
      padding: const EdgeInsets.all(20),
      onTap: onEdit ?? () {},
      borderRadius: BorderRadius.circular(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 시간
          Container(
            alignment: Alignment.center,
            width: 48,
            height: 36,
            child: Text(
              DateFormat('HH:mm').format(eventTime),
              style: const TextStyle(
                fontSize: 16,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(height: 24, width: 1, color: Colors.black.withAlpha(16)),
          const SizedBox(width: 12),
          // 내용 (Expanded로 감싸서 오버플로우 방지)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title, // Isar 모델에서 기본값('')이 있으므로 안전
                  style: contentTitle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  event.content, // Isar 모델에서 기본값('')이 있으므로 안전
                  style: contentDetail(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Text('편집', style: contentDetail()),
          const SizedBox(width: 12),
          Container(height: 24, width: 1, color: Colors.black.withAlpha(16)),
          const SizedBox(width: 5),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.delete_outline, color: textTertiary, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}