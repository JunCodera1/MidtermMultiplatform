import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/image_picker_widget.dart';
import '../widgets/loading_overlay.dart';

class EditUserScreen extends StatefulWidget {
  final UserModel user;
  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _username;
  late final TextEditingController _email;
  late final TextEditingController _password;
  XFile? _image;

  @override
  void initState() {
    super.initState();
    _username = TextEditingController(text: widget.user.username);
    _email = TextEditingController(text: widget.user.email);
    _password = TextEditingController(text: widget.user.password);
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<UserProvider>();
    final ok = await provider.updateUser(
      userId: widget.user.id!,
      username: _username.text,
      email: _email.text,
      password: _password.text,
      currentImageUrl: widget.user.image,
      newImageFile: _image,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(builder: (context, provider, _) {
      return LoadingOverlay(
        isLoading: provider.isOperating,
        message: 'Đang cập nhật...',
        child: Scaffold(
          appBar: AppBar(title: const Text('Sửa người dùng')),
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
                ImagePickerWidget(selectedImage: _image, currentImageUrl: widget.user.image, onPickImage: () async {
                  final image = await provider.pickImage();
                  if (image != null && mounted) setState(() => _image = image);
                }),
                const SizedBox(height: 28),
                FilledButton.icon(onPressed: provider.isOperating ? null : _save, icon: const Icon(Icons.save_outlined), label: const Text('Lưu thay đổi'), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14))),
              ],
            ),
          ),
        ),
      );
    });
  }
}
