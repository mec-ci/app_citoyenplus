import 'package:citoyen_plus/services/post_service.dart';
import 'package:flutter/material.dart';
import '../models/post.dart';

class ActualiteList extends StatefulWidget {
  const ActualiteList({super.key});

  @override
  State<ActualiteList> createState() {
    return _ActualiteListState();
  }
}

class _ActualiteListState extends State<ActualiteList> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _excerptController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  Future<PostModel>? _futureAlbum;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Create Data Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Create Data Example')),
        body: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8),
          child: (_futureAlbum == null) ? buildColumn() : buildFutureBuilder(),
        ),
      ),
    );
  }

  Column buildColumn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(hintText: 'Enter Title'),
        ),
        TextField(
          controller: _excerptController,
          decoration: const InputDecoration(hintText: 'Enter Excerpt'),
        ),
        TextField(
          controller: _contentController,
          decoration: const InputDecoration(hintText: 'Enter Content'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _futureAlbum = createArticle(
                _titleController.text,
                _contentController.text,
                date: DateTime.now(),
                excerpt: _excerptController.text,
              );
            });
          },
          child: const Text('Create Data'),
        ),
      ],
    );
  }

  FutureBuilder<PostModel> buildFutureBuilder() {
    return FutureBuilder<PostModel>(
      future: _futureAlbum,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text(snapshot.data!.title);
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }

        return const CircularProgressIndicator();
      },
    );
  }
}