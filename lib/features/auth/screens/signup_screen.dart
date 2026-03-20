import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/bazar_button.dart';
import '../../../core/widgets/bazar_text_field.dart';
import '../../home/screens/dashboard_screen.dart';
import '../services/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tela de Cadastro do Bazar.
/// Formulário unificado com Nome, E-mail, Telefone e Senha.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRegister(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Realiza o cadastro básico com e-mail e senha
      // O telefone e nome seriam salvos em um banco de dados (como Firestore) em um passo seguinte
      final error = await authProvider.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!context.mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conta criada com sucesso!'), backgroundColor: AppColors.success),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
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
                    'Crie sua conta',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Junte-se ao Bazar Cozy preenchendo as informações abaixo.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),
                  BazarTextField(
                    label: 'Nome Completo',
                    hint: 'Seu Nome',
                    icon: Icons.person_outline,
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Informe seu nome.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
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
                    label: 'Telefone',
                    hint: '+55 11 99999-9999',
                    icon: Icons.phone_outlined,
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Informe seu telefone.';
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
                  const SizedBox(height: 40),
                  BazarButton(
                    text: 'CADASTRAR AGORA',
                    isLoading: authProvider.isLoading,
                    onPressed: () => _onRegister(context),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: RichText(
                        text: TextSpan(
                          text: 'Já tem uma conta? ',
                          style: GoogleFonts.poppins(color: AppColors.textSecondary),
                          children: [
                            TextSpan(
                              text: 'Entrar',
                              style: GoogleFonts.poppins(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
      ),
    );
  }
}
