import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/bazar_button.dart';
import '../../../core/widgets/bazar_text_field.dart';
import '../../auth/services/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.displayName);
    _emailController = TextEditingController(text: user?.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Atualizar Nome
      final nameError = await authProvider.updateDisplayName(_nameController.text.trim());
      
      if (!mounted) return;

      if (nameError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(nameError), backgroundColor: AppColors.error),
        );
        return;
      }

      // Se o e-mail mudou, tenta atualizar também
      if (_emailController.text.trim() != authProvider.user?.email) {
        final emailError = await authProvider.updateEmail(_emailController.text.trim());
        if (!mounted) return;
        if (emailError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(emailError), backgroundColor: AppColors.error),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verifique seu novo e-mail para confirmar a alteração.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado!'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              BazarTextField(
                label: 'Nome Completo',
                hint: 'Seu Nome',
                icon: Icons.person_outline,
                controller: _nameController,
                validator: (value) => value == null || value.isEmpty ? 'Informe seu nome.' : null,
              ),
              const SizedBox(height: 24),
              BazarTextField(
                label: 'E-mail',
                hint: 'exemplo@email.com',
                icon: Icons.email_outlined,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value == null || !value.contains('@') ? 'Informe um e-mail válido.' : null,
              ),
              const SizedBox(height: 40),
              BazarButton(
                text: 'SALVAR ALTERAÇÕES',
                isLoading: authProvider.isLoading,
                onPressed: _onSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
