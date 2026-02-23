import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moyu_reader/app/router.dart';
import 'package:moyu_reader/features/import_book/domain/entities/chapter_index.dart';
import 'package:moyu_reader/features/import_book/domain/entities/imported_text_book.dart';
import 'package:moyu_reader/features/reader/domain/entities/reading_progress.dart';
import 'package:moyu_reader/features/reader/presentation/pages/reader_page.dart';
import 'package:moyu_reader/shared/services/reading_progress_storage.dart';

void main() {
  ImportedTextBook buildBookA() {
    final String chapter1Body = List<String>.filled(80, '第一章内容。').join('\n');
    final String chapter2Body = List<String>.filled(120, '第二章内容。').join('\n');
    final String content = '第1章 开始\n$chapter1Body\n\n第2章 继续\n$chapter2Body';
    final int c1Start = content.indexOf('第1章 开始');
    final int c2Start = content.indexOf('第2章 继续');

    return ImportedTextBook(
      title: '书A',
      content: content,
      encoding: 'utf-8',
      sourcePath: '/tmp/book_a.txt',
      chapters: <ChapterIndex>[
        ChapterIndex(
          index: 0,
          title: '第1章 开始',
          startOffset: c1Start,
          endOffset: c2Start,
        ),
        ChapterIndex(
          index: 1,
          title: '第2章 继续',
          startOffset: c2Start,
          endOffset: content.length,
        ),
      ],
    );
  }

  Future<void> pumpReader(WidgetTester tester, ImportedTextBook book) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: ReaderPage(initialBook: book),
      ),
    );
    await tester.pumpAndSettle();
  }

  test(
    'reading progress storage supports save/load and bookId isolation',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const ReadingProgressStorage storage = ReadingProgressStorage();

      await storage.saveProgress(
        ReadingProgress(
          bookId: '/tmp/book_a.txt',
          chapterIndex: 1,
          innerOffset: 20,
          outerOffset: 40,
          updatedAt: DateTime(2026, 2, 23),
          readChapterIndexes: <int>{0, 1},
        ),
      );
      await storage.saveProgress(
        ReadingProgress(
          bookId: '/tmp/book_b.txt',
          chapterIndex: 0,
          innerOffset: 5,
          outerOffset: 10,
          updatedAt: DateTime(2026, 2, 23),
          readChapterIndexes: <int>{0},
        ),
      );

      final ReadingProgress? a = await storage.loadProgress('/tmp/book_a.txt');
      final ReadingProgress? b = await storage.loadProgress('/tmp/book_b.txt');

      expect(a, isNotNull);
      expect(a!.chapterIndex, 1);
      expect(a.readChapterIndexes, <int>{0, 1});
      expect(b, isNotNull);
      expect(b!.chapterIndex, 0);
    },
  );

  test(
    'reading progress storage clears broken data and returns empty',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        ReadingProgressStorage.storageKey: '{bad json',
      });

      const ReadingProgressStorage storage = ReadingProgressStorage();
      final Map<String, ReadingProgress> loaded = await storage
          .loadAllProgress();
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      expect(loaded, isEmpty);
      expect(prefs.getString(ReadingProgressStorage.storageKey), isNull);
    },
  );

  testWidgets('reader restores chapter and offsets from persisted progress', (
    WidgetTester tester,
  ) async {
    final ImportedTextBook book = buildBookA();
    SharedPreferences.setMockInitialValues(<String, Object>{
      ReadingProgressStorage.storageKey: jsonEncode(<String, dynamic>{
        '/tmp/book_a.txt': <String, dynamic>{
          'bookId': '/tmp/book_a.txt',
          'chapterIndex': 1,
          'innerOffset': 120.0,
          'outerOffset': 0.0,
          'updatedAt': DateTime(2026, 2, 23).toIso8601String(),
          'readChapterIndexes': <int>[0, 1],
        },
      }),
    });

    await pumpReader(tester, book);

    expect(find.textContaining('第2章 继续'), findsOneWidget);

    final Finder innerScrollableFinder = find
        .descendant(
          of: find.byKey(const Key('reader_novel_inner_scroll')),
          matching: find.byType(Scrollable),
        )
        .first;
    final ScrollableState innerState = tester.state<ScrollableState>(
      innerScrollableFinder,
    );
    expect(innerState.position.pixels, greaterThan(0));
  });

  testWidgets('reader saves progress on lifecycle pause', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ImportedTextBook book = buildBookA();

    await pumpReader(tester, book);

    await tester.drag(
      find.byKey(const Key('reader_novel_drag_layer')),
      const Offset(0, -240),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(ReadingProgressStorage.storageKey);
    expect(raw, isNotNull);

    final Map<String, dynamic> json = jsonDecode(raw!) as Map<String, dynamic>;
    expect(json.containsKey('/tmp/book_a.txt'), isTrue);
  });
}
