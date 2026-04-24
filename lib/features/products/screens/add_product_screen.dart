import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/bazar_button.dart';
import '../../../core/widgets/bazar_text_field.dart';
import '../../auth/services/auth_provider.dart';
import '../models/product_model.dart';
import '../services/product_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;
  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _brandController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
      _categoryController.text = widget.product!.category;
      _brandController.text = widget.product!.brand;
      _imageUrlController.text = widget.product!.imageUrl ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (_formKey.currentState!.validate()) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      String? error;
      if (isEditing) {
        error = await productProvider.updateProduct(
          id: widget.product!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          category: _categoryController.text.trim(),
          brand: _brandController.text.trim(),
          imageUrl: _imageUrlController.text.trim(),
        );
      } else {
        error = await productProvider.addProduct(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          category: _categoryController.text.trim(),
          brand: _brandController.text.trim(),
          imageUrl: _imageUrlController.text.trim(),
          sellerId: authProvider.user?.uid ?? '',
        );
      }

      if (!mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Produto atualizado!' : 'Produto cadastrado!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar Produto' : 'Novo Produto',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              BazarTextField(
                label: 'Nome do Produto',
                hint: 'Ex: Vaso de Cerâmica',
                icon: Icons.shopping_bag_outlined,
                controller: _nameController,
                validator: (value) => value == null || value.isEmpty ? 'Informe o nome.' : null,
              ),
              const SizedBox(height: 20),
              BazarTextField(
                label: 'Preço',
                hint: '0.00',
                icon: Icons.attach_money,
                controller: _priceController,
                keyboardType: TextInputType.number,
                validator: (value) => value == null || double.tryParse(value) == null ? 'Informe um preço válido.' : null,
              ),
              const SizedBox(height: 20),
              BazarTextField(
                label: 'Categoria',
                hint: 'Ex: Decoração',
                icon: Icons.category_outlined,
                controller: _categoryController,
                validator: (value) => value == null || value.isEmpty ? 'Informe a categoria.' : null,
              ),
              const SizedBox(height: 20),
              BazarTextField(
                label: 'Marca',
                hint: 'Ex: Nike, Zara',
                icon: Icons.branding_watermark_outlined,
                controller: _brandController,
                validator: (value) => value == null || value.isEmpty ? 'Informe a marca.' : null,
              ),
              const SizedBox(height: 20),
              BazarTextField(
                label: 'Link da Imagem (URL)',
                hint: 'https://exemplo.com/imagem.jpg',
                icon: Icons.link,
                controller: _imageUrlController,
                validator: (value) => value == null || value.isEmpty ? 'Informe o link da imagem.' : null,
              ),
              const SizedBox(height: 20),
              BazarTextField(
                label: 'Descrição',
                hint: 'Conte mais sobre o produto...',
                icon: Icons.description_outlined,
                controller: _descriptionController,
                maxLines: 4,
                validator: (value) => value == null || value.isEmpty ? 'Informe a descrição.' : null,
              ),
              const SizedBox(height: 40),
              BazarButton(
                text: isEditing ? 'ATUALIZAR PRODUTO' : 'SALVAR PRODUTO',
                isLoading: productProvider.isLoading,
                onPressed: _onSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
