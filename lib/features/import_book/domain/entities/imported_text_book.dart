import 'chapter_index.dart';

class ImportedTextBook {
  const ImportedTextBook({
    required this.title,
    required this.content,
    required this.encoding,
    required this.chapters,
    this.sourcePath,
  });

  final String title;
  final String content;
  final String encoding;
  final List<ChapterIndex> chapters;
  final String? sourcePath;
}
