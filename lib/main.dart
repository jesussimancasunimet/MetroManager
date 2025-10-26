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


