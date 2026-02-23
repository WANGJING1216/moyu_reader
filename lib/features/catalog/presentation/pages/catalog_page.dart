import 'package:flutter/material.dart';

import '../../../import_book/domain/entities/chapter_index.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key, required this.args});

  final CatalogPageArgs args;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  late final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.args.openedAt != null) {
        final int elapsedMs = DateTime.now()
            .difference(widget.args.openedAt!)
            .inMilliseconds;
        debugPrint('catalog_open_cost_ms=$elapsedMs');
      }

      if (!_scrollController.hasClients || widget.args.chapters.isEmpty) {
        return;
      }
      final double targetOffset =
          (widget.args.currentChapterIndex * 56.0) - 220;
      final double clamped = targetOffset.clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.jumpTo(clamped);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('目录'),
        backgroundColor: const Color(0xFFF7F7F7),
        surfaceTintColor: const Color(0xFFF7F7F7),
      ),
      body: widget.args.chapters.isEmpty
          ? const Center(child: Text('暂无章节数据'))
          : ListView.builder(
              key: const Key('catalog_chapter_list'),
              controller: _scrollController,
              itemCount: widget.args.chapters.length,
              itemBuilder: (BuildContext context, int index) {
                final ChapterIndex chapter = widget.args.chapters[index];
                final bool isCurrent = index == widget.args.currentChapterIndex;
                final bool isRead = widget.args.readChapterIndexes.contains(
                  index,
                );

                Color textColor = const Color(0xFF1A1A1A);
                String statusText = '未读';
                if (isCurrent) {
                  textColor = const Color(0xFF1A7FD4);
                  statusText = '当前';
                } else if (isRead) {
                  textColor = const Color(0xFFAAAAAA);
                  statusText = '已读';
                }

                return ListTile(
                  key: Key('catalog_chapter_$index'),
                  leading: _buildStatusIcon(
                    index: index,
                    isCurrent: isCurrent,
                    isRead: isRead,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  minTileHeight: 56,
                  title: Text(
                    chapter.title,
                    style: TextStyle(color: textColor, fontSize: 16),
                  ),
                  trailing: Text(
                    statusText,
                    key: Key('catalog_status_$index'),
                    style: TextStyle(
                      color: isCurrent
                          ? const Color(0xFF1A7FD4)
                          : isRead
                          ? const Color(0xFFBBBBBB)
                          : const Color(0xFFCCCCCC),
                      fontSize: 12,
                    ),
                  ),
                  onTap: () => Navigator.of(context).pop<int>(index),
                );
              },
            ),
    );
  }

  Widget _buildStatusIcon({
    required int index,
    required bool isCurrent,
    required bool isRead,
  }) {
    if (isCurrent) {
      return Icon(
        Icons.circle,
        key: Key('catalog_status_icon_current_$index'),
        size: 10,
        color: Color(0xFF1A7FD4),
      );
    }
    if (isRead) {
      return Icon(
        Icons.check,
        key: Key('catalog_status_icon_read_$index'),
        size: 16,
        color: Color(0xFF9E9E9E),
      );
    }
    return const SizedBox(width: 16, height: 16);
  }
}

class CatalogPageArgs {
  const CatalogPageArgs({
    required this.bookId,
    required this.chapters,
    required this.currentChapterIndex,
    required this.readChapterIndexes,
    this.openedAt,
  });

  final String bookId;
  final List<ChapterIndex> chapters;
  final int currentChapterIndex;
  final Set<int> readChapterIndexes;
  final DateTime? openedAt;
}
