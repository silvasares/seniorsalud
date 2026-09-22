import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/readings_provider.dart';
import '../../constants/app_colors.dart';
import '../../widgets/profile_info_item.dart';
import 'dart:async';
import '../../services/insforge_service.dart';
import '../login_screen.dart';
class ProfileTab extends StatefulWidget {
  final String userId;
  const ProfileTab({super.key, required this.userId});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReadingsProvider>().loadProfile(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReadingsProvider>(
      builder: (context, rp, _) {
        final user = rp.profile;
        if (rp.isLoading) return const Center(child: CircularProgressIndicator());

        return SingleChildScrollView(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 48),
          child: Column(
            children: [
              Center(
                child: CircleAvatar(
                  radius: 65,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    (user?.name != null && user!.name.trim().isNotEmpty)
                        ? user.name.trim()[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 50,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Text(
                user?.name ?? 'Usuario',
                style: GoogleFonts.lexend(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 35),
              ProfileInfoItem(
                icon: Icons.person,
                label: 'Nombre Completo',
                value: user?.name ?? 'No especificado',
              ),
              ProfileInfoItem(
                icon: Icons.cake,
                label: 'Edad',
                value: user?.age != null ? '${user!.age} años' : 'No especificada',
              ),
              ProfileInfoItem(
                icon: Icons.phone,
                label: 'Teléfono',
                value: user?.phone ?? 'No disponible',
              ),
              ProfileInfoItem(
                icon: Icons.alternate_email,
                label: 'Usuario',
                value: '@${user?.username ?? 'usuario'}',
              ),
              ProfileInfoItem(
                icon: Icons.shield_outlined,
                label: 'Rol',
                value: (user?.role ?? 'usuario').toUpperCase(),
              ),
              ProfileInfoItem(
                icon: Icons.check_circle_outline,
                label: 'Estado de Cuenta',
                value: 'Activo',
                valueColor: Colors.green,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 15),
              OutlinedButton.icon(
                onPressed: () async {
                  final nav = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text(
                        '¿Borrar Cuenta?',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: const Text(
                        'Esta acción es irreversible y eliminará todos tus datos permanentemente. ¿Estás seguro?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Borrar Cuenta'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    if (!mounted) return;
                    unawaited(
                      showDialog(
                        context: navigatorKey.currentContext!,
                        barrierDismissible: false,
                        builder: (_) =>
                            const Center(child: CircularProgressIndicator()),
                      ),
                    );

                    final supabase = InsForgeService();
                    final success = await supabase.deleteUser(widget.userId);

                    if (mounted) nav.pop();

                    if (success && mounted) {
                      await supabase.signOut();
                      nav.pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    } else if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Error al borrar la cuenta. Inténtalo más tarde.',
                          ),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(
                  Icons.delete,
                  size: 20,
                  color: AppColors.deleteRed,
                ),
                label: const Text(
                  'Borrar Cuenta',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deleteRed,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.deleteRed,
                  minimumSize: const Size(double.infinity, 60),
                  side: const BorderSide(color: AppColors.deleteRed, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
