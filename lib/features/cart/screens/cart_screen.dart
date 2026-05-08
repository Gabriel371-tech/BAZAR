import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/bazar_button.dart';
import '../services/cart_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _couponController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Carrinho de Compras',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Consumer<CartProvider>(
              builder: (context, cartProvider, _) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${cartProvider.itemsCount}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, _) {
          if (cartProvider.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.cartShopping,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Seu carrinho está vazio',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  BazarButton(
                    text: 'Continuar Comprando',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lista de itens do carrinho
                _buildCartItems(context, cartProvider),
                const SizedBox(height: 24),

                // Campo de cupom
                _buildCouponSection(cartProvider),
                const SizedBox(height: 24),

                // Campo de CEP para cálculo de frete
                _buildShippingSection(cartProvider),
                const SizedBox(height: 24),

                // Resumo do pedido
                _buildOrderSummary(cartProvider),
                const SizedBox(height: 24),

                // Botões de ação
                _buildActionButtons(context, cartProvider),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Constrói a lista de itens do carrinho
  Widget _buildCartItems(BuildContext context, CartProvider cartProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Itens do Carrinho',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cartProvider.items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = cartProvider.items[index];
            return _buildCartItemCard(context, cartProvider, item);
          },
        ),
      ],
    );
  }

  /// Constrói um card de item do carrinho
  Widget _buildCartItemCard(
    BuildContext context,
    CartProvider cartProvider,
    dynamic item,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // Imagem do produto
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppColors.surface,
            ),
            child: item.product.imageUrl != null && item.product.imageUrl!.isNotEmpty
                ? Image.network(
                    item.product.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: FaIcon(
                        FontAwesomeIcons.image,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : Center(
                    child: FaIcon(
                      FontAwesomeIcons.image,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
          ),
          const SizedBox(width: 12),

          // Informações do produto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'R\$ ${item.product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                // Controles de quantidade
                Row(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          cartProvider.decrementQuantity(item.product.id),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Text('-'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          cartProvider.incrementQuantity(item.product.id),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Text('+'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Botão de remover
          Column(
            children: [
              GestureDetector(
                onTap: () {
                  cartProvider.removeProduct(item.product.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Produto removido do carrinho'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.trash,
                    size: 16,
                    color: AppColors.error,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'R\$ ${item.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói a seção de cupom
  Widget _buildCouponSection(CartProvider cartProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cupom de Desconto',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _couponController,
                enabled: cartProvider.couponCode == null,
                decoration: InputDecoration(
                  hintText: cartProvider.couponCode != null
                      ? 'Cupom: ${cartProvider.couponCode}'
                      : 'Digite o código do cupom',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cartProvider.couponCode == null
                    ? AppColors.primary
                    : AppColors.error,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                if (cartProvider.couponCode != null) {
                  cartProvider.removeCoupon();
                  _couponController.clear();
                } else {
                  final code = _couponController.text.trim();
                  if (code.isNotEmpty) {
                    final success = cartProvider.applyCoupon(code);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cupom aplicado com sucesso!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _couponController.clear();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cupom inválido'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: Text(
                cartProvider.couponCode != null ? 'Remover' : 'Aplicar',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        if (cartProvider.couponCode != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Desconto: ${cartProvider.discountPercentage.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  /// Constrói a seção de frete
  Widget _buildShippingSection(CartProvider cartProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cálculo de Frete',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cepController,
                maxLength: 8,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Digite seu CEP',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                final cep = _cepController.text.trim();
                if (cep.length == 8) {
                  // Simula cálculo de frete baseado em CEP
                  double shippingCost = 10.0;
                  if (cep.startsWith('0')) {
                    shippingCost = 15.0;
                  } else if (cep.startsWith('1')) {
                    shippingCost = 20.0;
                  }

                  cartProvider.setShippingCost(shippingCost);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Frete calculado: R\$ ${shippingCost.toStringAsFixed(2)}',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('CEP inválido'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text(
                'Calcular',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Constrói o resumo do pedido
  Widget _buildOrderSummary(CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo do Pedido',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Subtotal',
            'R\$ ${cartProvider.subtotal.toStringAsFixed(2)}',
          ),
          if (cartProvider.discountPercentage > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _buildSummaryRow(
                'Desconto (${cartProvider.discountPercentage.toStringAsFixed(0)}%)',
                '-R\$ ${cartProvider.discountAmount.toStringAsFixed(2)}',
                color: Colors.green,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: _buildSummaryRow(
              'Frete',
              cartProvider.shippingCost == 0
                  ? 'Grátis'
                  : 'R\$ ${cartProvider.shippingCost.toStringAsFixed(2)}',
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Total',
            'R\$ ${cartProvider.total.toStringAsFixed(2)}',
            isBold: true,
            fontSize: 18,
          ),
        ],
      ),
    );
  }

  /// Constrói uma linha do resumo
  Widget _buildSummaryRow(
    String label,
    String value, {
    Color color = AppColors.textPrimary,
    bool isBold = false,
    double fontSize = 14,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  /// Constrói os botões de ação
  Widget _buildActionButtons(BuildContext context, CartProvider cartProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BazarButton(
          text: 'Finalizar Compra',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pedido finalizado com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
            cartProvider.clearCart();
            Navigator.pop(context);
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirmar Limpeza'),
                content: const Text('Deseja limpar todos os itens do carrinho?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () {
                      cartProvider.clearCart();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Carrinho limpo'),
                        ),
                      );
                    },
                    child: const Text(
                      'Limpar Tudo',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.error),
          ),
          child: const Text(
            'Limpar Carrinho',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _couponController.dispose();
    _cepController.dispose();
    super.dispose();
  }
}
