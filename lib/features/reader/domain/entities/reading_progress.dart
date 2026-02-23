class ReadingProgress {
  const ReadingProgress({
    required this.bookId,
    required this.chapterIndex,
    required this.innerOffset,
    required this.outerOffset,
    required this.updatedAt,
    required this.readChapterIndexes,
  });

  final String bookId;
  final int chapterIndex;
  final double innerOffset;
  final double outerOffset;
  final DateTime updatedAt;
  final Set<int> readChapterIndexes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'bookId': bookId,
      'chapterIndex': chapterIndex,
      'innerOffset': innerOffset,
      'outerOffset': outerOffset,
      'updatedAt': updatedAt.toIso8601String(),
      'readChapterIndexes': readChapterIndexes.toList(),
    };
  }

  factory ReadingProgress.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawReadIndexes =
        json['readChapterIndexes'] as List<dynamic>? ?? <dynamic>[];

    return ReadingProgress(
      bookId: json['bookId'] as String,
      chapterIndex: json['chapterIndex'] as int,
      innerOffset: (json['innerOffset'] as num?)?.toDouble() ?? 0,
      outerOffset: (json['outerOffset'] as num?)?.toDouble() ?? 0,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      readChapterIndexes: rawReadIndexes
          .map((dynamic index) => (index as num).toInt())
          .toSet(),
    );
  }
}
