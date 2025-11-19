import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ramadhan_companion_app/model/doa_zikir_model.dart';
import 'package:translator/translator.dart';

class DoaService {
  static const String _baseUrl = 'https://muslim-api-three.vercel.app/v1/doa';
  final translation = GoogleTranslator();

  Future<List<DoaModel>> fetchAllDoa({bool useCache = true}) async {
    final prefs = await SharedPreferences.getInstance();

    if (useCache && prefs.containsKey('cached_all_doa')) {
      final cached = prefs.getString('cached_all_doa');
      if (cached != null && cached.isNotEmpty) {
        final List data = json.decode(cached);
        return data.map((e) => DoaModel.fromJson(e)).toList();
      }
    }

    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final doaList = (data['data'] as List)
          .map((item) => DoaModel.fromJson(item))
          .toList();

      for (var doa in doaList) {
        doa = await _translateDoa(doa);
      }

      await prefs.setString(
        'cached_all_doa',
        json.encode(doaList.map((e) => e.toJson()).toList()),
      );

      return doaList;
    } else {
      throw Exception('Failed to load Doa');
    }
  }

  Future<List<DoaModel>> fetchDoaBySource(
    String source, {
    bool useCache = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'cached_doa_source_$source';

    if (useCache && prefs.containsKey(cacheKey)) {
      final cached = prefs.getString(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        final List data = json.decode(cached);
        return data.map((e) => DoaModel.fromJson(e)).toList();
      }
    }

    final url = '$_baseUrl?source=$source';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final doaList = (data['data'] as List)
          .map((item) => DoaModel.fromJson(item))
          .toList();

      await prefs.setString(
        cacheKey,
        json.encode(doaList.map((e) => e.toJson()).toList()),
      );

      return doaList;
    } else {
      throw Exception('Failed to load Doa from source: $source');
    }
  }
}

Future<DoaModel> _translateDoa(DoaModel doa) async {
  final translator = GoogleTranslator();

  final translatedJudul = await translator.translate(
    doa.judul,
    from: 'id',
    to: 'en',
  );
  final translatedIndo = await translator.translate(
    doa.indo,
    from: 'id',
    to: 'en',
  );
  final translatedSource = await translator.translate(
    doa.source,
    from: 'id',
    to: 'en',
  );

  return DoaModel(
    judul: translatedJudul.text,
    arab: doa.arab,
    indo: translatedIndo.text,
    source: translatedSource.text,
  );
}
