import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ramadhan_companion_app/model/hadith_book_model.dart';
import 'package:ramadhan_companion_app/secrets/api_keys.dart';

class HadithService {
  final baseUrl = 'https://hadithapi.com/api';

  Future<List<HadithBook>> fetchHadithBooks() async {
    final url = Uri.parse('$baseUrl/books?apiKey=${ApiKeys.hadithApiKey}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['books'] != null) {
        return (data['books'] as List)
            .map((book) => HadithBook.fromJson(book))
            .toList();
      } else {
        throw Exception("Books not found in response");
      }
    } else {
      throw Exception("Failed to load books: ${response.statusCode}");
    }
  }

  Future<List<HadithChapter>> fetchHadithChapters(String bookSlug) async {
    final url = Uri.parse(
      '$baseUrl/$bookSlug/chapters?apiKey=${ApiKeys.hadithApiKey}',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['chapters'] != null) {
        return (data['chapters'] as List)
            .map((chapter) => HadithChapter.fromJson(chapter))
            .toList();
      } else {
        throw Exception("Chapters not found in response");
      }
    } else {
      throw Exception("Failed to load chapters: ${response.statusCode}");
    }
  }

  Future<List<HadithModel>> fetchHadiths({
    required String bookSlug,
    required int page,
    String? chapterId,
  }) async {
    final queryParams = {
      "apiKey": ApiKeys.hadithApiKey,
      "book": bookSlug,
      "page": page.toString(),
    };

    if (chapterId != null && chapterId.isNotEmpty) {
      queryParams["chapter"] = chapterId;
    }

    final url = Uri.parse(
      "$baseUrl/hadiths",
    ).replace(queryParameters: queryParams);

    final response = await http.get(url);

    // Success
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print(data);

      if (data['hadiths'] != null && data['hadiths']['data'] is List) {
        final list = data['hadiths']['data'] as List;
        return list.map((h) => HadithModel.fromJson(h)).toList();
      }

      // If API returns 200 but no hadiths array - treat as empty (no more)
      return [];
    }

    // If API returns 404 or a body that states "not found", treat as end-of-data (return empty)
    final bodyLower = response.body.toLowerCase();
    if (response.statusCode == 404 ||
        bodyLower.contains('not found') ||
        bodyLower.contains('hadith not found')) {
      return [];
    }

    // Other errors -> bubble up
    throw Exception(
      "Failed to load hadiths [${response.statusCode}]: ${response.body}",
    );
  }
}
