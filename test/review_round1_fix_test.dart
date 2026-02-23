import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moyu_reader/app/router.dart';
import 'package:moyu_reader/features/import_book/data/repositories/local_txt_book_import_repository.dart';
import 'package:moyu_reader/shared/services/local_book_storage.dart';

void main() {
  test('single chapter title should build title-based chapter index', () {
    const LocalTxtBookImportRepository repository =
        LocalTxtBookImportRepository();
    const String content = '第1章 开端\n这里是正文内容。';

    final chapters = repository.buildChapterIndexesForTesting(content);

    expect(chapters, hasLength(1));
    expect(chapters.first.title, '第1章 开端');
    expect(chapters.first.startOffset, 0);
    expect(chapters.first.endOffset, content.length);
  });

  testWidgets('/catalog route without arguments should not crash', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRoutes.catalog,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reader_top_bar')), findsOneWidget);
  });

  test('loadLatestBook returns null and clears bad json data', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'moyu_reader_latest_book': '{bad json',
    });
    const LocalBookStorage storage = LocalBookStorage();

    final book = await storage.loadLatestBook();
    final prefs = await SharedPreferences.getInstance();

    expect(book, isNull);
    expect(prefs.getString('moyu_reader_latest_book'), isNull);
  });
}
