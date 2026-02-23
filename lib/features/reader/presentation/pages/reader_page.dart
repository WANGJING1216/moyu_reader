import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../shared/services/local_book_storage.dart';
import '../../../../shared/services/reading_progress_storage.dart';
import '../../../catalog/presentation/pages/catalog_page.dart';
import '../../../import_book/domain/entities/imported_text_book.dart';
import '../../application/reader_fake_data.dart';
import '../../application/reader_progress_session_store.dart';
import '../../domain/entities/fake_chat_message.dart';
import '../../domain/entities/reading_progress.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({
    super.key,
    this.initialBook,
    this.avatarLongPressDuration = const Duration(milliseconds: 500),
  });

  final ImportedTextBook? initialBook;
  final Duration avatarLongPressDuration;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> with WidgetsBindingObserver {
  final ScrollController _outerScrollController = ScrollController();
  final ScrollController _innerScrollController = ScrollController();
  final LocalBookStorage _localBookStorage = const LocalBookStorage();
  final ReadingProgressStorage _readingProgressStorage =
      const ReadingProgressStorage();
  final ReaderProgressSessionStore _sessionStore = ReaderProgressSessionStore();
  Timer? _saveDebounceTimer;
  int _restoreToken = 0;

  ImportedTextBook? _currentBook;
  String? _currentBookId;
  late String _novelContent;
  int _currentChapterIndex = 0;
  Set<int> _readChapterIndexes = <int>{0};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _innerScrollController.addListener(_onProgressRelatedScroll);
    _outerScrollController.addListener(_onProgressRelatedScroll);

    _novelContent = List<String>.filled(
      6,
      ReaderFakeData.novelParagraph,
    ).join('\n\n');

    if (widget.initialBook != null) {
      _applyImportedBook(widget.initialBook!);
    } else {
      _restoreLatestBook();
    }
  }

  @override
  void dispose() {
    _saveReadingProgress();
    WidgetsBinding.instance.removeObserver(this);
    _saveDebounceTimer?.cancel();
    _innerScrollController.removeListener(_onProgressRelatedScroll);
    _outerScrollController.removeListener(_onProgressRelatedScroll);
    _outerScrollController.dispose();
    _innerScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _saveReadingProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      body: Column(
        children: <Widget>[
          _buildTopBar(),
          Expanded(child: _buildChatArea()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return CustomScrollView(
      key: const Key('reader_chat_area'),
      controller: _outerScrollController,
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate(<Widget>[
              ...ReaderFakeData.chatMessages.map(_buildFakeMessage),
              const SizedBox(height: 12),
              _buildNovelBubble(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildFakeMessage(FakeChatMessage message) {
    final bool isLeft = message.role == FakeChatRole.left;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (message.timestamp != null)
          Center(
            child: Container(
              key: Key('timestamp_${message.timestamp}'),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0x19000000),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                message.timestamp!,
                style: const TextStyle(fontSize: 11, color: Color(0xFFABABAB)),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: isLeft
                ? MainAxisAlignment.start
                : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (isLeft) _buildAvatar(message.avatar, isLeft),
              if (isLeft) const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(maxWidth: 260),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isLeft
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFF9FE175),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(fontSize: 15, height: 1.35),
                ),
              ),
              if (!isLeft) const SizedBox(width: 8),
              if (!isLeft) _buildAvatar(message.avatar, isLeft),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNovelBubble() {
    final double bubbleHeight = MediaQuery.sizeOf(context).height * 0.42;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double avatarAndGapWidth = 46;
        final double maxBubbleWidth = constraints.maxWidth - avatarAndGapWidth;
        final double bubbleWidth = (constraints.maxWidth * 0.85)
            .clamp(220.0, maxBubbleWidth)
            .toDouble();
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildCatalogAvatar(),
            const SizedBox(width: 8),
            SizedBox(
              width: bubbleWidth,
              child: Container(
                constraints: BoxConstraints(
                  minHeight: 220,
                  maxHeight: bubbleHeight,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Listener(
                    onPointerMove: (PointerMoveEvent event) {
                      _scrollBubbleWithBoundaryTransfer(-event.delta.dy);
                    },
                    onPointerSignal: (PointerSignalEvent event) {
                      if (event is PointerScrollEvent) {
                        _scrollBubbleWithBoundaryTransfer(event.scrollDelta.dy);
                      }
                    },
                    child: GestureDetector(
                      key: const Key('reader_novel_drag_layer'),
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: (DragUpdateDetails details) {
                        _scrollBubbleWithBoundaryTransfer(-details.delta.dy);
                      },
                      child: SingleChildScrollView(
                        key: const Key('reader_novel_inner_scroll'),
                        controller: _innerScrollController,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          _novelContent,
                          style: const TextStyle(fontSize: 16, height: 1.6),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      key: const Key('reader_input_bar'),
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F7),
        border: Border(top: BorderSide(color: Color(0xFFEAEAEA))),
      ),
      child: Row(
        children: <Widget>[
          Container(
            key: const Key('reader_plus_placeholder'),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFB5B5B5), width: 1.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add, size: 20, color: Color(0xFF7A7A7A)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 38,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '请输入消息',
                style: TextStyle(color: Color(0xFF9C9C9C)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              Icons.sentiment_satisfied_alt_outlined,
              color: Color(0xFF7A7A7A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      key: const Key('reader_top_bar'),
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F7),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const <Widget>[
                Icon(Icons.chevron_left, color: Color(0xFF1A7FD4), size: 22),
                SizedBox(width: 2),
                Text(
                  '微信',
                  style: TextStyle(color: Color(0xFF1A7FD4), fontSize: 16),
                ),
              ],
            ),
          ),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                '产品群聊',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Text(
                '在线',
                style: TextStyle(fontSize: 11, color: Color(0xFF888888)),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: PopupMenuButton<_ReaderMenuAction>(
              key: const Key('reader_menu_button'),
              tooltip: '更多',
              onSelected: _onMenuSelected,
              itemBuilder: (BuildContext context) {
                return const <PopupMenuEntry<_ReaderMenuAction>>[
                  PopupMenuItem<_ReaderMenuAction>(
                    key: Key('reader_menu_bookshelf'),
                    value: _ReaderMenuAction.bookshelf,
                    child: Text('我的书架'),
                  ),
                  PopupMenuItem<_ReaderMenuAction>(
                    key: Key('reader_menu_import_book'),
                    value: _ReaderMenuAction.importBook,
                    child: Text('导入新书'),
                  ),
                ];
              },
              child: const Text(
                '···',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String emoji, bool isLeft) {
    return Container(
      key: Key(isLeft ? 'avatar_left_$emoji' : 'avatar_right_$emoji'),
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: isLeft
            ? const LinearGradient(
                colors: <Color>[
                  Color(0xFFF8BBD9),
                  Color(0xFFCE93D8),
                  Color(0xFF9FA8DA),
                ],
              )
            : null,
        color: isLeft ? null : const Color(0xFF89C4FF),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
    );
  }

  Widget _buildCatalogAvatar() {
    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(
                duration: widget.avatarLongPressDuration,
              ),
              (LongPressGestureRecognizer instance) {
                instance.onLongPress = _openCatalog;
              },
            ),
      },
      child: Container(
        key: const Key('reader_catalog_avatar'),
        child: _buildAvatar(ReaderFakeData.readingAvatar, true),
      ),
    );
  }

  Future<void> _onMenuSelected(_ReaderMenuAction action) async {
    switch (action) {
      case _ReaderMenuAction.bookshelf:
        await Navigator.of(context).pushNamed(AppRoutes.bookshelf);
        return;
      case _ReaderMenuAction.importBook:
        final ImportedTextBook? imported = await Navigator.of(
          context,
        ).pushNamed<ImportedTextBook>(AppRoutes.importBook);
        if (!mounted || imported == null) {
          return;
        }
        _applyImportedBook(imported);
        _jumpBubbleToTop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '已导入：${imported.title}（${imported.encoding}，${imported.chapters.length}章）',
            ),
          ),
        );
        return;
    }
  }

  void _applyImportedBook(ImportedTextBook book) {
    _currentBook = book;
    _currentBookId = _buildBookId(book);

    final ReaderProgressSession session = _sessionStore.resolve(
      bookId: _currentBookId!,
      chapterCount: book.chapters.length,
    );
    _currentChapterIndex = session.currentChapterIndex;
    _readChapterIndexes = session.readChapterIndexes;

    if (book.chapters.isEmpty) {
      _novelContent = book.content;
      setState(() {});
      return;
    }

    _currentChapterIndex = _currentChapterIndex.clamp(
      0,
      book.chapters.length - 1,
    );
    _novelContent = _chapterText(book, _currentChapterIndex);
    setState(() {});

    _restoreProgressForCurrentBook(book);
  }

  Future<void> _restoreLatestBook() async {
    final ImportedTextBook? localBook = await _localBookStorage
        .loadLatestBook();
    if (!mounted || localBook == null) {
      return;
    }
    _applyImportedBook(localBook);
  }

  Future<void> _openCatalog() async {
    final ImportedTextBook? book = _currentBook;
    if (book == null || book.chapters.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('暂无章节数据')));
      return;
    }

    final int? selectedIndex = await Navigator.of(context).pushNamed<int>(
      AppRoutes.catalog,
      arguments: CatalogPageArgs(
        bookId: _currentBookId ?? _buildBookId(book),
        chapters: book.chapters,
        currentChapterIndex: _currentChapterIndex,
        readChapterIndexes: _readChapterIndexes,
        openedAt: DateTime.now(),
      ),
    );

    if (!mounted ||
        selectedIndex == null ||
        selectedIndex < 0 ||
        selectedIndex >= book.chapters.length) {
      return;
    }

    setState(() {
      _currentChapterIndex = selectedIndex;
      _readChapterIndexes = <int>{
        ..._readChapterIndexes,
        for (int i = 0; i <= selectedIndex; i++) i,
      };
      _novelContent = _chapterText(book, selectedIndex);
    });
    _syncCurrentBookSession(chapterCount: book.chapters.length);

    _jumpBubbleToTop();
    _saveReadingProgress();
  }

  String _buildBookId(ImportedTextBook book) {
    final String? sourcePath = book.sourcePath;
    if (sourcePath != null && sourcePath.trim().isNotEmpty) {
      return sourcePath;
    }
    // Stable fallback id: include title + length + chapter count + deterministic fingerprint.
    // This avoids collisions that would happen with only `title|encoding`.
    final int sampleLength = book.content.length < 512
        ? book.content.length
        : 512;
    final String head = book.content.substring(0, sampleLength);
    final String tail = book.content.substring(
      book.content.length - sampleLength,
    );
    final String fingerprint = _stableFingerprint(
      '${book.title}|${book.content.length}|${book.chapters.length}|$head|$tail',
    );
    return 'fallback:$fingerprint';
  }

  void _syncCurrentBookSession({required int chapterCount}) {
    final String? bookId = _currentBookId;
    if (bookId == null) {
      return;
    }
    _sessionStore.update(
      bookId: bookId,
      chapterCount: chapterCount,
      currentChapterIndex: _currentChapterIndex,
      readChapterIndexes: _readChapterIndexes,
    );
  }

  Future<void> _restoreProgressForCurrentBook(ImportedTextBook book) async {
    final String? bookId = _currentBookId;
    if (bookId == null || book.chapters.isEmpty) {
      return;
    }

    final int token = ++_restoreToken;
    final ReadingProgress? stored = await _readingProgressStorage.loadProgress(
      bookId,
    );
    if (!mounted || token != _restoreToken || _currentBookId != bookId) {
      return;
    }
    if (stored == null) {
      return;
    }

    final int restoredChapter = stored.chapterIndex.clamp(
      0,
      book.chapters.length - 1,
    );
    final Set<int> restoredRead = <int>{
      ..._readChapterIndexes,
      ...stored.readChapterIndexes,
      for (int i = 0; i <= restoredChapter; i++) i,
    };

    setState(() {
      _currentChapterIndex = restoredChapter;
      _readChapterIndexes = restoredRead;
      _novelContent = _chapterText(book, restoredChapter);
    });
    _syncCurrentBookSession(chapterCount: book.chapters.length);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToOffsets(
        innerOffset: stored.innerOffset,
        outerOffset: stored.outerOffset,
      );
    });
  }

  void _onProgressRelatedScroll() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 800), () {
      _saveReadingProgress();
    });
  }

  void _saveReadingProgress() {
    final ImportedTextBook? book = _currentBook;
    final String? bookId = _currentBookId;
    if (book == null || bookId == null || book.chapters.isEmpty) {
      return;
    }

    final ReadingProgress progress = ReadingProgress(
      bookId: bookId,
      chapterIndex: _currentChapterIndex,
      innerOffset: _innerScrollController.hasClients
          ? _innerScrollController.position.pixels
          : 0,
      outerOffset: _outerScrollController.hasClients
          ? _outerScrollController.position.pixels
          : 0,
      updatedAt: DateTime.now(),
      readChapterIndexes: _readChapterIndexes,
    );

    _readingProgressStorage.saveProgress(progress);
    _syncCurrentBookSession(chapterCount: book.chapters.length);
  }

  void _jumpToOffsets({
    required double innerOffset,
    required double outerOffset,
  }) {
    if (_innerScrollController.hasClients) {
      final ScrollPosition position = _innerScrollController.position;
      final double clamped = innerOffset.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      _innerScrollController.jumpTo(clamped);
    }

    if (_outerScrollController.hasClients) {
      final ScrollPosition position = _outerScrollController.position;
      final double clamped = outerOffset.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      _outerScrollController.jumpTo(clamped);
    }
  }

  String _stableFingerprint(String input) {
    int hash = 2166136261;
    for (final int codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  String _chapterText(ImportedTextBook book, int index) {
    if (book.chapters.isEmpty) {
      return book.content;
    }

    final int safeIndex = index.clamp(0, book.chapters.length - 1);
    final int start = book.chapters[safeIndex].startOffset.clamp(
      0,
      book.content.length,
    );
    final int end = book.chapters[safeIndex].endOffset.clamp(
      start,
      book.content.length,
    );
    return book.content.substring(start, end).trim();
  }

  void _jumpBubbleToTop() {
    if (_innerScrollController.hasClients) {
      _innerScrollController.jumpTo(
        _innerScrollController.position.minScrollExtent,
      );
    }
    if (_outerScrollController.hasClients) {
      _outerScrollController.jumpTo(
        _outerScrollController.position.minScrollExtent,
      );
    }
  }

  void _scrollBubbleWithBoundaryTransfer(double scrollDelta) {
    final double remaining = _consumeScrollDelta(
      _innerScrollController,
      scrollDelta,
    );
    if (remaining.abs() > 0) {
      _consumeScrollDelta(_outerScrollController, remaining);
    }
  }

  double _consumeScrollDelta(ScrollController controller, double delta) {
    if (!controller.hasClients || delta == 0) {
      return delta;
    }

    final ScrollPosition position = controller.position;
    final double target = (position.pixels + delta)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    final double consumed = target - position.pixels;

    if (consumed != 0) {
      controller.jumpTo(target);
    }

    return delta - consumed;
  }
}

enum _ReaderMenuAction { bookshelf, importBook }
