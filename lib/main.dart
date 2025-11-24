import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart'; // Ejecuta: flutterfire configure
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ======================== COLORES GLOBALES ========================

const kDeepBlue = Color(0xFF0F3A63);
const kAccentYellow = Color(0xFFF0B429);
const kLogoOrange = Color(0xFFFF8A3D);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const MetroManagerApp());
}

/// ======================== MODELOS Y REPOSITORIOS ========================

class AppUser {
  final String role;
  String nombre;
  String apellido;
  final String email;
  final String password;
  final String campoExtra;
  String cedula;
  String bio;

  AppUser({
    required this.role,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.password,
    required this.campoExtra,
    this.cedula = '',
    this.bio = '',
  });
}

class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> exists(String email) async {
    // Some firebase_auth versions do not expose fetchSignInMethodsForEmail.
    // To avoid depending on a method that may not exist in the SDK, return false here
    // and let register(...) handle duplicate-email errors returned by Firebase.
    return false;
  }

  Future<bool> register(AppUser user) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: user.email.trim(),
        password: user.password,
      );
      await _auth.currentUser?.updateDisplayName(
        '${user.nombre} ${user.apellido}',
      );
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase registration error: ${e.code} - ${e.message}');
      return false;
    }
  }

  Future<AppUser?> login(String email, String password) async {
    if (!_isValidEmail(email)) {
      debugPrint('Email format invalid');
      return null;
    }

    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        debugPrint('Login successful but user is null');
        return null;
      }

      return AppUser(
        role: 'estudiante',
        nombre: credential.user!.displayName?.split(' ').first ?? 'Usuario',
        apellido:
            credential.user!.displayName?.split(' ').skip(1).join(' ') ?? '',
        email: credential.user!.email ?? email.trim(),
        password: password,
        campoExtra: '',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        debugPrint('User not found');
      } else if (e.code == 'wrong-password') {
        debugPrint('Wrong password');
      } else if (e.code == 'invalid-credential') {
        debugPrint(
          'Invalid credentials - user may not exist or password is wrong',
        );
      } else if (e.code == 'invalid-email') {
        debugPrint('Invalid email format');
      } else {
        debugPrint('Firebase login error: ${e.code} - ${e.message}');
      }
      return null;
    } catch (e) {
      debugPrint('Unexpected login error: $e');
      return null;
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  List<AppUser> get students => [];
  List<AppUser> get professors => [];
}

class ProjectTask {
  final String id;
  final String title;
  bool completed;

  ProjectTask({required this.id, required this.title, this.completed = false});

  ProjectTask copy() => ProjectTask(id: id, title: title, completed: completed);
}

class Project {
  final String id;
  final String name;
  final String course;
  final String description;
  final List<ProjectTask> tasks;

  Project({
    required this.id,
    required this.name,
    required this.course,
    required this.description,
    required this.tasks,
  });
}

class StudentProjectData {
  final Project project;
  final List<ProjectTask> tasks;

  StudentProjectData({required this.project, required this.tasks});

  double get progress {
    if (tasks.isEmpty) return 0;
    final done = tasks.where((t) => t.completed).length;
    return done / tasks.length;
  }
}

class ProjectRepository {
  ProjectRepository._();
  static final ProjectRepository instance = ProjectRepository._();

  final List<Project> allProjects = [];
  final Map<String, List<StudentProjectData>> _studentProjects = {};
  final Map<String, List<Project>> _studentRequests = {};

  List<StudentProjectData> getStudentProjects(String email) {
    return _studentProjects[email.toLowerCase().trim()] ??
        <StudentProjectData>[];
  }

  List<Project> getStudentRequests(String email) {
    return _studentRequests[email.toLowerCase().trim()] ?? <Project>[];
  }

  List<Project> getAvailableProjectsForStudent(String email) {
    final key = email.toLowerCase().trim();
    final current = _studentProjects[key] ?? <StudentProjectData>[];
    final subscribedIds = current.map((sp) => sp.project.id).toSet();
    final requested = _studentRequests[key] ?? <Project>[];
    final requestedIds = requested.map((p) => p.id).toSet();
    return allProjects
        .where(
          (p) => !subscribedIds.contains(p.id) && !requestedIds.contains(p.id),
        )
        .toList();
  }

  void subscribeStudentToProject(String email, Project project) {
    final key = email.toLowerCase().trim();
    final list = _studentProjects.putIfAbsent(
      key,
      () => <StudentProjectData>[],
    );
    final already = list.any((sp) => sp.project.id == project.id);
    if (already) return;
    list.add(
      StudentProjectData(
        project: project,
        tasks: project.tasks.map((t) => t.copy()).toList(),
      ),
    );
  }

  void updateTaskStatus(String email, String pid, String tid, bool completed) {
    final list = _studentProjects[email.toLowerCase().trim()];
    if (list == null) return;
    for (final sp in list) {
      if (sp.project.id == pid) {
        for (final t in sp.tasks) {
          if (t.id == tid) {
            t.completed = completed;
            return;
          }
        }
      }
    }
  }

  void addRequestForStudent(String email, Project project) {
    final key = email.toLowerCase().trim();
    final list = _studentRequests.putIfAbsent(key, () => <Project>[]);
    final already = list.any((p) => p.id == project.id);
    if (!already) list.add(project);
  }

  void acceptRequest(String email, Project project) {
    final key = email.toLowerCase().trim();
    final list = _studentRequests[key];
    list?.removeWhere((p) => p.id == project.id);
    subscribeStudentToProject(email, project);
  }

  void rejectRequest(String email, Project project) {
    final key = email.toLowerCase().trim();
    _studentRequests[key]?.removeWhere((p) => p.id == project.id);
  }

  void addProject(Project project) => allProjects.add(project);

  int get totalAssignedTasks {
    int total = 0;
    for (final list in _studentProjects.values) {
      for (final sp in list) {
        total += sp.tasks.length;
      }
    }
    return total;
  }

  int get totalCompletedTasks {
    int total = 0;
    for (final list in _studentProjects.values) {
      for (final sp in list) {
        total += sp.tasks.where((t) => t.completed).length;
      }
    }
    return total;
  }
}

class ChatMessage {
  final String fromEmail;
  final String toEmail;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.fromEmail,
    required this.toEmail,
    required this.text,
    required this.timestamp,
  });
}

class ChatRepository {
  ChatRepository._();
  static final ChatRepository instance = ChatRepository._();

  final Map<String, List<ChatMessage>> _threads = {};

  String _threadId(String a, String b) {
    final e = [a.toLowerCase().trim(), b.toLowerCase().trim()]..sort();
    return '${e[0]}|${e[1]}';
  }

  List<ChatMessage> getThread(String a, String b) =>
      _threads[_threadId(a, b)] ?? <ChatMessage>[];

  void sendMessage({
    required String from,
    required String to,
    required String text,
  }) {
    if (text.trim().isEmpty) return;
    final id = _threadId(from, to);
    final list = _threads.putIfAbsent(id, () => <ChatMessage>[]);
    list.add(
      ChatMessage(
        fromEmail: from,
        toEmail: to,
        text: text,
        timestamp: DateTime.now(),
      ),
    );
  }
}

/// ======================== APP ROOT ========================

class MetroManagerApp extends StatelessWidget {
  const MetroManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: kDeepBlue,
      brightness: Brightness.light,
    );

    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: kDeepBlue,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(color: const Color(0xFF0E2238).withOpacity(.8)),
        hintStyle: const TextStyle(color: Color(0xFF667085)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE6E8EC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE6E8EC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kDeepBlue, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.withOpacity(.9)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(.14),
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white70),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withOpacity(.9),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MetroManager',
      theme: theme,
      home: const StartPage(),
    );
  }
}

class MetroManagerLogo extends StatelessWidget {
  final Color textColor;
  final double size;

  const MetroManagerLogo({
    super.key,
    this.textColor = Colors.white,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: kLogoOrange,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _bar(),
                const SizedBox(width: 2),
                _bar(height: 14),
                const SizedBox(width: 2),
                _bar(),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'MetroManager',
          style: TextStyle(
            color: textColor,
            fontSize: size,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _bar({double height = 10}) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDeepBlue,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: MetroManagerLogo(),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Bienvenido a MetroManager',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Organiza proyectos, tareas y la comunicación entre profesores y estudiantes '
                              'en un solo lugar. Empieza desde cero y ve construyendo tu espacio académico.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: const [
                                _FeatureChip(
                                  icon: Icons.check_circle_outline,
                                  label: 'Seguimiento de tareas',
                                ),
                                _FeatureChip(
                                  icon: Icons.people_outline,
                                  label: 'Colaboración profesor–estudiante',
                                ),
                                _FeatureChip(
                                  icon: Icons.chat_bubble_outline,
                                  label: 'Chat privado',
                                ),
                                _FeatureChip(
                                  icon: Icons.bar_chart_outlined,
                                  label: 'Dashboard de progreso',
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const LoginPage(),
                                      ),
                                    );
                                  },
                                  child: const Text('Iniciar sesión'),
                                ),
                                const SizedBox(width: 16),
                                OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterPage(),
                                      ),
                                    );
                                  },
                                  child: const Text('Crear cuenta'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.07),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withOpacity(.12),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(.12),
                                ),
                                child: const Icon(
                                  Icons.dashboard_customize_outlined,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Tu centro de control académico',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Crea proyectos, asigna tareas y revisa el avance de tus grupos en tiempo real.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: const [
                                  _MiniIconInfo(
                                    icon: Icons.assignment_outlined,
                                    label: 'Proyectos claros',
                                  ),
                                  _MiniIconInfo(
                                    icon: Icons.timeline_outlined,
                                    label: 'Avance visible',
                                  ),
                                  _MiniIconInfo(
                                    icon: Icons.shield_outlined,
                                    label: 'Espacio seguro',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: kDeepBlue),
      label: Text(label),
      backgroundColor: Colors.white,
      labelStyle: const TextStyle(
        color: kDeepBlue,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _MiniIconInfo extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniIconInfo({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final AppUser? user = await UserRepository.instance.login(
      _emailCtrl.text,
      _passCtrl.text,
    );

    if (user == null) {
      setState(() {
        _error = 'Correo o contraseña incorrectos.';
      });
      return;
    }

    setState(() => _error = null);

    if (user.role == 'estudiante') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => StudentProfilePage(user: user)),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ProfessorProfilePage(user: user)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDeepBlue,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            color: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MetroManagerLogo(textColor: kDeepBlue, size: 20),
                    const SizedBox(height: 16),
                    const Text(
                      'Iniciar sesión',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: kDeepBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Accede a tu panel como estudiante o profesor.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF667085), fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo institucional',
                        hintText: 'nombre@unimet.edu.ve',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Ingresa tu correo.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Ingresa tu contraseña.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kDeepBlue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Entrar'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const RegisterPage(),
                          ),
                        );
                      },
                      child: const Text('Crear cuenta nueva'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _campoExtraCtrl = TextEditingController();

  String _role = 'estudiante';
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _campoExtraCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = UserRepository.instance;
    final bool emailExists = await repo.exists(_emailCtrl.text);
    if (emailExists) {
      setState(() {
        _error = 'Ya existe una cuenta con ese correo.';
      });
      return;
    }

    final user = AppUser(
      role: _role,
      nombre: _nombreCtrl.text.trim(),
      apellido: _apellidoCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      campoExtra: _campoExtraCtrl.text.trim(),
    );

    final bool success = await repo.register(user);
    if (!success) {
      setState(() {
        _error = 'Error en el registro. Intenta de nuevo.';
      });
      return;
    }

    setState(() => _error = null);

    if (user.role == 'estudiante') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => StudentProfilePage(user: user)),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ProfessorProfilePage(user: user)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDeepBlue,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const Center(
                      child: MetroManagerLogo(textColor: kDeepBlue, size: 20),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Crear cuenta',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: kDeepBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Regístrate como estudiante o profesor.',
                      style: TextStyle(color: Color(0xFF667085), fontSize: 12),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Estudiante'),
                            value: 'estudiante',
                            groupValue: _role,
                            onChanged: (v) =>
                                setState(() => _role = v ?? 'estudiante'),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Profesor'),
                            value: 'profesor',
                            groupValue: _role,
                            onChanged: (v) =>
                                setState(() => _role = v ?? 'profesor'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nombreCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _apellidoCtrl,
                      decoration: const InputDecoration(labelText: 'Apellido'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo institucional',
                        hintText: 'nombre@unimet.edu.ve',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => v == null || v.length < 4
                          ? 'Mínimo 4 caracteres'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _campoExtraCtrl,
                      decoration: InputDecoration(
                        labelText: _role == 'estudiante'
                            ? 'Carrera'
                            : 'Profesión',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 10),
                    if (_error != null)
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kDeepBlue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Registrarme'),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      child: const Text('Ya tengo cuenta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StudentProfilePage extends StatefulWidget {
  final AppUser user;

  const StudentProfilePage({super.key, required this.user});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDeepBlue,
      appBar: AppBar(
        backgroundColor: kDeepBlue,
        elevation: 0,
        title: const MetroManagerLogo(),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await UserRepository.instance.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const StartPage()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Salir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: const Color(0xFF0B2947),
            selectedIndex: _tabIndex,
            onDestinationSelected: (i) => setState(() => _tabIndex = i),
            labelType: NavigationRailLabelType.all,
            selectedIconTheme: const IconThemeData(
              color: Colors.white,
              size: 26,
            ),
            selectedLabelTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            unselectedIconTheme: const IconThemeData(
              color: Colors.white70,
              size: 22,
            ),
            unselectedLabelTextStyle: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Inicio'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment),
                label: Text('Proyectos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.mail_outline),
                selectedIcon: Icon(Icons.mail),
                label: Text('Solicitudes'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: Text('Chat'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('Perfil'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_tabIndex) {
      case 0:
        return StudentHomeSection(user: widget.user);
      case 1:
        return StudentProjectsSection(user: widget.user);
      case 2:
        return StudentRequestsPage(user: widget.user);
      case 3:
        return StudentChatPage(user: widget.user);
      case 4:
      default:
        return StudentProfileForm(user: widget.user);
    }
  }
}

class StudentHomeSection extends StatelessWidget {
  final AppUser user;

  const StudentHomeSection({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final repo = ProjectRepository.instance;
    final proyectos = repo.getStudentProjects(user.email);
    final totalTareas = proyectos.fold<int>(
      0,
      (sum, sp) => sum + sp.tasks.length,
    );
    final completadas = proyectos.fold<int>(
      0,
      (sum, sp) => sum + sp.tasks.where((t) => t.completed).length,
    );

    final progreso = totalTareas == 0 ? 0.0 : completadas / totalTareas;

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, ${user.nombre}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0E2238),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Aquí puedes ver un resumen rápido de tu avance.',
              style: TextStyle(color: Color(0xFF667085), fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _DashboardSummaryCard(
                    label: 'Proyectos activos',
                    value: proyectos.length.toString(),
                    icon: Icons.assignment_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DashboardSummaryCard(
                    label: 'Tareas completadas',
                    value: completadas.toString(),
                    icon: Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DashboardSummaryCard(
                    label: 'Progreso total',
                    value: '${(progreso * 100).round()}%',
                    icon: Icons.timeline_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Acciones rápidas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0E2238),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickActionButton(
                  icon: Icons.assignment,
                  label: 'Ver mis proyectos',
                  onTap: () {
                    final state = context
                        .findAncestorStateOfType<_StudentProfilePageState>();
                    state?.setState(() => state._tabIndex = 1);
                  },
                ),
                _QuickActionButton(
                  icon: Icons.mail,
                  label: 'Ver solicitudes',
                  onTap: () {
                    final state = context
                        .findAncestorStateOfType<_StudentProfilePageState>();
                    state?.setState(() => state._tabIndex = 2);
                  },
                ),
                _QuickActionButton(
                  icon: Icons.chat_bubble,
                  label: 'Abrir chat',
                  onTap: () {
                    final state = context
                        .findAncestorStateOfType<_StudentProfilePageState>();
                    state?.setState(() => state._tabIndex = 3);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DashboardSummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.withOpacity(.04),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kAccentYellow.withOpacity(.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: kDeepBlue),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0E2238),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF667085),
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

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF0E2238),
        side: const BorderSide(color: Color(0xFFCBD5E1)),
        backgroundColor: Colors.white,
      ),
    );
  }
}

class StudentProjectsSection extends StatefulWidget {
  final AppUser user;

  const StudentProjectsSection({super.key, required this.user});

  @override
  State<StudentProjectsSection> createState() => _StudentProjectsSectionState();
}

class _StudentProjectsSectionState extends State<StudentProjectsSection> {
  @override
  Widget build(BuildContext context) {
    final repo = ProjectRepository.instance;
    final proyectos = repo.getStudentProjects(widget.user.email);

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mis proyectos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0E2238),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (proyectos.isEmpty)
                    const Text(
                      'Aún no estás suscrito a ningún proyecto.\n'
                      'Acepta una solicitud o espera a que un profesor te asigne una.',
                      style: TextStyle(color: Color(0xFF667085)),
                    ),
                  if (proyectos.isNotEmpty)
                    Expanded(
                      child: ListView.separated(
                        itemCount: proyectos.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, index) {
                          final sp = proyectos[index];
                          final progress = sp.progress.clamp(0.0, 1.0);
                          return Card(
                            elevation: 0,
                            color: Colors.grey.withOpacity(.04),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sp.project.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0E2238),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    sp.project.course,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF667085),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey.withOpacity(
                                      .2,
                                    ),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          kAccentYellow,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Progreso: ${(progress * 100).round()}%',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF667085),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Tareas',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ...sp.tasks.map(
                                    (t) => CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                      title: Text(
                                        t.title,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      value: t.completed,
                                      onChanged: (v) {
                                        setState(() {
                                          final checked = v ?? false;
                                          t.completed = checked;
                                          ProjectRepository.instance
                                              .updateTaskStatus(
                                                widget.user.email,
                                                sp.project.id,
                                                t.id,
                                                checked,
                                              );
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Proyectos disponibles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0E2238),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Estos son los proyectos que los profesores han configurado. '
                    'Puedes verlos y esperar a que te asignen o te envíen una solicitud.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF667085)),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final projects = ProjectRepository.instance.allProjects;
                        if (projects.isEmpty) {
                          return const Center(
                            child: Text(
                              'Todavía no hay proyectos configurados.',
                              style: TextStyle(color: Color(0xFF667085)),
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: projects.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, index) {
                            final p = projects[index];
                            return Card(
                              elevation: 0,
                              color: Colors.grey.withOpacity(.04),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      p.course,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF667085),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      p.description,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF667085),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Tareas:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (p.tasks.isEmpty)
                                      const Text(
                                        '• (Sin tareas definidas aún)',
                                        style: TextStyle(fontSize: 12),
                                      )
                                    else
                                      ...p.tasks.map(
                                        (t) => Text(
                                          '• ${t.title}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class StudentRequestsPage extends StatefulWidget {
  final AppUser user;

  const StudentRequestsPage({super.key, required this.user});

  @override
  State<StudentRequestsPage> createState() => _StudentRequestsPageState();
}

class _StudentRequestsPageState extends State<StudentRequestsPage> {
  @override
  Widget build(BuildContext context) {
    final repo = ProjectRepository.instance;
    final requests = repo.getStudentRequests(widget.user.email);

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Solicitudes de proyectos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0E2238),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Acepta o rechaza solicitudes enviadas por tus profesores.',
              style: TextStyle(fontSize: 13, color: Color(0xFF667085)),
            ),
            const SizedBox(height: 16),
            if (requests.isEmpty)
              const Text(
                'No tienes solicitudes pendientes en este momento.',
                style: TextStyle(color: Color(0xFF667085)),
              ),
            if (requests.isNotEmpty)
              Expanded(
                child: ListView.separated(
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final p = requests[index];
                    return Card(
                      elevation: 0,
                      color: Colors.grey.withOpacity(.04),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        title: Text(p.name),
                        subtitle: Text(p.course),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Rechazar',
                              onPressed: () {
                                setState(() {
                                  ProjectRepository.instance.rejectRequest(
                                    widget.user.email,
                                    p,
                                  );
                                });
                              },
                              icon: const Icon(Icons.close, color: Colors.red),
                            ),
                            IconButton(
                              tooltip: 'Aceptar',
                              onPressed: () {
                                setState(() {
                                  ProjectRepository.instance.acceptRequest(
                                    widget.user.email,
                                    p,
                                  );
                                });
                              },
                              icon: const Icon(
                                Icons.check,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class StudentChatPage extends StatefulWidget {
  final AppUser user;

  const StudentChatPage({super.key, required this.user});

  @override
  State<StudentChatPage> createState() => _StudentChatPageState();
}

class _StudentChatPageState extends State<StudentChatPage> {
  AppUser? _selectedProfessor;
  final _msgCtrl = TextEditingController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final professors = UserRepository.instance.professors;

    return Card(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chat con profesores',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0E2238),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Selecciona un profesor y conversa de forma privada.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF667085)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AppUser>(
                  value: _selectedProfessor,
                  decoration: const InputDecoration(labelText: 'Profesor'),
                  items: professors
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text('${p.nombre} ${p.apellido}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedProfessor = v),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _selectedProfessor == null
                ? const Center(
                    child: Text(
                      'Selecciona un profesor para ver la conversación.',
                      style: TextStyle(color: Color(0xFF667085)),
                    ),
                  )
                : _ChatThread(current: widget.user, other: _selectedProfessor!),
          ),
          if (_selectedProfessor != null)
            _ChatInputBar(
              controller: _msgCtrl,
              onSend: () {
                final text = _msgCtrl.text.trim();
                if (text.isEmpty) return;
                ChatRepository.instance.sendMessage(
                  from: widget.user.email,
                  to: _selectedProfessor!.email,
                  text: text,
                );
                _msgCtrl.clear();
                setState(() {});
              },
            ),
        ],
      ),
    );
  }
}

class StudentProfileForm extends StatefulWidget {
  final AppUser user;

  const StudentProfileForm({super.key, required this.user});

  @override
  State<StudentProfileForm> createState() => _StudentProfileFormState();
}

class _StudentProfileFormState extends State<StudentProfileForm> {
  late final TextEditingController _cedulaCtrl;
  late final TextEditingController _bioCtrl;

  @override
  void initState() {
    super.initState();
    _cedulaCtrl = TextEditingController(text: widget.user.cedula);
    _bioCtrl = TextEditingController(text: widget.user.bio);
  }

  @override
  void dispose() {
    _cedulaCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: ListView(
          children: [
            const Text(
              'Mi perfil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0E2238),
              ),
            ),
            const SizedBox(height: 12),
            _FieldRowStatic(
              label: 'Nombre y Apellido',
              value: '${widget.user.nombre} ${widget.user.apellido}',
            ),
            const SizedBox(height: 12),
            _FieldRowStatic(label: 'Carrera', value: widget.user.campoExtra),
            const SizedBox(height: 12),
            _FieldRowStatic(label: 'Correo', value: widget.user.email),
            const SizedBox(height: 18),
            TextField(
              controller: _cedulaCtrl,
              decoration: const InputDecoration(labelText: 'Cédula'),
              keyboardType: TextInputType.number,
              onChanged: (v) => widget.user.cedula = v.trim(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bioCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Sobre mí',
                alignLabelWithHint: true,
              ),
              onChanged: (v) => widget.user.bio = v.trim(),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfessorProfilePage extends StatefulWidget {
  final AppUser user;

  const ProfessorProfilePage({super.key, required this.user});

  @override
  State<ProfessorProfilePage> createState() => _ProfessorProfilePageState();
}

class _ProfessorProfilePageState extends State<ProfessorProfilePage> {
  int _tabIndex = 0;
  AppUser? _selectedStudentForChat;
  final TextEditingController _profChatCtrl = TextEditingController();

  @override
  void dispose() {
    _profChatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Scaffold(
      backgroundColor: kDeepBlue,
      appBar: AppBar(
        backgroundColor: kDeepBlue,
        elevation: 0,
        title: const MetroManagerLogo(),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await UserRepository.instance.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const StartPage()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Salir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: const Color(0xFF0B2947),
            selectedIndex: _tabIndex,
            onDestinationSelected: (i) => setState(() => _tabIndex = i),
            labelType: NavigationRailLabelType.all,
            selectedIconTheme: const IconThemeData(
              color: Colors.white,
              size: 26,
            ),
            selectedLabelTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            unselectedIconTheme: const IconThemeData(
              color: Colors.white70,
              size: 22,
            ),
            unselectedLabelTextStyle: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment),
                label: Text('Proyectos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Estudiantes'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.chat_bubble_outlined),
                selectedIcon: Icon(Icons.chat_bubble),
                label: Text('Chat'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('Perfil'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildBody(user),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppUser user) {
    switch (_tabIndex) {
      case 0:
        return _professorDashboard(user);
      case 1:
        return _projectsManagement();
      case 2:
        return _studentsManagement();
      case 3:
        return _chatManagement(user);
      case 4:
      default:
        return _professorProfile(user);
    }
  }

  Widget _professorDashboard(AppUser user) {
    final students = UserRepository.instance.students;
    final totalProjects = ProjectRepository.instance.allProjects.length;
    final totalTasks = ProjectRepository.instance.totalAssignedTasks;
    final completedTasks = ProjectRepository.instance.totalCompletedTasks;
    final completionRate = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

    return ProfessorHomeSection(
      user: user,
      totalStudents: students.length,
      totalProjects: totalProjects,
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      completionRate: completionRate,
      onGoToProjects: () => setState(() => _tabIndex = 1),
      onGoToStudents: () => setState(() => _tabIndex = 2),
      onGoToChat: () => setState(() => _tabIndex = 3),
      onCreateProject: _openCreateProjectDialog,
    );
  }

  Widget _projectsManagement() {
    final projects = ProjectRepository.instance.allProjects;
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Proyectos configurados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0E2238),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Listado de proyectos disponibles para los estudiantes.',
              style: TextStyle(fontSize: 13, color: Color(0xFF667085)),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _openCreateProjectDialog,
                icon: const Icon(Icons.add),
                label: const Text('Nuevo proyecto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kDeepBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: projects.isEmpty
                  ? const Center(
                      child: Text(
                        'Aún no has creado proyectos.',
                        style: TextStyle(color: Color(0xFF667085)),
                      ),
                    )
                  : ListView.separated(
                      itemCount: projects.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        final p = projects[index];
                        return Card(
                          elevation: 0,
                          color: Colors.grey.withOpacity(.04),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.course,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF667085),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  p.description,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF667085),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Tareas:',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                if (p.tasks.isEmpty)
                                  const Text(
                                    '• (Sin tareas definidas aún)',
                                    style: TextStyle(fontSize: 12),
                                  )
                                else
                                  ...p.tasks.map(
                                    (t) => Text(
                                      '• ${t.title}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _studentsManagement() {
    final students = UserRepository.instance.students;
    final projects = ProjectRepository.instance.allProjects;

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestión de estudiantes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0E2238),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecciona un estudiante y envía solicitudes para que se una a un proyecto.',
              style: TextStyle(fontSize: 13, color: Color(0xFF667085)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<AppUser>(
                    decoration: const InputDecoration(labelText: 'Estudiante'),
                    value: _selectedStudentForChat,
                    items: students
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              '${s.nombre} ${s.apellido} (${s.email})',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedStudentForChat = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: projects.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay proyectos para asignar todavía.',
                        style: TextStyle(color: Color(0xFF667085)),
                      ),
                    )
                  : ListView.separated(
                      itemCount: projects.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final p = projects[index];
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          tileColor: Colors.grey.withOpacity(.04),
                          title: Text(p.name),
                          subtitle: Text(p.course),
                          trailing: ElevatedButton(
                            onPressed: _selectedStudentForChat == null
                                ? null
                                : () {
                                    ProjectRepository.instance
                                        .addRequestForStudent(
                                          _selectedStudentForChat!.email,
                                          p,
                                        );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Solicitud enviada a ${_selectedStudentForChat!.email}',
                                        ),
                                      ),
                                    );
                                  },
                            child: const Text('Enviar solicitud'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatManagement(AppUser user) {
    final students = UserRepository.instance.students;

    return Card(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chat con estudiantes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0E2238),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Elige un estudiante para conversar de forma privada.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF667085)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AppUser>(
                  decoration: const InputDecoration(labelText: 'Estudiante'),
                  value: _selectedStudentForChat,
                  items: students
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text('${s.nombre} ${s.apellido}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedStudentForChat = v),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _selectedStudentForChat == null
                ? const Center(
                    child: Text(
                      'Selecciona un estudiante para ver la conversación.',
                      style: TextStyle(color: Color(0xFF667085)),
                    ),
                  )
                : _ChatThread(current: user, other: _selectedStudentForChat!),
          ),
          if (_selectedStudentForChat != null)
            _ChatInputBar(
              controller: _profChatCtrl,
              onSend: () {
                final text = _profChatCtrl.text.trim();
                if (text.isEmpty) return;
                ChatRepository.instance.sendMessage(
                  from: user.email,
                  to: _selectedStudentForChat!.email,
                  text: text,
                );
                _profChatCtrl.clear();
                setState(() {});
              },
            ),
        ],
      ),
    );
  }

  Widget _professorProfile(AppUser user) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Perfil del profesor',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0E2238),
              ),
            ),
            const SizedBox(height: 16),
            _FieldRowStatic(
              label: 'Nombre y Apellido',
              value: '${user.nombre} ${user.apellido}',
            ),
            const SizedBox(height: 18),
            _FieldRowStatic(label: 'Profesión', value: user.campoExtra),
            const SizedBox(height: 18),
            _FieldRowStatic(label: 'Correo Electrónico', value: user.email),
          ],
        ),
      ),
    );
  }

  Future<void> _openCreateProjectDialog() async {
    final nameCtrl = TextEditingController();
    final courseCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final taskCtrl = TextEditingController();
    final List<String> tasks = [];

    final newProject = await showDialog<Project>(
      context: context,
      builder: (dialogContext) {
        String? errorText;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Nuevo proyecto'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del proyecto',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: courseCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Curso asociado',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: taskCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nueva tarea (opcional)',
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Agregar tarea',
                          onPressed: () {
                            final text = taskCtrl.text.trim();
                            if (text.isEmpty) return;
                            setStateDialog(() {
                              tasks.add(text);
                              taskCtrl.clear();
                            });
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (tasks.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tareas agregadas:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...tasks.map(
                              (t) => Text(
                                '• $t',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorText!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final course = courseCtrl.text.trim();
                    final desc = descCtrl.text.trim();
                    if (name.isEmpty || course.isEmpty || desc.isEmpty) {
                      setStateDialog(() {
                        errorText =
                            'Todos los campos del proyecto son obligatorios.';
                      });
                      return;
                    }
                    final now = DateTime.now().millisecondsSinceEpoch;
                    final project = Project(
                      id: 'p_$now',
                      name: name,
                      course: course,
                      description: desc,
                      tasks: tasks
                          .asMap()
                          .entries
                          .map(
                            (e) => ProjectTask(
                              id: 't_${e.key}_$now',
                              title: e.value,
                            ),
                          )
                          .toList(),
                    );
                    Navigator.of(dialogContext).pop(project);
                  },
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );

    if (newProject != null) {
      setState(() {
        ProjectRepository.instance.addProject(newProject);
      });
    }
  }
}

class ProfessorHomeSection extends StatelessWidget {
  final AppUser user;
  final int totalStudents;
  final int totalProjects;
  final int totalTasks;
  final int completedTasks;
  final double completionRate;
  final VoidCallback onGoToProjects;
  final VoidCallback onGoToStudents;
  final VoidCallback onGoToChat;
  final VoidCallback onCreateProject;

  const ProfessorHomeSection({
    super.key,
    required this.user,
    required this.totalStudents,
    required this.totalProjects,
    required this.totalTasks,
    required this.completedTasks,
    required this.completionRate,
    required this.onGoToProjects,
    required this.onGoToStudents,
    required this.onGoToChat,
    required this.onCreateProject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, Prof. ${user.apellido}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0E2238),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Este es tu panel de resumen del curso.',
              style: TextStyle(color: Color(0xFF667085), fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _DashboardSummaryCard(
                    label: 'Estudiantes registrados',
                    value: totalStudents.toString(),
                    icon: Icons.people_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DashboardSummaryCard(
                    label: 'Proyectos creados',
                    value: totalProjects.toString(),
                    icon: Icons.assignment_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DashboardSummaryCard(
                    label: 'Tareas completadas',
                    value: '$completedTasks / $totalTasks',
                    icon: Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DashboardSummaryCard(
                    label: 'Tasa de avance',
                    value: '${(completionRate * 100).round()}%',
                    icon: Icons.bar_chart_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Acciones rápidas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0E2238),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickActionButton(
                  icon: Icons.add,
                  label: 'Crear proyecto',
                  onTap: onCreateProject,
                ),
                _QuickActionButton(
                  icon: Icons.assignment,
                  label: 'Ver proyectos',
                  onTap: onGoToProjects,
                ),
                _QuickActionButton(
                  icon: Icons.people,
                  label: 'Gestionar estudiantes',
                  onTap: onGoToStudents,
                ),
                _QuickActionButton(
                  icon: Icons.chat_bubble,
                  label: 'Ir al chat',
                  onTap: onGoToChat,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldRowStatic extends StatelessWidget {
  final String label;
  final String value;

  const _FieldRowStatic({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(.04),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(fontSize: 14, color: Color(0xFF0E2238)),
          ),
        ),
      ],
    );
  }
}

class _ChatThread extends StatefulWidget {
  final AppUser current;
  final AppUser other;

  const _ChatThread({required this.current, required this.other});

  @override
  State<_ChatThread> createState() => _ChatThreadState();
}

class _ChatThreadState extends State<_ChatThread> {
  final _scrollController = ScrollController();

  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  void didUpdateWidget(covariant _ChatThread oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  @override
  Widget build(BuildContext context) {
    final messages = ChatRepository.instance.getThread(
      widget.current.email,
      widget.other.email,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());

    if (messages.isEmpty) {
      return const Center(
        child: Text(
          'Aún no hay mensajes. Escribe el primero.',
          style: TextStyle(color: Color(0xFF667085)),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: messages.length,
      itemBuilder: (_, index) {
        final m = messages[index];
        final isMe = m.fromEmail == widget.current.email;
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isMe ? kDeepBlue : Colors.grey.withOpacity(.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              m.text,
              style: TextStyle(
                color: isMe ? Colors.white : const Color(0xFF0E2238),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _ChatInputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(.06),
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Escribe un mensaje...',
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onSend,
            icon: const Icon(Icons.send),
            color: kDeepBlue,
          ),
        ],
      ),
    );
  }
}