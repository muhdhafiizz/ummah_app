import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ramadhan_companion_app/model/masjid_nearby_model.dart';
import 'package:ramadhan_companion_app/secrets/api_keys.dart';

class MasjidNearbyService {
  static const String _geoapifyBaseUrl = 'https://api.geoapify.com/v2/places';
  static const String _geocodeBaseUrl =
      'https://api.geoapify.com/v1/geocode/search';

  /// Get latitude and longitude from city + country using Geoapify geocoding
  Future<LatLng> getLatLngFromAddress(String city, String country) async {
    final address = Uri.encodeComponent("$city, $country");
    final url = Uri.parse(
      "$_geocodeBaseUrl?text=$address&apiKey=${ApiKeys.geoapifyKey}",
    );

    final response = await http.get(url);
    final data = json.decode(response.body);

    if (response.statusCode == 200 && data["features"].isNotEmpty) {
      final coords = data["features"][0]["geometry"]["coordinates"];
      // Geoapify returns [lon, lat]
      return LatLng(coords[1], coords[0]);
    } else {
      throw Exception(
        "Failed to get coordinates: ${data["error"] ?? 'Unknown error'}",
      );
    }
  }

  /// Fetch nearby masjids (Geoapify category: religion.place_of_worship.islam)
  Future<List<MasjidNearbyModel>> getNearbyMasjids(
    double lat,
    double lng,
  ) async {
    final radiusMeters = 5000; // 5km radius

    final url = Uri.parse(
      "$_geoapifyBaseUrl?categories=religion.place_of_worship.islam"
      "&filter=circle:$lng,$lat,$radiusMeters"
      "&limit=20"
      "&apiKey=${ApiKeys.geoapifyKey}",
    );

    debugPrint("Fetching nearby masjids from: $url");

    final response = await http.get(url);
    final data = json.decode(response.body);

    if (response.statusCode != 200 || data["features"] == null) {
      throw Exception(
        "Failed to fetch masjids: ${data["error"] ?? 'Unknown error'}",
      );
    }

    final results = data["features"] as List;

    List<MasjidNearbyModel> masjids = [];
    for (var feature in results) {
      final props = feature["properties"];
      final geometry = feature["geometry"]["coordinates"];
      final wikidataId =
          props["wiki_and_media"]?["wikidata"] ?? props["wikidata"];

      String? imageUrl;
      if (wikidataId != null) {
        imageUrl = await getWikimediaImage(wikidataId);
      }

      masjids.add(
        MasjidNearbyModel(
          id: props["place_id"] ?? "",
          name: props["name"] ?? "Unknown Masjid",
          address: props["formatted"] ?? "Unknown Address",
          city:
              props["suburb"] ??
              props["town"] ??
              props["district"] ??
              props["datasource"]?["raw"]?["addr:place"] ??
              props["datasource"]?["raw"]?["addr:city"] ??
              props["hamlet"] ??
              props["street"] ??
              "",
          state: props["city"] ?? props["state"] ?? "",
          latitude: geometry[1],
          longitude: geometry[0],
          photoReference: imageUrl != null ? [imageUrl] : [],
          rating: null,
          wikidataId: wikidataId,
          building: props["datasource"]?["raw"]?["building"],
          denomination: props["datasource"]?["raw"]?["denomination"],
          wheelchair: props["datasource"]?["raw"]?["wheelchair"]
        ),
      );
    }

    return masjids;
  }

  Future<String?> getWikimediaImage(String wikidataId) async {
    try {
      final url = Uri.parse(
        "https://www.wikidata.org/wiki/Special:EntityData/$wikidataId.json",
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final entity = data["entities"][wikidataId];

        final claims = entity["claims"];
        if (claims != null &&
            claims["P18"] != null &&
            claims["P18"].isNotEmpty) {
          final imageName = claims["P18"][0]["mainsnak"]["datavalue"]["value"];
          final encoded = Uri.encodeComponent(imageName);
          return "https://commons.wikimedia.org/wiki/Special:FilePath/$encoded";
        }
      }
    } catch (e) {
      debugPrint("⚠️ Wikimedia fetch failed: $e");
    }
    return null;
  }
}
