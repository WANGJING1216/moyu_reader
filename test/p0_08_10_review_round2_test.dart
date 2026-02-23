import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moyu_reader/app/router.dart';
import 'package:moyu_reader/features/catalog/presentation/pages/catalog_page.dart';
import 'package:moyu_reader/features/import_book/domain/entities/chapter_index.dart';
import 'package:moyu_reader/features/reader/application/reader_progress_session_store.dart';

void main() {
  test('catalog route uses slide transition and duration under 0.3s', () {
    final Route<dynamic> route = AppRouter.onGenerateRoute(
      const RouteSettings(
        name: AppRoutes.catalog,
        arguments: CatalogPageArgs(
          bookId: 'book_a',
          chapters: <ChapterIndex>[
            ChapterIndex(index: 0, title: '第1章', startOffset: 0, endOffset: 10),
          ],
          currentChapterIndex: 0,
          readChapterIndexes: <int>{0},
        ),
      ),
    );

    expect(route, isA<PageRouteBuilder<int?>>());
    final PageRouteBuilder<int?> pageRoute = route as PageRouteBuilder<int?>;
    expect(pageRoute.transitionDuration.inMilliseconds, lessThanOrEqualTo(300));
    expect(
      pageRoute.transitionDuration,
      equals(AppRouter.catalogTransitionDuration),
    );
  });

  test('reader progress sessions are isolated by bookId', () {
    final ReaderProgressSessionStore store = ReaderProgressSessionStore();

    final ReaderProgressSession bookAInit = store.resolve(
      bookId: 'book_a',
      chapterCount: 5,
    );
    expect(bookAInit.currentChapterIndex, 0);
    expect(bookAInit.readChapterIndexes, <int>{0});

    store.update(
      bookId: 'book_a',
      chapterCount: 5,
      currentChapterIndex: 3,
      readChapterIndexes: <int>{0, 1, 2, 3},
    );

    final ReaderProgressSession bookBInit = store.resolve(
      bookId: 'book_b',
      chapterCount: 5,
    );
    expect(bookBInit.currentChapterIndex, 0);
    expect(bookBInit.readChapterIndexes, <int>{0});

    final ReaderProgressSession bookAResolved = store.resolve(
      bookId: 'book_a',
      chapterCount: 5,
    );
    expect(bookAResolved.currentChapterIndex, 3);
    expect(bookAResolved.readChapterIndexes, <int>{0, 1, 2, 3});
  });

  testWidgets('catalog page accepts openedAt and renders list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CatalogPage(
          args: CatalogPageArgs(
            bookId: 'book_a',
            chapters: <ChapterIndex>[
              ChapterIndex(
                index: 0,
                title: '第1章',
                startOffset: 0,
                endOffset: 10,
              ),
            ],
            currentChapterIndex: 0,
            readChapterIndexes: <int>{0},
            openedAt: null,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byKey(const Key('catalog_chapter_list')), findsOneWidget);
  });
}
