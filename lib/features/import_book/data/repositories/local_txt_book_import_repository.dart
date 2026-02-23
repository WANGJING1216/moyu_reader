import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:gbk_codec/gbk_codec.dart';

import '../../../../shared/services/local_book_storage.dart';
import '../../domain/entities/chapter_index.dart';
import '../../domain/entities/import_book_exception.dart';
import '../../domain/entities/imported_text_book.dart';
import '../../domain/repositories/book_import_repository.dart';

class LocalTxtBookImportRepository implements BookImportRepository {
  const LocalTxtBookImportRepository({
    LocalBookStorage storage = const LocalBookStorage(),
  }) : _storage = storage;

  final LocalBookStorage _storage;

  static final RegExp _chapterTitlePattern = RegExp(
    r'^(?:\s*)(第[\d一二三四五六七八九十百千零两〇]+[章节卷回篇].*|Chapter\s+\d+.*)$',
    caseSensitive: false,
    multiLine: true,
  );

  @override
  Future<ImportedTextBook?> pickAndImportTxt() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['txt'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final PlatformFile file = result.files.single;
    if (!_isTxtFile(file.name)) {
      throw const BookImportException('仅支持导入 .txt 文件。');
    }

    final List<int>? bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw const BookImportException('文件读取失败或内容为空，请重新选择TXT文件。');
    }

    final _DecodedText decodedText = _decodeText(bytes);
    final String content = decodedText.content.trim();
    if (content.isEmpty) {
      throw const BookImportException('文件内容为空或不可读取。');
    }

    final List<ChapterIndex> chapters = _buildChapterIndexes(content);
    final ImportedTextBook book = ImportedTextBook(
      title: _sanitizeTitle(file.name),
      content: content,
      sourcePath: file.path,
      encoding: decodedText.encoding,
      chapters: chapters,
    );

    await _storage.saveBook(book);
    return book;
  }

  _DecodedText _decodeText(List<int> bytes) {
    try {
      final String utf8Text = const Utf8Decoder(
        allowMalformed: false,
      ).convert(bytes);
      if (_looksLikeMojibake(utf8Text)) {
        throw const FormatException('utf8 mojibake');
      }
      return _DecodedText(content: utf8Text, encoding: 'utf-8');
    } catch (_) {
      try {
        final String gbkText = gbk.decode(bytes);
        if (gbkText.trim().isEmpty || _looksLikeMojibake(gbkText)) {
          throw const FormatException('gbk mojibake');
        }
        return _DecodedText(content: gbkText, encoding: 'gbk');
      } catch (_) {
        throw const BookImportException('编码不支持，请转为 UTF-8/GBK。');
      }
    }
  }

  List<ChapterIndex> _buildChapterIndexes(String content) {
    final List<_TitleHit> titleHits = <_TitleHit>[];
    final Iterable<RegExpMatch> matches = _chapterTitlePattern.allMatches(
      content,
    );

    for (final RegExpMatch match in matches) {
      final String title = (match.group(1) ?? '').trim();
      if (title.isEmpty || match.start == 0 && titleHits.isNotEmpty) {
        continue;
      }
      titleHits.add(_TitleHit(offset: match.start, title: title));
    }

    if (titleHits.isNotEmpty) {
      return _buildByTitleHits(content, titleHits);
    }

    return _buildByChunk(content, 2000);
  }

  List<ChapterIndex> _buildByTitleHits(
    String content,
    List<_TitleHit> titleHits,
  ) {
    final List<ChapterIndex> chapters = <ChapterIndex>[];
    for (int i = 0; i < titleHits.length; i++) {
      final _TitleHit current = titleHits[i];
      final int start = current.offset;
      final int end = i + 1 < titleHits.length
          ? titleHits[i + 1].offset
          : content.length;
      if (end <= start) {
        continue;
      }
      chapters.add(
        ChapterIndex(
          index: chapters.length,
          title: current.title,
          startOffset: start,
          endOffset: end,
        ),
      );
    }

    if (chapters.isEmpty) {
      return _buildByChunk(content, 2000);
    }
    return chapters;
  }

  List<ChapterIndex> _buildByChunk(String content, int chunkSize) {
    final List<ChapterIndex> chapters = <ChapterIndex>[];
    int offset = 0;
    int index = 0;

    while (offset < content.length) {
      final int end = (offset + chunkSize).clamp(0, content.length).toInt();
      chapters.add(
        ChapterIndex(
          index: index,
          title: '第${index + 1}节',
          startOffset: offset,
          endOffset: end,
        ),
      );
      offset = end;
      index++;
    }

    return chapters;
  }

  bool _looksLikeMojibake(String text) {
    return text.contains('�');
  }

  String _sanitizeTitle(String fileName) {
    final String lower = fileName.toLowerCase();
    if (lower.endsWith('.txt')) {
      return fileName.substring(0, fileName.length - 4);
    }
    return fileName;
  }

  bool _isTxtFile(String fileName) {
    return fileName.toLowerCase().endsWith('.txt');
  }

  List<ChapterIndex> buildChapterIndexesForTesting(String content) {
    return _buildChapterIndexes(content);
  }
}

class _DecodedText {
  const _DecodedText({required this.content, required this.encoding});

  final String content;
  final String encoding;
}

class _TitleHit {
  const _TitleHit({required this.offset, required this.title});

  final int offset;
  final String title;
}
