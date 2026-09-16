import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class Api {
  String? access,refresh;
  final String base=AppConfig.apiBaseUrl;
  Map<String,String> get headers=>{"Content-Type":"application/json",if(access!=null)"Authorization":"Bearer $access"};
  Future<Map<String,dynamic>> post(String path,Map<String,dynamic> body,{bool auth=true}) async {
    final r=await http.post(Uri.parse("$base$path"),headers:auth?headers:{"Content-Type":"application/json"},body:jsonEncode(body));
    if(r.statusCode>=400) throw Exception(jsonDecode(r.body)["detail"]??"Request failed");
    return jsonDecode(r.body);
  }
  Future<List<dynamic>> getList(String path) async {
    final r=await http.get(Uri.parse("$base$path"),headers:headers);
    if(r.statusCode>=400) throw Exception(jsonDecode(r.body)["detail"]??"Request failed");
    return jsonDecode(r.body);
  }
  Future<Map<String,dynamic>> getMap(String path) async {
    final r=await http.get(Uri.parse("$base$path"),headers:headers);
    if(r.statusCode>=400) throw Exception(jsonDecode(r.body)["detail"]??"Request failed");
    return jsonDecode(r.body);
  }
}
