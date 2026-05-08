import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../../products/models/product_model.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  double _shippingCost = 10.0; // Frete padrão
  String? _couponCode;
  double _discountPercentage = 0.0;

  // Getters
  List<CartItem> get items => _items;
  double get shippingCost => _shippingCost;
  String? get couponCode => _couponCode;
  double get discountPercentage => _discountPercentage;

  /// Subtotal (soma de todos os itens sem frete ou desconto)
  double get subtotal {
    return _items.fold(0, (total, item) => total + item.subtotal);
  }

  /// Total com desconto aplicado
  double get discountAmount => subtotal * (_discountPercentage / 100);

  /// Total final (subtotal - desconto + frete)
  double get total => subtotal - discountAmount + _shippingCost;

  /// Quantidade total de itens
  int get itemsCount => _items.fold(0, (count, item) => count + item.quantity);

  /// Adiciona um produto ao carrinho
  void addProduct(Product product, {int quantity = 1}) {
    final existingIndex =
        _items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      // Produto já existe, incrementa a quantidade
      _items[existingIndex].quantity += quantity;
    } else {
      // Novo produto
      _items.add(CartItem(product: product, quantity: quantity));
    }

    notifyListeners();
  }

  /// Remove um produto do carrinho
  void removeProduct(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  /// Incrementa a quantidade de um item
  void incrementQuantity(String productId) {
    final item = _items.firstWhere(
      (item) => item.product.id == productId,
      orElse: () => throw Exception('Produto não encontrado no carrinho'),
    );
    item.quantity++;
    notifyListeners();
  }

  /// Decrementa a quantidade de um item
  void decrementQuantity(String productId) {
    final item = _items.firstWhere(
      (item) => item.product.id == productId,
      orElse: () => throw Exception('Produto não encontrado no carrinho'),
    );

    if (item.quantity > 1) {
      item.quantity--;
    } else {
      removeProduct(productId);
    }
    notifyListeners();
  }

  /// Define a quantidade de um item específico
  void setQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }

    final itemIndex = _items.indexWhere((item) => item.product.id == productId);
    if (itemIndex >= 0) {
      _items[itemIndex].quantity = quantity;
      notifyListeners();
    }
  }

  /// Remove todos os itens do carrinho
  void clearCart() {
    _items.clear();
    _couponCode = null;
    _discountPercentage = 0.0;
    notifyListeners();
  }

  /// Aplica um cupom de desconto
  bool applyCoupon(String couponCode, {double discountPercentage = 10.0}) {
    // Aqui você pode adicionar validação de cupom contra um backend/API
    // Por enquanto, aceitamos qualquer cupom válido

    if (couponCode.isEmpty) {
      _couponCode = null;
      _discountPercentage = 0.0;
      notifyListeners();
      return false;
    }

    // Validações de cupom (exemplos)
    final couponMap = {
      'DESCONTO10': 10.0,
      'DESCONTO15': 15.0,
      'DESCONTO20': 20.0,
      'FRETE': 100.0, // Frete grátis
    };

    if (couponMap.containsKey(couponCode.toUpperCase())) {
      if (couponMap[couponCode.toUpperCase()] == 100.0) {
        _shippingCost = 0.0;
        _couponCode = couponCode.toUpperCase();
      } else {
        _discountPercentage = couponMap[couponCode.toUpperCase()] ?? 0.0;
        _couponCode = couponCode.toUpperCase();
      }
      notifyListeners();
      return true;
    }

    return false;
  }

  /// Remove o cupom aplicado
  void removeCoupon() {
    _couponCode = null;
    _discountPercentage = 0.0;
    _shippingCost = 10.0;
    notifyListeners();
  }

  /// Define o custo de frete baseado em CEP/região
  void setShippingCost(double cost) {
    _shippingCost = cost;
    notifyListeners();
  }

  /// Retorna o carrinho em formato de mapa para persistência
  Map<String, dynamic> toMap() {
    return {
      'items': _items
          .map((item) => {
                'productId': item.product.id,
                'quantity': item.quantity,
              })
          .toList(),
      'shippingCost': _shippingCost,
      'couponCode': _couponCode,
      'discountPercentage': _discountPercentage,
    };
  }

  /// Verifica se o carrinho está vazio
  bool get isEmpty => _items.isEmpty;

  /// Obtém um item específico do carrinho
  CartItem? getItem(String productId) {
    try {
      return _items.firstWhere((item) => item.product.id == productId);
    } catch (e) {
      return null;
    }
  }
}
