import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../auth/services/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Icon(
          Icons.eco, // Placeholder para a logo superior
          color: AppColors.primary,
          size: 30,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textPrimary),
            onPressed: () {
              authProvider.signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.eco, color: Colors.white, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'Bazar Cozy',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Home (Dashboard)'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag_outlined),
              title: const Text('Produtos'),
              onTap: () {
                // Navegar para produtos
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Perfil'),
              onTap: () {
                // Navegar para perfil
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: AppColors.error),
              title: const Text('Sair', style: TextStyle(color: AppColors.error)),
              onTap: () {
                authProvider.signOut();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Logo meio transparente ao fundo
          Center(
            child: Opacity(
              opacity: 0.1,
              child: Icon(
                Icons.eco,
                size: 200,
                color: AppColors.primary,
              ),
            ),
          ),
          // Conteúdo da Dashboard
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bem-vindo,',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  authProvider.user?.email ?? authProvider.user?.phoneNumber ?? 'Usuario',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 32),
                // Exemplo de cards da dashboard
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildDashboardCard(
                        'Total de Vendas',
                        'R\$ 1.250,00',
                        Icons.trending_up,
                      ),
                      _buildDashboardCard(
                        'Novos Pedidos',
                        '12',
                        Icons.shopping_cart_outlined,
                      ),
                      _buildDashboardCard(
                        'Produtos Ativos',
                        '45',
                        Icons.inventory_2_outlined,
                      ),
                      _buildDashboardCard(
                        'Avaliacoes',
                        '4.8',
                        Icons.star_outline,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
