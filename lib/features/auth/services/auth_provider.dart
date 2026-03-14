import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Provedor de Autenticação do Firebase.
/// Gerencia o estado do usuário e métodos de Login e Cadastro.
class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;

  AuthProvider() {
    // Escuta mudanças no estado de autenticação (logado/deslogado)
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  /// Método para Cadastrar um novo usuário com e-mail e senha.
  Future<String?> signUp(String email, String password) async {
    _setLoading(true);
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      _setLoading(false);
      return null; // Sucesso
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return _getFirebaseErrorMessage(e.code);
    } catch (e) {
      _setLoading(false);
      return "Ocorreu um erro inesperado.";
    }
  }

  /// Método para Logar um usuário existente.
  Future<String?> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _setLoading(false);
      return null; // Sucesso
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return _getFirebaseErrorMessage(e.code);
    } catch (e) {
      _setLoading(false);
      return "Ocorreu um erro inesperado.";
    }
  }

  /// Método para deslogar.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Converte códigos de erro do Firebase para mensagens amigáveis em Português.
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'email-already-in-use':
        return 'Este e-mail já está em uso.';
      case 'weak-password':
        return 'A senha é muito fraca.';
      case 'invalid-email':
        return 'E-mail inválido.';
      default:
        return 'Erro na autenticação. Tente novamente.';
    }
  }
}
