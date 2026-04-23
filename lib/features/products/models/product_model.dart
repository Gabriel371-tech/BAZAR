import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String brand; // Adicionado
  final DateTime createdAt;
  final String? imageUrl;
  final String sellerId;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.brand, // Adicionado
    required this.createdAt,
    required this.sellerId,
    this.imageUrl,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      brand: data['brand'] ?? 'Bazar', // Adicionado
      sellerId: data['sellerId'] ?? '',
      imageUrl: data['imageUrl'],
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    String? img = json['imagem'] ?? json['imageUrl'];
    
    // CORREÇÃO AUTOMÁTICA PARA IMAGENS QUE FUNCIONAM NO WEB
    if (img != null && img.contains('unsplash.com')) {
      if (img.contains('1542291026')) img = 'https://images.pexels.com/photos/2529148/pexels-photo-2529148.jpeg?auto=compress&cs=tinysrgb&w=500'; // Tênis
      if (img.contains('1576871337')) img = 'https://images.pexels.com/photos/6770028/pexels-photo-6770028.jpeg?auto=compress&cs=tinysrgb&w=500'; // Jaqueta (Novo Link)
      if (img.contains('1572804013')) img = 'https://images.pexels.com/photos/2235071/pexels-photo-2235071.jpeg?auto=compress&cs=tinysrgb&w=500'; // Vestido
    }

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
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'brand': brand, // Adicionado
      'sellerId': sellerId,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
