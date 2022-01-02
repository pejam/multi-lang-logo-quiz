import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multi_lang_logo_quiz/lang_type.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> database = new List<String>.empty();
  int index = -1;
  int clickHint = 0;

  String correctAnswer = "",
      suggest = "";
  Map<int, int> correctAnswerKey = new Map();
  Map<int, int> showSuggestAnswerMap = new Map();
  Map<int, bool> showCorrectAnswerMap = new Map();

  int languageType = LangType.EN.value;
  String languageValue = LangType.EN.enName;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();


    //Load Database
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await addToDatabaseFromAssets();

      if (database.length > 0) startGame();
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(
          title: Center(child: Text("Logo Quiz")),
          actions: [
            IconButton(icon: Icon(Icons.refresh), onPressed: () => readJson()),//startGame()),
            IconButton(
                icon: Icon(Icons.help), onPressed: () => _onHelpPressed()),
          ],
        ),
        body: Center(
          child: database.length > 0
              ? Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(flex: 1, child: _languageDropDown())
                  ],
                ),
                SizedBox(
                  height: 24,
                ),
                database.length > 0 ? _showImage() : Container(),
                SizedBox(
                  height: 24,
                ),
                database.length > 0
                    ? showCorrectAnswerGrid()
                    : Container(),
                database.length > 0
                    ? _showSuggestAnswerGrid()
                    : Container(),
                SizedBox(
                  width: MediaQuery
                      .of(context)
                      .size
                      .width,
                  child: ElevatedButton(
                    onPressed: showCorrectAnswerMap.values.contains(false)
                        ? null
                        : () => startGame(),
                    child: Text('Next'),
                  ),
                )
              ],
            ),
          )
              : Center(
            child: CircularProgressIndicator(),
          ),
        ));
  }

  Expanded _showSuggestAnswerGrid() {
    return Expanded(
      flex: 3,
      child: GridView.builder(
        itemCount: suggest.length,
        gridDelegate:
        SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10),
        itemBuilder: (context, index) {
          return GestureDetector(
              onTap: () {
                if (correctAnswer
                    .toUpperCase()
                    .contains(suggest[index].toUpperCase())) {
                  correctAnswerKey.forEach((key, value) {
                    if (String.fromCharCode(value).toUpperCase() ==
                        suggest[index].toUpperCase())
                      setState(() {
                        showCorrectAnswerMap[key] = true;
                        showSuggestAnswerMap[index] = 1;
                      });
                  });
                } else {
                  setState(() {
                    showSuggestAnswerMap[index] = 0;
                  });
                }
              },
              child: Card(
                  color: showSuggestAnswerMap[index] == -1
                      ? Colors.blueGrey
                      : showSuggestAnswerMap[index] == 0
                      ? Colors.red
                      : Colors.green,
                  child: Center(
                    child: showSuggestAnswerMap[index] == 1
                        ? Icon(Icons.check, color: Colors.white)
                        : showSuggestAnswerMap[index] == 0
                        ? Icon(Icons.clear)
                        : Text('${suggest[index]}',
                        style: TextStyle(color: Colors.white)),
                  )));
        },
      ),
    );
  }

  Expanded showCorrectAnswerGrid() {
    return Expanded(
      flex: 3,
      child: GridView.builder(
        itemCount: correctAnswer.length,
        gridDelegate:
        SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10),
        itemBuilder: (context, index) {
          return Card(
              color: Colors.black,
              child: showCorrectAnswerMap[index] == true
                  ? Center(
                child: Text(
                  '${String.fromCharCode(correctAnswerKey[index])}',
                  style: TextStyle(color: Colors.white),
                ),
              )
                  : Container());
        },
      ),
    );
  }

  Expanded _showImage() {
    return Expanded(
      flex: 5,
      child: Image.asset(database[index]),
    );
  }

  List _items = [];

  // Fetch content from the json file
  Future<void> readJson() async {
    final String response =
    await rootBundle.loadString('assets/names/animals.json');
    _items = await json.decode(response);
  }

  Future addToDatabaseFromAssets() async {
    final manifestContent =
    await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    final imagePaths = manifestMap.keys
        .where((element) => element.contains('animals/'))
        .where((element) => element.contains('.png'))
        .toList();

    await readJson();

    setState(() {
      database = imagePaths;
    });
  }

  void startGame() {
    correctAnswer = suggest = "";
    showSuggestAnswerMap.clear();
    showCorrectAnswerMap.clear();
    correctAnswerKey = new Map();

    var lastIndex = index;
    do {
      index = Random().nextInt(database.length - 1);
    } while (index == lastIndex);

    correctAnswer = database[index]
        .substring(database[index].lastIndexOf('/') + 1,
            database[index].lastIndexOf('.'))
        .toUpperCase();

    correctAnswer = _items[index]["en"].toUpperCase();

    correctAnswerKey = correctAnswer.runes.toList().asMap();
    correctAnswerKey.forEach((key, value) {
      /**
       * false = Not Show
       * true = Show
       */
      showCorrectAnswerMap.putIfAbsent(key, () => false);
    });

    suggest = randomWithAnswer(correctAnswer).toUpperCase();
    var list = suggest.runes.toList();
    list.shuffle();
    list.asMap().forEach((key, value) {
      /**
       * init suggest map
       * -1 : Not Answer
       * 0 : Wrong Answer
       * 1 : Right Answer
       */
      showSuggestAnswerMap.putIfAbsent(key, () => -1);
    });
    suggest = String.fromCharCodes(list);
    setState(() {});
  }



  randomWithAnswer(String correctAnswer) {
    const aToZ = 'abcdefghijklmnopqrstuvwxyz';
    int originalLength = correctAnswer.length;
    var randomText = "";
    for (int i = 0; i < originalLength; ++i)
      randomText += aToZ[Random().nextInt(aToZ.length)];

    correctAnswer += randomText;
    return correctAnswer;
  }

  void _onHelpPressed() {
    if (clickHint < 3) {
      int hint;
      for (var i in showCorrectAnswerMap.entries) {
        if (i.value == false) {
          showCorrectAnswerMap[i.key] = true;
          hint = correctAnswerKey[i.key];
          break;
        }
      }
      var list = suggest.runes.toList();
      for (int i = 0; i < list.length; ++i) {
        if (list[i] == hint) {
          if (showSuggestAnswerMap[i] != 1) {
            showSuggestAnswerMap[i] = 1;
            break;
          } else
            continue;
        }
      }
      setState(() {
        clickHint++;
      });
    } else
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('only 3 time')));
  }

  _languageDropDown() {
    var dropdownNames = languageType == LangType.EN.value
        ? LangType.EN.listOfEnName
        : LangType.FA.listOfFaName;

    return DropdownButton<String>(
      value: languageValue,
      icon: const Icon(Icons.arrow_drop_down),
      iconSize: 24,
      elevation: 16,
      style: const TextStyle(color: Colors.deepPurple),
      underline: Container(
        height: 2,
        color: Colors.deepPurpleAccent,
      ),
      onChanged: (String newValue) {
        setState(() {
          languageValue = newValue;
          languageType == LangType.EN.value
              ? LangType.EN.listOfEnName.indexOf(newValue)
              : LangType.FA.listOfFaName.indexOf(newValue);
        });
      },
      items: dropdownNames.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
