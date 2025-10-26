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
 AppUser? login(String email, String password) { // Verifica password
   final key = email.toLowerCase().trim();
   final user = _users[key];
   if (user == null) return null;
   if (user.password != password) return null; // Devuelve
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
                                'Solo se permiten correos institucionales UNIMET\n' // Comment
                                    'Estudiantes: @correo.unimet.edu.ve\n' // Identifica estudiantes
                                    'Profesores: @unimet.edu.ve', // Identifica profe
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
    return Scaiold(
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
      child: const Text('Regístrate', style: TextStyle(color: kAccentYellow, fontWeight:
      FontWeight.w800)),
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


