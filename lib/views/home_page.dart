import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../main.dart';
import '../models/movie.dart';
import '../models/setting.dart';
import '../services/fetch_service.dart';
import '../services/sql_db_provider.dart';
import 'movie_detail_view.dart';

class PreHomePage extends StatelessWidget {
  final List<String> _filterProviders = [];

  PreHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Setting>>(
      future: SQLiteDbProvider().getSettingByAttribute('provider'),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text(snapshot.error.toString());
        return snapshot.hasData
            ? prepareStringList(snapshot.data ?? [])
            : const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Widget prepareStringList(List<Setting> providerList) {
    for (var element in providerList) {
      _filterProviders.add(element.id);
    }
    print('list length ${providerList.length}');
    //return Text(providerList.toString());
    return MyHomePage(_filterProviders, key: UniqueKey(),);
  }
}

class MyHomePage extends StatefulWidget {
  final List<String> filterProviders;
  const MyHomePage(this.filterProviders, {Key? key}):super(key: key);

  @override
  State<MyHomePage> createState() => _HomePageState();
}

class _HomePageState extends State<MyHomePage>{
  static const _pageSize = 30;

  bool _hasNextPage = true;

  final myMovies = MovieBloc();
  final List<Movie> _popularListState = [];

  final PagingController<int, Movie> _pagingController =
  PagingController(firstPageKey: int.tryParse(GlobalConfiguration().getValue('page')) ?? 1);

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    super.initState();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      GlobalConfiguration().updateValue("page", "$pageKey");
      if(_hasNextPage){
        final List<Movie> newItems = await fetchPopular(pageKey);
        final isLastPage = newItems.length < _pageSize;
        // print("LASTPAGE COMPARE $pageKey ${newItems.length} $_pageSize");

        List<Movie> newMovies = [];
        for (var element in newItems) {
          final bool isInDb = await SQLiteDbProvider().isInDb(element.id);
          if(!_popularListState.contains(element) &&! isInDb) {
            newMovies.add(element);
          }
        }
        if (isLastPage) {
          _pagingController.appendLastPage(newMovies);
          _hasNextPage = false;
        } else {
          final nextPageKey = pageKey + 1; // newItems.length;
          _pagingController.appendPage(newMovies, nextPageKey);
        }
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  Widget _buildListPage(BuildContext context, Movie itemMovie){
    if(_popularListState.contains(itemMovie)) return Container();
    return Dismissible(
      key: UniqueKey(),
      secondaryBackground: Container(
        color: Colors.red[500],
        child: const Padding(
          padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
          child: Icon(
            Icons.archive,
            color: Colors.white70,
          ),
        ),
      ),
      background: Container(
        color: Colors.green[500],
        child: const Padding(
          padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
          child: Icon(Icons.list_rounded, color: Colors.white70),
        ),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          Movie tempMovie = Movie(
            id: itemMovie.id,
            title: itemMovie.title,
            poster: itemMovie.poster,
            objectType: itemMovie.objectType,
            isWatchList: false,
            isArchive: true,
            updateTime: DateTime.now(),
          );
          myMovies.add(tempMovie);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text("archive ${itemMovie.title}")
              )
          );
          setState(() {
            _popularListState.add(itemMovie);
          });
        } else {
          Movie tempMovie = Movie(
            id: itemMovie.id,
            title: itemMovie.title,
            poster: itemMovie.poster,
            objectType: itemMovie.objectType,
            isWatchList: true,
            isArchive: false,
            updateTime: DateTime.now(),
          );
          myMovies.add(tempMovie);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text("watchlist ${itemMovie.title}")
              )
          );

          setState(() {
            _popularListState.add(itemMovie);
          });
        }
      },
      child: FutureBuilder<bool>(
        future: SQLiteDbProvider().isInDb(itemMovie.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Text('Stream error ${snapshot.error}');
          if (snapshot.hasData){
            if(snapshot.data ?? false){
              return Container();
            } else {
              return cardInk(itemMovie);
            }
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: _buildPageView(context),
      /*floatingActionButton: FloatingActionButton(
        onPressed: (){
          setState((){
            // _pagingController.nextPageKey = 1;
            _pagingController.notifyPageRequestListeners(1);
            _hasNextPage = true;
          });
        },
        hoverElevation: 50,
        child: const Icon(Icons.vertical_align_top, color: Colors.black87,),
      ),*/
    );
  }

  Widget _buildPageView(BuildContext context) =>
      PagedListView<int, Movie>(
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<Movie>(
          itemBuilder: (context, item, index) {
            return _buildListPage(context, item,);
          },
        ),
      );

  Widget cardInk(Movie oneMovie) {
    return InkWell(
      child: Card(
        child: ListTile(
          leading: Image.network("https://images.justwatch.com${oneMovie.poster}"),
          title: Text(oneMovie.title),
          subtitle: Text(
              "${oneMovie.originalReleaseYear} ${oneMovie.objectType} ${oneMovie.cinemaReleaseDate}"),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MyDetail(id: oneMovie.id, objectType: oneMovie.objectType,),
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
