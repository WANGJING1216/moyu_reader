import 'package:flutter/material.dart';

import '../../application/use_cases/import_txt_book_use_case.dart';
import '../../domain/entities/import_book_exception.dart';
import '../../domain/entities/imported_text_book.dart';

class ImportBookPage extends StatefulWidget {
  const ImportBookPage({super.key, required this.useCase});

  final ImportTxtBookUseCase useCase;

  @override
  State<ImportBookPage> createState() => _ImportBookPageState();
}

class _ImportBookPageState extends State<ImportBookPage> {
  late final ImportTxtBookUseCase _useCase = widget.useCase;
  bool _isImporting = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        surfaceTintColor: const Color(0xFFF2F2F7),
        title: const Text('导入新书'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('请选择 TXT 文件导入阅读', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 14),
              SizedBox(
                key: const Key('import_book_button_box'),
                width: 220,
                child: ElevatedButton(
                  key: const Key('import_book_button'),
                  onPressed: _isImporting ? null : _importTxt,
                  child: Text(_isImporting ? '导入中...' : '选择TXT并导入'),
                ),
              ),
              if (_errorMessage != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  key: const Key('import_book_error_message'),
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFD93025)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importTxt() async {
    setState(() {
      _isImporting = true;
      _errorMessage = null;
    });

    try {
      final ImportedTextBook? importedBook = await _useCase.call();
      if (!mounted) {
        return;
      }

      if (importedBook == null) {
        Navigator.of(context).pop();
        return;
      }

      Navigator.of(context).pop(importedBook);
    } on BookImportException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = '导入失败，请稍后重试。';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }
}
