class Provider{
  final int id;
  final String technicalName;
  final String shortName;
  final String clearName;
  final int priority;
  final String iconUrl;

  Provider({
    required this.id, required this.technicalName, required this.shortName,
    required this.clearName, required this.priority, required this.iconUrl,
  });

  factory Provider.fromJson(Map<String, dynamic> json){
    return Provider(
      id: json['id'],
      technicalName: json['technical_name'],
      shortName: json['short_name'],
      clearName: json['clear_name'],
      priority: json['priority'],
      iconUrl: json['icon_url'].replaceAll('{profile}', 's100') ?? "empty",
    );
  }
}