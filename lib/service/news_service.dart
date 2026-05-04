import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ramadhan_companion_app/model/news_model.dart';
import 'package:ramadhan_companion_app/secrets/api_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewsService {
  final String baseUrl = 'https://newsdata.io/api/1/latest';

  Future<List<NewsItem>> getMuslimNews() async {
    final url = Uri.parse(
      '$baseUrl?apikey=${ApiKeys.newsDataIOKey}&country=my&q=islam&language=en',
    );
    final prefs = await SharedPreferences.getInstance();

    print(url);

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      List results = data["results"] ?? [];
      // await prefs.setString('results', results);

      return results.map((e) => NewsItem.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load news');
    }
  }
}
