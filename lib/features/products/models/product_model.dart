import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String brand;
  final DateTime createdAt;
  final String? imageUrl;
  final String sellerId;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.brand,
    DateTime? createdAt,
    required this.sellerId,
    this.imageUrl,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      brand: data['brand'] ?? 'Bazar',
      sellerId: data['sellerId'] ?? '',
      imageUrl: data['imageUrl'],
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    String? img = json['imagem'] ?? json['imageUrl'] ?? json['image_url'];
    
    return Product(
      id: (json['id'] ?? '').toString(),
      name: json['nome'] ?? json['name'] ?? '',
      description: json['descricao'] ?? json['descrição'] ?? json['description'] ?? '',
      price: (json['preco'] ?? json['preço'] ?? json['price'] ?? 0).toDouble(),
      category: json['category'] ?? 'Geral',
      brand: json['marca'] ?? json['brand'] ?? 'Bazar',
      sellerId: json['sellerId'] ?? 'system',
      imageUrl: img,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': name,
      'marca': brand,
      'descrição': description,
      'preço': price,
      'imagem': imageUrl,
      'category': category,
      'sellerId': sellerId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'brand': brand,
      'sellerId': sellerId,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
