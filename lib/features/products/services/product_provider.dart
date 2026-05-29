import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';
import '../../../core/services/notification_service.dart';
import '../models/product_model.dart';

class ProductProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = '';
  double _minPrice = 0.0;
  double _maxPrice = 10000.0;
  List<Product> _filteredProducts = [];

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;
  List<Product> get filteredProducts => _filteredProducts;

  // Configurações do JSONBin
  final String _binId = '69e957d2856a682189614c23';
  
  // ATENÇÃO: Substitua pelo seu X-Master-Key real do console JSONBin!
  final String _apiKey = r'$2a$10$sV.w2uJ6HwkguXs2vwUM4u15GSm0E5DTYrU3f35WeRaWAA2Z2tGEO';

  Future<Map<String, dynamic>?> _fetchJsonBinRecord() async {
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
        if (recordContent is Map<String, dynamic>) {
          if (recordContent.containsKey('record') && recordContent['record'] is Map<String, dynamic>) {
            return Map<String, dynamic>.from(recordContent['record']);
          }
          return recordContent;
        }
        if (recordContent is List<dynamic>) {
          return {'record': recordContent};
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar registro JSONBin de produtos: $e');
    }
    return null;
  }

  /// Atualiza o JSONBin com a lista atualizada de produtos.
  Future<void> _updateJsonBin(List<Product> allProducts) async {
    try {
      final existingRecord = await _fetchJsonBinRecord();
      final existingOrders = (existingRecord != null && existingRecord['orders'] is List)
          ? existingRecord['orders']
          : <dynamic>[];

      final body = json.encode({
        'products': allProducts.map((p) => p.toJson()).toList(),
        'orders': existingOrders,
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
      final existingRecord = await _fetchJsonBinRecord();
      final dynamic recordContent = existingRecord ?? {};

      List<dynamic> productsJson = [];
      if (recordContent is Map<String, dynamic>) {
        if (recordContent['products'] is List) {
          productsJson = recordContent['products'];
        } else if (recordContent['record'] is List) {
          productsJson = recordContent['record'];
        } else if (recordContent['record'] is Map<String, dynamic> && recordContent['record']['products'] is List) {
          productsJson = recordContent['record']['products'];
        }
      } else if (recordContent is List) {
        productsJson = recordContent;
      }

      return productsJson.map((json) => Product.fromJson(json)).toList();
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

      // 3. Notificação Local
      NotificationService.showUpdateNotification(
        id: DateTime.now().millisecond,
        productName: name,
        updateMessage: 'Seu produto foi cadastrado com sucesso!',
      );

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

  /// Combina produtos do JSONBin com os do Firestore sem duplicatas.
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
        // Usa um Map para evitar duplicatas baseadas no ID
        final Map<String, Product> combinedMap = {};
        
        // Primeiro adiciona os do JSONBin (produtos do sistema)
        for (var p in jsonBinList) {
          combinedMap[p.id] = p;
        }
        
        // Depois adiciona os do Firestore (que podem sobrescrever ou ser novos)
        // O Firestore tem prioridade
        for (var p in firestoreList) {
          combinedMap[p.id] = p;
        }
        
        return combinedMap.values.toList();
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

  /// Atualiza a query de busca
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  /// Define a categoria selecionada
  void setSelectedCategory(String category) {
    if (_selectedCategory == category) {
      _selectedCategory = '';
    } else {
      _selectedCategory = category;
    }
    _applyFilters();
  }

  /// Define o intervalo de preço
  void setPriceRange(double min, double max) {
    _minPrice = min;
    _maxPrice = max;
    _applyFilters();
  }

  /// Limpa todos os filtros
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = '';
    _minPrice = 0.0;
    _maxPrice = 10000.0;
    _filteredProducts.clear();
    notifyListeners();
  }

  /// Aplica os filtros e pesquisa aos produtos
  Future<void> _applyFilters() async {
    _setLoading(true);
    try {
      final allProducts = await fetchProductsFromJsonBin();
      
      _filteredProducts = allProducts.where((product) {
        // Filtro de pesquisa (por nome e descrição)
        final matchesSearch = _searchQuery.isEmpty ||
            product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.category.toLowerCase().contains(_searchQuery.toLowerCase());

        // Filtro de categoria
        final matchesCategory =
            _selectedCategory.isEmpty || product.category == _selectedCategory;

        // Filtro de preço
        final matchesPrice =
            product.price >= _minPrice && product.price <= _maxPrice;

        return matchesSearch && matchesCategory && matchesPrice;
      }).toList();

      _setLoading(false);
    } catch (e) {
      debugPrint("Erro ao aplicar filtros: $e");
      _setLoading(false);
    }
  }

  /// Obtém todas as categorias únicas dos produtos
  Future<List<String>> getCategories() async {
    try {
      final allProducts = await fetchProductsFromJsonBin();
      final categories = allProducts.map((p) => p.category).toSet().toList();
      return categories..sort();
    } catch (e) {
      debugPrint("Erro ao buscar categorias: $e");
      return [];
    }
  }
}

