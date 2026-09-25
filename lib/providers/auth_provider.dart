import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../models/user.dart';
import '../services/insforge_service.dart';


class AuthProvider extends ChangeNotifier {
  final InsForgeService _service = InsForgeService();

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  String? get error => _error;
  String get userId => _currentUser?.id ?? '';

  Future<AuthResult> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final session = await _service.signIn(username, password);
      if (session == null) {
        _isLoading = false;
        _error = 'Usuario o contraseña incorrectos.';
        notifyListeners();
        return AuthResult(error: _error);
      }

      final profile = await _service.getUserProfile(session.userId);
      if (profile == null) {
        await _service.signOut();
        _isLoading = false;
        _error = 'Tu cuenta no tiene perfil asociado. Contacta al administrador.';
        notifyListeners();
        return AuthResult(error: _error);
      }

      final user = AppUser.fromMap(profile);
      if (user.isApproved) {
        _currentUser = user;
        _error = null;
        _isLoading = false;
        notifyListeners();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('bg_user_id', user.id);
        await prefs.setString('bg_refresh_token', session.refreshToken);
        if (!kIsWeb) {
          await Workmanager().registerPeriodicTask(
            'checkNewMessages',
            'checkNewMessages',
            frequency: const Duration(minutes: 15),
            constraints: Constraints(networkType: NetworkType.connected),
          );
        }

        return AuthResult(user: user);
      } else {
        // Cuenta pendiente o rechazada: no debe quedar sesion abierta.
        await _service.signOut();
        _isLoading = false;
        notifyListeners();
        if (user.isRejected) {
          return AuthResult(error: 'Tu solicitud de acceso fue rechazada. Contacta al administrador.');
        }
        return AuthResult(error: 'Tu cuenta está pendiente de aprobación.');
      }
    } catch (e, stack) {
      print('[LOGIN ERROR] $e');
      print('[LOGIN STACK] $stack');
      _isLoading = false;
      _error = 'Error: $e';
      notifyListeners();
      return AuthResult(error: _error);
    }
  }

  Future<AuthResult> register({
    required String name,
    required String username,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (await _service.checkUsernameExists(username)) {
        _isLoading = false;
        _error = 'Ese nombre de usuario ya está en uso.';
        notifyListeners();
        return AuthResult(error: _error);
      }

      final data = await _service.registerUser(
        name: name,
        username: username,
        phone: phone,
        password: password,
      );
      _isLoading = false;
      if (data != null) {
        notifyListeners();
        return AuthResult(user: AppUser.fromMap(data));
      } else {
        _error = 'Error al registrarse. Prueba con otro usuario.';
        notifyListeners();
        return AuthResult(error: _error);
      }
    } on InsForgeRpcException catch (e) {
      _isLoading = false;
      _error = e.message;
      notifyListeners();
      return AuthResult(error: _error);
    } catch (e) {
      _isLoading = false;
      _error = 'Error de conexión. Intenta de nuevo.';
      notifyListeners();
      return AuthResult(error: _error);
    }
  }

  Future<void> logout() async {
    await _service.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bg_user_id');
    await prefs.remove('bg_refresh_token');
    if (!kIsWeb) {
      await Workmanager().cancelAll();
    }
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
