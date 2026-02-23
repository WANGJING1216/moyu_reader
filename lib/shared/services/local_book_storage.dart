import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/import_book/domain/entities/chapter_index.dart';
import '../../features/import_book/domain/entities/imported_text_book.dart';

class LocalBookStorage {
  const LocalBookStorage();

  static const String _latestBookKey = 'moyu_reader_latest_book';

  Future<void> saveBook(ImportedTextBook book) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> json = <String, dynamic>{
        'title': book.title,
        'content': book.content,
        'sourcePath': book.sourcePath,
        'encoding': book.encoding,
        'updatedAt': DateTime.now().toIso8601String(),
        'chapters': book.chapters.map((ChapterIndex c) => c.toJson()).toList(),
      };
      await prefs.setString(_latestBookKey, jsonEncode(json));
    } on MissingPluginException {
      // Keep app usable when storage plugin is unavailable on current runtime.
    } on PlatformException {
      // Ignore storage failure and keep import flow available.
    }
  }

  Future<ImportedTextBook?> loadLatestBook() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_latestBookKey);
      if (raw == null || raw.trim().isEmpty) {
        return null;
      }

      final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
      final List<dynamic> rawChapters =
          (json['chapters'] as List<dynamic>? ?? <dynamic>[]);

      return ImportedTextBook(
        title: json['title'] as String,
        content: json['content'] as String,
        sourcePath: json['sourcePath'] as String?,
        encoding: json['encoding'] as String? ?? 'unknown',
        chapters: rawChapters
            .map(
              (dynamic item) =>
                  ChapterIndex.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
