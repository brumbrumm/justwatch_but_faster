class Setting {
  final String id;
  final String attribute;
  final DateTime dateTime;

  static final columns = ["id", "attribute", "dateTime"];
  Setting(this.id, this.attribute, this.dateTime);

  factory Setting.fromJson(Map<String, dynamic> json){
    return Setting(
      json['id'],
      json['attribute'],
      DateTime.parse((json['dateTime'])),
    );
  }

  Map<String, dynamic> toMap(){
    return {
      'id': id,
      'attribute': attribute,
      'dateTime': dateTime.toString(),
    };
  }
}