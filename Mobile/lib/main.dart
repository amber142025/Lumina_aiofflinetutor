import 'package:flutter/material.dart';

import 'services/api.dart';
import 'services/tutor_service.dart';
import 'data/local_store.dart';
import 'models/models.dart';
import 'services/download_service.dart';

void main() {
  runApp(const LuminaApp());
}

class LuminaApp extends StatelessWidget {
  const LuminaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lumina',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1020),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B7CFF),
          brightness: Brightness.dark,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: LoginPage(),
    );
  }
}

final api = Api();

// ============================================================
// LOGIN
// ============================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final id = TextEditingController();
  final pw = TextEditingController();

  bool hide = true;
  bool busy = false;

  Future<void> login() async {
    setState(() {
      busy = true;
    });

    try {
      final r = await api.post(
        '/api/v1/auth/login',
        {
          'identifier': id.text.trim(),
          'password': pw.text,
        },
        auth: false,
      );

      api.access = r['access_token'];
      api.refresh = r['refresh_token'];

      final u = UserSession.fromJson(r['user']);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => Home(session: u),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  @override
  void dispose() {
    id.dispose();
    pw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 460,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'LUMINA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your learning, without the signal.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 38),
                TextField(
                  controller: id,
                  decoration: const InputDecoration(
                    labelText: 'Username or Email',
                    prefixIcon: Icon(
                      Icons.person_outline,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pw,
                  obscureText: hide,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        hide
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          hide = !hide;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: busy ? null : login,
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Text(
                      busy ? 'Signing in...' : 'Sign in',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'Create account',
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Demo: student / Lumina@123',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// REGISTER
// ============================================================

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final u = TextEditingController();
  final e = TextEditingController();
  final n = TextEditingController();
  final p = TextEditingController();
  final cp = TextEditingController();
  final code = TextEditingController();

  String role = 'student';
  bool hide = true;
  bool busy = false;

  Future<void> reg() async {
    setState(() {
      busy = true;
    });

    try {
      await api.post(
        '/api/v1/auth/register',
        {
          'username': u.text.trim(),
          'email': e.text.trim(),
          'display_name': n.text.trim(),
          'password': p.text,
          'confirm_password': cp.text,
          'role': role,
          'invitation_code': code.text.trim().isEmpty ? null : code.text.trim(),
        },
        auth: false,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registration successful',
            ),
          ),
        );

        Navigator.pop(context);
      }
    } catch (x) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(x.toString()),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  @override
  void dispose() {
    u.dispose();
    e.dispose();
    n.dispose();
    p.dispose();
    cp.dispose();
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Lumina account',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: n,
            decoration: const InputDecoration(
              labelText: 'Full name',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: u,
            decoration: const InputDecoration(
              labelText: 'Username',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: e,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: role,
            items: const [
              DropdownMenuItem(
                value: 'student',
                child: Text('Student'),
              ),
              DropdownMenuItem(
                value: 'teacher',
                child: Text('Teacher'),
              ),
              DropdownMenuItem(
                value: 'parent',
                child: Text('Parent'),
              ),
              DropdownMenuItem(
                value: 'manager',
                child: Text('Manager'),
              ),
              DropdownMenuItem(
                value: 'content_manager',
                child: Text('Content Manager'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  role = value;
                });
              }
            },
            decoration: const InputDecoration(
              labelText: 'Account type',
            ),
          ),
          const SizedBox(height: 12),
          if (role != 'student') ...[
            TextField(
              controller: code,
              decoration: const InputDecoration(
                labelText: 'Organization / Invitation code',
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: p,
            obscureText: hide,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(
                  hide ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    hide = !hide;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Minimum 8 characters • uppercase • lowercase • '
            'number • special character',
            style: TextStyle(
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: cp,
            obscureText: hide,
            decoration: const InputDecoration(
              labelText: 'Confirm password',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: busy ? null : reg,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                busy ? 'Creating account...' : 'Register',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HOME
// ============================================================

class Home extends StatefulWidget {
  final UserSession session;

  const Home({
    required this.session,
    super.key,
  });

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int tab = 0;
  late TutorService tutor;

  @override
  void initState() {
    super.initState();
    tutor = TutorService(api);
  }

  Future<void> logout() async {
    try {
      await api.post(
        '/api/v1/auth/logout',
        {
          'refresh_token': api.refresh ?? '',
        },
      );
    } catch (_) {}

    api.access = null;
    api.refresh = null;

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role =
        widget.session.roles.isEmpty ? 'student' : widget.session.roles.first;
    final pages = role == 'student'
        ? <Widget>[
            Dashboard(session: widget.session, tutor: tutor),
            const Explore(),
            const AssignmentPage(),
            const ProgressPage(),
            ProfilePage(session: widget.session),
          ]
        : <Widget>[
            RoleWorkspace(session: widget.session, role: role),
            ProfilePage(session: widget.session),
          ];
    final destinations = role == 'student'
        ? const <NavigationDestination>[
            NavigationDestination(
                icon: Icon(Icons.auto_awesome), label: 'Today'),
            NavigationDestination(
                icon: Icon(Icons.explore_outlined), label: 'Explore'),
            NavigationDestination(
                icon: Icon(Icons.assignment_outlined), label: 'Tasks'),
            NavigationDestination(
                icon: Icon(Icons.insights_outlined), label: 'Progress'),
            NavigationDestination(
                icon: Icon(Icons.person_outline), label: 'Profile'),
          ]
        : const <NavigationDestination>[
            NavigationDestination(
                icon: Icon(Icons.dashboard_outlined), label: 'Workspace'),
            NavigationDestination(
                icon: Icon(Icons.person_outline), label: 'Profile'),
          ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lumina'),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(
              Icons.logout,
            ),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) {
          setState(() {
            tab = i;
          });
        },
        destinations: destinations,
      ),
    );
  }
}

// ============================================================
// DASHBOARD
// ============================================================

class Dashboard extends StatefulWidget {
  final UserSession session;
  final TutorService tutor;

  const Dashboard({
    required this.session,
    required this.tutor,
    super.key,
  });

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<Map<String, dynamic>> cards = [];
  List<Map<String, dynamic>> metrics = [];
  String? summaryError;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final x = await widget.tutor.cards();
    try {
      final response = await api.getMap('/api/v1/management/dashboard');
      metrics = (response['metrics'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      summaryError = null;
    } catch (_) {
      summaryError = 'Your live learning summary is unavailable right now.';
    }
    if (mounted) {
      setState(() => cards = x);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Good to see you, ${widget.session.displayName}',
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          widget.session.roles.join(' • '),
          style: const TextStyle(
            color: Colors.white60,
          ),
        ),
        const SizedBox(height: 22),
        if (summaryError != null)
          Text(summaryError!,
              style: const TextStyle(color: Colors.orangeAccent)),
        if (metrics.isNotEmpty)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: metrics
                .map((metric) => SizedBox(
                      width: 145,
                      child: Card(
                          child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${metric['value'] ?? 0}',
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(metric['label']?.toString() ?? ''),
                            ]),
                      )),
                    ))
                .toList(),
          ),
        const SizedBox(height: 12),
        const _FeatureCard(
          icon: Icons.explore,
          title: 'Focus Compass',
          body: 'Know what to learn next based on your current learning state.',
        ),
        const _FeatureCard(
          icon: Icons.psychology,
          title: 'Proactive Tutor',
          body:
              'Lumina can notice weak areas, unfinished lessons and upcoming study sessions.',
        ),
        const _FeatureCard(
          icon: Icons.offline_bolt,
          title: 'Offline Mode',
          body:
              'Continue supported lessons, quizzes, progress and local tutor guidance without continuous Internet.',
        ),
        const SizedBox(height: 18),
        const Text(
          'Lumina noticed…',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...cards.map(
          (x) => Card(
            child: ListTile(
              leading: const Icon(
                Icons.auto_awesome,
              ),
              title: Text(
                x['title']?.toString() ?? '',
              ),
              subtitle: Text(
                x['body']?.toString() ?? '',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// FEATURE CARD
// ============================================================

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 32,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Ready-to-use starter learning content keeps Explore useful before the
// backend has been seeded. Real server courses take priority when available.
final List<Course> _luminaStarterCourses = [
  Course(
      id: -1,
      subjectId: -1,
      title: 'Everyday English',
      level: 'Beginner • 10 min',
      description:
          'Build useful vocabulary, practise simple conversations, and check your understanding.'),
  Course(
      id: -2,
      subjectId: -2,
      title: 'Digital Skills & Online Safety',
      level: 'All levels • 8 min',
      description:
          'Learn strong passwords, phishing awareness, and safer everyday technology habits.'),
  Course(
      id: -3,
      subjectId: -3,
      title: 'Study Smarter',
      level: 'All levels • 7 min',
      description:
          'Use active recall, short study sessions, and spaced repetition to remember more.'),
];

class DemoCoursePage extends StatelessWidget {
  final Course course;
  const DemoCoursePage({required this.course, super.key});

  @override
  Widget build(BuildContext context) {
    final lessons = course.id == -1
        ? <Map<String, String>>[
            {
              'title': 'Introduce yourself',
              'body':
                  'A useful introduction is short and clear. Try: “Hello, my name is Alex. I am learning English. Nice to meet you.” Say it aloud, then replace Alex with your own name.'
            },
            {
              'title': 'Everyday phrases',
              'body':
                  'Practise these phrases: “Could you help me, please?”, “I do not understand yet”, and “Could you say that again?” Repeat each phrase three times and use one in a sentence.'
            },
          ]
        : course.id == -2
            ? <Map<String, String>>[
                {
                  'title': 'Spot a phishing message',
                  'body':
                      'Phishing messages pressure you to act quickly, ask for passwords, or send you to unfamiliar links. Check the sender and website address. Never share a one-time verification code.'
                },
                {
                  'title': 'Create a stronger password',
                  'body':
                      'Use a long, unique passphrase for each account. A password manager can help. Turn on multi-factor authentication and never reuse your school password on other websites.'
                },
              ]
            : <Map<String, String>>[
                {
                  'title': 'Active recall',
                  'body':
                      'Close your notes and write down everything you remember. Then check your notes and correct gaps. Trying to retrieve an answer strengthens learning more than rereading alone.'
                },
                {
                  'title': 'Spaced practice',
                  'body':
                      'Review a topic after one day, three days, and one week. Short sessions spread over time usually help you remember longer than one long cram session.'
                },
              ];
    return Scaffold(
      appBar: AppBar(title: Text(course.title)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF5146A5), Color(0xFF176B78)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.auto_awesome, size: 34),
              const SizedBox(height: 12),
              Text(course.level,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(course.description),
              const SizedBox(height: 12),
              const Text('Learn • Practise • Remember',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: 18),
          const Text('Your learning path',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...lessons.asMap().entries.map((entry) => Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${entry.key + 1}')),
                  title: Text(entry.value['title']!),
                  subtitle: const Text('Read, think, and try it yourself'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StarterLessonPage(
                          courseTitle: course.title,
                          lessonTitle: entry.value['title']!,
                          body: entry.value['body']!,
                          quizQuestion: course.id == -1
                              ? 'Which phrase politely asks someone to repeat?'
                              : course.id == -2
                                  ? 'What should you do with an unexpected login link?'
                                  : 'What is active recall?',
                          choices: course.id == -1
                              ? [
                                  'Could you say that again?',
                                  'Go away.',
                                  'I will never ask.'
                                ]
                              : course.id == -2
                                  ? [
                                      'Click quickly',
                                      'Check the sender and link first',
                                      'Share your password'
                                    ]
                                  : [
                                      'Reread only',
                                      'Close notes and recall from memory',
                                      'Study once only'
                                    ],
                          correct: 0 == 1 ? 0 : (course.id == -1 ? 0 : 1),
                        ),
                      )),
                ),
              )),
          const SizedBox(height: 8),
          const Text(
              'This starter course works without a connection. Your server-provided courses appear here when available.',
              style: TextStyle(color: Colors.white60)),
        ],
      ),
    );
  }
}

class StarterLessonPage extends StatefulWidget {
  final String courseTitle, lessonTitle, body, quizQuestion;
  final List<String> choices;
  final int correct;
  const StarterLessonPage(
      {required this.courseTitle,
      required this.lessonTitle,
      required this.body,
      required this.quizQuestion,
      required this.choices,
      required this.correct,
      super.key});

  @override
  State<StarterLessonPage> createState() => _StarterLessonPageState();
}

class _StarterLessonPageState extends State<StarterLessonPage> {
  int? selected;
  bool checked = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.lessonTitle)),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const Row(children: [
            Icon(Icons.menu_book, color: Color(0xFFB7A9FF)),
            SizedBox(width: 8),
            Text('MICRO LESSON',
                style:
                    TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 18),
          Text(widget.lessonTitle,
              style:
                  const TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(widget.body,
                      style: const TextStyle(fontSize: 17, height: 1.55)))),
          const SizedBox(height: 24),
          const Text('Quick knowledge check',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(widget.quizQuestion, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 10),
          ...widget.choices.asMap().entries.map((e) => Card(
                child: RadioListTile<int>(
                  value: e.key,
                  groupValue: selected,
                  title: Text(e.value),
                  onChanged: checked
                      ? null
                      : (value) => setState(() => selected = value),
                ),
              )),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: selected == null || checked
                ? null
                : () => setState(() => checked = true),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Check my answer'),
          ),
          if (checked)
            Card(
              color: selected == widget.correct
                  ? const Color(0xFF174B3D)
                  : const Color(0xFF512D36),
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    selected == widget.correct
                        ? 'Correct! Great work. Explain in your own words why this answer is useful.'
                        : 'Not quite. Review the lesson and try to explain the safer or more effective choice.',
                    style: const TextStyle(fontSize: 16),
                  )),
            ),
          if (checked)
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to learning path'),
            ),
        ]),
      );
}

// ============================================================
// EXPLORE
// ============================================================

class Explore extends StatefulWidget {
  const Explore({super.key});

  @override
  State<Explore> createState() => _ExploreState();
}

class _ExploreState extends State<Explore> {
  List<Course> courses = List<Course>.from(_luminaStarterCourses);
  bool offline = true;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (loading) return;
    setState(() => loading = true);
    try {
      final xs = await api.getList('/api/v1/learning/courses');
      final remote = xs
          .map((e) => Course.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();

      if (remote.isNotEmpty) {
        courses = remote;
        offline = false;
        try {
          await LocalStore.instance.cacheCourses(
            xs.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
          );
        } catch (_) {
          // Keep server courses visible even if local caching fails.
        }
      } else {
        // An empty backend response should never leave learners with a blank page.
        courses = List<Course>.from(_luminaStarterCourses);
        offline = true;
      }
    } catch (_) {
      try {
        final cached = await LocalStore.instance.courses();
        final saved = cached
            .map((e) => Course.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList();
        courses =
            saved.isNotEmpty ? saved : List<Course>.from(_luminaStarterCourses);
      } catch (_) {
        courses = List<Course>.from(_luminaStarterCourses);
      }
      offline = true;
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Explore Learning',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
            ),
            if (offline) const Chip(label: Text('OFFLINE / DEMO')),
          ],
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department,
                    size: 32, color: Color(0xFFFFC857)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Small steps, real progress',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                TextButton(
                  onPressed: loading ? null : load,
                  child: Text(loading ? 'Loading…' : 'Refresh'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          offline
              ? 'Starter lessons are available now. Connect the backend to load your school courses.'
              : 'Choose a course and learn something useful today.',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        ...courses.map((x) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF5146A5),
                  child: Icon(x.id < 0 ? Icons.auto_awesome : Icons.menu_book),
                ),
                title: Text(x.title),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${x.level}\n${x.description}'),
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => x.id < 0
                        ? DemoCoursePage(course: x)
                        : CoursePage(course: x),
                  ),
                ),
              ),
            )),
      ],
    );
  }
}

// ============================================================
// COURSE PAGE
// ============================================================

class CoursePage extends StatefulWidget {
  final Course course;

  const CoursePage({
    required this.course,
    super.key,
  });

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  List<Map<String, dynamic>> units = [];
  bool enrolled = false;
  bool loading = true;
  bool enrolling = false;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      units = (await api.getList(
        '/api/v1/learning/courses/${widget.course.id}/units',
      ))
          .cast<Map<String, dynamic>>();
      final existing = await api.getList('/api/v1/learning/enrollments');
      enrolled = existing
          .any((item) => (item as Map)['course_id'] == widget.course.id);
      error = null;
    } catch (e) {
      error = 'Could not load this course. Check your connection and retry.';
    } finally {
      loading = false;
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> enroll() async {
    if (enrolling) return;
    setState(() => enrolling = true);
    try {
      await api.post('/api/v1/learning/courses/${widget.course.id}/enroll', {});
      if (mounted) {
        setState(() => enrolled = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are enrolled in this course.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not enroll: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => enrolling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.course.title,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            widget.course.description,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          if (!enrolled)
            FilledButton.icon(
              onPressed: enrolling ? null : enroll,
              icon: enrolling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.school_outlined),
              label: Text(enrolling ? 'Enrolling…' : 'Enroll in this course'),
            )
          else
            const Chip(
                avatar: Icon(Icons.check_circle_outline),
                label: Text('Enrolled')),
          const SizedBox(height: 16),
          if (error != null)
            Card(
                child: ListTile(
              title: Text(error!),
              trailing:
                  IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
            )),
          if (loading) const Center(child: CircularProgressIndicator()),
          if (units.isEmpty)
            const Text(
              'Course content is being prepared. Check back soon.',
            ),
          ...units.map(
            (u) => Card(
              child: ListTile(
                title: Text(
                  u['title']?.toString() ?? '',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UnitPage(
                        unitId: u['id'] as int,
                        title: u['title']?.toString() ?? '',
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// UNIT PAGE
// ============================================================

class UnitPage extends StatefulWidget {
  final int unitId;
  final String title;

  const UnitPage({
    required this.unitId,
    required this.title,
    super.key,
  });

  @override
  State<UnitPage> createState() => _UnitPageState();
}

class _UnitPageState extends State<UnitPage> {
  List<Lesson> lessons = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final xs = await api.getList(
        '/api/v1/learning/units/${widget.unitId}/lessons',
      );

      lessons = xs
          .map(
            (e) => Lesson.fromJson(e),
          )
          .toList();

      await LocalStore.instance.cacheLessons(
        xs.cast<Map<String, dynamic>>(),
      );
    } catch (_) {
      lessons = (await LocalStore.instance.lessons(
        widget.unitId,
      ))
          .map(
            (e) => Lesson.fromJson(e),
          )
          .toList();
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: lessons.length,
        itemBuilder: (_, i) {
          final l = lessons[i];

          return Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  '${i + 1}',
                ),
              ),
              title: Text(
                l.title,
              ),
              subtitle: Text(
                l.summary,
              ),
              trailing: const Icon(
                Icons.play_circle_outline,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LessonPage(
                      lessonId: l.id,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// LESSON PAGE
// ============================================================

class LessonPage extends StatefulWidget {
  final int lessonId;

  const LessonPage({
    required this.lessonId,
    super.key,
  });

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  Map<String, dynamic>? data;

  double progress = 0;
  int pos = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      data = await api.getMap(
        '/api/v1/learning/lessons/${widget.lessonId}',
      );

      final p = data?['progress'];

      if (p != null) {
        progress = (p['progress'] ?? 0).toDouble();
        pos = p['last_position'] ?? 0;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> save(bool complete) async {
    await LocalStore.instance.saveProgress(
      widget.lessonId,
      complete ? 1 : progress,
      complete,
      pos,
    );

    try {
      await api.post(
        '/api/v1/learning/progress',
        {
          'lesson_id': widget.lessonId,
          'progress': complete ? 1 : progress,
          'completed': complete,
          'last_position': pos,
        },
      );
    } catch (_) {}
  }

  Future<void> downloadMedia(
    dynamic mediaId,
    String title,
    String url,
  ) async {
    try {
      final path = await DownloadService().download(
        mediaId,
        title,
        url,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Downloaded to $path',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final l = data!['lesson'];
    final media = (data!['media'] as List?) ?? <dynamic>[];
    final q = data!['quiz'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l['title']?.toString() ?? 'Lesson',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            l['summary']?.toString() ?? '',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          ...media.map(
            (m) => Card(
              child: ListTile(
                leading: const Icon(
                  Icons.video_library,
                ),
                title: Text(
                  m['title']?.toString() ?? '',
                ),
                subtitle: Text(
                  'Video • ${m['duration_seconds'] ?? 0} sec',
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.download,
                  ),
                  onPressed: () {
                    downloadMedia(
                      m['id'],
                      m['title']?.toString() ?? 'lesson',
                      m['url']?.toString() ?? '',
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Lesson progress: ${(progress * 100).round()}%',
          ),
          Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: (v) {
              setState(() {
                progress = v;
              });
            },
          ),
          FilledButton(
            onPressed: () => save(true),
            child: const Text(
              'Mark lesson complete',
            ),
          ),
          if (q != null)
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.quiz,
                ),
                title: Text(
                  q['title']?.toString() ?? 'Quiz',
                ),
                subtitle: Text(
                  '${(q['questions'] as List?)?.length ?? 0} questions',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizPage(
                        quiz: Map<String, dynamic>.from(q),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// QUIZ
// ============================================================

class QuizPage extends StatefulWidget {
  final Map<String, dynamic> quiz;

  const QuizPage({
    required this.quiz,
    super.key,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final answers = <String, TextEditingController>{};

  bool submitted = false;
  Map<String, dynamic>? result;

  @override
  void initState() {
    super.initState();

    final questions = (widget.quiz['questions'] as List?) ?? [];

    for (final q in questions) {
      answers['${q['id']}'] = TextEditingController();
    }
  }

  Future<void> submit() async {
    final a = <String, String>{
      for (final e in answers.entries) e.key: e.value.text,
    };

    try {
      result = await api.post(
        '/api/v1/learning/quiz/submit',
        {
          'quiz_id': widget.quiz['id'],
          'answers': a,
        },
      );
    } catch (_) {
      result = {
        'score': 0,
        'correct': 0,
        'total': answers.length,
      };
    }

    if (mounted) {
      setState(() {
        submitted = true;
      });
    }
  }

  @override
  void dispose() {
    for (final controller in answers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questions = (widget.quiz['questions'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.quiz['title']?.toString() ?? 'Quiz',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          ...questions.map(
            (q) {
              final key = '${q['id']}';

              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 16,
                ),
                child: TextField(
                  controller: answers[key],
                  decoration: InputDecoration(
                    labelText: q['prompt']?.toString() ?? '',
                  ),
                ),
              );
            },
          ),
          FilledButton(
            onPressed: submitted ? null : submit,
            child: Text(
              submitted ? 'Submitted' : 'Submit quiz',
            ),
          ),
          if (result != null)
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'Score: ${(((result!['score'] ?? 0) as num) * 100).round()}%',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// ASSIGNMENTS
// ============================================================

class AssignmentPage extends StatefulWidget {
  const AssignmentPage({super.key});

  @override
  State<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends State<AssignmentPage> {
  List<Map<String, dynamic>> assignments = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      assignments = (await api.getList('/api/v1/learning/assignments'))
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (e) {
      error = 'Could not load assignments. Check your connection and retry.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text('Assignments',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Work shared with you through your enrolled courses.',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 14),
            if (loading)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )),
            if (error != null)
              Card(
                  child: ListTile(
                title: Text(error!),
                trailing: IconButton(
                    onPressed: load, icon: const Icon(Icons.refresh)),
              )),
            if (!loading && error == null && assignments.isEmpty)
              const Card(
                  child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                    'No assignments yet. Enroll in a course to receive work from your teacher.'),
              )),
            ...assignments.map((assignment) {
              final submission = assignment['submission'] as Map?;
              return Card(
                  child: ListTile(
                leading: CircleAvatar(
                  child: Icon(submission == null
                      ? Icons.assignment_outlined
                      : Icons.task_alt),
                ),
                title: Text(assignment['title']?.toString() ?? 'Assignment'),
                subtitle: Text(
                  '${assignment['course_title'] ?? 'Course'}'
                  '${assignment['due_at'] == null ? '' : ' • Due ${assignment['due_at']}'}'
                  '${submission == null ? ' • Not submitted' : ' • Submitted'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AssignmentDetailPage(assignment: assignment),
                      ));
                  if (mounted) load();
                },
              ));
            }),
          ],
        ),
      );
}

class AssignmentDetailPage extends StatefulWidget {
  final Map<String, dynamic> assignment;
  const AssignmentDetailPage({required this.assignment, super.key});

  @override
  State<AssignmentDetailPage> createState() => _AssignmentDetailPageState();
}

class _AssignmentDetailPageState extends State<AssignmentDetailPage> {
  late final TextEditingController response;
  bool saving = false;
  late Map<String, dynamic>? submission;

  @override
  void initState() {
    super.initState();
    submission = widget.assignment['submission'] == null
        ? null
        : Map<String, dynamic>.from(widget.assignment['submission'] as Map);
    response =
        TextEditingController(text: submission?['response']?.toString() ?? '');
  }

  @override
  void dispose() {
    response.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (response.text.trim().isEmpty || saving) return;
    setState(() => saving = true);
    try {
      submission = await api.post(
        '/api/v1/learning/assignments/${widget.assignment['id']}/submit',
        {'response': response.text.trim()},
      );
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your work was submitted.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title:
                Text(widget.assignment['title']?.toString() ?? 'Assignment')),
        body: ListView(padding: const EdgeInsets.all(18), children: [
          Chip(
              label: Text(
                  widget.assignment['course_title']?.toString() ?? 'Course')),
          if (widget.assignment['due_at'] != null)
            Text('Due ${widget.assignment['due_at']}'),
          const SizedBox(height: 14),
          Text(widget.assignment['description']?.toString() ?? '',
              style: const TextStyle(fontSize: 17, height: 1.45)),
          const SizedBox(height: 22),
          TextField(
            controller: response,
            minLines: 5,
            maxLines: 12,
            maxLength: 10000,
            decoration: const InputDecoration(
              labelText: 'Your response',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: saving ? null : submit,
            icon: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_outlined),
            label: Text(saving
                ? 'Submitting…'
                : submission == null
                    ? 'Submit assignment'
                    : 'Update submission'),
          ),
          if (submission?['grade'] != null) ...[
            const SizedBox(height: 18),
            Card(
                child: ListTile(
              leading: const Icon(Icons.grade_outlined),
              title: Text('Grade: ${submission!['grade']} / 100'),
              subtitle: Text(submission?['feedback']?.toString() ?? ''),
            )),
          ],
          if (submission != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text('Last submitted ${submission?['submitted_at'] ?? ''}',
                  style: const TextStyle(color: Colors.white60)),
            ),
        ]),
      );
}

// ============================================================
// PROGRESS
// ============================================================

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  List<dynamic> p = [];
  List<dynamic> m = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      p = await api.getList(
        '/api/v1/learning/progress',
      );

      m = await api.getList(
        '/api/v1/learning/mastery',
      );
    } catch (_) {}

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'Progress & Mastery',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Lesson progress',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (p.isEmpty)
          const Text(
            'No lesson progress yet.',
          ),
        ...p.map(
          (x) {
            final value =
                ((x['progress'] ?? 0) as num).toDouble().clamp(0.0, 1.0);

            return ListTile(
              title: Text(
                'Lesson ${x['lesson_id']}',
              ),
              subtitle: LinearProgressIndicator(
                value: value,
              ),
              trailing: Text(
                '${(value * 100).round()}%',
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        const Text(
          'Mastery / Weak Areas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (m.isEmpty)
          const Text(
            'No mastery data yet.',
          ),
        ...m.map(
          (x) {
            final score = ((x['score'] ?? 0) as num).toDouble();

            return ListTile(
              title: Text(
                x['topic']?.toString() ?? '',
              ),
              subtitle: Text(
                'Attempts: ${x['attempts'] ?? 0}',
              ),
              trailing: Text(
                '${(score * 100).round()}%',
              ),
            );
          },
        ),
      ],
    );
  }
}

// ============================================================
// DOWNLOADS
// ============================================================

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  List<Map<String, dynamic>> xs = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      xs = await LocalStore.instance.downloads();
    } catch (_) {
      xs = [];
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'My Downloads',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Downloaded learning media stored on this device.',
          style: TextStyle(
            color: Colors.white60,
          ),
        ),
        const SizedBox(height: 15),
        if (xs.isEmpty)
          const Text(
            'No downloads yet. Download supported lesson media from a lesson.',
          ),
        ...xs.map(
          (x) => Card(
            child: ListTile(
              leading: const Icon(
                Icons.offline_pin,
              ),
              title: Text(
                x['title']?.toString() ?? '',
              ),
              subtitle: Text(
                x['local_path']?.toString() ?? '',
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Local file: ${x['local_path']}',
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PROFILE
// ============================================================

class ProfilePage extends StatelessWidget {
  final UserSession session;

  const ProfilePage({
    required this.session,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const CircleAvatar(
          radius: 38,
          child: Icon(
            Icons.person,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            session.displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            session.email,
            style: const TextStyle(
              color: Colors.white60,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              subtitle:
                  const Text('Study reminders and role-specific preferences'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsPage(session: session),
                  )),
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('My downloads'),
              subtitle:
                  const Text('Manage learning media saved on this device'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('My downloads')),
                      body: DownloadsPage(),
                    ),
                  )),
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Security'),
              subtitle: Text('Protected account • ${session.roles.join(", ")}'),
            ),
          ]),
        ),
      ],
    );
  }
}

class SettingsPage extends StatefulWidget {
  final UserSession session;
  const SettingsPage({required this.session, super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, dynamic>? settings;
  bool loading = true;
  bool saving = false;
  String? error;

  static const rolePreferenceLabels = <String, String>{
    'student': 'Study reminder updates',
    'teacher': 'Assignment submission updates',
    'parent': 'Learner progress updates',
    'manager': 'Platform activity updates',
    'content_manager': 'Course review updates',
    'admin': 'Security updates',
  };
  static const rolePreferenceKeys = <String, String>{
    'student': 'study_reminder_updates',
    'teacher': 'assignment_updates',
    'parent': 'learner_progress_updates',
    'manager': 'platform_activity_updates',
    'content_manager': 'course_review_updates',
    'admin': 'security_updates',
  };

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      settings = await api.getMap('/api/v1/auth/settings');
    } catch (_) {
      error =
          'Could not load your saved settings. Check your connection and try again.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> savePreference(String key, bool value,
      {bool roleSpecific = false}) async {
    if (settings == null || saving) return;
    final previous = Map<String, dynamic>.from(settings!);
    setState(() {
      saving = true;
      if (roleSpecific) {
        final roleSettings = Map<String, dynamic>.from(
          settings!['role_notifications'] as Map? ?? const {},
        );
        roleSettings[key] = value;
        settings!['role_notifications'] = roleSettings;
      } else {
        settings![key] = value;
      }
    });
    try {
      final body = roleSpecific
          ? {
              'role_notifications': Map<String, dynamic>.from(
                  settings!['role_notifications'] as Map)
            }
          : {key: value};
      settings = await api.put('/api/v1/auth/settings', body);
    } catch (e) {
      settings = previous;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Settings were not saved: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(error!, textAlign: TextAlign.center),
                  TextButton.icon(
                      onPressed: load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again')),
                ]))
              : ListView(padding: const EdgeInsets.all(18), children: [
                  Text('Account preferences',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                    'Changes are saved to your account and will be available when you sign in on another device.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Card(
                      child: Column(children: [
                    SwitchListTile(
                      title: const Text('Study reminders'),
                      subtitle: const Text(
                          'Allow study reminder preferences for your account'),
                      value: settings!['study_reminders'] == true,
                      onChanged: saving
                          ? null
                          : (v) => savePreference('study_reminders', v),
                    ),
                    SwitchListTile(
                      title: const Text('Weekly progress summary'),
                      subtitle: const Text(
                          'Include a weekly learning progress summary'),
                      value: settings!['weekly_summary'] == true,
                      onChanged: saving
                          ? null
                          : (v) => savePreference('weekly_summary', v),
                    ),
                  ])),
                  const SizedBox(height: 22),
                  Text('Role preferences',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Card(
                      child: Column(children: [
                    for (final role in widget.session.roles)
                      if (rolePreferenceLabels.containsKey(role))
                        SwitchListTile(
                          title: Text(rolePreferenceLabels[role]!),
                          value: (settings!['role_notifications']
                                  as Map?)?[rolePreferenceKeys[role]] ==
                              true,
                          onChanged: saving
                              ? null
                              : (v) => savePreference(
                                  rolePreferenceKeys[role]!, v,
                                  roleSpecific: true),
                        ),
                  ])),
                  if (saving)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: LinearProgressIndicator(),
                    ),
                ]),
    );
  }
}

// ============================================================
// ROLE-SPECIFIC WORKSPACES
// ============================================================

class RoleWorkspace extends StatefulWidget {
  final UserSession session;
  final String role;
  const RoleWorkspace({super.key, required this.session, required this.role});

  @override
  State<RoleWorkspace> createState() => _RoleWorkspaceState();
}

class _RoleWorkspaceState extends State<RoleWorkspace> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> records = [];
  List<Map<String, dynamic>> metrics = [];
  String? dashboardError;

  String get title {
    switch (widget.role) {
      case 'teacher':
        return 'Teacher Workspace';
      case 'parent':
        return 'Parent Centre';
      case 'manager':
        return 'Management Overview';
      case 'content_manager':
        return 'Content Studio';
      case 'admin':
        return 'Administration';
      default:
        return 'Learning Workspace';
    }
  }

  String get description {
    switch (widget.role) {
      case 'teacher':
        return 'Manage your teaching workload and assignments.';
      case 'parent':
        return 'Review learning activity and keep study routines visible.';
      case 'manager':
        return 'Review platform users and operational activity.';
      case 'content_manager':
        return 'Review learning courses and publishing inventory.';
      case 'admin':
        return 'Review users and oversee access to the platform.';
      default:
        return 'Your role-based Lumina workspace.';
    }
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      String endpoint;
      if (widget.role == 'teacher') {
        endpoint = '/api/v1/management/teacher/assignments';
      } else if (widget.role == 'manager' || widget.role == 'admin') {
        endpoint = '/api/v1/management/users';
      } else if (widget.role == 'content_manager') {
        endpoint = '/api/v1/management/courses';
      } else if (widget.role == 'parent') {
        endpoint = '/api/v1/management/parent/children';
      } else if (widget.role == 'student') {
        endpoint = '/api/v1/learning/enrollments';
      } else {
        endpoint = '/api/v1/management/schedule';
      }
      records = (await api.getList(endpoint))
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      error = null;
    } catch (_) {
      error =
          'Could not load live workspace data. Check your connection and role permissions, then retry.';
      records = [];
    }
    try {
      final response = await api.getMap('/api/v1/management/dashboard');
      metrics = (response['metrics'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      dashboardError = null;
    } catch (_) {
      metrics = [];
      dashboardError = 'Summary metrics are currently unavailable.';
    }
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> createCourse() async {
    try {
      final subjectRows = await api.getList('/api/v1/learning/subjects');
      final subjects = subjectRows
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      if (!mounted) return;
      if (subjects.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Add a subject before creating a course.')),
        );
        return;
      }
      final body = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => CreateCourseDialog(subjects: subjects),
      );
      if (body == null) return;
      await api.post('/api/v1/management/courses', body);
      await load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Course published with its first lesson and quiz.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Course could not be created: $e')),
        );
      }
    }
  }

  Future<void> createAssignment() async {
    try {
      final rows = await api.getList('/api/v1/learning/courses');
      final courses =
          rows.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      if (!mounted) return;
      if (courses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('There are no published courses to assign yet.')),
        );
        return;
      }
      final body = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => CreateAssignmentDialog(courses: courses),
      );
      if (body == null) return;
      await api.post('/api/v1/management/teacher/assignments', body);
      await load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Assignment shared with students enrolled in that course.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Assignment could not be created: $e')),
        );
      }
    }
  }

  Future<void> linkLearner() async {
    try {
      final rows = await api.getList('/api/v1/management/users');
      final users =
          rows.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      final parents = users
          .where(
              (account) => (account['roles'] as List? ?? []).contains('parent'))
          .toList();
      final students = users
          .where((account) =>
              (account['roles'] as List? ?? []).contains('student'))
          .toList();
      if (!mounted) return;
      if (parents.isEmpty || students.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('You need a parent account and a student account.')),
        );
        return;
      }
      final body = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => LinkLearnerDialog(
          parents: parents,
          students: students,
        ),
      );
      if (body == null) return;
      await api.post('/api/v1/management/parent/children', body);
      await load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Learner linked to parent account.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Learner could not be linked: $e')),
        );
      }
    }
  }

  IconData get roleIcon {
    switch (widget.role) {
      case 'teacher':
        return Icons.cast_for_education;
      case 'parent':
        return Icons.family_restroom;
      case 'manager':
        return Icons.analytics_outlined;
      case 'content_manager':
        return Icons.library_books_outlined;
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.dashboard_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF27264F), Color(0xFF151D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(roleIcon, size: 34, color: const Color(0xFFC9BEFF)),
                const SizedBox(height: 18),
                Text(title,
                    style: const TextStyle(
                        fontSize: 25, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Welcome, ${widget.session.displayName}',
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(description,
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (dashboardError != null)
            Text(dashboardError!,
                style: const TextStyle(color: Colors.orangeAccent)),
          if (metrics.isNotEmpty)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: metrics
                  .map((metric) => SizedBox(
                        width: 145,
                        child: Card(
                            child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${metric['value'] ?? 0}',
                                    style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(metric['label']?.toString() ?? ''),
                              ]),
                        )),
                      ))
                  .toList(),
            ),
          if (widget.role == 'teacher')
            FilledButton.icon(
                onPressed: loading ? null : createAssignment,
                icon: const Icon(Icons.add),
                label: const Text('Create assignment'))
          else if (widget.role == 'content_manager')
            FilledButton.icon(
                onPressed: loading ? null : createCourse,
                icon: const Icon(Icons.add),
                label: const Text('Create course'))
          else if (widget.role == 'manager' || widget.role == 'admin')
            FilledButton.icon(
                onPressed: loading ? null : linkLearner,
                icon: const Icon(Icons.family_restroom),
                label: const Text('Link learner to parent')),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: Text(
                      widget.role == 'teacher'
                          ? 'My assignments'
                          : widget.role == 'parent'
                              ? 'Linked learners'
                              : widget.role == 'content_manager'
                                  ? 'Course inventory'
                                  : widget.role == 'student'
                                      ? 'My courses'
                                      : 'User records',
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.bold))),
              IconButton(
                  onPressed: loading ? null : load,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh'),
            ],
          ),
          if (loading)
            const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()))
          else if (error != null)
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(error!),
                          const SizedBox(height: 8),
                          TextButton.icon(
                              onPressed: load,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try again'))
                        ])))
          else if (records.isEmpty)
            const Card(
                child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                        'No records available yet. This is an empty state, not a system error.')))
          else
            ...records.map((item) {
              final name = (item['display_name'] ??
                      item['title'] ??
                      item['name'] ??
                      item['event_type'] ??
                      'Record')
                  .toString();
              final detail = widget.role == 'manager' || widget.role == 'admin'
                  ? '${item['email'] ?? ''}  •  ${(item['roles'] as List? ?? []).join(', ')}  •  ${item['active'] == false ? 'Inactive' : 'Active'}'
                  : widget.role == 'teacher'
                      ? '${item['course_title'] ?? 'Course not linked'} • ${item['submission_count'] ?? 0} submissions'
                      : widget.role == 'content_manager'
                          ? '${item['level'] ?? ''} • ${item['published'] == true ? 'Published' : 'Draft'}'
                          : widget.role == 'parent'
                              ? '${item['course_count'] ?? 0} courses • ${item['completed_lessons'] ?? 0} lessons completed'
                              : widget.role == 'student'
                                  ? 'Enrolled learning course'
                                  : '${item['start_at'] ?? ''}';
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                      child: Icon(widget.role == 'teacher'
                          ? Icons.assignment_outlined
                          : widget.role == 'content_manager'
                              ? Icons.menu_book_outlined
                              : widget.role == 'parent'
                                  ? Icons.child_care_outlined
                                  : Icons.person_outline)),
                  title: Text(name),
                  subtitle: detail.trim().isEmpty ? null : Text(detail),
                  trailing: widget.role == 'manager' || widget.role == 'admin'
                      ? Icon(item['active'] == false
                          ? Icons.block
                          : Icons.check_circle_outline)
                      : widget.role == 'teacher'
                          ? const Icon(Icons.chevron_right)
                          : null,
                  onTap: widget.role == 'teacher'
                      ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TeacherSubmissionsPage(assignment: item),
                          ))
                      : null,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class CreateCourseDialog extends StatefulWidget {
  final List<Map<String, dynamic>> subjects;
  const CreateCourseDialog({required this.subjects, super.key});

  @override
  State<CreateCourseDialog> createState() => _CreateCourseDialogState();
}

class _CreateCourseDialogState extends State<CreateCourseDialog> {
  final formKey = GlobalKey<FormState>();
  final title = TextEditingController();
  final level = TextEditingController(text: 'Beginner');
  final description = TextEditingController();
  final unitTitle = TextEditingController(text: 'Unit 1');
  final lessonTitle = TextEditingController();
  final lessonSummary = TextEditingController();
  final question = TextEditingController();
  final answer = TextEditingController();
  late int subjectId = (widget.subjects.first['id'] as num).toInt();

  @override
  void dispose() {
    title.dispose();
    level.dispose();
    description.dispose();
    unitTitle.dispose();
    lessonTitle.dispose();
    lessonSummary.dispose();
    question.dispose();
    answer.dispose();
    super.dispose();
  }

  String? requiredText(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Create a course'),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<int>(
                initialValue: subjectId,
                decoration: const InputDecoration(labelText: 'Subject'),
                items: widget.subjects
                    .map((subject) => DropdownMenuItem(
                          value: (subject['id'] as num).toInt(),
                          child: Text(subject['name']?.toString() ?? 'Subject'),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => subjectId = value!),
              ),
              TextFormField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Course title'),
                  validator: requiredText),
              TextFormField(
                  controller: level,
                  decoration: const InputDecoration(labelText: 'Level'),
                  validator: requiredText),
              TextFormField(
                  controller: description,
                  decoration:
                      const InputDecoration(labelText: 'Course description'),
                  minLines: 2,
                  maxLines: 4,
                  validator: requiredText),
              const Divider(height: 28),
              TextFormField(
                  controller: unitTitle,
                  decoration: const InputDecoration(labelText: 'First unit'),
                  validator: requiredText),
              TextFormField(
                  controller: lessonTitle,
                  decoration: const InputDecoration(labelText: 'First lesson'),
                  validator: requiredText),
              TextFormField(
                  controller: lessonSummary,
                  decoration:
                      const InputDecoration(labelText: 'Lesson content'),
                  minLines: 2,
                  maxLines: 5,
                  validator: requiredText),
              const Divider(height: 28),
              TextFormField(
                  controller: question,
                  decoration:
                      const InputDecoration(labelText: 'Quick-check question'),
                  minLines: 2,
                  maxLines: 4,
                  validator: requiredText),
              TextFormField(
                  controller: answer,
                  decoration:
                      const InputDecoration(labelText: 'Expected answer'),
                  validator: requiredText),
              const SizedBox(height: 10),
              const Text(
                  'The course will publish with one unit, lesson, and auto-graded quiz. More content can be added in a later edit.',
                  style: TextStyle(color: Colors.white60)),
            ])),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(context, <String, dynamic>{
                'subject_id': subjectId,
                'title': title.text.trim(),
                'level': level.text.trim(),
                'description': description.text.trim(),
                'units': [
                  {
                    'title': unitTitle.text.trim(),
                    'lessons': [
                      {
                        'title': lessonTitle.text.trim(),
                        'summary': lessonSummary.text.trim(),
                        'quiz': {
                          'title': '${lessonTitle.text.trim()} Quick Check',
                          'difficulty': 'adaptive',
                          'questions': [
                            {
                              'prompt': question.text.trim(),
                              'answer': answer.text.trim(),
                              'explanation': '',
                            }
                          ],
                        },
                      }
                    ],
                  }
                ],
              });
            },
            child: const Text('Publish course'),
          ),
        ],
      );
}

class LinkLearnerDialog extends StatefulWidget {
  final List<Map<String, dynamic>> parents;
  final List<Map<String, dynamic>> students;
  const LinkLearnerDialog({
    required this.parents,
    required this.students,
    super.key,
  });

  @override
  State<LinkLearnerDialog> createState() => _LinkLearnerDialogState();
}

class _LinkLearnerDialogState extends State<LinkLearnerDialog> {
  late int parentId = (widget.parents.first['id'] as num).toInt();
  late int childId = (widget.students.first['id'] as num).toInt();

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Link learner to parent'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<int>(
            initialValue: parentId,
            decoration: const InputDecoration(labelText: 'Parent'),
            items: widget.parents
                .map((account) => DropdownMenuItem(
                      value: (account['id'] as num).toInt(),
                      child: Text(account['display_name']?.toString() ??
                          account['username']?.toString() ??
                          'Parent'),
                    ))
                .toList(),
            onChanged: (value) => setState(() => parentId = value!),
          ),
          DropdownButtonFormField<int>(
            initialValue: childId,
            decoration: const InputDecoration(labelText: 'Student'),
            items: widget.students
                .map((account) => DropdownMenuItem(
                      value: (account['id'] as num).toInt(),
                      child: Text(account['display_name']?.toString() ??
                          account['username']?.toString() ??
                          'Student'),
                    ))
                .toList(),
            onChanged: (value) => setState(() => childId = value!),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'parent_id': parentId,
              'child_id': childId,
            }),
            child: const Text('Link accounts'),
          ),
        ],
      );
}

class CreateAssignmentDialog extends StatefulWidget {
  final List<Map<String, dynamic>> courses;
  const CreateAssignmentDialog({required this.courses, super.key});

  @override
  State<CreateAssignmentDialog> createState() => _CreateAssignmentDialogState();
}

class _CreateAssignmentDialogState extends State<CreateAssignmentDialog> {
  final formKey = GlobalKey<FormState>();
  final title = TextEditingController();
  final description = TextEditingController();
  final dueAt = TextEditingController();
  late int courseId = (widget.courses.first['id'] as num).toInt();

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    dueAt.dispose();
    super.dispose();
  }

  String? requiredText(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Create assignment'),
        content: SizedBox(
          width: 460,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<int>(
                initialValue: courseId,
                decoration: const InputDecoration(labelText: 'Course'),
                items: widget.courses
                    .map((course) => DropdownMenuItem(
                          value: (course['id'] as num).toInt(),
                          child: Text(course['title']?.toString() ?? 'Course'),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => courseId = value!),
              ),
              TextFormField(
                  controller: title,
                  decoration:
                      const InputDecoration(labelText: 'Assignment title'),
                  validator: requiredText),
              TextFormField(
                  controller: description,
                  decoration: const InputDecoration(labelText: 'Instructions'),
                  minLines: 3,
                  maxLines: 5,
                  validator: requiredText),
              TextFormField(
                controller: dueAt,
                decoration: const InputDecoration(
                    labelText: 'Due date (optional)',
                    hintText: '2026-12-31T23:59:00'),
                validator: (value) => value == null ||
                        value.trim().isEmpty ||
                        DateTime.tryParse(value.trim()) != null
                    ? null
                    : 'Use a valid date and time',
              ),
            ])),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(context, <String, dynamic>{
                'course_id': courseId,
                'title': title.text.trim(),
                'description': description.text.trim(),
                'due_at': dueAt.text.trim().isEmpty
                    ? null
                    : DateTime.parse(dueAt.text.trim())
                        .toUtc()
                        .toIso8601String(),
              });
            },
            child: const Text('Share assignment'),
          ),
        ],
      );
}

class TeacherSubmissionsPage extends StatefulWidget {
  final Map<String, dynamic> assignment;
  const TeacherSubmissionsPage({required this.assignment, super.key});

  @override
  State<TeacherSubmissionsPage> createState() => _TeacherSubmissionsPageState();
}

class _TeacherSubmissionsPageState extends State<TeacherSubmissionsPage> {
  List<Map<String, dynamic>> submissions = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      submissions = (await api.getList(
        '/api/v1/management/teacher/assignments/${widget.assignment['id']}/submissions',
      ))
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      error = 'Could not load student submissions. Please retry.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> grade(Map<String, dynamic> submission) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => GradeSubmissionDialog(submission: submission),
    );
    if (result == null) return;
    try {
      await api.patch(
        '/api/v1/management/teacher/assignments/${widget.assignment['id']}/submissions/${submission['id']}',
        result,
      );
      await load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Grade could not be saved: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Student submissions')),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(
                    child: TextButton.icon(
                        onPressed: load,
                        icon: const Icon(Icons.refresh),
                        label: Text(error!)))
                : submissions.isEmpty
                    ? const Center(child: Text('No submissions yet.'))
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: submissions
                            .map((submission) => Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              submission['student_name']
                                                      ?.toString() ??
                                                  'Student',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 17)),
                                          const SizedBox(height: 4),
                                          Text(
                                              'Submitted ${submission['submitted_at'] ?? ''}',
                                              style: const TextStyle(
                                                  color: Colors.white60)),
                                          const SizedBox(height: 12),
                                          Text(submission['response']
                                                  ?.toString() ??
                                              ''),
                                          if (submission['grade'] != null) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                                'Grade: ${submission['grade']} / 100'),
                                            if ((submission['feedback']
                                                        ?.toString() ??
                                                    '')
                                                .isNotEmpty)
                                              Text(
                                                  'Feedback: ${submission['feedback']}'),
                                          ],
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton.icon(
                                              onPressed: () =>
                                                  grade(submission),
                                              icon: const Icon(
                                                  Icons.rate_review_outlined),
                                              label: Text(
                                                  submission['grade'] == null
                                                      ? 'Grade'
                                                      : 'Update grade'),
                                            ),
                                          ),
                                        ]),
                                  ),
                                ))
                            .toList()),
      );
}

class GradeSubmissionDialog extends StatefulWidget {
  final Map<String, dynamic> submission;
  const GradeSubmissionDialog({required this.submission, super.key});

  @override
  State<GradeSubmissionDialog> createState() => _GradeSubmissionDialogState();
}

class _GradeSubmissionDialogState extends State<GradeSubmissionDialog> {
  late final TextEditingController grade = TextEditingController(
    text: widget.submission['grade']?.toString() ?? '',
  );
  late final TextEditingController feedback = TextEditingController(
    text: widget.submission['feedback']?.toString() ?? '',
  );

  @override
  void dispose() {
    grade.dispose();
    feedback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Review submission'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: grade,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Grade (0–100)'),
          ),
          TextField(
            controller: feedback,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Feedback'),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(grade.text.trim());
              if (value == null || value < 0 || value > 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Enter a grade between 0 and 100.')),
                );
                return;
              }
              Navigator.pop(
                  context, {'grade': value, 'feedback': feedback.text.trim()});
            },
            child: const Text('Save grade'),
          ),
        ],
      );
}
