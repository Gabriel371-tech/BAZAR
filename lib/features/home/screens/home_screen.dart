import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/bazar_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/signup_screen.dart';

/// Tela Inicial (Landing Page) do Bazar.
/// Apresenta o conceito do site e botões para entrar ou cadastrar.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logotipo ou Ícone do Bazar
              FaIcon(
                FontAwesomeIcons.store,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              // Nome do Bazar
              Text(
                'BAZAR COZY',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              // Slogan
              Text(
                'Descubra tesouros únicos com um toque natural.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 60),
              // Botões de Ação
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  children: [
                    BazarButton(
                      text: 'ENTRAR',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    BazarButton(
                      text: 'CADASTRAR',
                      isFull: false,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignupScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Footer simples
              Text(
                '© 2024 Bazar Cozy Inc.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
