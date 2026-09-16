import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalStore {
  static final LocalStore instance=LocalStore._(); LocalStore._();
  Database? _db;
  Future<Database> get db async {
    if(_db!=null)return _db!;
    final p=join(await getDatabasesPath(),"lumina.db");
    _db=await openDatabase(p,version:1,onCreate:(d,v) async{
      await d.execute("CREATE TABLE courses(id INTEGER PRIMARY KEY,title TEXT,level TEXT,description TEXT,subject_id INTEGER)");
      await d.execute("CREATE TABLE lessons(id INTEGER PRIMARY KEY,unit_id INTEGER,title TEXT,summary TEXT,offline_available INTEGER)");
      await d.execute("CREATE TABLE progress(lesson_id INTEGER PRIMARY KEY,progress REAL,completed INTEGER,last_position INTEGER,updated_at TEXT)");
      await d.execute("CREATE TABLE downloads(id INTEGER PRIMARY KEY,lesson_id INTEGER,title TEXT,url TEXT,local_path TEXT,media_type TEXT)");
      await d.execute("CREATE TABLE sync_queue(id INTEGER PRIMARY KEY AUTOINCREMENT,type TEXT,payload TEXT)");
      await d.execute("CREATE TABLE tutor_cards(id INTEGER PRIMARY KEY AUTOINCREMENT,type TEXT,title TEXT,body TEXT)");
    }); return _db!;
  }
  Future<void> cacheCourses(List<Map<String,dynamic>> xs) async { final d=await db; for(final x in xs) await d.insert("courses",x,conflictAlgorithm:ConflictAlgorithm.replace); }
  Future<List<Map<String,dynamic>>> courses() async => (await db).query("courses");
  Future<void> cacheLessons(List<Map<String,dynamic>> xs) async { final d=await db; for(final x in xs) await d.insert("lessons",{...x,"offline_available":x["offline_available"]==true?1:0},conflictAlgorithm:ConflictAlgorithm.replace); }
  Future<List<Map<String,dynamic>>> lessons(int unit) async => (await db).query("lessons",where:"unit_id=?",whereArgs:[unit]);
  Future<void> saveProgress(int lessonId,double p,bool complete,int pos) async { final d=await db; await d.insert("progress",{"lesson_id":lessonId,"progress":p,"completed":complete?1:0,"last_position":pos,"updated_at":DateTime.now().toIso8601String()},conflictAlgorithm:ConflictAlgorithm.replace); await d.insert("sync_queue",{"type":"lesson_progress","payload":jsonEncode({"lesson_id":lessonId,"progress":p,"completed":complete,"last_position":pos})}); }
  Future<List<Map<String,dynamic>>> queue() async => (await db).query("sync_queue");
  Future<void> clearQueue(List<int> ids) async { final d=await db; for(final id in ids) await d.delete("sync_queue",where:"id=?",whereArgs:[id]); }
  Future<void> addDownload(Map<String,dynamic> x) async => (await db).insert("downloads",x,conflictAlgorithm:ConflictAlgorithm.replace);
  Future<List<Map<String,dynamic>>> downloads() async => (await db).query("downloads");
  Future<void> cacheTutor(List<Map<String,dynamic>> xs) async { final d=await db; await d.delete("tutor_cards"); for(final x in xs) await d.insert("tutor_cards",x); }
  Future<List<Map<String,dynamic>>> tutorCards() async => (await db).query("tutor_cards");
}
