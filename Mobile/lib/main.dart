import 'package:flutter/material.dart';
import 'services/api.dart';
import 'services/tutor_service.dart';
import 'data/local_store.dart';
import 'models/models.dart';
import 'services/download_service.dart';

void main(){runApp(const LuminaApp());}

class LuminaApp extends StatelessWidget{
 const LuminaApp({super.key});
 @override Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false,title:"Lumina",
   theme:ThemeData(useMaterial3:true,brightness:Brightness.dark,scaffoldBackgroundColor:const Color(0xFF0B1020),
   colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFF8B7CFF),brightness:Brightness.dark),
   inputDecorationTheme:const InputDecorationTheme(border:OutlineInputBorder())),
   home:LoginPage());
}

final api=Api();

class LoginPage extends StatefulWidget{ @override State<LoginPage> createState()=>_LoginPageState();}
class _LoginPageState extends State<LoginPage>{
 final id=TextEditingController(),pw=TextEditingController(); bool hide=true,busy=false;
 Future<void> login() async {setState(()=>busy=true);try{final r=await api.post("/api/v1/auth/login",{"identifier":id.text.trim(),"password":pw.text},auth:false);api.access=r["access_token"];api.refresh=r["refresh_token"];final u=UserSession.fromJson(r["user"]);if(mounted)Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>Home(session:u)));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}finally{if(mounted)setState(()=>busy=false);}}
 @override Widget build(BuildContext c)=>Scaffold(body:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(28),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:460),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
   const Text("LUMINA",style:TextStyle(fontSize:36,fontWeight:FontWeight.w800,letterSpacing:3)),const SizedBox(height:8),
   const Text("Your learning, without the signal.",style:TextStyle(color:Colors.white70,fontSize:16)),const SizedBox(height:38),
   TextField(controller:id,decoration:const InputDecoration(labelText:"Username or Email",prefixIcon:Icon(Icons.person_outline))),
   const SizedBox(height:16),TextField(controller:pw,obscureText:hide,decoration:InputDecoration(labelText:"Password",prefixIcon:const Icon(Icons.lock_outline),suffixIcon:IconButton(icon:Icon(Icons.visibility_outlined),onPressed:()=>setState(()=>hide=!hide)))),
   const SizedBox(height:24),FilledButton(onPressed:busy?null:login,child:Padding(padding:const EdgeInsets.all(13),child:Text(busy?"Signing in...":"Sign in"))),
   const SizedBox(height:14),OutlinedButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>RegisterPage())),child:const Text("Create account")),
   const SizedBox(height:18),const Text("Demo: student / Lumina@123",textAlign:TextAlign.center,style:TextStyle(color:Colors.white54))
 ]))));
}

class RegisterPage extends StatefulWidget{@override State<RegisterPage> createState()=>_RegisterPageState();}
class _RegisterPageState extends State<RegisterPage>{
 final u=TextEditingController(),e=TextEditingController(),n=TextEditingController(),p=TextEditingController(),cp=TextEditingController(),code=TextEditingController();String role="student";bool hide=true;
 Future<void> reg() async {try{await api.post("/api/v1/auth/register",{"username":u.text,"email":e.text,"display_name":n.text,"password":p.text,"confirm_password":cp.text,"role":role,"invitation_code":code.text.isEmpty?null:code.text},auth:false);if(mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text("Registration successful")));Navigator.pop(context);}}catch(x){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(x.toString())));}}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text("Create Lumina account")),body:ListView(padding:const EdgeInsets.all(24),children:[
   TextField(controller:n,decoration:const InputDecoration(labelText:"Full name")),const SizedBox(height:12),
   TextField(controller:u,decoration:const InputDecoration(labelText:"Username")),const SizedBox(height:12),
   TextField(controller:e,decoration:const InputDecoration(labelText:"Email")),const SizedBox(height:12),
   DropdownButtonFormField(value:role,items:["student","teacher","parent","manager","content_manager"].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(x)=>setState(()=>role=x!),decoration:const InputDecoration(labelText:"Account type")),const SizedBox(height:12),
   if(role!="student")TextField(controller:code,decoration:const InputDecoration(labelText:"Organization / Invitation code")),const SizedBox(height:12),
   TextField(controller:p,obscureText:hide,decoration:InputDecoration(labelText:"Password",suffixIcon:IconButton(icon:Icon(Icons.visibility),onPressed:()=>setState(()=>hide=!hide)))),const SizedBox(height:8),
   const Text("Minimum 8 characters • uppercase • lowercase • number • special character",style:TextStyle(color:Colors.white60)),const SizedBox(height:12),
   TextField(controller:cp,obscureText:hide,decoration:const InputDecoration(labelText:"Confirm password")),const SizedBox(height:24),
   FilledButton(onPressed:reg,child:const Text("Register"))
 ]));
}

class Home extends StatefulWidget{final UserSession session;const Home({required this.session,super.key});@override State<Home> createState()=>_HomeState();}
class _HomeState extends State<Home>{int tab=0;late TutorService tutor;
 @override void initState(){super.initState();tutor=TutorService(api);}
 @override Widget build(BuildContext c){final role=widget.session.roles.first;final pages=[
   Dashboard(session:widget.session,tutor:tutor),Explore(),ProgressPage(),DownloadsPage(),ProfilePage(session:widget.session)];
   return Scaffold(appBar:AppBar(title:const Text("Lumina"),actions:[IconButton(onPressed:()async{await api.post("/api/v1/auth/logout",{"refresh_token":api.refresh??""});if(mounted)Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>LoginPage()));},icon:const Icon(Icons.logout))]),
     body:pages[tab],bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),destinations:const[
       NavigationDestination(icon:Icon(Icons.auto_awesome),label:"Today"),NavigationDestination(icon:Icon(Icons.explore_outlined),label:"Explore"),
       NavigationDestination(icon:Icon(Icons.insights_outlined),label:"Progress"),NavigationDestination(icon:Icon(Icons.download_outlined),label:"Downloads"),
       NavigationDestination(icon:Icon(Icons.person_outline),label:"Profile")]));
 }}

class Dashboard extends StatefulWidget{final UserSession session;final TutorService tutor;const Dashboard({required this.session,required this.tutor,super.key});@override State<Dashboard> createState()=>_DashboardState();}
class _DashboardState extends State<Dashboard>{List<Map<String,dynamic>> cards=[];@override void initState(){super.initState();load();}Future<void>load()async{final x=await widget.tutor.cards();if(mounted)setState(()=>cards=x);}
 @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(20),children:[
   Text("Good to see you, ${widget.session.displayName}",style:const TextStyle(fontSize:25,fontWeight:FontWeight.bold)),const SizedBox(height:5),Text(widget.session.roles.join(" • "),style:const TextStyle(color:Colors.white60)),
   const SizedBox(height:22),const _FeatureCard(icon:Icons.explore,title:"Focus Compass",body:"Know what to learn next based on your current learning state."),
   const _FeatureCard(icon:Icons.psychology,title:"Proactive Tutor",body:"Lumina can notice weak areas, unfinished lessons and upcoming study sessions."),
   const _FeatureCard(icon:Icons.offline_bolt,title:"Offline Mode",body:"Continue supported lessons, quizzes, progress and local tutor guidance without continuous Internet."),
   const SizedBox(height:18),const Text("Lumina noticed…",style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),...cards.map((x)=>Card(child:ListTile(leading:const Icon(Icons.auto_awesome),title:Text(x["title"]??""),subtitle:Text(x["body"]??""))))
 ]);}

class _FeatureCard extends StatelessWidget{final IconData icon;final String title,body;const _FeatureCard({required this.icon,required this.title,required this.body});@override Widget build(BuildContext c)=>Card(margin:const EdgeInsets.only(bottom:12),child:Padding(padding:const EdgeInsets.all(16),child:Row(children:[Icon(icon,size:32),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:16)),const SizedBox(height:4),Text(body,style:const TextStyle(color:Colors.white70))]))])));}

class Explore extends StatefulWidget{@override State<Explore> createState()=>_ExploreState();}
class _ExploreState extends State<Explore>{List<Course> courses=[];bool offline=false;
 @override void initState(){super.initState();load();}
 Future<void>load()async{try{final xs=await api.getList("/api/v1/learning/courses");courses=xs.map((e)=>Course.fromJson(e)).toList();await LocalStore.instance.cacheCourses(xs.cast<Map<String,dynamic>>());}catch(_){final xs=await LocalStore.instance.courses();courses=xs.map((e)=>Course.fromJson(e)).toList();offline=true;}if(mounted)setState((){});}
 @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(18),children:[Row(children:[const Expanded(child:Text("Explore Learning",style:TextStyle(fontSize:25,fontWeight:FontWeight.bold))),if(offline)const Chip(label:Text("OFFLINE"))]),const SizedBox(height:14),...courses.map((x)=>Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.menu_book)),title:Text(x.title),subtitle:Text("${x.level}\n${x.description}"),isThreeLine:true,onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>CoursePage(course:x))))))]);}

class CoursePage extends StatefulWidget{final Course course;const CoursePage({required this.course,super.key});@override State<CoursePage> createState()=>_CoursePageState();}
class _CoursePageState extends State<CoursePage>{List<Map<String,dynamic>> units=[];@override void initState(){super.initState();load();}Future<void>load()async{try{units=(await api.getList("/api/v1/learning/courses/${widget.course.id}/units")).cast<Map<String,dynamic>>();}catch(_){}if(mounted)setState((){});}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text(widget.course.title)),body:ListView(padding:const EdgeInsets.all(18),children:[Text(widget.course.description,style:const TextStyle(color:Colors.white70)),const SizedBox(height:20),...units.map((u)=>Card(child:ListTile(title:Text(u["title"]),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>UnitPage(unitId:u["id"],title:u["title"]))))))]));}

class UnitPage extends StatefulWidget{final int unitId;final String title;const UnitPage({required this.unitId,required this.title,super.key});@override State<UnitPage> createState()=>_UnitPageState();}
class _UnitPageState extends State<UnitPage>{List<Lesson> lessons=[];@override void initState(){super.initState();load();}Future<void>load()async{try{final xs=await api.getList("/api/v1/learning/units/${widget.unitId}/lessons");lessons=xs.map((e)=>Lesson.fromJson(e)).toList();await LocalStore.instance.cacheLessons(xs.cast<Map<String,dynamic>>());}catch(_){lessons=(await LocalStore.instance.lessons(widget.unitId)).map((e)=>Lesson.fromJson(e)).toList();}if(mounted)setState((){});}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text(widget.title)),body:ListView.builder(padding:const EdgeInsets.all(18),itemCount:lessons.length,itemBuilder:(_,i){final l=lessons[i];return Card(child:ListTile(leading:CircleAvatar(child:Text("${i+1}")),title:Text(l.title),subtitle:Text(l.summary),trailing:const Icon(Icons.play_circle_outline),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>LessonPage(lessonId:l.id)))));}));
}}

class LessonPage extends StatefulWidget{final int lessonId;const LessonPage({required this.lessonId,super.key});@override State<LessonPage> createState()=>_LessonPageState();}
class _LessonPageState extends State<LessonPage>{Map<String,dynamic>? data;double progress=0;int pos=0;@override void initState(){super.initState();load();}Future<void>load()async{try{data=await api.getMap("/api/v1/learning/lessons/${widget.lessonId}");final p=data!["progress"];if(p!=null){progress=(p["progress"]??0).toDouble();pos=p["last_position"]??0;}}catch(_){ }if(mounted)setState((){});}
 Future<void>save(bool complete)async{await LocalStore.instance.saveProgress(widget.lessonId,complete?1:progress,complete,pos);try{await api.post("/api/v1/learning/progress",{"lesson_id":widget.lessonId,"progress":complete?1:progress,"completed":complete,"last_position":pos});}catch(_){}}
 @override Widget build(BuildContext c){if(data==null)return const Center(child:CircularProgressIndicator());final l=data!["lesson"];final media=(data!["media"] as List);final q=data!["quiz"];return Scaffold(appBar:AppBar(title:Text(l["title"])),body:ListView(padding:const EdgeInsets.all(18),children:[
   Text(l["summary"],style:const TextStyle(fontSize:16,color:Colors.white70)),const SizedBox(height:20),
   ...media.map((m)=>Card(child:ListTile(leading:const Icon(Icons.video_library),title:Text(m["title"]),subtitle:Text("Video • ${m["duration_seconds"]} sec"),trailing:IconButton(icon:const Icon(Icons.download),onPressed:()async{try{final path=await DownloadService().download(m["id"],m["title"],m["url"]);if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text("Downloaded to $path")));}catch(e){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}})))),
   const SizedBox(height:10),Text("Lesson progress: ${(progress*100).round()}%"),Slider(value:progress,onChanged:(v)=>setState(()=>progress=v)),FilledButton(onPressed:()=>save(true),child:const Text("Mark lesson complete")),
   if(q!=null)Card(child:ListTile(leading:const Icon(Icons.quiz),title:Text(q["title"]),subtitle:Text("${(q["questions"] as List).length} questions"),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>QuizPage(quiz:Map<String,dynamic>.from(q))))))
 ]));}
}

class QuizPage extends StatefulWidget{final Map<String,dynamic> quiz;const QuizPage({required this.quiz,super.key});@override State<QuizPage> createState()=>_QuizPageState();}
class _QuizPageState extends State<QuizPage>{final answers=<String,TextEditingController>{};bool submitted=false;Map<String,dynamic>? result;
 @override void initState(){super.initState();for(final q in widget.quiz["questions"])answers["${q["id"]}"]=TextEditingController();}
 Future<void>submit()async{final a={for(final e in answers.entries)e.key:e.value.text};try{result=await api.post("/api/v1/learning/quiz/submit",{"quiz_id":widget.quiz["id"],"answers":a});}catch(_){result={"score":0,"correct":0,"total":answers.length};}setState(()=>submitted=true);}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text(widget.quiz["title"])),body:ListView(padding:const EdgeInsets.all(18),children:[...widget.quiz["questions"].map<Widget>((q)=>Padding(padding:const EdgeInsets.only(bottom:16),child:TextField(controller:answers["${q["id"]}"],decoration:InputDecoration(labelText:q["prompt"])))),FilledButton(onPressed:submitted?null:submit,child:Text(submitted?"Submitted":"Submit quiz")),if(result!=null)Padding(padding:const EdgeInsets.all(18),child:Text("Score: ${((result!["score"] as num)*100).round()}%",style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold))) ]));}

class ProgressPage extends StatefulWidget{@override State<ProgressPage> createState()=>_ProgressPageState();}
class _ProgressPageState extends State<ProgressPage>{List<dynamic> p=[],m=[];@override void initState(){super.initState();load();}Future<void>load()async{try{p=await api.getList("/api/v1/learning/progress");m=await api.getList("/api/v1/learning/mastery");}catch(_){}if(mounted)setState((){});}
 @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(18),children:[const Text("Progress & Mastery",style:TextStyle(fontSize:25,fontWeight:FontWeight.bold)),const SizedBox(height:18),const Text("Lesson progress",style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),...p.map((x)=>ListTile(title:Text("Lesson ${x["lesson_id"]}"),subtitle:LinearProgressIndicator(value:(x["progress"]??0).toDouble()),trailing:Text("${((x["progress"]??0)*100).round()}%"))),const SizedBox(height:18),const Text("Mastery / Weak Areas",style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),...m.map((x)=>ListTile(title:Text(x["topic"]),subtitle:Text("Attempts: ${x["attempts"]}"),trailing:Text("${((x["score"]??0)*100).round()}%"))) ]);}

class DownloadsPage extends StatefulWidget{@override State<DownloadsPage> createState()=>_DownloadsPageState();}
class _DownloadsPageState extends State<DownloadsPage>{List<Map<String,dynamic>> xs=[];@override void initState(){super.initState();load();}Future<void>load()async{xs=await LocalStore.instance.downloads();if(mounted)setState((){});}
 @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(18),children:[const Text("My Downloads",style:TextStyle(fontSize:25,fontWeight:FontWeight.bold)),const SizedBox(height:8),const Text("Downloaded learning media stored on this device.",style:TextStyle(color:Colors.white60)),const SizedBox(height:15),if(xs.isEmpty)const Text("No downloads yet. Download supported lesson media from a lesson."),...xs.map((x)=>Card(child:ListTile(leading:const Icon(Icons.offline_pin),title:Text(x["title"]),subtitle:Text(x["local_path"]),onTap:()=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text("Local file: ${x["local_path"]}"))))) ]);}

class ProfilePage extends StatelessWidget{final UserSession session;const ProfilePage({required this.session,super.key});@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(18),children:[const CircleAvatar(radius:38,child:Icon(Icons.person,size:40)),const SizedBox(height:16),Center(child:Text(session.displayName,style:const TextStyle(fontSize:24,fontWeight:FontWeight.bold))),Center(child:Text(session.email,style:const TextStyle(color:Colors.white60))),const SizedBox(height:24),Card(child:Column(children:[ListTile(leading:const Icon(Icons.security),title:const Text("Security"),subtitle:Text("JWT + RBAC • ${session.roles.join(", ")}")),const ListTile(leading:Icon(Icons.settings),title:Text("Settings"),subtitle:Text("Notifications, offline preferences and account controls"))]))]);}
