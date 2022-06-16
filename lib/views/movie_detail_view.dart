import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:justwatch_but_faster/main.dart';

import '../models/movie.dart';
import '../models/provider.dart';
import '../services/fetch_service.dart';
import '../services/sql_db_provider.dart';

class MyDetail extends StatefulWidget{
  final int id;
  final String objectType;
  const MyDetail({
    Key? key, required this.id,
    required this.objectType
  }):super(key: key);

  @override
  State<MyDetail> createState() => _MyDetailState();
}

class _MyDetailState extends State<MyDetail>{
  bool isWatchList = false;
  late Future<Movie> movieFuture;

  int counterState = 0;

  @override
  void initState() {
    super.initState();

    movieFuture = fetchMovie(widget.objectType, widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getMovie(context),
    );
  }

  Widget _getMovie(BuildContext context){
    return FutureBuilder<Movie>(
        future: movieFuture,
        builder: (context, snapshot){
          if(snapshot.hasError) {
            // print(snapshot.error.toString());
            return Text(snapshot.error.toString());
          }
          if(snapshot.hasData){
            if(snapshot.data != null){
              return _buildMovie(context, snapshot.data!);
            } else {
              return const Text('Empty movie information');
            }
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
    );
  }

  Widget _buildMovie(BuildContext context, Movie movie){
    List<Widget> providerList = [];
    List<Offer> checkDuplicate = [];
    List<Offer> offerList = movie.offers ?? [];
    offerList.sort((b, a) => a.type.length.compareTo(b.type.length));

    for (Offer element in offerList) {
      if(checkDuplicate.where((duplicate) => duplicate.providerId == element.providerId).isNotEmpty) {
        continue;
      }
      checkDuplicate.add(element);

      final Iterable<Provider> provList = PROVIDER_LIST.where((elementGlobal) => elementGlobal.id == element.providerId);
      Provider? prov = null;
      if(provList.isNotEmpty){
        prov = provList.first;
      }
      providerList.add(
        Container(
          padding: const EdgeInsets.all(2.0),
          width: MediaQuery.of(context).size.width * 0.3,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.1,
                  child: prov != null ? Image.network(
                    "https://images.justwatch.com${prov.iconUrl}") : Container(),
                ),
                Text("${element.packageShortName} ${element.type}",
                  overflow: TextOverflow.fade,
                ),
              ],
            ),
          )
          ,
        )
      );
    }
    // print('${providerList.length} ${movie.offers}');
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
        SizedBox(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.3,
          child: Align(
            alignment: Alignment.topRight,
            child: SafeArea(
              child: SingleChildScrollView(
    child: Column(
      children: providerList,
    ),
    ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 38, left: 14),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                child: Container(
                  padding: const EdgeInsets.only(left: 0, right: 0),
                  width: 50.0,
                  height: 50.0,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.black.withOpacity(0.5)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(
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
              const Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                  )
              ),
              const SizedBox(
                height: 120,
              ),
              Text(
                movie.title,
                style: const TextStyle(fontSize: 35, color: Colors.white70),
              ),
              const SizedBox(height: 12,),
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child:
                    ListView.builder(
                        shrinkWrap: true,
                        itemCount: movie.scorings != null ? movie.scorings!.length : 0,
                        itemBuilder: (BuildContext context, int index){
                          return Text("${movie.scorings?[index].providerType} ${movie.scorings?[index].value}");
                        }
                    )
                ),
              ),
              const SizedBox(height: 12,),
              Text(
                movie.objectType,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 8,),
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Text(
                    "${movie.shortDescription}",
                    style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.2),
                  ),
                ),
              ),
              _prepareBuildCapture(context, movie),
              const SizedBox(height: 12,),
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black87.withOpacity(0.6),
                        offset: const Offset(0, 4),
                        blurRadius: 4
                    ),
                  ],
                  // color: Colors.redAccent,
                  borderRadius: const BorderRadius.all(Radius.circular(15),),
                ),
                margin: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                height: 65,
                width: double.infinity,
                child: _addOrRemoveFromWatchlist(movie)
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _addOrRemoveFromWatchlist(Movie movie){
    // print('ADD OR REMOVE $isWatchList');
    if(((movie.isWatchList ?? false) && counterState == 0) || isWatchList ) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          primary: Colors.red
        ),
      child: const Text('remove from watchlist',
        style: TextStyle(color: Colors.white70, fontSize: 15, letterSpacing: 1),
      ),
      onPressed: () {
        setState((){
          counterState++;
          isWatchList = false;
          SQLiteDbProvider().deleteMovie(movie.id);
        });
      }
    );
    }
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        primary: Colors.greenAccent,

      ),
      onPressed: () {
        setState((){
          counterState++;
          isWatchList = true;
          SQLiteDbProvider().insertMovie(
              Movie(
                id: movie.id,
                title: movie.title,
                poster: movie.poster,
                objectType: movie.objectType,
                isWatchList: true,
                isArchive: false,
                updateTime: DateTime.now(),
              )
          );
        });
      },
      child: const Text('add to watchlist',
        style: TextStyle(
            color: Colors.black87, fontSize: 15, letterSpacing: 1),
      ),
    );
  }

  Widget _buildCapture(BuildContext context, String suffix){
    String src = "https://images.justwatch.com$suffix";
    return Padding(
      padding: const EdgeInsets.only(right: 14.0),
      child: ClipRect(
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreenImage(src),
              ),
            );
          },
          child: Image.network(
            src,
            width: 160.0,
            height: 120.0,
            fit: BoxFit.cover,
          ),
        ),),
    );
  }

  Widget _prepareBuildCapture(BuildContext context, Movie movie){
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox.fromSize(
            size: const Size.fromHeight(100.0),
            child: ListView.builder(
              itemCount: movie.posters != null ? movie.posters!.length : 0,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(top: 8.0, left: 20.0),
              itemBuilder: (BuildContext context, int index) => _buildCapture(context, movie.posters![index].backdropUrl),
            ),
          )
        ]
    );
  }
}

class FullScreenImage extends StatelessWidget{
  final String src;
  const FullScreenImage(this.src, {Key? key}):super(key: key);

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
