import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/insforge_service.dart';
import '../../widgets/app_input_field.dart';

class AdminUsersTab extends StatefulWidget {
  final bool showOnlyPending;
  const AdminUsersTab({super.key, this.showOnlyPending = false});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final _service = InsForgeService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(AdminUsersTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showOnlyPending != widget.showOnlyPending) _load();
  }

  Future<void> _load() async {
    try {
      final all = await _service.getAllUsers();
      if (mounted) {
        setState(() {
          _users = widget.showOnlyPending
              ? all.where((u) => u['status'] == 'pending').toList()
              : all;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar usuario'),
        content: Text(
          '¿Seguro que quieres eliminar a @${user['username'] ?? ''}? '
          'Se borrarán también sus lecturas, alertas, citas y medicamentos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final success = await _service.adminDeleteUser(user['id']);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Usuario eliminado.' : 'Error al eliminar el usuario.')),
    );
    if (success) _load();
  }

  Future<void> _setStatus(Map<String, dynamic> user, String status) async {
    final label = status == 'approved' ? 'aprobada' : 'rechazada';
    final success = await _service.adminUpdateUserStatus(user['id'], status);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Solicitud de @${user['username'] ?? ''} $label.'
            : 'Error al actualizar el estado.'),
      ),
    );
    if (success) _load();
  }

  static const _statusItems = [
    DropdownMenuItem(value: 'approved', child: Text('Aprobado')),
    DropdownMenuItem(value: 'pending', child: Text('Pendiente')),
    DropdownMenuItem(value: 'rejected', child: Text('Rechazado')),
  ];

  void _showCreateUserDialog() {
    final nameC = TextEditingController();
    final usernameC = TextEditingController();
    final phoneC = TextEditingController();
    final passwordC = TextEditingController();
    final ageC = TextEditingController();
    String role = 'patient';
    String status = 'approved';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          backgroundColor: const Color(0xFFF8F9FA),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Crear Usuario', style: GoogleFonts.lexend(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
                const SizedBox(height: 25),
                AppInputField(controller: nameC, hint: 'Nombre Completo', icon: Icons.person),
                const SizedBox(height: 15),
                AppInputField(controller: usernameC, hint: 'Usuario', icon: Icons.alternate_email),
                const SizedBox(height: 15),
                AppInputField(controller: phoneC, hint: 'Telefono', icon: Icons.phone),
                const SizedBox(height: 15),
                AppInputField(controller: passwordC, hint: 'Contrasena', icon: Icons.lock, isObscure: true),
                const SizedBox(height: 15),
                AppInputField(controller: ageC, hint: 'Edad (opcional)', icon: Icons.cake),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rol', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.lightBorder)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: role,
                                items: const [
                                  DropdownMenuItem(value: 'patient', child: Text('Paciente')),
                                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                ],
                                onChanged: (val) { if (val != null) setDialogState(() => role = val); },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Estado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.lightBorder)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: status,
                                items: _statusItems,
                                onChanged: (val) { if (val != null) setDialogState(() => status = val); },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 35),
                ElevatedButton(
                  onPressed: () async {
                    if (nameC.text.trim().isEmpty || usernameC.text.trim().isEmpty || passwordC.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nombre, usuario y contrasena son obligatorios.')),
                      );
                      return;
                    }
                    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
                    String? error;
                    Map<String, dynamic>? result;
                    try {
                      result = await _service.createUser(
                        name: nameC.text.trim(), username: usernameC.text.trim(), phone: phoneC.text.trim(),
                        password: passwordC.text.trim(), age: int.tryParse(ageC.text.trim()),
                        approved: status == 'approved', role: role,
                      );
                    } on InsForgeRpcException catch (e) {
                      error = e.message;
                    } catch (e) {
                      error = 'Error de conexion.';
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                      Navigator.pop(context);
                      if (result != null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario creado con exito.')));
                        _load();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error ?? 'Error al crear el usuario.')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 2),
                  child: const Text('Crear Usuario', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final nameC = TextEditingController(text: user['name']);
    final usernameC = TextEditingController(text: user['username']);
    final phoneC = TextEditingController(text: user['phone']);
    final passwordC = TextEditingController();
    final ageC = TextEditingController(text: user['age']?.toString() ?? '');
    String role = user['role'] ?? 'patient';
    String status = user['status'] ?? 'approved';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          backgroundColor: const Color(0xFFF8F9FA),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Editar Usuario', style: GoogleFonts.lexend(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
                const SizedBox(height: 25),
                AppInputField(controller: nameC, hint: 'Nombre Completo', icon: Icons.person),
                const SizedBox(height: 15),
                AppInputField(controller: usernameC, hint: 'Usuario', icon: Icons.alternate_email),
                const SizedBox(height: 15),
                AppInputField(controller: phoneC, hint: 'Telefono', icon: Icons.phone),
                const SizedBox(height: 15),
                AppInputField(controller: passwordC, hint: 'Nueva Contrasena (opcional)', icon: Icons.lock, isObscure: true),
                const SizedBox(height: 15),
                AppInputField(controller: ageC, hint: 'Edad (opcional)', icon: Icons.cake),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rol', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.lightBorder)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: role,
                                items: const [
                                  DropdownMenuItem(value: 'patient', child: Text('Paciente')),
                                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                ],
                                onChanged: (val) { if (val != null) setDialogState(() => role = val); },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Estado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.lightBorder)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: status,
                                items: _statusItems,
                                onChanged: (val) { if (val != null) setDialogState(() => status = val); },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 35),
                ElevatedButton(
                  onPressed: () async {
                    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
                    var success = false;
                    String? error;
                    try {
                      success = await _service.adminUpdateUser(
                        userId: user['id'].toString(), name: nameC.text.trim(), username: usernameC.text.trim(),
                        phone: phoneC.text.trim(), role: role, status: status, password: passwordC.text.trim(),
                        age: int.tryParse(ageC.text.trim()),
                      );
                    } on InsForgeRpcException catch (e) {
                      error = e.message;
                    } catch (e) {
                      error = 'Error de conexion.';
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                      Navigator.pop(context);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario actualizado.')));
                        _load();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error ?? 'Error al actualizar.')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 2),
                  child: const Text('Guardar Cambios', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(color: AppColors.adminBackground, child: const Center(child: CircularProgressIndicator()));
    }
    return Container(
      color: AppColors.adminBackground,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showCreateUserDialog(),
                icon: const Icon(Icons.person_add, color: Colors.white),
                label: const Text('Crear Usuario', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _users.isEmpty
                ? const Center(child: Text('No hay usuarios'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final isPending = user['status'] == 'pending';
                      final isRejected = user['status'] == 'rejected';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isPending
                                ? Colors.orange.withValues(alpha: 0.5)
                                : isRejected
                                    ? Colors.red.withValues(alpha: 0.4)
                                    : AppColors.cardBorder,
                          ),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5, offset: const Offset(0, 2))],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              (user['name'] != null && user['name'].toString().trim().isNotEmpty) ? user['name'].toString().trim()[0].toUpperCase() : 'U',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(user['name'] ?? '', style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87), overflow: TextOverflow.ellipsis),
                              ),
                              if (isPending) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10)),
                                  child: const Text('Pendiente', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                              if (isRejected) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                                  child: const Text('Rechazado', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text('@${user['username'] ?? 'usuario'}', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isPending) ...[
                                IconButton(
                                  tooltip: 'Aprobar',
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                  onPressed: () => _setStatus(user, 'approved'),
                                ),
                                IconButton(
                                  tooltip: 'Rechazar',
                                  icon: const Icon(Icons.cancel, color: Colors.red),
                                  onPressed: () => _setStatus(user, 'rejected'),
                                ),
                              ],
                              if (isRejected)
                                IconButton(
                                  tooltip: 'Aprobar',
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                  onPressed: () => _setStatus(user, 'approved'),
                                ),
                              IconButton(
                                tooltip: 'Editar',
                                icon: const Icon(Icons.edit, color: AppColors.primary),
                                onPressed: () => _showEditUserDialog(user),
                              ),
                              IconButton(
                                tooltip: 'Eliminar',
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDelete(user),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
