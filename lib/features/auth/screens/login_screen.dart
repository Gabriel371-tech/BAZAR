import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/bazar_button.dart';
import '../../../core/widgets/bazar_text_field.dart';
import '../../home/screens/dashboard_screen.dart';
import '../services/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tela de Login do Bazar.
/// Permite que usuários existentes entrem em suas contas.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPhoneAuth = false;
  bool _isCodeSent = false;
  String _verificationId = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _onLogin(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (!_isPhoneAuth) {
        // Login por E-mail
        final error = await authProvider.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (!mounted) return;
        _handleResult(context, error);
      } else {
        // Login por Telefone
        if (!_isCodeSent) {
          await authProvider.verifyPhone(
            _phoneController.text.trim(),
            onCodeSent: (id) {
              if (!mounted) return;
              setState(() {
                _verificationId = id;
                _isCodeSent = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Código enviado!'), backgroundColor: AppColors.success),
              );
            },
            onError: (error) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error), backgroundColor: AppColors.error),
              );
            },
          );
        } else {
          final error = await authProvider.signInWithOTP(_verificationId, _otpController.text.trim());
          if (!mounted) return;
          _handleResult(context, error);
        }
      }
    }
  }

  void _handleResult(BuildContext context, String? error) {
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login realizado com sucesso!'), backgroundColor: AppColors.success),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bem-vindo de volta!',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Por favor, entre com suas credenciais.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Seletor de Tipo de Login
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _isPhoneAuth = false),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: !_isPhoneAuth ? AppColors.primary.withValues(alpha: 0.1) : null,
                            side: BorderSide(color: !_isPhoneAuth ? AppColors.primary : Colors.grey),
                          ),
                          child: Text('E-mail', style: TextStyle(color: !_isPhoneAuth ? AppColors.primary : Colors.grey)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _isPhoneAuth = true),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _isPhoneAuth ? AppColors.primary.withValues(alpha: 0.1) : null,
                            side: BorderSide(color: _isPhoneAuth ? AppColors.primary : Colors.grey),
                          ),
                          child: Text('Telefone', style: TextStyle(color: _isPhoneAuth ? AppColors.primary : Colors.grey)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (!_isPhoneAuth) ...[
                    BazarTextField(
                      label: 'E-mail',
                      hint: 'exemplo@email.com',
                      icon: Icons.email_outlined,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty || !value.contains('@')) return 'Informe um e-mail válido.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    BazarTextField(
                      label: 'Senha',
                      hint: '••••••••',
                      icon: Icons.lock_outline,
                      controller: _passwordController,
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.length < 6) return 'A senha deve ter pelo menos 6 caracteres.';
                        return null;
                      },
                    ),
                  ] else ...[
                    if (!_isCodeSent)
                      BazarTextField(
                        label: 'Número de Telefone',
                        hint: '+55 11 99999-9999',
                        icon: Icons.phone_outlined,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Informe seu telefone.';
                          return null;
                        },
                      )
                    else
                      BazarTextField(
                        label: 'Código SMS',
                        hint: '123456',
                        icon: Icons.message_outlined,
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Informe o código recebido.';
                          return null;
                        },
                      ),
                  ],
                  const SizedBox(height: 40),
                  BazarButton(
                    text: _isPhoneAuth && !_isCodeSent ? 'ENVIAR CÓDIGO' : 'ENTRAR',
                    isLoading: authProvider.isLoading,
                    onPressed: () => _onLogin(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
