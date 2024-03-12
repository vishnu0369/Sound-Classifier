import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'animation_screen.dart';
import 'get_prediction.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'get_results.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sound Classifier',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}


class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Material(
        child: Stack(children: <Widget>[
          Scaffold(
              body: AudioFilePicker()),
          IgnorePointer(
              child: AnimationScreen(color: Theme.of(context).accentColor))
        ]));
  }
}

class AudioFilePicker extends StatefulWidget {

  @override
  _AudioFilePickerState createState() => _AudioFilePickerState();
}

class _AudioFilePickerState extends State<AudioFilePicker> {
  final CollectionReference Sounds =
  FirebaseFirestore.instance.collection('Sounds');

  String _fileNameController = "";
  String _resultController = "";

  Future<void> _create([DocumentSnapshot? documentSnapshot]) async {
    final String fileName = _fileNameController;
    final String _result = _resultController;
    Sounds.add({
      "File Name": fileName,
      "Result": _result,
    });

    _fileNameController = '';
    _resultController = '';
  }

  String res1 = "";
  String res2 = "";
  String res3 = "";

  Future<String> makeBase64(String path) async {
    try {
      File file = File(path);
      file.openRead();
      var contents = await file.readAsBytes();
      var base64File = base64.encode(contents);
      print(base64File);
      return base64File;
    } catch (e) {
      print(e.toString());

      return "";
    }
  }

  String _fileName = "";
  String filePath = "";
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );
    if (result != null) {
      _fileName = result.files.single.name;

      File file = File(result.files.single.path!);
      print(file);
      setState(() {
        filePath = file.path as String;
      });
    }
  }

  AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
  }

  void playAudio() async {
    File file = File(filePath);
    await audioPlayer.play(filePath);
    setState(() {
      isPlaying = true;
    });
  }

  void pauseAudio() async {
    await audioPlayer.pause();
    setState(() {
      isPlaying = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
    audioPlayer.stop();
  }



  Future<GetPrediction> askPrediction(String base64String) async {

    final response = await http.post(
      Uri.parse('https://sound-detection.onrender.com/predict'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{

        // 'type': c,
        'audio': base64String,
      }),
    );
    print("hello res");
    if (response.statusCode == 200) {
      print("hello res");
      return GetPrediction.fromJson(jsonDecode(response.body));
    } else {
      print('Request failed with status: ${response.body}.');
      throw Exception('Failed to fetch');
    }
  }

  void _navigateToNextScreen(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => Results()));
  }

  String res = "";
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF212121),
        title: Text(
          'Sound Classifier',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.audiotrack, size: 80.0),
            ElevatedButton(
              onPressed: _pickFile,
              child: Text(
                'Select Audio File',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                primary: Color(0xFF4CAF50),
              ),
            ),

            SizedBox(height: 16.0),
            _fileName != null
                ? Text(
              'Selected Audio File: $_fileName',
              style: TextStyle(fontSize: 16.0),
            )
                : Container(),
            Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: 20.0),


                  ElevatedButton(
                    onPressed: isPlaying ? pauseAudio : playAudio,
                    child: Text(isPlaying ? 'Pause' : 'Play'),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                String s = await makeBase64(filePath);
                print(s);
                final GetPrediction out = await askPrediction(s);
                setState(() {
                  List<String> outputs = out.result.split(",");

                  res1 = outputs[0];
                  res2 = outputs[1];
                  res3 = outputs[2];
                  print(res1);
                  print(res2);
                  print(res3);
                });
              },
              child: Text(
                'Predict',
                style: TextStyle(
                  color: Colors.white,
                ),

              ),
              style: ElevatedButton.styleFrom(
                primary: Color(0xFFF44336),
              ),
            ),
            SizedBox(height: 16.0),
            res1 != ""
                ? Column(
              children: [
                Text(
                  'Prediction Output 1:',
                  style: TextStyle(fontSize: 16.0),
                ),
                Text(
                  '$res1',
                  style: TextStyle(fontSize: 16.0),
                ),
              ],
            )
                : Container(),
            SizedBox(height: 16.0),
            res2 != ""
                ? Column(
              children: [
                Text(
                  'Prediction Output 2:',
                  style: TextStyle(fontSize: 16.0),
                ),
                Text(
                  '$res2',
                  style: TextStyle(fontSize: 16.0),
                ),
              ],
            )
                : Container(),
            SizedBox(height: 16.0),
            res3 != ""
                ? Column(
              children: [
                Text(
                  'Prediction Output 3:',
                  style: TextStyle(fontSize: 16.0),
                ),
                Text(
                  '$res3',
                  style: TextStyle(fontSize: 16.0),
                ),
              ],
            )
                : Container(),
            res1 != ""
                ? ElevatedButton(
                onPressed: () => {
                  _fileNameController = _fileName,
                  _resultController = res1,
                  _create()
                },
                child: Text('Save Result'))
                : Container(),
            ElevatedButton(
                onPressed: () => {_navigateToNextScreen(context)},
                child: const Text('Saved Results')),
          ],
        ),
      ),
      backgroundColor: Color(0xFFECEFF1),
    );
  }
}