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

  /// Método para iniciar a verificação de telefone.
  Future<void> verifyPhone(
    String phoneNumber, {
    required Function(String verificationId) onCodeSent,
    required Function(String errorMessage) onError,
  }) async {
    _setLoading(true);
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          _setLoading(false);
        },
        verificationFailed: (FirebaseAuthException e) {
          _setLoading(false);
          onError(_getFirebaseErrorMessage(e.code));
        },
        codeSent: (String verificationId, int? resendToken) {
          _setLoading(false);
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _setLoading(false);
        },
      );
    } catch (e) {
      _setLoading(false);
      onError("Erro ao verificar telefone.");
    }
  }

  /// Método para completar o login com o código SMS.
  Future<String?> signInWithOTP(String verificationId, String smsCode) async {
    _setLoading(true);
    try {
      AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
      _setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return _getFirebaseErrorMessage(e.code);
    } catch (e) {
      _setLoading(false);
      return "Ocorreu um erro inesperado.";
    }
  }

  /// Método para Cadastrar com E-mail e vincular Telefone simultaneamente.
  Future<String?> signUpWithEmailAndPhone({
    required String email,
    required String password,
    required String verificationId,
    required String smsCode,
  }) async {
    _setLoading(true);
    try {
      // 1. Criar usuário com E-mail e Senha
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Criar credencial de Telefone
      AuthCredential phoneCredential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // 3. Vincular o telefone à conta recém-criada
      await userCredential.user!.linkWithCredential(phoneCredential);

      _setLoading(false);
      return null;
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
      case 'invalid-phone-number':
        return 'Número de telefone inválido.';
      case 'too-many-requests':
        return 'Muitas solicitações. Tente novamente mais tarde.';
      case 'invalid-verification-code':
        return 'Código de verificação inválido.';
      default:
        return 'Erro na autenticação. Tente novamente.';

    }
  }
}
