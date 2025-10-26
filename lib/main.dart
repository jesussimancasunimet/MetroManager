// PRIMER DIA DE TRABAJO
// FOTOS JUNTOS
// https://drive.google.com/drive/folders/1UMj6OgQgoc3GavE7xWEY5IawKM2NU0KG

import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Paleta global
const kDeepBlue = Color(0xFF0F3A63);
const kAccentYellow = Color(0xFFF0B429);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const MetroManagerApp());
}

/// ======================== MODELOS Y REPO (DEMO) ========================
class AppUser {
  final String role;        // 'estudiante' o 'profesor'
  String nombre;            // editable en Perfil
  String apellido;          // editable en Perfil
  final String email;
  final String password;
  final String campoExtra;  // carrera (estudiante) o profesión (profesor)

  String cedula;            // editable
  String bio;               // editable

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
}

/// ======================== APP ROOT ========================
class MetroManagerApp extends StatelessWidget {
  const MetroManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: kDeepBlue,
      brightness: Brightness.light,
      primary: kDeepBlue,
    );

    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: kDeepBlue,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(color: const Color(0xFF0E2238).withValues(alpha: .8)),
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
          borderSide: BorderSide(color: Colors.red.withValues(alpha: .9)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: .12),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.white.withValues(alpha: .12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white70),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        side: const BorderSide(color: Colors.white70),
        checkColor: WidgetStateProperty.all(kDeepBlue),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withValues(alpha: .9),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      }),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 400));

    final user = UserRepository.instance.login(_emailCtrl.text, _passCtrl.text);

    setState(() => _loading = false);

    if (user == null) {
      if (!UserRepository.instance.exists(_emailCtrl.text)) {
        _showSnack('No estás registrado. Usa “Regístrate” para crear tu cuenta.');
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
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
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Inicia sesión para poder proceder',
                    style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: .85)),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _emailCtrl,
                    autofillHints: const [AutofillHints.email],
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Color(0xFF0E2238)),
                    decoration: const InputDecoration(
                      hintText: 'usuario@correo.unimet.edu.ve o usuario@unimet.edu.ve',
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
                        child: Icon(Icons.info_outline, color: Colors.white70, size: 18),
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
                        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure = !_obscure),
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
                          onChanged: (v) => setState(() => _remember = v ?? false),
                        ),
                        const SizedBox(width: 6),
                        const Text('Recordar Contraseña', style: TextStyle(color: Colors.white)),
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
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
                      Text('¿No tienes cuenta?', style: TextStyle(color: Colors.white)),
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
            padding: EdgeInsets.symmetric(horizontal: isWide ? 60 : 18, vertical: 40),
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
      child: const Text('Regístrate', style: TextStyle(color: kAccentYellow, fontWeight: FontWeight.w800)),
    );
  }
}

/// ======================== ROLE SELECT ========================
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                        child: _LogoTitleRow(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Crear cuenta', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (_, c) {
                    final two = c.maxWidth >= 720;
                    final cards = [
                      _RoleCard(
                        icon: Icons.school_outlined,
                        title: 'Estudiante',
                        subtitle: 'Gestiona clases, tareas y más.',
                        onTap: () => Navigator.pushNamed(context, '/register', arguments: 'estudiante'),
                        accentColor: kAccentYellow,
                      ),
                      _RoleCard(
                        icon: Icons.person_outline,
                        title: 'Profesor',
                        subtitle: 'Organiza cursos y tus grupos.',
                        onTap: () => Navigator.pushNamed(context, '/register', arguments: 'profesor'),
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
                    return Column(children: [cards[0], const SizedBox(height: 12), cards[1]]);
                  },
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  label: const Text('Volver', style: TextStyle(color: Colors.white)),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
    Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false, arguments: user);
  }

  @override
  Widget build(BuildContext context) {
    final role = ModalRoute.of(context)?.settings.arguments as String? ?? 'estudiante';
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                        child: _LogoTitleRow(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Registro - ${esEstudiante ? "Estudiante" : "Profesor"}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Card(
                    color: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                                      textCapitalization: TextCapitalization.words,
                                      decoration: const InputDecoration(
                                        labelText: 'Nombre',
                                        prefixIcon: Icon(Icons.badge_outlined),
                                      ),
                                      validator: _requiredValidator('Ingresa tu nombre'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _apellidoCtrl,
                                      textCapitalization: TextCapitalization.words,
                                      decoration: const InputDecoration(
                                        labelText: 'Apellido',
                                        prefixIcon: Icon(Icons.badge),
                                      ),
                                      validator: _requiredValidator('Ingresa tu apellido'),
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
                                  hintText: 'usuario@correo.unimet.edu.ve o usuario@unimet.edu.ve',
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
                                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: _passwordValidator,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _extraCtrl,
                                textCapitalization: TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  labelText: labelExtra,
                                  prefixIcon: Icon(esEstudiante ? Icons.school_outlined : Icons.work_outline),
                                ),
                                validator: _requiredValidator(esEstudiante ? 'Ingresa tu carrera' : 'Ingresa tu profesión'),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: _saving
                                      ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                      : const Icon(Icons.person_add_alt),
                                  label: const Text('Registrarse'),
                                  onPressed: _saving ? null : () => _onRegister(role),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextButton.icon(
                                onPressed: _saving ? null : () => Navigator.pop(context),
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
    // Redirige después del primer frame (evita warnings con BuildContext)
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

  int _tabIndex = 3; // 0:Inicio, 1:Proyectos, 2:Solicitudes, 3:Perfil

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
      backgroundColor: Colors.grey.withValues(alpha: .08),
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
            Text('METRO MANAGER ESTUDIANTE',
                style: TextStyle(color: Color(0xFF0E2238), fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0E2238),
                side: BorderSide(color: Colors.grey.withValues(alpha: .4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              ),
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false),
              child: const Text('Salir'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // NAV TABS
          Container(
            color: Colors.white,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    _TopTab(label: 'Página Principal', selected: _tabIndex == 0, onTap: () => setState(() => _tabIndex = 0)),
                    _TopTab(label: 'Mis Proyectos', selected: _tabIndex == 1, onTap: () => setState(() => _tabIndex = 1)),
                    _TopTab(label: 'Solicitudes Enviadas', selected: _tabIndex == 2, onTap: () => setState(() => _tabIndex = 2)),
                    _TopTab(label: 'Perfil', selected: _tabIndex == 3, onTap: () => setState(() => _tabIndex = 3)),
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
                  child: _tabIndex == 3 ? _profileContent() : _placeholderSection(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderSection() {
    final titles = ['Página Principal', 'Mis Proyectos', 'Solicitudes Enviadas'];
    return Card(
      color: Colors.white,
      child: Center(
        child: Text('Sección: ${titles[_tabIndex]} (demo)',
            style: const TextStyle(fontSize: 18, color: Color(0xFF0E2238))),
      ),
    );
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
                    hintLeft: 'Nombre',
                    hintRight: 'Apellido',
                  ),
                  const SizedBox(height: 18),
                  _FieldBlock.single(
                    title: 'Cédula',
                    controller: _cedulaCtrl,
                    hint: 'Ej: 31894531',
                  ),
                  const SizedBox(height: 18),
                  _FieldBlock.single(
                    title: 'Carrera',
                    controller: TextEditingController(text: user.campoExtra),
                    hint: 'Tu carrera',
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
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  const Text('Biografía Personal',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0E2238))),
                  const SizedBox(height: 4),
                  const Text('(Opcional)', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioCtrl,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      hintText: 'Escribe algo sobre ti...',
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: kAccentYellow, width: 1.2),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: kAccentYellow, width: 1.6),
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
      user.nombre  = _nombreCtrl.text.trim();
      user.apellido = _apellidoCtrl.text.trim();
      user.cedula  = _cedulaCtrl.text.trim();
      user.bio     = _bioCtrl.text.trim();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
  }
}


/// ======================== PERFIL PROFESOR ========================
class ProfessorProfilePage extends StatelessWidget {
  const ProfessorProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = (ModalRoute.of(context)?.settings.arguments as AppUser?)!;
    return Scaffold(
      backgroundColor: Colors.grey.withValues(alpha: .08),
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
            Text('METRO MANAGER PROFESOR',
                style: TextStyle(color: Color(0xFF0E2238), fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0E2238),
                side: BorderSide(color: Colors.grey.withValues(alpha: .4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              ),
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false),
              child: const Text('Salir'),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _FieldRowStatic(label: 'Nombre y Apellido', value: '${user.nombre} ${user.apellido}'),
                          const SizedBox(height: 18),
                          _FieldRowStatic(label: 'Profesión', value: user.campoExtra),
                          const SizedBox(height: 18),
                          _FieldRowStatic(label: 'Correo Electrónico', value: user.email),
                          const SizedBox(height: 18),
                          _FieldRowStatic(label: 'Cédula', value: user.cedula.isEmpty ? '—' : user.cedula),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  flex: 2,
                  child: Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Biografía',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0E2238))),
                          const SizedBox(height: 8),
                          Text(user.bio.isEmpty ? 'Sin biografía' : user.bio),
                        ],
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

class _FieldRowStatic extends StatelessWidget {
  final String label;
  final String value;
  const _FieldRowStatic({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0E2238))),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: kAccentYellow, width: 1.2)),
          ),
          width: double.infinity,
          child: Text(value),
        ),
      ],
    );
  }
}

/// ======================== WIDGETS AUXILIARES ========================
class _TopTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TopTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    color: const Color(0xFF0E2238),
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500)),
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
  final String? hintLeft;
  final String? hintRight;
  final String? hint;
  final bool readOnly;

  const _FieldBlock({
    required this.title,
    this.controllerLeft,
    this.controllerRight,
    this.hintLeft,
    this.hintRight,
    this.readOnly = false,
  })  : controller = null,
        hint = null;

  const _FieldBlock.single({
    required this.title,
    required this.controller,
    this.hint,
    this.readOnly = false,
  })  : controllerLeft = null,
        controllerRight = null,
        hintLeft = null,
        hintRight = null;

  @override
  Widget build(BuildContext context) {
    final label = Text(title,
        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0E2238)));

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
              suffixIcon: readOnly ? null : const Icon(Icons.edit, size: 18),
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
        Text('METRO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0E2238))),
        Text('MANAGER', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0E2238))),
      ],
    );
  }
}

class _MetroMark extends StatelessWidget {
  const _MetroMark();
  @override
  Widget build(BuildContext context) {
    // Logo simple: 3 barras verticales
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

  Widget _markBar(Color c, double h) => Container(
    width: 8,
    height: h,
    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
  );
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
                  ? widget.accentColor.withValues(alpha: .7)
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
                  color: widget.accentColor.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: const Color(0xFF0E2238)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('', style: TextStyle(height: 0)),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0E2238),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(widget.subtitle,
                        style: const TextStyle(color: Color(0xFF475467))),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: widget.onTap, child: const Text('Continuar')),
            ],
          ),
        ),
      ),
    );
  }
}

/// Scroll amigable en Web (mouse/trackpad/touch)
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
  if (v == null || v.trim().isEmpty) return 'Ingresa tu correo UNIMET';
  final email = v.trim();
  final ok = RegExp(r'^[^@]+@(correo\.unimet\.edu\.ve|unimet\.edu\.ve)$').hasMatch(email);
  if (!ok) return 'Usa tu correo institucional (@correo.unimet.edu.ve o @unimet.edu.ve)';
  return null;
}

String? _passwordValidator(String? v) {
  if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
  if (v.length < 6) return 'Mínimo 6 caracteres';
  return null;
}

String? Function(String?) _requiredValidator(String message) =>
        (v) => (v == null || v.trim().isEmpty) ? message : null;

 // FINAL LO LOGRAMOS SI CORRE
// FOTICO JUNTOS
// https://drive.google.com/file/d/1eNbDjN2aPTE_yJkO8kFhOcsTiB2yscsj/view?usp=drivesdk
