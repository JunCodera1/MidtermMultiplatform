import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/image_picker_widget.dart';
import '../widgets/loading_overlay.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  XFile? _image;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await context.read<UserProvider>().pickImage();
    if (image != null && mounted) setState(() => _image = image);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<UserProvider>().addUser(
          username: _username.text,
          email: _email.text,
          password: _password.text,
          imageFile: _image,
        );
    if (!mounted) return;
    final message = context.read<UserProvider>().errorMessage;
    if (ok) {
      Navigator.pop(context, true);
    } else if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(builder: (context, provider, _) {
      return LoadingOverlay(
        isLoading: provider.isOperating,
        message: 'Đang lưu người dùng...',
        child: Scaffold(
          appBar: AppBar(title: const Text('Thêm người dùng')),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                CustomTextField(controller: _username, label: 'Username', prefixIcon: Icons.person_outline, validator: Validators.validateUsername),
                const SizedBox(height: 16),
                CustomTextField(controller: _email, label: 'Email', prefixIcon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: Validators.validateEmail),
                const SizedBox(height: 16),
                CustomTextField(controller: _password, label: 'Password', prefixIcon: Icons.lock_outline, isPassword: true, validator: Validators.validatePassword),
                const SizedBox(height: 20),
                ImagePickerWidget(selectedImage: _image, onPickImage: _pickImage),
                const SizedBox(height: 28),
                FilledButton.icon(onPressed: provider.isOperating ? null : _save, icon: const Icon(Icons.save_outlined), label: const Text('Lưu người dùng'), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14))),
              ],
            ),
          ),
        ),
      );
    });
  }
}
