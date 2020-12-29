import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'globals.dart' as globals;
import 'models/comic.dart';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blueGrey,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'xkcd'),
    );
  }
}

Future<Comic> fetchComic([int num]) async {
  if(num != null && num > globals.current){
    showAlert('Alert', 'You\'re already on the last comic.');
    num = globals.current;
  }
  if(num != null && num == 0){
    num = 1;
  }

  ComicProvider cp = new ComicProvider();
  var savedComic = await cp.getComic(num);

  globals.iconFlag = savedComic != null;

  String url = num == null ? 'https://xkcd.com/info.0.json' : 'https://xkcd.com/$num/info.0.json';
  final response = await http.get(url);

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    var comic = Comic.fromJson(jsonDecode(response.body));
    globals.comic = comic;
    globals.viewed = comic.num;
    if(!globals.comicList.contains(comic.num))
      globals.comicList.add(comic.num);
    if(globals.firstLoad){
      globals.current = comic.num;
      globals.firstLoad = false;
    }
    return comic;
  } else {
    showAlert('Alert', 'There was an error fetching the comic.');
    return globals.comic;
  }
}

void showAlert(String title, String content){
  showDialog(
      context: globals.ctx,
      builder: (_)=>AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: (){
                Navigator.pop(globals.ctx);
              },
              child: Text('Ok')
          )
        ],
      ),
      barrierDismissible: false
  );
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  int current = 0;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  Future<Comic> futureComic;
  AnimationController _controller;
  Animation<double> _myAnimation;
  Icon _myIconButton;
  DateTime _lastQuitTime;
  ComicProvider comicProvider;


  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    futureComic = fetchComic();
    comicProvider = new ComicProvider();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    _myAnimation = CurvedAnimation(
        curve: Curves.decelerate,
        parent: _controller
    );

    _myIconButton = myIconButton(false);
  }

  Icon myIconButton(bool flag){
    return Icon(
      flag ? Icons.bookmark : Icons.bookmark_border,
      color: Colors.white,
      semanticLabel: 'Add to favorites',
      key: ValueKey(flag ? 1 : 2),
    );
  }

  void updateState(int num){

  }

  @override
  Widget build(BuildContext context) {

    globals.ctx = context;
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
          actions: [
            IconButton(
              iconSize: globals.toolbarIconSize,
              icon: Icon(Icons.bookmarks_outlined),
              onPressed: () async{
                var comics = await comicProvider.getComics();
                showModalBottomSheet<void>(
                  context: context,
                  builder: (BuildContext context) {
                    List<Widget> children = [];
                    children..add(ListTile(
                      title: Text(
                        'Saved',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                      tileColor: Colors.blueGrey,
                    ));
                    comics.forEach((comic) {
                      children..add(ListTile(
                        title: Text("${comic.num} - ${comic.title}"),
                        onTap: (){
                          setState(() {
                            futureComic = fetchComic(comic.num);
                          });
                          Navigator.pop(context);
                        },
                      ));
                    });
                    return ListView(
                      padding: EdgeInsets.zero,
                      children: children,
                    );
                  },
                );
              },
            ),
            IconButton(
                iconSize: globals.toolbarIconSize,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 100),
                  child: _myIconButton,
                ),
                onPressed: () async{
                  globals.iconFlag = !globals.iconFlag;
                  if(globals.iconFlag){
                    await comicProvider.insert(globals.comic);
                  }else{
                    await comicProvider.delete(globals.comic.num);
                  }
                  setState(() {
                    _myIconButton = myIconButton(globals.iconFlag);
                  });
                }
            ),
          ]
      ),
      body: WillPopScope(
          onWillPop: () async {

            if(globals.comicList.isNotEmpty && globals.comicList.length > 1){
              globals.comicList.removeLast();
              int lastComic = globals.comicList.last;
              setState(() {
                futureComic = fetchComic(lastComic);
              });
              return false;
            }

            if (_lastQuitTime == null || DateTime.now().difference(_lastQuitTime).inSeconds > 1) {
              print('Press again Back Button exit');
              _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text('Press again Back Button exit'), duration: const Duration(seconds: 1),));
              _lastQuitTime = DateTime.now();
              return false;
            } else {
              print('sign out');
              Navigator.of(context).pop(true);
              return true;
            }
          },
          child: Center(
            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.
              child: FutureBuilder<Comic>(
                future: futureComic,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasData) {
                    Future.delayed(Duration.zero, () async {
                      setState(() {
                        _myIconButton = myIconButton(globals.iconFlag);
                      });
                    });

                    return Container(
                      alignment: Alignment.topCenter,
                      padding: EdgeInsets.all(15),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Text(
                              snapshot.data.title,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 32
                              ),
                            ),
                            SizedBox(
                              height: 15,
                              width: double.infinity,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ButtonBar(
                                  alignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    RaisedButton(
                                        onPressed: () {
                                          setState(() {
                                            futureComic = fetchComic(1);
                                          });
                                        },
                                        child: Text('|<')
                                    ),
                                    RaisedButton(
                                        onPressed: () {
                                          setState(() {
                                            futureComic = fetchComic(--globals.viewed);
                                          });
                                        },
                                        child: Text('PREV')
                                    ),
                                    RaisedButton(
                                        onPressed: () {
                                          setState(() {
                                            futureComic = fetchComic(Random().nextInt(globals.current));
                                          });
                                        },
                                        child: Text('RANDOM')
                                    ),
                                    RaisedButton(
                                        onPressed: () {
                                          setState(() {
                                            futureComic = fetchComic(++globals.viewed);
                                          });
                                        },
                                        child: Text('NEXT')
                                    ),
                                    RaisedButton(
                                        onPressed: () {
                                          setState(() {
                                            futureComic = fetchComic(globals.current);
                                          });
                                        },
                                        child: Text('>|')
                                    ),
                                  ],
                                )
                              ],
                            ),
                            SizedBox(
                              height: 15,
                              width: double.infinity,
                            ),
                            Tooltip(
                              margin: EdgeInsets.all(15),
                              padding: EdgeInsets.all(15),
                              message: snapshot.data.alt,
                              textStyle: TextStyle(fontSize: 16, color: Colors
                                  .white),
                              child: InteractiveViewer(
                                constrained: true,
                                child: CachedNetworkImage(
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator(),
                                  imageUrl: snapshot.data.img,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Text("${snapshot.error}");
                  }

                  // By default, show a loading spinner.
                  return CircularProgressIndicator();
                },
              )
          ),
      ),
    );
  }
}
