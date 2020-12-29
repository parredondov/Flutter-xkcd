import 'package:sqflite/sqflite.dart';

final String dbName = 'xkcd_db.db';
final String tableComics = 'comics';
final String columnTitle = 'title';
final String columnNum = 'num';
final String columnAlt = 'alt';
final String columnImg = 'img';

class Comic{
  final String month;
  final int num;
  final String link;	//""
  final String year;	//"2020"
  final String news;	//""
  // ignore: non_constant_identifier_names
  final String safe_title;	//"Vaccine Tracker"
  final String transcript;	//""
  final String alt;	//"*refresh* Aww, still in Kalamazoo. *refresh* Aww, still in Kalamazoo."
  final String img; //"https://imgs.xkcd.com/comics/vaccine_tracker.png"
  final String title; //"Vaccine Tracker"
  final String day;

  // ignore: non_constant_identifier_names
  Comic({this.month, this.num, this.link, this.year, this.news, this.safe_title, this.transcript, this.alt, this.img, this.title, this.day});


  factory Comic.fromJson(Map<String, dynamic> json) {
    return Comic(
      month: json['month'],
      num: json['num'],
      link: json['link'],
      year: json['year'],
      news: json['news'],
      safe_title: json['safe_title'],
      transcript: json['transcript'],
      alt: json['alt'],
      img: json['img'],
      title: json['title'],
      day: json['day'],
    );
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnTitle: title,
      columnNum: num,
      columnAlt: alt,
      columnImg: img
    };
    return map;
  }

  static Comic fromMap(Map<String, dynamic> map) {
    return new Comic(num: map[columnNum], alt: map[columnAlt], title: map[columnTitle], img: map[columnImg]);
  }

}

class ComicProvider {
  Database db;

  Future open(String path) async {
    db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
          var sql = '''create table $tableComics ( 
                $columnNum integer primary key, 
                $columnTitle text not null, 
                $columnAlt text not null, 
                $columnImg text not null)''';

          await db.execute(sql);
        });
  }

  Future<Comic> insert(Comic todo) async {
    try{
      await open(dbName);
      await db.insert(tableComics, todo.toMap());
    }catch(e){
      print(e);
    }finally{
      await close();
    }
    return todo;
  }

  Future<Comic> getComic(int num) async {
    try{
      await open(dbName);
      List<Map> maps = await db.query(tableComics,
          columns: [columnNum, columnImg, columnAlt, columnTitle],
          where: '$columnNum = ?',
          whereArgs: [num]);
      if (maps.length > 0) {
        return Comic.fromMap(maps.first);
      }
    }catch(e){
      print(e);
    }finally{
      await close();
    }
    return null;
  }

  Future<List<Comic>> getComics() async {
    var comics = new List<Comic>();
    try{
      await open(dbName);
      List<Map> maps = await db.query(tableComics,
          columns: [columnNum, columnImg, columnAlt, columnTitle]);
      maps.forEach((element) {
        comics.add(Comic.fromMap(element));
      });
    }catch(e){
      print(e);
    }finally{
      await close();
    }
    return comics;
  }

  Future delete(int id) async {
    try{
      await open(dbName);
      return await db.delete(tableComics, where: '$columnNum = ?', whereArgs: [id]);
    }catch(e){
      print(e);
    }finally{
      await close();
    }
  }

  Future<int> update(Comic todo) async {
    return await db.update(tableComics, todo.toMap(),
        where: '$columnNum = ?', whereArgs: [todo.num]);
  }

  Future close() async => db.close();
}