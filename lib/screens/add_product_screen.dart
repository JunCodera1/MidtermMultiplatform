// ============================================================
// lib/screens/add_product_screen.dart
// Thêm sản phẩm: name, price, soluong, image
// ============================================================

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/image_picker_widget.dart';
import '../widgets/loading_overlay.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _soluong = TextEditingController();
  XFile? _image;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _soluong.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final provider = context.read<ProductProvider>();
    final source = await chooseImageSource(context);
    if (source == null) return;
    final image = await provider.pickImage(source);
    if (image != null && mounted) setState(() => _image = image);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ProductProvider>();
    final ok = await provider.addProduct(
      name: _name.text,
      price: num.parse(_price.text.trim()),
      soluong: int.parse(_soluong.text.trim()),
      imageFile: _image,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(provider.errorMessage!), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(builder: (context, provider, _) {
      return LoadingOverlay(
        isLoading: provider.isOperating,
        message: 'Đang lưu sản phẩm...',
        child: Scaffold(
          appBar: AppBar(title: const Text('Thêm sản phẩm')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    CustomTextField(
                      controller: _name,
                      label: 'Tên sản phẩm (name)',
                      prefixIcon: Icons.label_outline,
                      validator: Validators.validateProductName,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _price,
                      label: 'Giá (price)',
                      prefixIcon: Icons.attach_money,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: Validators.validatePrice,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _soluong,
                      label: 'Số lượng (soluong)',
                      prefixIcon: Icons.inventory_2_outlined,
                      keyboardType: TextInputType.number,
                      validator: Validators.validateQuantity,
                    ),
                    const SizedBox(height: 20),
                    ImagePickerWidget(
                        selectedImage: _image, onPickImage: _pickImage),
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: provider.isOperating ? null : _save,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Lưu sản phẩm'),
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
