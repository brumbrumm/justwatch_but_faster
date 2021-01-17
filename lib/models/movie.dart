class Movie{
  final String jwEntityId;
  final int id;
  final String title;
  final String fullPath;
  final String poster;
  final int originalReleaseYear;
  final String objectType;
  final String cinemaReleaseDate;

  final bool isWatchList;
  final bool isArchive;
  final DateTime updateTime;

  final String shortDescription;

  List<Poster> posters;
  List<Offer> offers;
  List<Scoring> scorings;
  List<External> externals;

  static final columns = ["id", "title", "poster", "objectType", "isWatchList", "isArchive", "dateTime"];
  Movie({
    this.jwEntityId, this.id, this.title, this.fullPath, this.poster,
    this.originalReleaseYear, this.objectType, this.cinemaReleaseDate,
    this.isWatchList, this.isArchive, this.updateTime, this.posters,
    this.offers, this.externals, this.shortDescription, this.scorings,
});

  Map<String, dynamic> toMap(){
    return {
      'id': id,
      'title': title,
      'poster': poster,
      "objectType": objectType,
      'isWatchList': isWatchList ? 1 : 0,
      'isArchive': isArchive ? 1 : 0,
      'dateTime': updateTime.toString(),
    };
  }

  factory Movie.fromDb(Map<String, dynamic> json){
    return Movie(
      id: json['id'],
      title: json['title'],
      poster: json['poster'],
      objectType: json['objectType'],
      isWatchList: json['isWatchList'] == 1 ? true : false,
        isArchive: json['isArchive'] == 1 ? true : false,
      updateTime: DateTime.parse((json['dateTime'])),
    );
  }

  factory Movie.fromPopular(Map<String, dynamic> json){
    return Movie(
      jwEntityId: json['jw_entity_id'].toString(),
      id: json['id'],
      title: json['title'],
      fullPath: json['full_path'] ?? "empty",
      poster: json['poster'].replaceAll('{profile}', 's592') ?? "empty",
      originalReleaseYear: json['original_release_year'] ?? 0,
      objectType: json['object_type'] ?? "empty",
      cinemaReleaseDate: json['cinema_release_date']  ?? "empty",
    );
  }

  factory Movie.fromMovie(Map<String, dynamic> json){
    print(json['scoring']);
    return Movie(
      jwEntityId: json['jw_entity_id'].toString(),
      id: json['id'],
      title: json['title'],
      fullPath: json['full_path'] ?? "empty",
      poster: json['poster'].replaceAll('{profile}', 's592') ?? "empty",
      originalReleaseYear: json['original_release_year'] ?? 0,
      objectType: json['object_type'] ?? "empty",
      cinemaReleaseDate: json['cinema_release_date']  ?? "empty",
      shortDescription: json['short_description'],

      posters: (json['backdrops'] as List).map((i) => Poster.fromJson(i)).toList(),
      offers:  (json['offers'] as List).map((i) => Offer.fromJson(i)).toList(),
      scorings: (json['scoring'] as List).map((i) => Scoring.fromJson(i)).toList(),
      externals: (json['external_ids'] as List).map((i) => External.fromJson(i)).toList(),
    );
  }
}

class Poster{
  final String backdropUrl;

  Poster({this.backdropUrl});

  factory Poster.fromJson(Map<String, dynamic> json){
    return json != null ? Poster(
      backdropUrl: json['backdrop_url'].replaceAll('{profile}', 's1440') ?? "empty",
    ) : Poster();
  }
}

class Offer{
  final String type;
  final int providerId;

  Offer({this.type, this.providerId});

  factory Offer.fromJson(Map<String, dynamic> json){
    return Offer(
      type: json['monetization_type'] ?? "empty",
      providerId: json['provider_id'] ?? 0,
    );
  }
}

class Scoring{
  final String providerType;
  final double value;

  Scoring({this.providerType, this.value});

  factory Scoring.fromJson(Map<String, dynamic> json){
    return Scoring(
      providerType: json['provider_type'] ?? "empty",
      value: double.tryParse(json['value'].toString().trim()) ?? 0,
    );
  }
}

class External{
  final String provider;
  final String externalId;

  External({this.provider, this.externalId});

  factory External.fromJson(Map<String, dynamic> json){
    return External(
      provider: json['provider'] ?? "empty",
      externalId: json['external_id'] ?? "empty",
    );
  }
}