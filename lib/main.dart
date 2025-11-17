import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ======================== COLORES GLOBALES ========================
// Definimos las constantes de color utilizadas en toda la aplicación
// para mantener una identidad visual consistente.
const kDeepBlue = Color(0xFF0F3A63);
const kAccentYellow = Color(0xFFF0B429);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const MetroManagerApp());
}

/// ======================== MODELOS Y REPOSITORIOS ========================
// Andrea y Adolfo configuraron la lógica de negocio y las estructuras de datos que representan la información de
// la aplicación, así como los Repositorios que gestionan esos datos.
class AppUser {
  final String role; // 'estudiante' o 'profesor'
  String nombre;
  String apellido;
  final String email;
  final String password;
  final String campoExtra; // carrera (estudiante) o profesión (profesor)

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

  final Map<String, AppUser> _users = {};

  bool exists(String email) => _users.containsKey(email.toLowerCase().trim());

  bool register(AppUser user) {
    final key = user.email.toLowerCase().trim();
    if (_users.containsKey(key)) return false;
    _users[key] = user;
    return true;
  }

  AppUser? login(String email, String password) {
    final key = email.toLowerCase().trim();
    final user = _users[key];
    if (user == null) return null;
    if (user.password != password) return null;
    return user;
  }

  List<AppUser> get students =>
      _users.values.where((u) => u.role == 'estudiante').toList();
}

/// ---- Proyectos y tareas ----

class ProjectTask {
  final String id;
  final String title;
  bool completed;

  ProjectTask({
    required this.id,
    required this.title,
    this.completed = false,
  });

  ProjectTask copy() =>
      ProjectTask(id: id, title: title, completed: completed);
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

  StudentProjectData({
    required this.project,
    required this.tasks,
  });

  double get progress {
    if (tasks.isEmpty) return 0;
    final done = tasks.where((t) => t.completed).length;
    return done / tasks.length;
  }
}

class ProjectRepository {
  ProjectRepository._();

  static final ProjectRepository instance = ProjectRepository._();

  /// Proyectos demo + los que se creen
  final List<Project> allProjects = [
    Project(
      id: 'p1',
      name: 'Sistema de Gestión de Laboratorios',
      course: 'Sistemas de Información',
      description:
      'Aplicación web para reservar laboratorios, registrar prácticas y gestionar horarios.',
      tasks: [
        ProjectTask(id: 'p1t1', title: 'Diseñar caso de uso principal'),
        ProjectTask(id: 'p1t2', title: 'Armar boceto de interfaz'),
        ProjectTask(id: 'p1t3', title: 'Definir modelo de datos inicial'),
      ],
    ),
    Project(
      id: 'p2',
      name: 'Plataforma de Tutorías UNIMET',
      course: 'Ing. de Software',
      description:
      'Módulo para conectar tutores y estudiantes, agendar sesiones y registrar asistencia.',
      tasks: [
        ProjectTask(id: 'p2t1', title: 'Definir historias de usuario'),
        ProjectTask(id: 'p2t2', title: 'Crear prototipo en Figma'),
        ProjectTask(id: 'p2t3', title: 'Documentar API de reservas'),
      ],
    ),
    Project(
      id: 'p3',
      name: 'Dashboard Académico',
      course: 'Base de Datos',
      description:
      'Panel para visualizar promedios, aprobaciones y carga académica de los estudiantes.',
      tasks: [
        ProjectTask(id: 'p3t1', title: 'Diseñar esquema relacional'),
        ProjectTask(id: 'p3t2', title: 'Crear consultas SQL de reportes'),
        ProjectTask(id: 'p3t3', title: 'Armar gráfico de promedios'),
      ],
    ),
  ];

  /// Proyectos suscritos por estudiante (email -> lista)
  final Map<String, List<StudentProjectData>> _studentProjects = {};

  /// Solicitudes enviadas por profesores a estudiantes (email -> proyectos)
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
    final list =
    _studentProjects.putIfAbsent(key, () => <StudentProjectData>[]);
    final already = list.any((sp) => sp.project.id == project.id);
    if (already) return;

    list.add(
      StudentProjectData(
        project: project,
        tasks: project.tasks.map((t) => t.copy()).toList(),
      ),
    );
  }

  void updateTaskStatus(
      String email,
      String projectId,
      String taskId,
      bool completed,
      ) {
    final key = email.toLowerCase().trim();
    final list = _studentProjects[key];
    if (list == null) return;

    for (final sp in list) {
      if (sp.project.id == projectId) {
        for (final t in sp.tasks) {
          if (t.id == taskId) {
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
    final list = _studentRequests[key];
    list?.removeWhere((p) => p.id == project.id);
  }

  /// Nuevo: permitir que el profesor cree proyectos
  void addProject(Project project) {
    allProjects.add(project);
  }
}

/// ======================== APP ROOT ========================
// definición de la apariencia y la navegación de la aplicación.
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
        labelStyle: TextStyle(
          color: const Color(0xFF0E2238).withOpacity(.8),
        ),
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
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(.12),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.white.withOpacity(.12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white70),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        side: const BorderSide(color: Colors.white70),
        checkColor: MaterialStateProperty.all(kDeepBlue),
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return Colors.white;
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withOpacity(.9),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MetroManager',
      theme: theme,
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: const _WebScrollBehavior(),
          child: child ?? const SizedBox.shrink(),
        );
      },
      initialRoute: '/',
      routes: {
        '/': (_) => const LoginPage(),
        '/role': (_) => const RoleSelectPage(),
        '/register': (_) => const RegisterPage(),
        '/home': (_) => const HomePage(),
        '/student/profile': (_) => const StudentProfilePage(),
        '/professor/profile': (_) => const ProfessorProfilePage(),
      },
    );
  }
}

/// ======================== LOGIN ========================
// se realizó la representación del formulario de inicio de seción
// y la logica de autenticación
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
  bool _loading = false;
  bool _remember = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 400));

    final user =
    UserRepository.instance.login(_emailCtrl.text, _passCtrl.text);

    setState(() => _loading = false);

    if (user == null) {
      if (!UserRepository.instance.exists(_emailCtrl.text)) {
        _showSnack(
          'No estás registrado. Usa “Regístrate” para crear tu cuenta.',
        );
      } else {
        _showSnack('Contraseña incorrecta. Inténtalo nuevamente.');
      }
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home', arguments: user);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 920.0;

    final logoCard = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Card(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 22),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MetroMark(),
                SizedBox(width: 18),
                _LogoTitle(),
              ],
            ),
          ),
        ),
      ),
    );

    final form = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 22),
                  const Text(
                    'Bienvenido',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Inicia sesión para poder proceder',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(.85),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _emailCtrl,
                    autofillHints: const [AutofillHints.email],
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Color(0xFF0E2238)),
                    decoration: const InputDecoration(
                      hintText:
                      'usuario@correo.unimet.edu.ve o usuario@unimet.edu.ve',
                      prefixIcon: Icon(Icons.alternate_email),
                      suffixIcon: Icon(Icons.mail_outline),
                    ),
                    validator: _unimetEmailValidator,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.info_outline,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Solo se permiten correos institucionales UNIMET\n'
                              'Estudiantes: @correo.unimet.edu.ve\n'
                              'Profesores: @unimet.edu.ve',
                          style: TextStyle(fontSize: 13.5, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passCtrl,
                    autofillHints: const [AutofillHints.password],
                    obscureText: _obscure,
                    style: const TextStyle(color: Color(0xFF0E2238)),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Mostrar' : 'Ocultar',
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscure = !_obscure);
                        },
                      ),
                    ),
                    validator: _passwordValidator,
                    onFieldSubmitted: (_) => _onLogin(),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: _remember,
                          onChanged: (v) =>
                              setState(() => _remember = v ?? false),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Recordar Contraseña',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _onLogin,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_loading)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          if (_loading) const SizedBox(width: 10),
                          const Text('Iniciar Sesión'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: const [
                      Text(
                        '¿No tienes cuenta?',
                        style: TextStyle(color: Colors.white),
                      ),
                      _RegisterLink(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 60 : 18,
              vertical: 40,
            ),
            child: Column(
              children: [
                logoCard,
                const SizedBox(height: 26),
                form,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterLink extends StatelessWidget {
  const _RegisterLink();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/role'),
      child: const Text(
        'Regístrate',
        style: TextStyle(
          color: kAccentYellow,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// ======================== ROLE SELECT ========================
// en esta sección el usuartio podrá elegir el rol con el que se
// registrará: estudiante o profesor
class RoleSelectPage extends StatelessWidget {
  const RoleSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 36),
            child: Column(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: Card(
                      color: Colors.white,
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Padding(
                        padding:
                        EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                        child: _LogoTitleRow(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Crear cuenta',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (_, c) {
                    final two = c.maxWidth >= 720;
                    final cards = [
                      _RoleCard(
                        icon: Icons.school_outlined,
                        title: 'Estudiante',
                        subtitle: 'Gestiona clases, tareas y más.',
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/register',
                          arguments: 'estudiante',
                        ),
                        accentColor: kAccentYellow,
                      ),
                      _RoleCard(
                        icon: Icons.person_outline,
                        title: 'Profesor',
                        subtitle: 'Organiza cursos y tus grupos.',
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/register',
                          arguments: 'profesor',
                        ),
                        accentColor: Colors.white70,
                      ),
                    ];

                    if (two) {
                      return Row(
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 16),
                          Expanded(child: cards[1]),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        cards[0],
                        const SizedBox(height: 12),
                        cards[1],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  label: const Text(
                    'Volver',
                    style: TextStyle(color: Colors.white),
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

/// ======================== REGISTER ========================
// formulario y la lógica para crear un nuevo usuario
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
  final _extraCtrl = TextEditingController(); // carrera o profesión
  bool _obscure = true;
  bool _saving = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _extraCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _onRegister(String role) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 360));

    final user = AppUser(
      role: role,
      nombre: _nombreCtrl.text.trim(),
      apellido: _apellidoCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      campoExtra: _extraCtrl.text.trim(),
    );

    final ok = UserRepository.instance.register(user);

    setState(() => _saving = false);

    if (!ok) {
      _showSnack('Ese correo ya está registrado. Intenta iniciar sesión.');
      return;
    }

    if (!mounted) return;
    _showSnack('Registro exitoso. ¡Bienvenid@!');
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
          (r) => false,
      arguments: user,
    );
  }

  @override
  Widget build(BuildContext context) {
    final role =
        ModalRoute.of(context)?.settings.arguments as String? ?? 'estudiante';
    final esEstudiante = role == 'estudiante';
    final labelExtra = esEstudiante ? 'Carrera que estudias' : 'Profesión';

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 36),
            child: Column(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: Card(
                      color: Colors.white,
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Padding(
                        padding:
                        EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                        child: _LogoTitleRow(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Registro - ${esEstudiante ? "Estudiante" : "Profesor"}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Card(
                    color: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Form(
                        key: _formKey,
                        child: AutofillGroup(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _nombreCtrl,
                                      textCapitalization:
                                      TextCapitalization.words,
                                      decoration: const InputDecoration(
                                        labelText: 'Nombre',
                                        prefixIcon: Icon(Icons.badge_outlined),
                                      ),
                                      validator: _requiredValidator(
                                          'Ingresa tu nombre'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _apellidoCtrl,
                                      textCapitalization:
                                      TextCapitalization.words,
                                      decoration: const InputDecoration(
                                        labelText: 'Apellido',
                                        prefixIcon: Icon(Icons.badge),
                                      ),
                                      validator: _requiredValidator(
                                        'Ingresa tu apellido',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                decoration: const InputDecoration(
                                  labelText: 'Correo UNIMET',
                                  hintText:
                                  'usuario@correo.unimet.edu.ve o usuario@unimet.edu.ve',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: _unimetEmailValidator,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passCtrl,
                                autofillHints: const [AutofillHints.newPassword],
                                obscureText: _obscure,
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: _obscure ? 'Mostrar' : 'Ocultar',
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() => _obscure = !_obscure);
                                    },
                                  ),
                                ),
                                validator: _passwordValidator,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _extraCtrl,
                                textCapitalization:
                                TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  labelText: labelExtra,
                                  prefixIcon: Icon(
                                    esEstudiante
                                        ? Icons.school_outlined
                                        : Icons.work_outline,
                                  ),
                                ),
                                validator: _requiredValidator(
                                  esEstudiante
                                      ? 'Ingresa tu carrera'
                                      : 'Ingresa tu profesión',
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: _saving
                                      ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                      : const Icon(Icons.person_add_alt),
                                  label: const Text('Registrarse'),
                                  onPressed:
                                  _saving ? null : () => _onRegister(role),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextButton.icon(
                                onPressed:
                                _saving ? null : () => Navigator.pop(context),
                                icon: const Icon(Icons.chevron_left),
                                label: const Text('Volver'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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

/// ======================== HOME (redirige a Perfil) ========================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _navigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_navigated) return;

    final user = ModalRoute.of(context)?.settings.arguments as AppUser?;
    if (user == null) return;

    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        user.role == 'estudiante' ? '/student/profile' : '/professor/profile',
        arguments: user,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.shrink());
  }
}

/// ======================== PERFIL ESTUDIANTE ========================

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final _bioCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  late AppUser user;

  int _tabIndex = 0; // 0:Inicio, 1:Proyectos, 2:Solicitudes, 3:Perfil

  @override
  void dispose() {
    _bioCtrl.dispose();
    _cedulaCtrl.dispose();
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    user = (ModalRoute.of(context)?.settings.arguments as AppUser?)!;
    _bioCtrl.text = user.bio;
    _cedulaCtrl.text = user.cedula;
    _nombreCtrl.text = user.nombre;
    _apellidoCtrl.text = user.apellido;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.withOpacity(.08),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: const [
            SizedBox(width: 16),
            _MetroMark(),
            SizedBox(width: 12),
            Text(
              'METRO MANAGER ESTUDIANTE',
              style: TextStyle(
                color: Color(0xFF0E2238),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0E2238),
                side: BorderSide(color: Colors.grey.withOpacity(.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                    (r) => false,
              ),
              child: const Text('Salir'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    _TopTab(
                      label: 'Página Principal',
                      selected: _tabIndex == 0,
                      onTap: () => setState(() => _tabIndex = 0),
                    ),
                    _TopTab(
                      label: 'Mis Proyectos',
                      selected: _tabIndex == 1,
                      onTap: () => setState(() => _tabIndex = 1),
                    ),
                    _TopTab(
                      label: 'Solicitudes Enviadas',
                      selected: _tabIndex == 2,
                      onTap: () => setState(() => _tabIndex = 2),
                    ),
                    _TopTab(
                      label: 'Perfil',
                      selected: _tabIndex == 3,
                      onTap: () => setState(() => _tabIndex = 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: _buildTabBody(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBody() {
    switch (_tabIndex) {
      case 0:
        return StudentHomeSection(
          user: user,
          onGoToProjects: () => setState(() => _tabIndex = 1),
          onGoToRequests: () => setState(() => _tabIndex = 2),
          onGoToProfile: () => setState(() => _tabIndex = 3),
        );
      case 1:
        return StudentProjectsSection(user: user);
      case 2:
        return StudentRequestsSection(user: user);
      case 3:
      default:
        return _profileContent();
    }
  }

  Widget _profileContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // IZQUIERDA
        Expanded(
          flex: 3,
          child: Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _FieldBlock(
                    title: 'Nombre y Apellido',
                    controllerLeft: _nombreCtrl,
                    controllerRight: _apellidoCtrl,
                  ),
                  const SizedBox(height: 18),
                  _FieldBlock.single(
                    title: 'Cédula',
                    controller: _cedulaCtrl,
                    hint: 'Ej: 31894531',
                  ),
                  const SizedBox(height: 18),
                  _FieldBlock.single(
                    title: 'Carrera / Profesión',
                    controller: TextEditingController(text: user.campoExtra),
                    hint: 'Tu carrera o profesión',
                    readOnly: true,
                  ),
                  const SizedBox(height: 18),
                  _FieldBlock.single(
                    title: 'Correo Electrónico',
                    controller: TextEditingController(text: user.email),
                    hint: 'correo@correo.unimet.edu.ve',
                    readOnly: true,
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kDeepBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _saveChanges,
                      child: const Text('Guardar Cambios'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        // DERECHA (BIO)
        Expanded(
          flex: 2,
          child: Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Biografía Personal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0E2238),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '(Opcional)',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioCtrl,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      hintText: 'Escribe algo sobre ti...',
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                        BorderSide(color: kAccentYellow, width: 1.2),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                        BorderSide(color: kAccentYellow, width: 1.6),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
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

  void _saveChanges() {
    setState(() {
      user.nombre = _nombreCtrl.text.trim();
      user.apellido = _apellidoCtrl.text.trim();
      user.cedula = _cedulaCtrl.text.trim();
      user.bio = _bioCtrl.text.trim();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil actualizado')),
    );
  }
}

/// ======================== SECCIONES ESTUDIANTE ========================

/// Home del estudiante
class StudentHomeSection extends StatelessWidget {
  final AppUser user;
  final VoidCallback onGoToProjects;
  final VoidCallback onGoToRequests;
  final VoidCallback onGoToProfile;

  const StudentHomeSection({
    super.key,
    required this.user,
    required this.onGoToProjects,
    required this.onGoToRequests,
    required this.onGoToProfile,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Card(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildHeader()),
                  const SizedBox(width: 16),
                  _buildQuickProfileCard(),
                ],
              ),
              const SizedBox(height: 24),
              _buildSummaryRow(),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 780;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildNewsCard()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildQuickActionsCard()),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildNewsCard(),
                      const SizedBox(height: 16),
                      _buildQuickActionsCard(),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// HERO
  Widget _buildHeader() {
    final nombre = user.nombre.isEmpty ? 'Estudiante' : user.nombre;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kDeepBlue, Color(0xFF174773)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $nombre 👋',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Este es tu panel inicial de MetroManager. Revisa tu progreso, novedades y próximas acciones.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _BubbleChip(
                      icon: Icons.check_circle_outline,
                      label: 'Tareas del día',
                    ),
                    _BubbleChip(
                      icon: Icons.school_outlined,
                      label: 'Cursos clave',
                    ),
                    _BubbleChip(
                      icon: Icons.emoji_events_outlined,
                      label: 'Meta semanal',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 110,
            height: 100,
            child: Stack(
              children: [
                Positioned(
                  bottom: 0,
                  left: 8,
                  right: 8,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.dashboard_customize_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 0,
                  child: _floatingCircleIcon(
                    Icons.notifications_active_outlined,
                  ),
                ),
                Positioned(
                  top: 24,
                  left: 0,
                  child: _floatingCircleIcon(
                    Icons.auto_graph_outlined,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickProfileCard() {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kAccentYellow.withOpacity(.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de perfil',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF0E2238),
            ),
          ),
          const SizedBox(height: 10),
          _infoRow(Icons.badge_outlined, '${user.nombre} ${user.apellido}'),
          const SizedBox(height: 6),
          _infoRow(Icons.school_outlined, user.campoExtra),
          const SizedBox(height: 6),
          _infoRow(Icons.email_outlined, user.email),
          const SizedBox(height: 6),
          _infoRow(
            Icons.credit_card_outlined,
            user.cedula.isEmpty ? 'Cédula no registrada' : user.cedula,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0E2238)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF0E2238),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow() {
    final repo = ProjectRepository.instance;
    final projects = repo.getStudentProjects(user.email);
    final requests = repo.getStudentRequests(user.email);

    final progress = projects.isEmpty
        ? 0.0
        : projects.map((p) => p.progress).fold(0.0, (a, b) => a + b) /
        projects.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final cards = [
          DashboardSummaryCard(
            icon: Icons.work_outline,
            title: 'Proyectos activos',
            value: projects.length.toString(),
            subtitle: 'Proyectos en los que estás suscrito.',
          ),
          DashboardSummaryCard(
            icon: Icons.mark_email_read_outlined,
            title: 'Solicitudes',
            value: requests.length.toString(),
            subtitle: 'Invitaciones pendientes de profesores.',
          ),
          DashboardSummaryCard(
            icon: Icons.trending_up,
            title: 'Progreso promedio',
            value: '${(progress * 100).round()}%',
            subtitle: 'Basado en tareas marcadas como completadas.',
          ),
        ];

        if (isWide) {
          return Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
              const SizedBox(width: 12),
              Expanded(child: cards[2]),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cards[0],
            const SizedBox(height: 12),
            cards[1],
            const SizedBox(height: 12),
            cards[2],
          ],
        );
      },
    );
  }

  Widget _buildNewsCard() {
    final noticias = [
      {
        'titulo': 'Nueva fecha para entrega de Proyecto 1',
        'detalle':
        'El profesor ajustó la entrega para el próximo lunes a las 11:59 p.m.',
      },
      {
        'titulo': 'Coaching de proyectos este jueves',
        'detalle':
        'Sesión virtual para dudas técnicas de Sistemas de Información.',
      },
      {
        'titulo': 'Recordatorio: subir avances semanales',
        'detalle':
        'Actualiza tus tareas completadas para mantener tu progreso al día.',
      },
    ];

    return Card(
      elevation: 0,
      color: Colors.grey.withOpacity(.03),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Novedades',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0E2238),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Lo más importante de tus cursos y proyectos.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 14),
            ...noticias.map(
                  (n) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n['titulo'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0E2238),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      n['detalle'] as String,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 0,
      color: Colors.grey.withOpacity(.03),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Acciones rápidas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0E2238),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _quickActionButton(
                  icon: Icons.work_outline,
                  label: 'Ver mis proyectos',
                  onTap: onGoToProjects,
                ),
                _quickActionButton(
                  icon: Icons.mark_email_read_outlined,
                  label: 'Revisar solicitudes',
                  onTap: onGoToRequests,
                ),
                _quickActionButton(
                  icon: Icons.person_outline,
                  label: 'Editar perfil',
                  onTap: onGoToProfile,
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Tips rápidos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0E2238),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '• Mantén tus datos actualizados en el perfil.\n'
                  '• Revisa tus actividades al entrar.\n'
                  '• Usa la barra de progreso de cada proyecto para no perderte.',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF667085),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 200,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
        ),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          side: BorderSide(color: Colors.grey.withOpacity(.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Chips

class _BubbleChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BubbleChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: kDeepBlue),
      label: Text(label),
      backgroundColor: Colors.white,
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: kDeepBlue,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}

Widget _floatingCircleIcon(IconData icon) {
  return Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.18),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white.withOpacity(.5)),
    ),
    child: Icon(
      icon,
      size: 16,
      color: Colors.white,
    ),
  );
}

/// ---- Mis Proyectos ----

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
    final disponibles = repo.getAvailableProjectsForStudent(widget.user.email);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Proyectos actuales
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
                          'Acepta una solicitud o suscríbete desde la lista de la derecha.',
                      style: TextStyle(color: Color(0xFF667085)),
                    ),
                  if (proyectos.isNotEmpty)
                    Expanded(
                      child: ListView.separated(
                        itemCount: proyectos.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
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
                                    value: progress == 0 && sp.tasks.isEmpty
                                        ? 0
                                        : progress,
                                    minHeight: 8,
                                    backgroundColor:
                                    Colors.grey.withOpacity(.2),
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
                                          t.completed = v ?? false;
                                          ProjectRepository.instance
                                              .updateTaskStatus(
                                            widget.user.email,
                                            sp.project.id,
                                            t.id,
                                            v ?? false,
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
        const SizedBox(width: 18),
        // Proyectos disponibles
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
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0E2238),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (disponibles.isEmpty)
                    const Text(
                      'No hay más proyectos disponibles por ahora.',
                      style: TextStyle(color: Color(0xFF667085)),
                    ),
                  if (disponibles.isNotEmpty)
                    Expanded(
                      child: ListView.separated(
                        itemCount: disponibles.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                        itemBuilder: (_, index) {
                          final p = disponibles[index];
                          return Card(
                            elevation: 0,
                            color: Colors.grey.withOpacity(.03),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    p.course,
                                    style: const TextStyle(
                                      fontSize: 12,
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
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          ProjectRepository.instance
                                              .subscribeStudentToProject(
                                            widget.user.email,
                                            p,
                                          );
                                        });
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Te suscribiste a "${p.name}"',
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text('Suscribirme'),
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
      ],
    );
  }
}

/// ---- Solicitudes Enviadas ----

class StudentRequestsSection extends StatefulWidget {
  final AppUser user;

  const StudentRequestsSection({super.key, required this.user});

  @override
  State<StudentRequestsSection> createState() => _StudentRequestsSectionState();
}

class _StudentRequestsSectionState extends State<StudentRequestsSection> {
  @override
  Widget build(BuildContext context) {
    final repo = ProjectRepository.instance;
    final solicitudes = repo.getStudentRequests(widget.user.email);

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Solicitudes recibidas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0E2238),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aquí aparecen las invitaciones de profesores para unirte a proyectos.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 16),
            if (solicitudes.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Todavía no tienes solicitudes.\nCuando un profesor te invite, aparecerá aquí.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF667085)),
                  ),
                ),
              ),
            if (solicitudes.isNotEmpty)
              Expanded(
                child: ListView.separated(
                  itemCount: solicitudes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final p = solicitudes[index];
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
                                color: Color(0xFF0E2238),
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
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        ProjectRepository.instance
                                            .acceptRequest(
                                          widget.user.email,
                                          p,
                                        );
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Aceptaste la solicitud de "${p.name}"',
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kDeepBlue,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Aceptar'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        ProjectRepository.instance
                                            .rejectRequest(
                                          widget.user.email,
                                          p,
                                        );
                                      });
                                    },
                                    child: const Text('Rechazar'),
                                  ),
                                ),
                              ],
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

/// ======================== PERFIL PROFESOR ========================

class ProfessorProfilePage extends StatefulWidget {
  const ProfessorProfilePage({super.key});

  @override
  State<ProfessorProfilePage> createState() => _ProfessorProfilePageState();
}

class _ProfessorProfilePageState extends State<ProfessorProfilePage> {
  int _tabIndex = 0; // 0:Inicio, 1:Proyectos, 2:Estudiantes, 3:Perfil
  late AppUser user;

  String? _selectedStudentEmail;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    user = (ModalRoute.of(context)?.settings.arguments as AppUser?)!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.withOpacity(.08),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: const [
            SizedBox(width: 16),
            _MetroMark(),
            SizedBox(width: 12),
            Text(
              'METRO MANAGER PROFESOR',
              style: TextStyle(
                color: Color(0xFF0E2238),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0E2238),
                side: BorderSide(color: Colors.grey.withOpacity(.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                    (r) => false,
              ),
              child: const Text('Salir'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    _TopTab(
                      label: 'Página Principal',
                      selected: _tabIndex == 0,
                      onTap: () => setState(() => _tabIndex = 0),
                    ),
                    _TopTab(
                      label: 'Proyectos',
                      selected: _tabIndex == 1,
                      onTap: () => setState(() => _tabIndex = 1),
                    ),
                    _TopTab(
                      label: 'Estudiantes',
                      selected: _tabIndex == 2,
                      onTap: () => setState(() => _tabIndex = 2),
                    ),
                    _TopTab(
                      label: 'Perfil',
                      selected: _tabIndex == 3,
                      onTap: () => setState(() => _tabIndex = 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: _buildBody(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_tabIndex) {
      case 0:
        return _professorDashboard();
      case 1:
        return _projectsManagement();
      case 2:
        return _studentsManagement();
      case 3:
      default:
        return _professorProfile();
    }
  }

  Widget _professorDashboard() {
    final students = UserRepository.instance.students;
    final totalProjects = ProjectRepository.instance.allProjects.length;

    return ProfessorHomeSection(
      user: user,
      totalStudents: students.length,
      totalProjects: totalProjects,
      onGoToProjects: () => setState(() => _tabIndex = 1),
      onGoToStudents: () => setState(() => _tabIndex = 2),
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
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF667085),
              ),
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
              child: ListView.separated(
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
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (p.tasks.isEmpty)
                            const Text(
                              '• (Sin tareas definidas aún)',
                              style: TextStyle(fontSize: 12),
                            ),
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
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStudentEmail,
                    decoration: const InputDecoration(
                      labelText: 'Estudiante',
                    ),
                    items: students
                        .map(
                          (s) => DropdownMenuItem(
                        value: s.email,
                        child: Text(
                          '${s.nombre} ${s.apellido} (${s.email})',
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedStudentEmail = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
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
                      onPressed: _selectedStudentEmail == null
                          ? null
                          : () {
                        ProjectRepository.instance.addRequestForStudent(
                          _selectedStudentEmail!,
                          p,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Solicitud enviada a $_selectedStudentEmail',
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

  Widget _professorProfile() {
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

  /// ********** DIÁLOGO NUEVO DE CREAR PROYECTO (ARREGLADO) **********
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
                              errorText = null;
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (tasks.isNotEmpty)
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                          itemCount: tasks.length,
                          itemBuilder: (_, index) {
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.check_circle_outline,
                                size: 18,
                              ),
                              title: Text(
                                tasks[index],
                                style: const TextStyle(fontSize: 13),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () {
                                  setStateDialog(() {
                                    tasks.removeAt(index);
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    if (errorText != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          errorText!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
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
                        'Completa nombre, curso y descripción del proyecto.';
                      });
                      return;
                    }

                    final projectId =
                        'p_${DateTime.now().millisecondsSinceEpoch}';

                    // Si no agregas tareas, se crea al menos una por defecto
                    final taskList = tasks.isEmpty
                        ? [
                      ProjectTask(
                        id: '${projectId}_t1',
                        title:
                        'Definir pasos y entregables para este proyecto',
                      )
                    ]
                        : List.generate(
                      tasks.length,
                          (index) => ProjectTask(
                        id: '${projectId}_t${index + 1}',
                        title: tasks[index],
                      ),
                    );

                    final project = Project(
                      id: projectId,
                      name: name,
                      course: course,
                      description: desc,
                      tasks: taskList,
                    );

                    Navigator.of(dialogContext).pop(project);
                  },
                  child: const Text('Guardar'),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Proyecto "${newProject.name}" creado'),
        ),
      );
    }
  }
}

/// Home del profesor

class ProfessorHomeSection extends StatelessWidget {
  final AppUser user;
  final int totalStudents;
  final int totalProjects;
  final VoidCallback onGoToProjects;
  final VoidCallback onGoToStudents;
  final VoidCallback onCreateProject;

  const ProfessorHomeSection({
    super.key,
    required this.user,
    required this.totalStudents,
    required this.totalProjects,
    required this.onGoToProjects,
    required this.onGoToStudents,
    required this.onCreateProject,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Card(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: DashboardSummaryCard(
                      icon: Icons.people_outline,
                      title: 'Estudiantes registrados',
                      value: totalStudents.toString(),
                      subtitle: 'Estudiantes que han creado cuenta.',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DashboardSummaryCard(
                      icon: Icons.work_outline,
                      title: 'Proyectos configurados',
                      value: totalProjects.toString(),
                      subtitle: 'Proyectos disponibles para asignar.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 720;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildNewsCard()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildQuickActionsCard()),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildNewsCard(),
                      const SizedBox(height: 16),
                      _buildQuickActionsCard(),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final nombre = user.nombre.isEmpty ? 'Profesor' : user.nombre;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kDeepBlue, Color(0xFF174773)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $nombre 👋',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Desde aquí puedes gestionar tus proyectos y las solicitudes a estudiantes.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _BubbleChip(
                      icon: Icons.work_outline,
                      label: 'Proyectos',
                    ),
                    _BubbleChip(
                      icon: Icons.people_outline,
                      label: 'Estudiantes',
                    ),
                    _BubbleChip(
                      icon: Icons.mail_outline,
                      label: 'Solicitudes',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 110,
            height: 100,
            child: Stack(
              children: [
                Positioned(
                  bottom: 0,
                  left: 8,
                  right: 8,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.manage_accounts_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 0,
                  child: _floatingCircleIcon(
                    Icons.campaign_outlined,
                  ),
                ),
                Positioned(
                  top: 24,
                  left: 0,
                  child: _floatingCircleIcon(
                    Icons.timeline_outlined,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard() {
    final noticias = [
      {
        'titulo': 'Recordatorio de revisión de avances',
        'detalle':
        'Revisa los avances de los grupos antes del viernes para dar feedback.',
      },
      {
        'titulo': 'Nuevo taller de proyectos',
        'detalle':
        'Organiza una sesión de dudas de MetroManager para tus estudiantes.',
      },
      {
        'titulo': 'Consejo',
        'detalle':
        'Crea proyectos con tareas claras para que los estudiantes sepan exactamente qué hacer.',
      },
    ];

    return Card(
      elevation: 0,
      color: Colors.grey.withOpacity(.03),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Novedades para profesores',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0E2238),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Información relevante para la gestión de tus cursos.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 14),
            ...noticias.map(
                  (n) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n['titulo'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0E2238),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      n['detalle'] as String,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 0,
      color: Colors.grey.withOpacity(.03),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Acciones rápidas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0E2238),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _quickActionButton(
                  icon: Icons.work_outline,
                  label: 'Ver proyectos',
                  onTap: onGoToProjects,
                ),
                _quickActionButton(
                  icon: Icons.people_outline,
                  label: 'Ver estudiantes',
                  onTap: onGoToStudents,
                ),
                _quickActionButton(
                  icon: Icons.add_circle_outline,
                  label: 'Crear proyecto',
                  onTap: onCreateProject,
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Consejos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0E2238),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '• Pon nombres claros a tus proyectos.\n'
                  '• Agrega tareas como pasos concretos (ej: “1) Levantar requisitos”, “2) Hacer mockups”).\n'
                  '• Usa la pestaña Estudiantes para enviar las solicitudes.',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF667085),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 220,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
        ),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          side: BorderSide(color: Colors.grey.withOpacity(.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// ======================== WIDGETS AUXILIARES ========================

class DashboardSummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const DashboardSummaryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.withOpacity(.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kAccentYellow.withOpacity(.20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF0E2238)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0E2238),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF667085),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0E2238),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TopTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: const Color(0xFF0E2238),
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 3,
              width: 48,
              decoration: BoxDecoration(
                color: selected ? kAccentYellow : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldBlock extends StatelessWidget {
  final String title;
  final TextEditingController? controllerLeft;
  final TextEditingController? controllerRight;
  final TextEditingController? controller;
  final String? hint;
  final bool readOnly;

  const _FieldBlock({
    required this.title,
    this.controllerLeft,
    this.controllerRight,
  })  : controller = null,
        hint = null,
        readOnly = false;

  const _FieldBlock.single({
    required this.title,
    required this.controller,
    this.hint,
    this.readOnly = false,
  })  : controllerLeft = null,
        controllerRight = null;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Color(0xFF0E2238),
      ),
    );

    if (controller != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label,
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            readOnly: readOnly,
            decoration: InputDecoration(
              hintText: hint,
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: kAccentYellow, width: 1.2),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: kAccentYellow, width: 1.6),
              ),
              suffixIcon:
              readOnly ? null : const Icon(Icons.edit, size: 18),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label,
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controllerLeft,
                decoration: const InputDecoration(
                  hintText: 'Nombre',
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: kAccentYellow, width: 1.2),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: kAccentYellow, width: 1.6),
                  ),
                  suffixIcon: Icon(Icons.edit, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                controller: controllerRight,
                decoration: const InputDecoration(
                  hintText: 'Apellido',
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: kAccentYellow, width: 1.2),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: kAccentYellow, width: 1.6),
                  ),
                  suffixIcon: Icon(Icons.edit, size: 18),
                ),
              ),
            ),
          ],
        ),
      ],
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
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF0E2238),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: kAccentYellow, width: 1.2),
            ),
          ),
          width: double.infinity,
          child: Text(value),
        ),
      ],
    );
  }
}

class _LogoTitleRow extends StatelessWidget {
  const _LogoTitleRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _MetroMark(),
        SizedBox(width: 18),
        _LogoTitle(),
      ],
    );
  }
}

class _LogoTitle extends StatelessWidget {
  const _LogoTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'METRO',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0E2238),
          ),
        ),
        Text(
          'MANAGER',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0E2238),
          ),
        ),
      ],
    );
  }
}

class _MetroMark extends StatelessWidget {
  const _MetroMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _markBar(kAccentYellow, 18),
          const SizedBox(width: 4),
          _markBar(kAccentYellow, 26),
          const SizedBox(width: 4),
          _markBar(kAccentYellow, 18),
        ],
      ),
    );
  }

  Widget _markBar(Color c, double h) {
    return Container(
      width: 8,
      height: h,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color accentColor;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.accentColor,
    super.key,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: widget.onTap,
        onHover: (v) => setState(() => _hover = v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hover
                  ? widget.accentColor.withOpacity(.7)
                  : const Color(0xFFE6E8EC),
              width: _hover ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  color: const Color(0xFF0E2238),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0E2238),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(color: Color(0xFF475467)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: widget.onTap,
                child: const Text('Continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Scroll amigable en Web
class _WebScrollBehavior extends MaterialScrollBehavior {
  const _WebScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

/// ============ VALIDADORES ============

String? _unimetEmailValidator(String? v) {
  if (v == null || v.trim().isEmpty) {
    return 'Ingresa tu correo UNIMET';
  }
  final email = v.trim();
  final ok = RegExp(
    r'^[^@]+@(correo\.unimet\.edu\.ve|unimet\.edu\.ve)$',
  ).hasMatch(email);
  if (!ok) {
    return 'Usa tu correo institucional (@correo.unimet.edu.ve o @unimet.edu.ve)';
  }
  return null;
}

String? _passwordValidator(String? v) {
  if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
  if (v.length < 6) return 'Mínimo 6 caracteres';
  return null;
}

String? Function(String?) _requiredValidator(String message) {
  return (v) => (v == null || v.trim().isEmpty) ? message : null;
}


// NUEVO BOTON

class MetroQuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? helper;
  final VoidCallback onTap;
  final double width;

  const MetroQuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.helper,
    this.width = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
            border: Border.all(color: Colors.grey.withOpacity(.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: kAccentYellow.withOpacity(.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF0E2238)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0E2238),
                      ),
                    ),
                    if (helper != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        helper!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF667085),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: Color(0xFF98A2B3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



// HERO NUEVO BOTON REUTILIZABLE


class MetroHeroHeader extends StatelessWidget {
  final AppUser user;
  final String subtitle;
  final List<Widget> actions;
  final List<Widget> chips;
  final List<Widget> stats;

  const MetroHeroHeader({
    super.key,
    required this.user,
    required this.subtitle,
    this.actions = const [],
    this.chips = const [],
    this.stats = const [],
  });

  @override
  Widget build(BuildContext context) {
    final nombre = user.fullName.isEmpty ? 'Usuario' : user.fullName;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kDeepBlue, Color(0xFF174773)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // LADO IZQUIERDO: info principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: kAccentYellow.withOpacity(.22),
                      child: Text(
                        user.initials,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, $nombre 👋',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.white.withOpacity(.85),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (chips.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: chips,
                  ),
                if (stats.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: stats,
                  ),
                ],
              ],
            ),
          ),

          // LADO DERECHO: acciones / iconos
          if (actions.isNotEmpty) ...[
            const SizedBox(width: 16),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}


// TARJETA DE SECCION PRE ARMADA

class MetroSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  const MetroSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MetroSectionHeader(
              title: title,
              subtitle: subtitle,
              trailing: trailing,
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

// FONDO

class MetroGradientBackground extends StatelessWidget {
  final Widget child;

  const MetroGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8FAFF),
            Color(0xFFE6EDF7),
          ],
        ),
      ),
      child: child,
    );
  }
}


