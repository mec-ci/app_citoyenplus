import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

Future<Album> createAlbum(String nom, String description) async {
  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/categorie-signalement'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'nom': nom,
      'description': description,
    }),
  );
  // 🔥 DEBUG
  //print("STATUS CODE: ${response.statusCode}");
  //print("RESPONSE BODY: ${response.body}");
  //print("RESPONSE HEADERS: ${response.headers}");

  if (response.statusCode == 200 || response.statusCode == 201) {
    // If the server did return a 201 CREATED response,
    // then parse the JSON.
    return Album.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else {
    // If the server did not return a 201 CREATED response,
    // then throw an exception.
    throw Exception('Failed to create album.');
  }
}

class Album {
  String nom;
  String description;

  Album({
    required this.nom,
    required this.description,
  });


  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      nom: json['nom'],
      description: json['description'],
    );
  }
}


class AjouterCategorieSignalement extends StatefulWidget {
  const AjouterCategorieSignalement({super.key});

  @override
  State<AjouterCategorieSignalement> createState() {
    return _AjouterCategorieSignalementState();
  }
}

class _AjouterCategorieSignalementState extends State<AjouterCategorieSignalement> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
 

  Future<Album>? _futureAlbum;

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
          controller: _nomController,
          decoration: const InputDecoration(hintText: 'Enter Nom'),
        ),
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(hintText: 'Enter Description'),
        ),
       
        ElevatedButton(
          onPressed: () {
            setState(() {
              _futureAlbum = createAlbum(
                _nomController.text,
                _descriptionController.text,
               
              );
            });
          },
          child: const Text('Create Data'),
        ),
      ],
    );
  }

  FutureBuilder<Album> buildFutureBuilder() {
    return FutureBuilder<Album>(
      future: _futureAlbum,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text(snapshot.data!.nom);
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }

        return const CircularProgressIndicator();
      },
    );
  }
}
