import 'dart:async' show Future;
import 'package:path/path.dart' show join;
import 'package:sqflite/sqflite.dart';

import 'package:justwatch_but_faster/models/movie.dart';
import 'package:justwatch_but_faster/models/setting.dart';

class SQLiteDbProvider {
  Future<Database> initializeDB() async{
    String path = join(await getDatabasesPath(), 'database.db');

    return openDatabase(
        path,
        version: 1,
        onOpen: (db){},
        onCreate: (Database db, int version) async {
          await db.execute(
              "CREATE TABLE Movie(id INTEGER PRIMARY KEY, title TEXT, poster TEXT, objectType TEXT, isWatchList INT, isArchive INT, dateTime TEXT)"
          );

          await db.execute(
              "CREATE TABLE Setting(id TEXT PRIMARY KEY, attribute TEXT, dateTime TEXT)"
          );
        }
    );
  }

  Future<List<Setting>> getAllSettings() async{
    final db = await initializeDB();

    List<Map> results = await db.query(
      "Setting", columns: Setting.columns,
    );
    List<Setting> settings = [];
    results.forEach((element) {
      Setting setting = Setting.fromJson(element);
      settings.add(setting);
    });

    return settings;
  }

  Future<List<Movie>> getAllMovies() async{
    final db = await initializeDB();

    List<Map> results = await db.query(
        "Movie", columns: Movie.columns, orderBy: "dateTime DESC"
    );
    List<Movie> movies = [];
    results.forEach((result){
      Movie movie = Movie.fromDb(result);
      movies.add(movie);
    });
    return movies;
  }

  Future<List<Setting>> getSettingByAttribute(String attribute) async {
    final db = await initializeDB();
    List<Map> results = await db.query(
        "Setting", where: "attribute = ?", whereArgs: [attribute]
    );
    List<Setting> settings = [];
    results.forEach((result){
      Setting setting = Setting.fromJson(result);
      settings.add(setting);
    });
    return settings;
  }

  Future<List<Movie>> getAllWatchlist() async{
    final db = await initializeDB();

    List<Map> results = await db.query(
        "Movie", columns: Movie.columns, where: "isWatchList = 1", orderBy: "dateTime DESC"
    );
    List<Movie> movies = [];
    results.forEach((result){
      Movie movie = Movie.fromDb(result);
      movies.add(movie);
    });
    return movies;
  }

  Future<List<Movie>> getAllArchive() async{
    final db = await initializeDB();

    List<Map> results = await db.query(
        "Movie", columns: Movie.columns, where: "isArchive = 1", orderBy: "dateTime DESC"
    );
    List<Movie> movies = [];
    results.forEach((result){
      Movie movie = Movie.fromDb(result);
      movies.add(movie);
    });
    return movies;
  }

  Future<Setting> getSettingById(String id, {String attribute = "en"}) async {
    final db = await initializeDB();
    var result = await db.query(
        "Setting", where: "id = ?", whereArgs: [id]
    );
    Setting setting = result.isNotEmpty ? Setting.fromJson(result.first) :
    Setting(id, attribute, DateTime.now());
    return setting;
  }

  Future<Movie?> getMovieById(int id) async {
    final db = await initializeDB();
    var result = await db.query(
        "Movie", where: "id = ?", whereArgs: [id]
    );
    return result.isNotEmpty ? Movie.fromDb(result.first) : null;
  }

  Future<bool> isInDb(int id) async {
    final db = await initializeDB();
    var result = await db.query(
        "Movie", where: "id = ?", whereArgs: [id]
    );
    return result.isNotEmpty ? true : false;
  }

  Future<void> insertSetting(Setting setting) async{
    final db = await initializeDB();
    await db.insert("Setting", setting.toMap(), conflictAlgorithm: ConflictAlgorithm.replace,);
  }

  Future<void> insertMovie(Movie movie) async{
    final db = await initializeDB();
    await db.insert("Movie", movie.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteSetting(String id) async{
    final db = await initializeDB();
    await db.delete("Setting", where: "id = ?", whereArgs: [id],);
    print('delete $id');
  }

  Future<void> deleteMovie(int id) async{
    final db = await initializeDB();
    await db.delete("Movie", where: "id = ?", whereArgs: [id]);
  }
}

