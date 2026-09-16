import '../data/local_store.dart';
import 'api.dart';

class TutorService {
  final Api api; TutorService(this.api);
  Future<List<Map<String,dynamic>>> cards() async {
    try {
      final xs=await api.getList("/api/v1/ai/recommendations");
      final cards=xs.map((e)=>Map<String,dynamic>.from(e)).toList();
      await LocalStore.instance.cacheTutor(cards);
      return cards;
    } catch (_) { return await LocalStore.instance.tutorCards(); }
  }
  Future<String> ask(String message,Map<String,dynamic> context) async {
    try { final r=await api.post("/api/v1/ai/chat",{"message":message,"context":context}); return r["reply"]; }
    catch (_) { return "Offline tutor: break the topic into one small idea, review one mistake, and complete a short practice activity."; }
  }
}
