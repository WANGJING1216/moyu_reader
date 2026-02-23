class ReaderProgressSession {
  const ReaderProgressSession({
    required this.currentChapterIndex,
    required this.readChapterIndexes,
  });

  final int currentChapterIndex;
  final Set<int> readChapterIndexes;
}

class ReaderProgressSessionStore {
  final Map<String, ReaderProgressSession> _sessionsByBookId =
      <String, ReaderProgressSession>{};

  ReaderProgressSession resolve({
    required String bookId,
    required int chapterCount,
  }) {
    final ReaderProgressSession? existing = _sessionsByBookId[bookId];
    if (existing == null) {
      final ReaderProgressSession initial = ReaderProgressSession(
        currentChapterIndex: 0,
        readChapterIndexes: chapterCount > 0 ? <int>{0} : <int>{},
      );
      _sessionsByBookId[bookId] = initial;
      return initial;
    }

    final int maxIndex = chapterCount > 0 ? chapterCount - 1 : 0;
    final int safeCurrent = existing.currentChapterIndex.clamp(0, maxIndex);
    final Set<int> safeRead = existing.readChapterIndexes
        .where((int index) => index >= 0 && index < chapterCount)
        .toSet();

    final ReaderProgressSession safe = ReaderProgressSession(
      currentChapterIndex: safeCurrent,
      readChapterIndexes: safeRead,
    );
    _sessionsByBookId[bookId] = safe;
    return safe;
  }

  void update({
    required String bookId,
    required int chapterCount,
    required int currentChapterIndex,
    required Set<int> readChapterIndexes,
  }) {
    final int maxIndex = chapterCount > 0 ? chapterCount - 1 : 0;
    final int safeCurrent = currentChapterIndex.clamp(0, maxIndex);
    final Set<int> safeRead = readChapterIndexes
        .where((int index) => index >= 0 && index < chapterCount)
        .toSet();

    _sessionsByBookId[bookId] = ReaderProgressSession(
      currentChapterIndex: safeCurrent,
      readChapterIndexes: safeRead,
    );
  }
}
