class UserSession {
  final int id; final String username,email,displayName; final List<String> roles;
  UserSession({required this.id,required this.username,required this.email,required this.displayName,required this.roles});
  factory UserSession.fromJson(Map<String,dynamic> j)=>UserSession(
    id:j["id"],username:j["username"],email:j["email"],displayName:j["display_name"],roles:List<String>.from(j["roles"]??[]));
}
class Course { final int id; final String title,level,description; final int subjectId;
  Course({required this.id,required this.title,required this.level,required this.description,required this.subjectId});
  factory Course.fromJson(Map<String,dynamic> j)=>Course(id:j["id"],title:j["title"],level:j["level"],description:j["description"]??"",subjectId:j["subject_id"]);
}
class Lesson { final int id,unitId; final String title,summary; final bool offline;
  Lesson({required this.id,required this.unitId,required this.title,required this.summary,required this.offline});
  factory Lesson.fromJson(Map<String,dynamic> j)=>Lesson(id:j["id"],unitId:j["unit_id"],title:j["title"],summary:j["summary"]??"",offline:j["offline_available"]??false);
}
