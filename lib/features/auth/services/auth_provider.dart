import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Provedor de Autenticação do Firebase com integração ao Firestore.
/// Gerencia o estado do usuário, autenticação e dados no banco de dados.
class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;

  AuthProvider() {
    // Escuta mudanças no estado de autenticação (logado/deslogado)
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _loadUserData();
      } else {
        _userData = null;
        notifyListeners();
      }
    });
  }

  /// Busca dados adicionais do usuário no Firestore.
  Future<void> _loadUserData() async {
    if (_user != null) {
      try {
        DocumentSnapshot doc = await _db.collection('users').doc(_user!.uid).get();
        if (doc.exists) {
          _userData = doc.data() as Map<String, dynamic>;
          notifyListeners();
        }
      } catch (e) {
        debugPrint("Erro ao carregar dados do usuário: $e");
      }
    }
  }

  /// Método para Cadastrar um novo usuário com e-mail e senha e salvar no Firestore.
  Future<String?> signUp(String email, String password, {String? displayName, String? phoneNumber}) async {
    _setLoading(true);
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      User? user = userCredential.user;
      if (user != null) {
        // Criar documento do usuário no Firestore
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'displayName': displayName ?? '',
          'phoneNumber': phoneNumber ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (displayName != null) {
          await user.updateDisplayName(displayName);
        }
        await _loadUserData();
      }
      
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

  /// Método para Cadastrar com E-mail e vincular Telefone, salvando no Firestore.
  Future<String?> signUpWithEmailAndPhone({
    required String email,
    required String password,
    required String verificationId,
    required String smsCode,
    String? displayName,
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

      // 4. Salvar dados no Firestore
      await _db.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'phoneNumber': userCredential.user!.phoneNumber,
        'displayName': displayName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (displayName != null) {
        await userCredential.user!.updateDisplayName(displayName);
      }
      await _loadUserData();

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

  /// Atualiza o nome de exibição do usuário no Auth e no Firestore.
  Future<String?> updateDisplayName(String name) async {
    _setLoading(true);
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.updateDisplayName(name);
        
        // Atualizar no Firestore
        await _db.collection('users').doc(currentUser.uid).update({
          'displayName': name,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await currentUser.reload();
        _user = _auth.currentUser;
        await _loadUserData();
      }
      _setLoading(false);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return _getFirebaseErrorMessage(e.code);
    } catch (e) {
      _setLoading(false);
      return "Erro ao atualizar nome.";
    }
  }

  /// Atualiza o e-mail do usuário no Auth e Firestore.
  Future<String?> updateEmail(String newEmail) async {
    _setLoading(true);
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Nota: O Firebase exige login recente para mudar e-mail
        await currentUser.verifyBeforeUpdateEmail(newEmail);
        
        // Atualiza o Firestore imediatamente (ou você pode esperar a verificação)
        await _db.collection('users').doc(currentUser.uid).update({
          'email': newEmail,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        await _loadUserData();
      }
      _setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return _getFirebaseErrorMessage(e.code);
    } catch (e) {
      _setLoading(false);
      return "Erro ao solicitar alteração de e-mail.";
    }
  }

  /// Atualiza o número de telefone no Firestore.
  Future<String?> updatePhoneNumber(String phoneNumber) async {
    _setLoading(true);
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _db.collection('users').doc(currentUser.uid).update({
          'phoneNumber': phoneNumber,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await _loadUserData();
      }
      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return "Erro ao atualizar telefone.";
    }
  }

  /// Exclui a conta do usuário.
  Future<String?> deleteAccount() async {
    _setLoading(true);
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        String uid = currentUser.uid;
        await currentUser.delete();
        // Opcional: Remover dados do Firestore ao deletar a conta
        await _db.collection('users').doc(uid).delete();
      }
      _setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return _getFirebaseErrorMessage(e.code);
    } catch (e) {
      _setLoading(false);
      return "Erro ao excluir conta.";
    }
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
