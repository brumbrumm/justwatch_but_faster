import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:justwatch_but_faster/models/movie.dart';
import 'package:justwatch_but_faster/models/setting.dart';

import 'package:justwatch_but_faster/services/fetchService.dart';
import 'package:justwatch_but_faster/services/sqlDbProvider.dart';

import 'package:justwatch_but_faster/views/settingView.dart';

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

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
    } else if (indexTitle == 1) {
      return "New";
    } else if (indexTitle == 2) {
      return "WatchList";
    } else if (indexTitle == 3) {
      return "Archive";
    } else if (indexTitle == 4) {
      return "Settings";
    } else {
      return "Simple Wins";
    }
  }

  static List<Widget> _widgetOptions = <Widget>[
    PreHomePage(),
    //MyHomePage(),
    MyNew(),
    MyWatchlist(),
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
            label: 'home',
          ),
          BottomNavigationBarItem(
            icon: _selectedIndex == 1
                ? Icon(Icons.new_releases)
                : Icon(Icons.new_releases_outlined),
            label: 'new',
          ),
          BottomNavigationBarItem(
            icon: _selectedIndex == 2
                ? Icon(Icons.list_rounded)
                : Icon(Icons.format_list_numbered_rounded),
            label: 'watchlist',
          ),
          BottomNavigationBarItem(
            icon: _selectedIndex == 3
                ? Icon(Icons.archive)
                : Icon(Icons.archive_outlined),
            label: 'archive',
          ),
          BottomNavigationBarItem(
            icon: _selectedIndex == 4
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
    return Flexible(
        child: FutureBuilder<List<Setting>>(
      future: SQLiteDbProvider.db.getSettingByAttribute('provider'),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text(snapshot.error.toString());
        return snapshot.hasData
            ? prepareStringList(snapshot.data)
            : Center(
                child: CircularProgressIndicator(),
              );
      },
    ));
  }

  Widget prepareStringList(List<Setting> _providerList) {
    _providerList.forEach((element) {
      _filterProviders.add(element.id);
    });
    return MyHomePage(
      filterProviders: _filterProviders,
    );
  }
}

class MyHomePage extends StatefulWidget {
  final List<String> filterProviders;
  MyHomePage({Key key, this.filterProviders}) : super(key: key);

  @override
  _MyHomePageState createState() =>
      _MyHomePageState(filterProviders: filterProviders);
}

class _MyHomePageState extends State<MyHomePage> {
  Future<List<Movie>> _movieFutureList;

  Future<List<Setting>> _providerFutureList;

  final List<String> filterProviders;
  _MyHomePageState({Key key, this.filterProviders});

  List<Movie> _popularListState;

  final myMovies = MovieBloc();

  bool _hasMore;
  bool _error;
  bool _loading;
  int _pageNumber;

  final int _defaultMoviesPerPageCount = 30;
  final int _nextPageThreshold = 5;

  @override
  void initState() {
    super.initState();
    //filterProviders = [];

    _pageNumber = 1;
    _hasMore = true;
    _error = false;
    _loading = true;
    _popularListState = [];
    _fetchMovies();
    //_providerFutureList = SQLiteDbProvider.db.getSettingByAttribute('provider');
    _movieFutureList = fetchPopular(filterProviders, _pageNumber);
  }

  Future<void> _fetchMovies() async {
    try {
      List<Movie> fetchedMovies =
          await fetchPopular(filterProviders, _pageNumber);
      setState(() {
        _hasMore = fetchedMovies.length == _defaultMoviesPerPageCount;
        _loading = false;
        _pageNumber += 1;
        _popularListState.addAll(fetchedMovies);
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Widget getBody() {
    if (_popularListState.isEmpty) {
      if (_loading) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          ),
        );
      } else if (_error) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text('Error while loading'),
          ),
        );
      } else {
        return Text('List is empty');
      }
    } else {
      return _buildPopularList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*appBar: AppBar(
        title: Text('Simple Win'),
      ),*/
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: getBody(),
            ),
          ],
        ),
      ),
    );
  }

  List<Movie> _excluded(List<Movie> _popular) {
    _popular.forEach((element) async {
      bool mov = await SQLiteDbProvider.db.isInDb(element.id);
      print(mov);
      if (mov) _popular.remove(element);
    });
    return _popular;
  }

  Widget _buildPopularList() {
    //_popularList = _popularListState ?? _popularList;
    return ListView.builder(
        physics: AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(2),
        itemCount: _popularListState.length +
            (_hasMore ? 1 : 0), // _popularList.length,
        itemBuilder: (context, index) {
          if (index == _popularListState.length - _nextPageThreshold &&
              _hasMore) {
            _fetchMovies();
          }
          if (index == _popularListState.length) {
            if (_error) {
              return Text('Error something went wrong');
            } else {
              return Center(
                  child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(),
              ));
            }
          }

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
                  id: _popularListState[index].id,
                  title: _popularListState[index].title,
                  poster: _popularListState[index].poster,
                  objectType: _popularListState[index].objectType,
                  isWatchList: false,
                  isArchive: true,
                  updateTime: DateTime.now(),
                );
                myMovies.add(_tempMovie);
                Scaffold.of(context).showSnackBar(SnackBar(
                    content:
                        Text("archive ${_popularListState[index].title}")));
                _popularListState.remove(_popularListState[index]);
                setState(() {
                  _popularListState = _popularListState;
                });
              } else {
                Movie _tempMovie = Movie(
                  id: _popularListState[index].id,
                  title: _popularListState[index].title,
                  poster: _popularListState[index].poster,
                  objectType: _popularListState[index].objectType,
                  isWatchList: true,
                  isArchive: false,
                  updateTime: DateTime.now(),
                );
                myMovies.add(_tempMovie);
                Scaffold.of(context).showSnackBar(SnackBar(
                    content:
                        Text("watchlist ${_popularListState[index].title}")));
                _popularListState.remove(_popularListState[index]);
                setState(() {
                  _popularListState = _popularListState;
                });
              }
            },
            child: FutureBuilder<bool>(
              future: SQLiteDbProvider.db.isInDb(_popularListState[index].id),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text('Stream error');
                return snapshot.hasData
                    ? snapshot.data
                        ? Container()
                        : cardInk(_popularListState[index])
                    : Center(
                        child: CircularProgressIndicator(),
                      );
              },
            ),

            //cardInk(_popularListState[index]),
          );
        });
  }

  Widget cardInk(Movie _oneMovie) {
    return InkWell(
      child: Card(
        child: ListTile(
          leading:
              Image.network("https://images.justwatch.com${_oneMovie.poster}"),
          title: Text(_oneMovie.title),
          subtitle: Text(
              "${_oneMovie.id} ${_oneMovie.originalReleaseYear} ${_oneMovie.objectType} ${_oneMovie.cinemaReleaseDate}"),
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
}

class MyDetail extends StatelessWidget{
  final int id;
  final String objectType;

  MyDetail({Key key, this.id, this.objectType});

  Movie movie;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*appBar: AppBar(
        title: Text('test'),
      ),*/
      body: _getMovie(context),
    );
  }

  Widget _getMovie(BuildContext context){
    return FutureBuilder<Movie>(
      future: fetchMovie(objectType, id),
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
                child: FlatButton(
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
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildScoring(List<Scoring> _scoringList){
    if(_scoringList.isEmpty) return Text('no score available');
    return Text("${_scoringList[0].providerType}: ${_scoringList[0].value}");
    return ListView.builder(
        itemCount: _scoringList.length,
        itemBuilder: (BuildContext context, int index){
          return Text("${_scoringList[index].providerType}: ${_scoringList[index].value}");
        }
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

  Widget _buildFullScreen(BuildContext context, String src){
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(src),
          fit: BoxFit.cover,
        )
      ),
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
class VERSION_MyDetail extends StatelessWidget {
  final int id;
  final String objectType;
  VERSION_MyDetail({Key key, this.id, this.objectType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: <Widget>[
        Container(
          child: FutureBuilder<Movie>(
            future: fetchMovie(objectType, id),
            builder: (context, snapshot) {
              if (snapshot.hasError) Text(snapshot.error.toString());
              return snapshot.hasData
                  ?  _buildDetailView(context, snapshot.data)
                  : Center(
                      child: CircularProgressIndicator(),
                    );
            },
          ),
        ),
      ],
    ));
  }

  Widget _buildDetailView(BuildContext context, Movie movie) {
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(left: 10.0),
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: new BoxDecoration(
            image: new DecorationImage(
              image: NetworkImage(
                  "https://images.justwatch.com${movie.posters[0].backdropUrl}"), //Image.network("https://images.justwatch.com${_movie.poster}"),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          height: MediaQuery.of(context).size.height * 0.5,
          padding: EdgeInsets.all(40.0),
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(color: Color.fromRGBO(50, 40, 70, 0.7)),
          child: Center(
            child: _buildNameScorring(movie),
          ),
        ),
        Positioned(
            left: 6.0,
            top: 54.0,
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              child: Icon(Icons.arrow_back_rounded, color: Colors.white70),
            )),
      ],
    );
  }

  Widget _buildNameScorring(Movie _movie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 120.0,
        ),
        Text(
          _movie.title,
          style: TextStyle(color: Colors.white70, fontSize: 42.0),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            ListView.builder(
                itemCount: _movie.scorings.length,
                itemBuilder: (BuildContext context, int index) {
                  return Text(
                      "${_movie.scorings[index].value} ${_movie.scorings[index].providerType}");
                }),
          ],
        )
      ],
    );
  }

  Widget _buildDescription(Movie _movie) {
    return Container(child: Text("${_movie.shortDescription}"));
  }
}

class MyNew extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('new');
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
                Scaffold.of(context)
                    .showSnackBar(SnackBar(content: Text('delete')));
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
                Scaffold.of(context)
                    .showSnackBar(SnackBar(content: Text('delete')));
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
