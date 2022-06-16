import 'dart:async';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:justwatch_but_faster/models/movie.dart';
import 'package:justwatch_but_faster/models/provider.dart';
import 'package:justwatch_but_faster/models/setting.dart';
import 'package:justwatch_but_faster/services/fetch_service.dart';

import 'package:justwatch_but_faster/services/sql_db_provider.dart';
import 'package:justwatch_but_faster/views/home_page.dart';
import 'package:justwatch_but_faster/views/my_archive.dart';
import 'package:justwatch_but_faster/views/my_watchlist_view.dart';

import 'package:justwatch_but_faster/views/setting_view.dart';

import 'config/app_settings_config.dart';


class AppBuilder extends StatefulWidget {
  final Function(BuildContext) builder;

  const AppBuilder(this.builder, {Key? key,}) : super(key: key);

  @override
  State<AppBuilder> createState() => AppBuilderState();

  static AppBuilderState? of(BuildContext context) {
    return context.findAncestorStateOfType<AppBuilderState>();
  }
}

class AppBuilderState extends State<AppBuilder> {
  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }

  void rebuild() {
    setState(() {});
  }
}

List<Provider> PROVIDER_LIST = [];

Future<bool> _initSettings() async {
  GlobalConfiguration cfg = GlobalConfiguration();
  cfg.loadFromMap(appSettings);
  void _setConfig(String settingsName) async {
    Setting setting = await SQLiteDbProvider()
        .getSettingById(settingsName, attribute: cfg.getValue(settingsName));
    cfg.updateValue(settingsName, setting.attribute);
  }

  appSettings.forEach((key, value) {
    _setConfig(key);
  });

  List<Provider> providerList = await fetchProvider();
  for(Provider prov in providerList){
    PROVIDER_LIST.add(prov);
  }
  return true;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const LoadingScreen());
}

class LoadingScreen extends StatefulWidget{
  const LoadingScreen({Key? key}):super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>{
  bool _isSettingsLoaded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    runInitTasks();
  }

  Future runInitTasks() async{
    /// Run each initializer method sequentially
    final bool isSettingsLoaded = await _initSettings();
    if (isSettingsLoaded) {
      setState(() {
        _isSettingsLoaded = true;
      });
    }
  }

  Widget _loadingScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepOrange,
      body: InkWell(
        child: Stack(
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        const Padding(padding: EdgeInsets.only(top: 30.0)),
                        Text(
                          "Simple wins",
                          style: Theme.of(context).textTheme.headline1,
                        ),
                      ],
                    )),
                Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const <Widget>[
                        CircularProgressIndicator(
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 20.0),
                        ),
                        Text('Loading'),
                      ],
                    ))
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if(_isSettingsLoaded){
      return const MyApp();
    }
    return MaterialApp(home: _loadingScreen(context),);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return AppBuilder((BuildContext context){
      return MaterialApp(
        title: 'Simple wins',
        theme: ThemeData(
          brightness: Brightness.dark,
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primarySwatch: Colors.deepOrange,
          // This makes the visual density adapt to the platform that you run
          // the app on. For desktop platforms, the controls will be smaller and
          // closer together (more dense) than on mobile platforms.
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const MyBottomNavigation(),
      );
    },);
  }
}

class MyBottomNavigation extends StatefulWidget {
  const MyBottomNavigation({Key? key}) : super(key: key);

  @override
  State<MyBottomNavigation> createState() => _MyBottomNavigation();
}

class _MyBottomNavigation extends State<MyBottomNavigation> {
  int _selectedIndex = 0;

  String getTitle(int indexTitle) {
    if (indexTitle == 0) {
      return "Simple Wins";
    } else if (indexTitle == 1) {
      return "WatchList";
    } else if (indexTitle == 2) {
      return "Archive";
    } else if (indexTitle == 3) {
      return "Settings";
    } else {
      return "Simple Wins";
    }
  }

  static final List<Widget> _widgetOptions = <Widget>[
    const MyWatchlist(),
    PreHomePage(),
    const MyArchive(),
    const SettingsView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(8),
        child: Container(
          color: Theme.of(context).backgroundColor,
        ),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: _selectedIndex == 0
                ? const Icon(Icons.home)
                : const Icon(Icons.home_outlined),
            label: 'watchlist',
          ),
          BottomNavigationBarItem(
            icon: _selectedIndex == 1
                ? const Icon(Icons.list_rounded)
                : const Icon(Icons.format_list_numbered_rounded),
            label: 'popular',
          ),
          BottomNavigationBarItem(
            icon: _selectedIndex == 2
                ? const Icon(Icons.archive)
                : const Icon(Icons.archive_outlined),
            label: 'archive',
          ),
          BottomNavigationBarItem(
            icon: _selectedIndex == 3
                ? const Icon(Icons.settings_applications)
                : const Icon(Icons.settings_applications_outlined),
            label: "settings",
          ),
        ],
        currentIndex: _selectedIndex,
        unselectedItemColor: Theme.of(context).unselectedWidgetColor,
        onTap: _onItemTapped,
        backgroundColor: Theme.of(context).backgroundColor,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class MovieBloc {
  MovieBloc() {
    getAllMovies();
    getArchive();
  }

  final _movieController = StreamController<List<Movie>>.broadcast();
  final _isArchiveController = StreamController<List<Movie>>.broadcast();

  get movies => _movieController.stream;
  get archive => _isArchiveController.stream;

  dispose() {
    _movieController.close();
  }

  getAllMovies() async {
    _movieController.sink.add(await SQLiteDbProvider().getAllMovies());
  }

  delete(int id) {
    SQLiteDbProvider().deleteMovie(id);
    getAllMovies();
  }

  add(Movie movie) {
    SQLiteDbProvider().insertMovie(movie);
    getAllMovies();
  }

  getMovieById(int id) {
    SQLiteDbProvider().getMovieById(id);
  }

  isInDb(int id) {
    SQLiteDbProvider().isInDb(id);
  }

  getWatchList() {
    SQLiteDbProvider().getAllWatchlist();
  }

  getArchive() async {
    _isArchiveController.sink.add(await SQLiteDbProvider().getAllArchive());
  }
}

class WatchListBloc {
  WatchListBloc() {
    getAllMovies();
  }

  final _movieController = StreamController<List<Movie>>.broadcast();

  get movies => _movieController.stream;

  dispose() {
    _movieController.close();
  }

  getAllMovies() async {
    _movieController.sink.add(await SQLiteDbProvider().getAllWatchlist());
  }

  delete(int id) {
    SQLiteDbProvider().deleteMovie(id);
    getAllMovies();
  }

  add(Movie movie) {
    SQLiteDbProvider().insertMovie(movie);
    getAllMovies();
  }

  getMovieById(int id) {
    SQLiteDbProvider().getMovieById(id);
  }

  isInDb(int id) {
    SQLiteDbProvider().isInDb(id);
  }

  getWatchList() {
    SQLiteDbProvider().getAllWatchlist();
  }

  getArchive() {
    SQLiteDbProvider().getAllArchive();
  }
}
