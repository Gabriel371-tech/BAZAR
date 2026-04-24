import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';
import '../models/product_model.dart';

class ProductProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Product> _products = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  // Configurações do JSONBin
  final String _binId = '69e957d2856a682189614c23';

  /// Busca produtos do JSONBin.
  Future<List<Product>> fetchProductsFromJsonBin() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.jsonbin.io/v3/b/$_binId/latest'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final dynamic recordContent = data['record'];
        
        List<dynamic> productsJson = [];
        if (recordContent is Map && recordContent.containsKey('record')) {
          productsJson = recordContent['record'];
        } else if (recordContent is List) {
          productsJson = recordContent;
        }

        return productsJson.map((json) => Product.fromJson(json)).toList();
      } else {
        debugPrint('Erro JSONBin (${response.statusCode}): ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint("Erro ao buscar produtos JSONBin: $e");
      return [];
    }
  }

  /// Adiciona um novo produto ao Firestore.
  Future<String?> addProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    required String brand,
    required String imageUrl, // Adicionado
    required String sellerId,
  }) async {
    _setLoading(true);
    try {
      await _db.collection('products').add({
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'brand': brand,
        'imageUrl': imageUrl, // Adicionado
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

  /// Atualiza um produto no Firestore.
  Future<String?> updateProduct({
    required String id,
    required String name,
    required String description,
    required double price,
    required String category,
    required String brand,
    required String imageUrl,
  }) async {
    _setLoading(true);
    try {
      await _db.collection('products').doc(id).update({
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'brand': brand,
        'imageUrl': imageUrl,
      });
      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return "Erro ao atualizar produto: $e";
    }
  }

  /// Exclui um produto do Firestore.
  Future<String?> deleteProduct(String id) async {
    _setLoading(true);
    try {
      await _db.collection('products').doc(id).delete();
      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return "Erro ao excluir produto: $e";
    }
  }

  /// Combina produtos do JSONBin com os do Firestore.
  Stream<List<Product>> get productsStream {
    // Stream do Firestore
    final firestoreStream = _db.collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromFirestore(doc))
            .toList());

    // Stream do JSONBin (emite uma vez)
    final jsonBinStream = Stream.fromFuture(fetchProductsFromJsonBin());

    // Combina os dois streams
    return CombineLatestStream.combine2<List<Product>, List<Product>, List<Product>>(
      firestoreStream,
      jsonBinStream,
      (firestoreList, jsonBinList) {
        // Une as duas listas
        return [...firestoreList, ...jsonBinList];
      },
    ).handleError((error) {
      debugPrint("Erro no stream de produtos: $error");
      return <Product>[];
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
