import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/novel.dart';

class StorageService {
  static Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/orenpad.json');
  }

  static Future<List<Novel>> loadNovels() async {
    final file = await _getFile();

    if (!await file.exists()) {
      return [];
    }

    try {
      final text = await file.readAsString();

      if (text.trim().isEmpty) {
        return [];
      }

      final List<dynamic> data = jsonDecode(text);

      return data.map((item) {
        final chapters = (item['chapters'] as List<dynamic>? ?? [])
            .map(
              (chapter) => Chapter(
                title: chapter['title'] ?? '',
                content: chapter['content'] ?? '',
                status: chapter['status'] ?? 'writing',
              ),
            )
            .toList();

        return Novel(
          title: item['title'] ?? '',
          description: item['description'] ?? '',
          coverPath: item['coverPath'],
          tags: List<String>.from(item['tags'] ?? []),
          chapters: chapters,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveNovels(List<Novel> novels) async {
    final file = await _getFile();

    final data = novels.map((novel) {
      return {
        'title': novel.title,
        'description': novel.description,
        'coverPath': novel.coverPath,
        'tags': novel.tags,
        'chapters': novel.chapters.map((chapter) {
          return {
            'title': chapter.title,
            'content': chapter.content,
            'status': chapter.status,
          };
        }).toList(),
      };
    }).toList();

    await file.writeAsString(jsonEncode(data));
  }
}
