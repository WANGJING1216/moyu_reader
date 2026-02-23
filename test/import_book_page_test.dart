import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moyu_reader/features/import_book/application/use_cases/import_txt_book_use_case.dart';
import 'package:moyu_reader/features/import_book/domain/entities/chapter_index.dart';
import 'package:moyu_reader/features/import_book/domain/entities/import_book_exception.dart';
import 'package:moyu_reader/features/import_book/domain/entities/imported_text_book.dart';
import 'package:moyu_reader/features/import_book/domain/repositories/book_import_repository.dart';
import 'package:moyu_reader/features/import_book/presentation/pages/import_book_page.dart';

void main() {
  testWidgets('import page shows error message when import fails', (
    WidgetTester tester,
  ) async {
    final ImportTxtBookUseCase useCase = ImportTxtBookUseCase(
      repository: _FakeFailRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(home: ImportBookPage(useCase: useCase)),
    );

    await tester.tap(find.byKey(const Key('import_book_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('import_book_error_message')), findsOneWidget);
    expect(find.text('文件内容为空或不可读取。'), findsOneWidget);
  });

  testWidgets('import page pops with book on success', (
    WidgetTester tester,
  ) async {
    final ImportTxtBookUseCase useCase = ImportTxtBookUseCase(
      repository: _FakeSuccessRepository(),
    );

    await tester.pumpWidget(
      _ImportHost(
        useCase: useCase,
        buttonLabel: '打开导入页-成功',
        resultPrefix: 'success:',
      ),
    );

    await tester.tap(find.text('打开导入页-成功'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('import_book_button')));
    await tester.pumpAndSettle();

    expect(find.text('success:示例书名'), findsOneWidget);
  });

  testWidgets('import page pops null when user cancels', (
    WidgetTester tester,
  ) async {
    final ImportTxtBookUseCase useCase = ImportTxtBookUseCase(
      repository: _FakeCancelRepository(),
    );

    await tester.pumpWidget(
      _ImportHost(
        useCase: useCase,
        buttonLabel: '打开导入页-取消',
        resultPrefix: 'cancel:',
      ),
    );

    await tester.tap(find.text('打开导入页-取消'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('import_book_button')));
    await tester.pumpAndSettle();

    expect(find.text('cancel:null'), findsOneWidget);
  });
}

class _ImportHost extends StatefulWidget {
  const _ImportHost({
    required this.useCase,
    required this.buttonLabel,
    required this.resultPrefix,
  });

  final ImportTxtBookUseCase useCase;
  final String buttonLabel;
  final String resultPrefix;

  @override
  State<_ImportHost> createState() => _ImportHostState();
}

class _ImportHostState extends State<_ImportHost> {
  String _result = 'pending';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (BuildContext innerContext) => Scaffold(
          body: Column(
            children: <Widget>[
              ElevatedButton(
                onPressed: () async {
                  final ImportedTextBook? imported =
                      await Navigator.of(innerContext).push<ImportedTextBook?>(
                        MaterialPageRoute<ImportedTextBook?>(
                          builder: (_) =>
                              ImportBookPage(useCase: widget.useCase),
                        ),
                      );
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    _result =
                        '${widget.resultPrefix}${imported?.title ?? 'null'}';
                  });
                },
                child: Text(widget.buttonLabel),
              ),
              Text(_result),
            ],
          ),
        ),
      ),
    );
  }
}

class _FakeSuccessRepository implements BookImportRepository {
  @override
  Future<ImportedTextBook?> pickAndImportTxt() async {
    return const ImportedTextBook(
      title: '示例书名',
      content: '示例内容',
      encoding: 'utf-8',
      chapters: <ChapterIndex>[],
    );
  }
}

class _FakeCancelRepository implements BookImportRepository {
  @override
  Future<ImportedTextBook?> pickAndImportTxt() async {
    return null;
  }
}

class _FakeFailRepository implements BookImportRepository {
  @override
  Future<ImportedTextBook?> pickAndImportTxt() async {
    throw const BookImportException('文件内容为空或不可读取。');
  }
}
