import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/product_model.dart';

class ProductProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Product> _products = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  /// Adiciona um novo produto ao Firestore.
  Future<String?> addProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    required String sellerId,
  }) async {
    _setLoading(true);
    try {
      await _db.collection('products').add({
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'sellerId': sellerId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return "Erro ao cadastrar produto: $e";
    }
  }

  /// Escuta em tempo real a lista de produtos.
  Stream<List<Product>> get productsStream {
    return _db.collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromFirestore(doc))
            .toList());
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
