import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../data/local_store.dart';

class DownloadService {
  Future<String> download(int id,String title,String url) async {
    final dir=await getApplicationDocumentsDirectory();
    final safe=title.replaceAll(RegExp(r'[^A-Za-z0-9_-]'),"_");
    final path="${dir.path}/lumina_$id\_$safe.mp4";
    final r=await http.get(Uri.parse(url));
    if(r.statusCode>=400) throw Exception("Download failed");
    await File(path).writeAsBytes(r.bodyBytes);
    await LocalStore.instance.addDownload({"id":id,"lesson_id":id,"title":title,"url":url,"local_path":path,"media_type":"video"});
    return path;
  }
}
