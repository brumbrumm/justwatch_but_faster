import 'package:flutter/material.dart';

import '../main.dart';
import '../models/movie.dart';
import 'movie_detail_view.dart';

class MyArchive extends StatefulWidget {
  const MyArchive({Key? key}) : super(key: key);

  @override
  State<MyArchive> createState() => _MyArchiveState();
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
                  ? buildList(context, snapshot.data ?? [])
                  : const Center(
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
                child: const Padding(
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
                    const SnackBar(
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