import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moyu_reader/app/app.dart';

void main() {
  testWidgets('P0-01 renders top/chat/input three-layer structure', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MoyuReaderApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reader_top_bar')), findsOneWidget);
    expect(find.byKey(const Key('reader_chat_area')), findsOneWidget);
    expect(find.byKey(const Key('reader_input_bar')), findsOneWidget);
  });

  testWidgets('P0-04 menu items are clickable and can navigate', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MoyuReaderApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reader_menu_button')));
    await tester.pumpAndSettle();
    expect(find.text('我的书架'), findsWidgets);

    await tester.tap(find.byKey(const Key('reader_menu_bookshelf')));
    await tester.pumpAndSettle();
    expect(find.text('我的书架（P0仅菜单入口）'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reader_menu_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reader_menu_import_book')));
    await tester.pumpAndSettle();
    expect(find.text('请选择 TXT 文件导入阅读'), findsOneWidget);
    expect(find.text('选择TXT并导入'), findsOneWidget);
  });

  testWidgets(
    'P0-02 nested scrolling transfers to outer when inner reaches boundary',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 520));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MoyuReaderApp());
      await tester.pumpAndSettle();

      final Finder outerScrollableFinder = find
          .descendant(
            of: find.byKey(const Key('reader_chat_area')),
            matching: find.byType(Scrollable),
          )
          .first;
      final Finder innerScrollableFinder = find
          .descendant(
            of: find.byKey(const Key('reader_novel_inner_scroll')),
            matching: find.byType(Scrollable),
          )
          .first;

      final ScrollableState outerStateBefore = tester.state<ScrollableState>(
        outerScrollableFinder,
      );
      final ScrollableState innerStateBefore = tester.state<ScrollableState>(
        innerScrollableFinder,
      );
      expect(outerStateBefore.position.maxScrollExtent, greaterThan(0));

      // Set a deterministic boundary-transfer scenario:
      // inner at top cannot consume negative delta, so it should transfer to outer.
      outerStateBefore.position.jumpTo(100);
      innerStateBefore.position.jumpTo(
        innerStateBefore.position.minScrollExtent,
      );
      await tester.pumpAndSettle();
      final double outerPixelsBefore = outerStateBefore.position.pixels;

      final Offset dragStart = tester.getCenter(
        find.byKey(const Key('reader_novel_drag_layer')),
      );
      final TestGesture gesture = await tester.startGesture(dragStart);
      await gesture.moveBy(const Offset(0, 120));
      await gesture.moveBy(const Offset(0, 120));
      await gesture.moveBy(const Offset(0, 120));
      await gesture.up();
      await tester.pumpAndSettle();

      final ScrollableState innerStateAfter = tester.state<ScrollableState>(
        innerScrollableFinder,
      );
      final ScrollableState outerStateAfter = tester.state<ScrollableState>(
        outerScrollableFinder,
      );
      expect(
        innerStateAfter.position.pixels,
        innerStateAfter.position.minScrollExtent,
      );
      expect(outerStateAfter.position.maxScrollExtent, greaterThan(0));
      expect(
        outerStateAfter.position.pixels,
        inInclusiveRange(
          outerStateAfter.position.minScrollExtent,
          outerStateAfter.position.maxScrollExtent,
        ),
      );
      expect(outerPixelsBefore, equals(100));
    },
  );
}
