import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moyu_reader/app/app.dart';

void main() {
  testWidgets('App boots to reader page', (WidgetTester tester) async {
    await tester.pumpWidget(const MoyuReaderApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reader_top_bar')), findsOneWidget);
    expect(find.byKey(const Key('reader_chat_area')), findsOneWidget);
    expect(find.byKey(const Key('reader_input_bar')), findsOneWidget);
    expect(find.byKey(const Key('reader_version_tag')), findsOneWidget);
  });
}
