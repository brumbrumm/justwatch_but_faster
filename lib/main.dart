import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:justwatch_but_faster/models/movie.dart';
import 'package:justwatch_but_faster/models/setting.dart';

import 'package:justwatch_but_faster/services/fetchService.dart';
import 'package:justwatch_but_faster/services/sqlDbProvider.dart';

import 'package:justwatch_but_faster/views/settingView.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class SizeConfig {
  static MediaQueryData _mediaQueryData;
  static double screenWidth;
  static double screenHeight;
  static double blockSizeHorizontal;
  static double blockSizeVertical;

  static double _safeAreaHorizontal;
  static double _safeAreaVertical;
  static double safeBlockHorizontal;
  static double safeBlockVertical;

  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;

    _safeAreaHorizontal =
        _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    _safeAreaVertical =
        _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    safeBlockHorizontal = (screenWidth - _safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - _safeAreaVertical) / 100;
  }
}

class AppBuilder extends StatefulWidget {
  final Function(BuildContext) builder;

  const AppBuilder({Key key, this.builder}) : super(key: key);

  @override
  AppBuilderState createState() => new AppBuilderState();

  static AppBuilderState of(BuildContext context) {
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

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return AppBuilder(builder: (BuildContext context){
      return MaterialApp(
        title: 'simple wins',
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
          primarySwatch: Colors.blue,
          // This makes the visual density adapt to the platform that you run
          // the app on. For desktop platforms, the controls will be smaller and
          // closer together (more dense) than on mobile platforms.
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: MyBottomNavigation(),
      );
    },);
  }
}

class MyBottomNavigation extends StatefulWidget {
  MyBottomNavigation({Key key}) : super(key: key);

  @override
  _MyBottomNavigation createState() => _MyBottomNavigation();
}

class _MyBottomNavigation extends State<MyBottomNavigation> {
  int _selectedIndex = 0;

  String getTitle(int indexTitle) {
    if (indexTitle == 0) {
      return "Simple Wins";
    } /*else if (indexTitle == 1) {
      return "New";
    }*/ else if (indexTitle == 1) {
      return "WatchList";
    } else if (indexTitle == 2) {
      return "Archive";
    } else if (indexTitle == 3) {
      return "Settings";
    } else {
      return "Simple Wins";
    }
  }

  static List<Widget> _widgetOptions = <Widget>[
    MyWatchlist(),
    // MyNew(),
    PreHomePage(),
    MyArchive(),
    SettingsView(),
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
      appBar: new PreferredSize(
        preferredSize: Size.fromHeight(8),
        child: new Container(
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
                ? Icon(Icons.home)
                : Icon(Icons.home_outlined),
            label: 'watchlist',
          ),
          /*BottomNavigationBarItem(
            icon: _selectedIndex == 1
                ? Icon(Icons.new_releases)
                : Icon(Icons.new_releases_outlined),
            label: 'new',
          ),*/
          BottomNavigationBarItem(
            icon: _selectedIndex == 1
                ? Icon(Icons.list_rounded)
                : Icon(Icons.format_list_numbered_rounded),
            label: 'popular',
          ),
          BottomNavigationBarItem(
            icon: _selectedIndex == 2
                ? Icon(Icons.archive)
                : Icon(Icons.archive_outlined),
            label: 'archive',
          ),
          BottomNavigationBarItem(
            icon: _selectedIndex == 3
                ? Icon(Icons.settings_applications)
                : Icon(Icons.settings_applications_outlined),
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

class PreHomePage extends StatelessWidget {
  List<String> _filterProviders = [];
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Setting>>(
      future: SQLiteDbProvider.db.getSettingByAttribute('provider'),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text(snapshot.error.toString());
        return snapshot.hasData
            ? prepareStringList(snapshot.data)
            : Center(
                child: CircularProgressIndicator(),
              );
      },
    );
  }

  Widget prepareStringList(List<Setting> _providerList) {
    _providerList.forEach((element) {
      _filterProviders.add(element.id);
    });
    return MyHomePage(_filterProviders,);
  }
}

class MyHomePage extends StatefulWidget {
  final List<String> filterProviders;
  MyHomePage(this.filterProviders);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<MyHomePage>{
  static const _pageSize = 30;

  final myMovies = MovieBloc();
  List<Movie> _popularListState;

  final PagingController<int, Movie> _pagingController =
  PagingController(firstPageKey: 0);

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    _popularListState = [];
    super.initState();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = await fetchPopular(widget.filterProviders, pageKey);
      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + 1; // newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  Widget _buildListPage(BuildContext context, Movie _itemMovie){
    if(_popularListState.contains(_itemMovie)) return Container();
    return Dismissible(
      key: UniqueKey(),
      secondaryBackground: Container(
        color: Colors.red[500],
        child: Padding(
          padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
          child: Icon(
            Icons.archive,
            color: Colors.white70,
          ),
        ),
      ),
      background: Container(
        color: Colors.green[500],
        child: Padding(
          padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
          child: Icon(Icons.list_rounded, color: Colors.white70),
        ),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          Movie _tempMovie = Movie(
            id: _itemMovie.id,
            title: _itemMovie.title,
            poster: _itemMovie.poster,
            objectType: _itemMovie.objectType,
            isWatchList: false,
            isArchive: true,
            updateTime: DateTime.now(),
          );
          myMovies.add(_tempMovie);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text("archive ${_itemMovie.title}")
              )
          );
          setState(() {
            _popularListState.add(_itemMovie);
          });
        } else {
          Movie _tempMovie = Movie(
            id: _itemMovie.id,
            title: _itemMovie.title,
            poster: _itemMovie.poster,
            objectType: _itemMovie.objectType,
            isWatchList: true,
            isArchive: false,
            updateTime: DateTime.now(),
          );
          myMovies.add(_tempMovie);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text("watchlist ${_itemMovie.title}")
              )
          );

          setState(() {
            _popularListState.add(_itemMovie);
          });
        }
      },
      child: FutureBuilder<bool>(
        future: SQLiteDbProvider.db.isInDb(_itemMovie.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Text('Stream error');
          return snapshot.hasData
              ? snapshot.data
              ? Container()
              : cardInk(_itemMovie)
              : Center(
            child: CircularProgressIndicator(),
          );
        },
      ),

      //cardInk(_popularListState[index]),
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: _buildPageView(context),
    );
  }

  Widget _buildPageView(BuildContext context) =>
      PagedListView<int, Movie>(
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<Movie>(
          itemBuilder: (context, item, index) => _buildListPage(
            context, item,
          ),
        ),
      );

  Widget cardInk(Movie _oneMovie) {
    return InkWell(
      child: Card(
        child: ListTile(
          leading:
          Image.network("https://images.justwatch.com${_oneMovie.poster}"),
          title: Text(_oneMovie.title),
          subtitle: Text(
              "${_oneMovie.originalReleaseYear} ${_oneMovie.objectType} ${_oneMovie.cinemaReleaseDate}"),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MyDetail(id: _oneMovie.id, objectType: _oneMovie.objectType,),
              ),
            );
          },
        ),
      ),
    );
  }
  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}

class MyDetail extends StatefulWidget{
  final int id;
  final String objectType;
  MyDetail({Key key, this.id, this.objectType});

  @override
  _MyDetailState createState() => _MyDetailState();
}

class _MyDetailState extends State<MyDetail>{
  Movie movie;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getMovie(context),
    );
  }

  Widget _getMovie(BuildContext context){
    return FutureBuilder<Movie>(
      future: fetchMovie(widget.objectType, widget.id),
        builder: (context, snapshot){
          if(snapshot.hasError) return Text(snapshot.error.toString());
          return snapshot.hasData
              ? _buildMovie(context, snapshot.data)
              : Center(
            child: CircularProgressIndicator(),
          );
        }
    );
  }

  Widget _buildMovie(BuildContext context, Movie _movie){
    movie = _movie;
    return Stack(
      children: <Widget>[
        Image.network(
            "https://images.justwatch.com${movie.poster}",
          height: double.infinity,
          width: double.infinity,
          fit: BoxFit.fitHeight,
        ),
        Container(
          color: Colors.black87.withOpacity(0.30),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: EdgeInsets.only(top: 38, left: 14),
            child: ClipRect(
              child: new BackdropFilter(
                filter: new ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                child: new Container(
                  padding: EdgeInsets.only(left: 0, right: 0),
                  width: 50.0,
                  height: 50.0,
                  decoration: new BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.black.withOpacity(0.5)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_sharp,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 2,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                  )
              ),
              SizedBox(
                height: 120,
              ),
              Text(
                movie.title,
                style: TextStyle(fontSize: 35, color: Colors.white70),
              ),
              SizedBox(height: 12,),
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child:
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: movie.scorings.length,
                          itemBuilder: (BuildContext context, int index){
                          return Text("${movie.scorings[index].providerType} ${movie.scorings[index].value}");
                          }
                  )
                ),
              ),
              SizedBox(height: 12,),
              Text(
                movie.objectType,
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              SizedBox(height: 8,),
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Text(
                    movie.shortDescription,
                    style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.2),
                  ),
                ),
              ),
              _prepareBuildCapture(context),
              SizedBox(height: 12,),
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black87.withOpacity(0.6),
                      offset: Offset(0, 4),
                      blurRadius: 4
                    ),
                  ],
                  color: Colors.black87,
                  borderRadius: BorderRadius.all(Radius.circular(15),),
                ),
                margin: EdgeInsets.fromLTRB(0, 0, 5, 0),
                height: 65,
                width: double.infinity,
                child: TextButton(
                  child: Text('add to watchlist',
                  style: TextStyle(color: Colors.white70, fontSize: 15, letterSpacing: 1),
                  ),
                  onPressed: () => SQLiteDbProvider.db.insertMovie(
                      Movie(
                        id: movie.id,
                        title: movie.title,
                        poster: movie.poster,
                        objectType: movie.objectType,
                        isWatchList: true,
                        isArchive: false,
                        updateTime: DateTime.now(),
                      )
                  ),
                ),
    ), /*FlatButton(
                  child: Text('add to watchlist',
                  style: TextStyle(color: Colors.white70, fontSize: 15, letterSpacing: 1),
                  ),
                  onPressed: () => SQLiteDbProvider.db.insertMovie(
                    Movie(
                      id: movie.id,
                      title: movie.title,
                      poster: movie.poster,
                      objectType: movie.objectType,
                      isWatchList: true,
                      isArchive: false,
                      updateTime: DateTime.now(),
                    )
                  ),
                ),*/
              //),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCapture(BuildContext context, String suffix){
    String _src = "https://images.justwatch.com$suffix";
    return Padding(
      padding: const EdgeInsets.only(right: 14.0),
      child: ClipRect(
          //borderRadius: BorderRadius.circular(3.0),
        child: GestureDetector(
          onTap: () {
              Navigator.push(
              context,
              MaterialPageRoute(
              builder: (context) => FullScreenImage(_src),
              ),
              );
      },
        child: Image.network(
          _src,
          width: 160.0,
          height: 120.0,
          fit: BoxFit.cover,
        ),
      ),),
    );
  }

  Widget _prepareBuildCapture(BuildContext context){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox.fromSize(
          size: const Size.fromHeight(100.0),
          child: ListView.builder(
            itemCount: movie.posters.length,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(top: 8.0, left: 20.0),
            itemBuilder: (BuildContext context, int index) => _buildCapture(context, movie.posters[index].backdropUrl),
          ),
        )
      ]
    );
  }
}

class FullScreenImage extends StatelessWidget{
  final String src;
  FullScreenImage(this.src, {Key key});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child:
          RotatedBox(
            quarterTurns: 1,
            child: InteractiveViewer(
              boundaryMargin: EdgeInsets.zero,
              minScale: 1,
              maxScale: 4,
              child:Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                      image: NetworkImage(
                          src
                      ),
                      fit: BoxFit.cover
                  ) ,
                ),
              ),
            ),
          ),
    );
  }
}

class AlternativeMyDetail extends StatefulWidget{
  final int id;
  final String objectType;

  AlternativeMyDetail(this.id, this.objectType, {Key key}) : super(key: key);
  @override
  _AlterntativeMyDetailState createState() => _AlterntativeMyDetailState();
}

class _AlterntativeMyDetailState extends State<AlternativeMyDetail>{
  Movie movie;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Movie>(
        future: fetchMovie(widget.objectType, widget.id),
        builder: (context, snapshot){
          if(snapshot.hasError) return Text(snapshot.error.toString());
          return snapshot.hasData
              ? _scaBody(context, snapshot.data)
              : Center(child: CircularProgressIndicator(),);
        },
      ),
    );
  }

  Widget _scaBody(BuildContext context, Movie _movie){
    movie = _movie;
    return  SingleChildScrollView(
      child: Column(
        children: <Widget>[
          _detailHead(),
          Padding(
              padding: const EdgeInsets.all(18.0),
            child: _description(),
          ),
          _imageShow(),
          SizedBox(height: 18.0,),
          _offers(),
          SizedBox(height: 20.0,),
        ],
      ),
    );
  }

  Widget _detailHead(){
    return Text("");
  }

  Widget _description(){
    return Text("");
  }

  Widget _imageShow(){
    return Text("");
  }

  Widget _offers(){
    return Text("");
  }
}

class MyWatchlist extends StatefulWidget {
  MyWatchlist({Key key}) : super(key: key);

  @override
  _MyWatchListState createState() => _MyWatchListState();
}

class _MyWatchListState extends State<MyWatchlist> {
  final myList = WatchListBloc();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Flexible(
          child: StreamBuilder<List<Movie>>(
            stream: myList.movies,
            builder:
                (BuildContext context, AsyncSnapshot<List<Movie>> snapshot) {
              if (snapshot.hasError) return Text(snapshot.error.toString());
              return snapshot.hasData
                  ? buildList(context, snapshot.data)
                  : Center(
                      child: CircularProgressIndicator(),
                    );
            },
          ),
        )
      ],
    );
  }

  Widget buildList(BuildContext context, List<Movie> _movieList) {
    return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _movieList.length,
        itemBuilder: (BuildContext context, int index) {
          Movie _movie = _movieList[index];
          return Card(
            child: Dismissible(
              key: UniqueKey(),
              background: Container(
                color: Colors.red[500],
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                  child: Icon(
                    Icons.delete_forever,
                    color: Colors.white70,
                  ),
                ),
              ),
              onDismissed: (direction) {
                myList.delete(_movie.id);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('delete')
                    )
                );
              },
              child: ListTile(
                leading: Image.network(
                    "https://images.justwatch.com${_movie.poster}"),
                title: Text(_movie.title),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyDetail(id: _movie.id, objectType: _movie.objectType,),
                    ),
                  );
                },
              ),
            ),
          );
        });
  }
}

class MyArchive extends StatefulWidget {
  MyArchive({Key key}) : super(key: key);

  @override
  _MyArchiveState createState() => _MyArchiveState();
}

class _MyArchiveState extends State<MyArchive> {
  final myList = MovieBloc();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Flexible(
          child: StreamBuilder<List<Movie>>(
            stream: myList.archive,
            builder:
                (BuildContext context, AsyncSnapshot<List<Movie>> snapshot) {
              if (snapshot.hasError) return Text(snapshot.error.toString());
              return snapshot.hasData
                  ? buildList(context, snapshot.data)
                  : Center(
                      child: CircularProgressIndicator(),
                    );
            },
          ),
        )
      ],
    );
  }

  Widget buildList(BuildContext context, List<Movie> _movieList) {
    return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _movieList.length,
        itemBuilder: (BuildContext context, int index) {
          Movie _movie = _movieList[index];
          return Card(
            child: Dismissible(
              key: UniqueKey(),
              background: Container(
                color: Colors.red[500],
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                  child: Icon(
                    Icons.delete_forever,
                    color: Colors.white70,
                  ),
                ),
              ),
              onDismissed: (direction) {
                myList.delete(_movie.id);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('delete')
                    )
                );
              },
              child: ListTile(
                leading: Image.network(
                    "https://images.justwatch.com${_movie.poster}"),
                title: Text(_movie.title),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyDetail(id: _movie.id, objectType: _movie.objectType,),
                    ),
                  );
                },
              ),
            ),
          );
        });
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
    _movieController.sink.add(await SQLiteDbProvider.db.getAllMovies());
  }

  delete(int id) {
    SQLiteDbProvider.db.deleteMovie(id);
    getAllMovies();
  }

  add(Movie movie) {
    SQLiteDbProvider.db.insertMovie(movie);
    getAllMovies();
  }

  getMovieById(int id) {
    SQLiteDbProvider.db.getMovieById(id);
  }

  isInDb(int id) {
    SQLiteDbProvider.db.isInDb(id);
  }

  getWatchList() {
    SQLiteDbProvider.db.getAllWatchlist();
  }

  getArchive() async {
    _isArchiveController.sink.add(await SQLiteDbProvider.db.getAllArchive());
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
    _movieController.sink.add(await SQLiteDbProvider.db.getAllWatchlist());
  }

  delete(int id) {
    SQLiteDbProvider.db.deleteMovie(id);
    getAllMovies();
  }

  add(Movie movie) {
    SQLiteDbProvider.db.insertMovie(movie);
    getAllMovies();
  }

  getMovieById(int id) {
    SQLiteDbProvider.db.getMovieById(id);
  }

  isInDb(int id) {
    SQLiteDbProvider.db.isInDb(id);
  }

  getWatchList() {
    SQLiteDbProvider.db.getAllWatchlist();
  }

  getArchive() {
    SQLiteDbProvider.db.getAllArchive();
  }
}
