import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../constants/app_colors.dart';
import '../widgets/app_input_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    String? invalidReason;
    if (name.isEmpty || username.isEmpty) {
      invalidReason = 'Nombre y usuario son obligatorios.';
    } else if (password.isEmpty) {
      invalidReason = 'La contraseña no puede estar vacía.';
    } else if (phone.isEmpty) {
      invalidReason = 'El teléfono de contacto es obligatorio.';
    }
    if (invalidReason != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(invalidReason)),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final result = await auth.register(
      name: name,
      username: username,
      phone: phone,
      password: password,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud enviada. El administrador revisará tu alta antes de que puedas iniciar sesión.'),
        ),
      );
      Navigator.pop(context);
    } else if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!)),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Nueva Cuenta',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 110,
                  errorBuilder: (c, e, s) => const Icon(
                    Icons.favorite,
                    color: AppColors.primary,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Solicitar Acceso',
                  style: GoogleFonts.lexend(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Completa tus datos para solicitar el alta al administrador',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 35),
                AppRoundedInputField(
                  controller: _nameController,
                  hint: 'Nombre Completo',
                  icon: Icons.person,
                ),
                const SizedBox(height: 15),
                AppRoundedInputField(
                  controller: _usernameController,
                  hint: 'Nombre de Usuario',
                  icon: Icons.alternate_email,
                ),
                const SizedBox(height: 15),
                AppRoundedInputField(
                  controller: _phoneController,
                  hint: 'Teléfono de Contacto',
                  icon: Icons.phone,
                ),
                const SizedBox(height: 15),
                AppRoundedInputField(
                  controller: _passwordController,
                  hint: 'Contraseña',
                  icon: Icons.lock,
                  isObscure: true,
                ),
                const SizedBox(height: 35),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.isLoading) {
                      return const CircularProgressIndicator();
                    }
                    return ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 70),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(35),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Solicitar Alta',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 25),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '¿Ya tienes cuenta? Iniciar Sesión',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
