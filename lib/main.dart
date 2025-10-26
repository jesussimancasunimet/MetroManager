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
