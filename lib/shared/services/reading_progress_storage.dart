import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/reader/domain/entities/reading_progress.dart';

class ReadingProgressStorage {
  const ReadingProgressStorage();

  static const String storageKey = 'moyu_reader_reading_progress_v1';

  Future<ReadingProgress?> loadProgress(String bookId) async {
    final Map<String, ReadingProgress> all = await loadAllProgress();
    return all[bookId];
  }

  Future<Map<String, ReadingProgress>> loadAllProgress() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(storageKey);
      if (raw == null || raw.trim().isEmpty) {
        return <String, ReadingProgress>{};
      }

      final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
      final Map<String, ReadingProgress> result = <String, ReadingProgress>{};
      for (final MapEntry<String, dynamic> entry in json.entries) {
        final dynamic value = entry.value;
        if (value is! Map<String, dynamic>) {
          continue;
        }
        try {
          final ReadingProgress parsed = ReadingProgress.fromJson(value);
          result[entry.key] = parsed;
        } catch (_) {
          continue;
        }
      }
      return result;
    } on MissingPluginException {
      return <String, ReadingProgress>{};
    } on PlatformException {
      return <String, ReadingProgress>{};
    } catch (_) {
      if (prefs != null) {
        await prefs.remove(storageKey);
      }
      return <String, ReadingProgress>{};
    }
  }

  Future<void> saveProgress(ReadingProgress progress) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Map<String, ReadingProgress> all = await loadAllProgress();
      all[progress.bookId] = progress;

      final Map<String, dynamic> json = <String, dynamic>{
        for (final MapEntry<String, ReadingProgress> entry in all.entries)
          entry.key: entry.value.toJson(),
      };
      await prefs.setString(storageKey, jsonEncode(json));
    } on MissingPluginException {
      // Keep app usable when storage plugin is unavailable.
    } on PlatformException {
      // Ignore persistence failure and keep reading flow available.
    }
  }
}
