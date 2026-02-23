import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moyu_reader/app/router.dart';
import 'package:moyu_reader/features/import_book/domain/entities/chapter_index.dart';
import 'package:moyu_reader/features/import_book/domain/entities/imported_text_book.dart';
import 'package:moyu_reader/features/reader/presentation/pages/reader_page.dart';

void main() {
  ImportedTextBook buildBook() {
    const String content = '第1章 开始\n第一章内容。\n\n第2章 转折\n第二章内容。\n\n第3章 收束\n第三章内容。';
    final int c1Start = content.indexOf('第1章 开始');
    final int c2Start = content.indexOf('第2章 转折');
    final int c3Start = content.indexOf('第3章 收束');

    return ImportedTextBook(
      title: '测试书籍',
      content: content,
      encoding: 'UTF-8',
      chapters: <ChapterIndex>[
        ChapterIndex(
          index: 0,
          title: '第1章 开始',
          startOffset: c1Start,
          endOffset: c2Start,
        ),
        ChapterIndex(
          index: 1,
          title: '第2章 转折',
          startOffset: c2Start,
          endOffset: c3Start,
        ),
        ChapterIndex(
          index: 2,
          title: '第3章 收束',
          startOffset: c3Start,
          endOffset: content.length,
        ),
      ],
    );
  }

  Widget buildApp({required ImportedTextBook book}) {
    return MaterialApp(
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: ReaderPage(
        initialBook: book,
        avatarLongPressDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  testWidgets('P0-08 long press avatar opens catalog page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp(book: buildBook()));
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('reader_catalog_avatar')));
    await tester.pumpAndSettle();

    expect(find.text('目录'), findsOneWidget);
    expect(find.byKey(const Key('catalog_chapter_list')), findsOneWidget);
    expect(find.text('第1章 开始'), findsOneWidget);
    expect(find.text('第2章 转折'), findsOneWidget);
    expect(find.text('第3章 收束'), findsOneWidget);
  });

  testWidgets('P0-09 tap chapter jumps back and updates reader content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp(book: buildBook()));
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('reader_catalog_avatar')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('catalog_chapter_1')));
    await tester.pumpAndSettle();

    expect(find.text('目录'), findsNothing);
    expect(find.textContaining('第2章 转折'), findsOneWidget);
    expect(find.textContaining('第二章内容。'), findsOneWidget);
  });

  testWidgets('P0-10 catalog shows current and read status', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp(book: buildBook()));
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('reader_catalog_avatar')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('catalog_status_0')), findsOneWidget);
    expect(find.text('当前'), findsOneWidget);
    expect(
      find.byKey(const Key('catalog_status_icon_current_0')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('catalog_chapter_2')));
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('reader_catalog_avatar')));
    await tester.pumpAndSettle();

    final Text readStatus = tester.widget<Text>(
      find.byKey(const Key('catalog_status_1')),
    );
    final Text currentStatus = tester.widget<Text>(
      find.byKey(const Key('catalog_status_2')),
    );

    expect(readStatus.data, equals('已读'));
    expect(currentStatus.data, equals('当前'));
    expect(find.byKey(const Key('catalog_status_icon_read_1')), findsOneWidget);
    expect(
      find.byKey(const Key('catalog_status_icon_current_2')),
      findsOneWidget,
    );
  });

  testWidgets('P0-10 read status does not lose when jumping back chapters', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp(book: buildBook()));
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('reader_catalog_avatar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('catalog_chapter_2')));
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('reader_catalog_avatar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('catalog_chapter_1')));
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('reader_catalog_avatar')));
    await tester.pumpAndSettle();

    final Text chapter2Status = tester.widget<Text>(
      find.byKey(const Key('catalog_status_2')),
    );
    expect(chapter2Status.data, equals('已读'));
    expect(find.byKey(const Key('catalog_status_icon_read_2')), findsOneWidget);
  });
}
