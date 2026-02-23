class ChapterIndex {
  const ChapterIndex({
    required this.index,
    required this.title,
    required this.startOffset,
    required this.endOffset,
  });

  final int index;
  final String title;
  final int startOffset;
  final int endOffset;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'index': index,
      'title': title,
      'startOffset': startOffset,
      'endOffset': endOffset,
    };
  }

  factory ChapterIndex.fromJson(Map<String, dynamic> json) {
    return ChapterIndex(
      index: json['index'] as int,
      title: json['title'] as String,
      startOffset: json['startOffset'] as int,
      endOffset: json['endOffset'] as int,
    );
  }
}
