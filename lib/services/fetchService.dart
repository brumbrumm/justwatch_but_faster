import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:justwatch_but_faster/models/localeChoice.dart';
import 'package:justwatch_but_faster/models/movie.dart';
import 'package:justwatch_but_faster/models/provider.dart';
import 'package:justwatch_but_faster/models/setting.dart';

import 'package:http/http.dart' as http;
import 'package:justwatch_but_faster/services/sqlDbProvider.dart';
import 'package:retry/retry.dart';


List<LocaleChoice> parseLocale(String responseBody){
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<LocaleChoice>((json) => LocaleChoice.fromJson((json))).toList();
}

List<Provider> parseProvider(String responseBody){
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<Provider>((json) => Provider.fromJson((json))).toList();
}

List<Movie> parsePopular(String responseBody){
  final parsed = json.decode(responseBody)['items'].cast<Map<String, dynamic>>();
  return parsed.map<Movie>((json) => Movie.fromPopular((json))).toList();
}

Movie parseMovie(String responseBody){
  final parsed = json.decode(responseBody);
  Movie movie = Movie.fromMovie(parsed);
  return movie;
}

Future<Movie> fetchMovie(String type, int id) async{
  Setting localSetting = await SQLiteDbProvider.db.getSettingById('locale');
  String locale = localSetting.attribute ?? 'de_DE';
  final String url = "https://apis.justwatch.com/content/titles/$type/$id/locale/$locale?language=${locale.substring(0,2)}";
  print(url);
  final response = await retry(
        () => http.get(
        url, headers: {
      //'User-Agent':	'SimpleWin',
    }
    ).timeout(Duration(seconds: 5)),
    // Retry on SocketException or TimeoutException
    retryIf: (e) => e is SocketException || e is TimeoutException,
  );
  if (response.statusCode == 200){
    return parseMovie(response.body);
  } else {
    throw Exception('Unable to fetch details from REST API');
  }
}

Future<List<LocaleChoice>> fetchLocale() async{
final String url = "https://apis.justwatch.com/content/locales/state";
final response = await retry(
    () => http.get(
        url, headers: {
      //'User-Agent':	'SimpleWin',
        }
    ).timeout(Duration(seconds: 5)),
  retryIf: (e) => e is SocketException || e is TimeoutException,
);
if (response.statusCode == 200){
  return parseLocale(response.body);
} else{
  throw Exception('Unable to fetch locale from REST API');
}
}

Future<List<Provider>> fetchProvider() async{
  Setting localSetting = await SQLiteDbProvider.db.getSettingById('locale');
  String locale = localSetting.attribute ?? 'de_DE';
  final String url = "https://apis.justwatch.com/content/providers/locale/$locale";
  final response = await retry(
        () => http.get(
        url, headers: {
      //'User-Agent':	'SimpleWin',
    }
    ).timeout(Duration(seconds: 5)),
    // Retry on SocketException or TimeoutException
    retryIf: (e) => e is SocketException || e is TimeoutException,
  );
  if (response.statusCode == 200){
    //print(response.body);
    return parseProvider(response.body);
  } else {
    throw Exception('Unable to fetch details from REST API');
  }
}

Future<List<Movie>> fetchPopular(List<String> providers, int pageNumber,) async{
  String provider = "";
  int _counter = 0;
  providers.forEach((element) {
    if (_counter == 0){
      provider += "%22$element%22";
    } else {
      provider += ",%22$element%22";
    }
    _counter += 1;
  });

  Setting localSetting = await SQLiteDbProvider.db.getSettingById('locale');
  String locale = localSetting.attribute ?? 'de_DE';

  final String prefixUrl = 'https://apis.justwatch.com/content/titles/$locale/popular';
  // final String url = '?body=%7B%22fields%22:[%22cinema_release_date%22,%22full_path%22,%22full_paths%22,%22id%22,%22localized_release_date%22,%22object_type%22,%22poster%22,%22scoring%22,%22title%22,%22tmdb_popularity%22,%22backdrops%22,%22offers%22,%22original_release_year%22,%22backdrops%22],%22providers%22:[$provider],%22enable_provider_filter%22:false,%22monetization_types%22:[],%22page%22:$pageNumber,%22page_size%22:30,%22matching_offers_only%22:true%7D&language=${locale.substring(0,2)}';

  final String url = '?body=%7B%22fields%22:[%22cinema_release_date%22,%22full_path%22,%22full_paths%22,%22id%22,%22localized_release_date%22,%22object_type%22,%22poster%22,%22scoring%22,%22title%22,%22tmdb_popularity%22,%22backdrops%22,%22production_countries%22,%22offers%22,%22original_release_year%22,%22backdrops%22],%22providers%22:[$provider],%22sort_asc%22:false,%22enable_provider_filter%22:false,%22monetization_types%22:[],%22page%22:$pageNumber,%22page_size%22:30,%22matching_offers_only%22:true%7D&language=${locale.substring(0,2)}';
  print(prefixUrl + url);
  final response = await retry(
        () => http.get(
        prefixUrl + url, headers: {
      //'User-Agent':	'SimpleWin',
    }
    ).timeout(Duration(seconds: 5)),
    // Retry on SocketException or TimeoutException
    retryIf: (e) => e is SocketException || e is TimeoutException,
  );
  print(response.statusCode);
  if (response.statusCode == 200){
    //print(response.body);
    return parsePopular(response.body);
  } else {
    throw Exception('Unable to fetch details from REST API');
  }
}