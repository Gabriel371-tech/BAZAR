import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'package:google_fonts/google_fonts.dart';

/// Um botão personalizado com o estilo "Earthy" do Bazar.
/// Permite customização de texto, ação e estilo (cheio ou contornado).
class BazarButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isFull; // Define se o botão é preenchido ou apenas com borda
  final bool isLoading; // Mostra um indicador de carregamento se verdadeiro

  const BazarButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFull = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, // O botão ocupa toda a largura disponível
      height: 55,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isFull ? AppColors.primary : Colors.transparent,
          foregroundColor: isFull ? Colors.white : AppColors.primary,
          elevation: isFull ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isFull ? BorderSide.none : const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
