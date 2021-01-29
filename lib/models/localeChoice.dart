class LocaleChoice{
  final String fullLocale;
  final String isoCode;
  final String country;

  LocaleChoice({this.fullLocale, this.isoCode, this.country});

  factory LocaleChoice.fromJson(Map<String, dynamic> json){
    return LocaleChoice(
      fullLocale: json['full_locale'],
      isoCode: json['iso_3166_2'],
      country: json['country'],
    );
  }
}