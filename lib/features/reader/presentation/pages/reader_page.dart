import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../shared/services/local_book_storage.dart';
import '../../../import_book/domain/entities/imported_text_book.dart';
import '../../application/reader_fake_data.dart';
import '../../domain/entities/fake_chat_message.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  final ScrollController _outerScrollController = ScrollController();
  final ScrollController _innerScrollController = ScrollController();
  final LocalBookStorage _localBookStorage = const LocalBookStorage();

  late String _novelContent;

  @override
  void initState() {
    super.initState();
    _novelContent = List<String>.filled(
      6,
      ReaderFakeData.novelParagraph,
    ).join('\n\n');
    _restoreLatestBook();
  }

  @override
  void dispose() {
    _outerScrollController.dispose();
    _innerScrollController.dispose();
    super.dispose();
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
            _buildAvatar(ReaderFakeData.readingAvatar, true),
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
        setState(() {
          _novelContent = imported.content;
        });
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

  Future<void> _restoreLatestBook() async {
    final ImportedTextBook? localBook = await _localBookStorage
        .loadLatestBook();
    if (!mounted || localBook == null) {
      return;
    }

    setState(() {
      _novelContent = localBook.content;
    });
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
