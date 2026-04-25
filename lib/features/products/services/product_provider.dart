import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';
import '../models/product_model.dart';

class ProductProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // Configurações do JSONBin
  final String _binId = '69e957d2856a682189614c23';
  
  // ATENÇÃO: Substitua pelo seu X-Master-Key real do console JSONBin!
  final String _apiKey = r'$2a$10$sV.w2uJ6HwkguXs2vwUM4u15GSm0E5DTYrU3f35WeRaWAA2Z2tGEO';

  /// Atualiza o JSONBin com a lista atualizada de produtos.
  Future<void> _updateJsonBin(List<Product> allProducts) async {
    try {
      final body = json.encode({
        'record': allProducts.map((p) => p.toJson()).toList()
      });
      
      final response = await http.put(
        Uri.parse('https://api.jsonbin.io/v3/b/$_binId'),
        headers: {
          'Content-Type': 'application/json',
          'X-Master-Key': _apiKey,
        },
        body: body,
      );

      if (response.statusCode != 200) {
        debugPrint('FALHA JSONBIN (${response.statusCode}): ${response.body}');
      } else {
        debugPrint('JSONBin atualizado com sucesso!');
      }
    } catch (e) {
      debugPrint("Erro fatal na sincronização JSONBin: $e");
    }
  }

  /// Busca produtos do JSONBin.
  Future<List<Product>> fetchProductsFromJsonBin() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.jsonbin.io/v3/b/$_binId/latest'),
        headers: {
          'X-Master-Key': _apiKey,
        },
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

  /// Adiciona um novo produto ao Firestore e sincroniza com JSONBin.
  Future<String?> addProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    required String brand,
    required String imageUrl,
    required String sellerId,
  }) async {
    _setLoading(true);
    try {
      // 1. Salva no Firestore
      final docRef = await _db.collection('products').add({
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'brand': brand,
        'imageUrl': imageUrl,
        'sellerId': sellerId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Sincroniza com JSONBin
      final currentProducts = await fetchProductsFromJsonBin();
      final newProduct = Product(
        id: docRef.id,
        name: name,
        description: description,
        price: price,
        category: category,
        brand: brand,
        imageUrl: imageUrl,
        sellerId: sellerId,
      );
      currentProducts.add(newProduct);
      await _updateJsonBin(currentProducts);

      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return "Erro ao cadastrar produto: $e";
    }
  }

  /// Atualiza um produto no Firestore e no JSONBin.
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
      // 1. Firestore
      await _db.collection('products').doc(id).update({
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'brand': brand,
        'imageUrl': imageUrl,
      });

      // 2. JSONBin
      final currentProducts = await fetchProductsFromJsonBin();
      final index = currentProducts.indexWhere((p) => p.id == id);
      if (index != -1) {
        currentProducts[index] = Product(
          id: id,
          name: name,
          description: description,
          price: price,
          category: category,
          brand: brand,
          imageUrl: imageUrl,
          sellerId: currentProducts[index].sellerId,
        );
        await _updateJsonBin(currentProducts);
      }

      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return "Erro ao atualizar produto: $e";
    }
  }

  /// Exclui um produto do Firestore e do JSONBin.
  Future<String?> deleteProduct(String id) async {
    _setLoading(true);
    try {
      // 1. Firestore
      await _db.collection('products').doc(id).delete();

      // 2. JSONBin
      final currentProducts = await fetchProductsFromJsonBin();
      currentProducts.removeWhere((p) => p.id == id);
      await _updateJsonBin(currentProducts);

      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return "Erro ao excluir produto: $e";
    }
  }

  /// Combina produtos do JSONBin com os do Firestore.
  Stream<List<Product>> get productsStream {
    final firestoreStream = _db.collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromFirestore(doc))
            .toList());

    final jsonBinStream = Stream.fromFuture(fetchProductsFromJsonBin());

    return CombineLatestStream.combine2<List<Product>, List<Product>, List<Product>>(
      firestoreStream,
      jsonBinStream,
      (firestoreList, jsonBinList) {
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
