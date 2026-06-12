import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';

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
        NotificationService.saveTokenToFirestore(user.uid);
      } else {
        _userData = null;
        notifyListeners();
      }
    });
  }

  /// Mostra notificação de boas vindas
  void _showWelcomeNotification(User user) {
    final name = _userData?['displayName'] ?? user.displayName ?? 'Usuário';
    NotificationService.showNotification(
      id: 0,
      title: 'Login realizado',
      body: 'Seja bem vindo $name',
    );
  }

  /// Busca dados adicionais do usuário no Firestore.
  Future<void> _loadUserData() async {
    if (_user != null) {
      try {
        DocumentSnapshot doc = await _db.collection('users').doc(_user!.uid).get();
        if (doc.exists) {
          _userData = doc.data() as Map<String, dynamic>;
          notifyListeners();
        } else {
          debugPrint("Aviso: Documento do usuário ${_user!.uid} não encontrado no Firestore.");
        }
      } catch (e) {
        debugPrint("Erro ao carregar dados do usuário (UID: ${_user!.uid}): $e");
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
        _showWelcomeNotification(user);
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
          UserCredential userCredential = await _auth.signInWithCredential(credential);
          if (userCredential.user != null) {
            await _loadUserData();
            _showWelcomeNotification(userCredential.user!);
          }
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
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _loadUserData();
        _showWelcomeNotification(userCredential.user!);
      }
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
      _showWelcomeNotification(userCredential.user!);

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
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        await _loadUserData();
        _showWelcomeNotification(userCredential.user!);
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

  /// Método para deslogar.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Atualiza os dados do perfil no Firebase Auth e no Firestore de uma vez.
  Future<String?> updateFullProfile({
    String? displayName,
    String? phoneNumber,
    String? photoURL,
  }) async {
    _setLoading(true);
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return "Usuário não autenticado.";

      Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Atualizar no Firebase Auth (se aplicável)
      if (displayName != null || photoURL != null) {
        await currentUser.updateDisplayName(displayName ?? currentUser.displayName);
        await currentUser.updatePhotoURL(photoURL ?? currentUser.photoURL);
        
        if (displayName != null) updates['displayName'] = displayName;
        if (photoURL != null) updates['photoURL'] = photoURL;
      }

      // No Firestore, também atualizamos o telefone
      if (phoneNumber != null) {
        updates['phoneNumber'] = phoneNumber;
      }

      // Atualizar no Firestore
      await _db.collection('users').doc(currentUser.uid).update(updates);

      // Recarregar usuário para refletir mudanças no Auth
      await currentUser.reload();
      _user = _auth.currentUser;
      await _loadUserData();

      _setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return _getFirebaseErrorMessage(e.code);
    } catch (e) {
      _setLoading(false);
      debugPrint("Erro ao atualizar perfil: $e");
      return "Erro ao atualizar perfil.";
    }
  }

  /// Atualiza o nome de exibição do usuário no Auth e no Firestore.
  Future<String?> updateDisplayName(String name) async {
    return updateFullProfile(displayName: name);
  }

  /// Atualiza o e-mail do usuário no Auth e Firestore.
  /// Nota: O e-mail no Auth só muda após a verificação do novo endereço.
  Future<String?> updateEmail(String newEmail) async {
    _setLoading(true);
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Solicita a alteração no Firebase Auth
        await currentUser.verifyBeforeUpdateEmail(newEmail);
        
        // Atualiza o Firestore (opcional: você pode preferir atualizar apenas após verificado)
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
    return updateFullProfile(phoneNumber: phoneNumber);
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
