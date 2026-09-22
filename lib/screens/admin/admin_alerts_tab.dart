import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/insforge_service.dart';

class AdminAlertsTab extends StatefulWidget {
  const AdminAlertsTab({super.key});

  @override
  State<AdminAlertsTab> createState() => _AdminAlertsTabState();
}

class _AdminAlertsTabState extends State<AdminAlertsTab> {
  final _service = InsForgeService();
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.getAllAlerts();
    if (mounted) setState(() { _alerts = data; _isLoading = false; });
  }

  void _showNewMessageDialog() async {
    final users = await _service.getApprovedUsers();
    if (!mounted) return;

    final msgC = TextEditingController();
    String alertType = 'custom';
    bool sendToAll = true;
    List<String> selectedUserIds = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          backgroundColor: const Color(0xFFF8F9FA),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enviar Mensaje',
                  style: GoogleFonts.lexend(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 25),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: TextField(
                    controller: msgC,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu mensaje o aviso aquí...',
                      contentPadding: EdgeInsets.all(15),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Tipo de Mensaje',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: alertType,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'custom',
                          child: Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue),
                              SizedBox(width: 10),
                              Text('Informativo'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'reminder',
                          child: Row(
                            children: [
                              Icon(Icons.alarm, color: Colors.orange),
                              SizedBox(width: 10),
                              Text('Recordatorio'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'warning',
                          child: Row(
                            children: [
                              Icon(Icons.warning, color: Colors.amber),
                              SizedBox(width: 10),
                              Text('Precaución'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'critical',
                          child: Row(
                            children: [
                              Icon(Icons.error, color: Colors.red),
                              SizedBox(width: 10),
                              Text('Crítico'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => alertType = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Destinatarios',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text(
                          'Todos',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        value: true,
                        groupValue: sendToAll,
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => sendToAll = val);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text(
                          'Algunos',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        value: false,
                        groupValue: sendToAll,
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => sendToAll = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                if (!sendToAll) ...[
                  const SizedBox(height: 10),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.lightBorder),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final u = users[index];
                        final uid = u['id'].toString();
                        final isSelected = selectedUserIds.contains(uid);
                        return CheckboxListTile(
                          title: Text(
                            u['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '@${u['username'] ?? ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          value: isSelected,
                          activeColor: AppColors.primary,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                selectedUserIds.add(uid);
                              } else {
                                selectedUserIds.remove(uid);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    final messageText = msgC.text.trim();
                    if (messageText.isEmpty) return;

                    List<String> recipients = [];
                    if (sendToAll) {
                      recipients =
                          users.map((u) => u['id'].toString()).toList();
                    } else {
                      recipients = selectedUserIds;
                    }

                    if (recipients.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Selecciona al menos un destinatario.'),
                        ),
                      );
                      return;
                    }

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (c) =>
                          const Center(child: CircularProgressIndicator()),
                    );

                    int successCount = 0;
                    for (final uid in recipients) {
                      final success = await _service.adminAddAlert(
                        userId: uid,
                        message: messageText,
                        type: alertType,
                      );
                      if (success) successCount++;
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Mensaje enviado con éxito a $successCount usuario(s).',
                          ),
                        ),
                      );
                      _load();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Enviar Mensaje',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewMessageDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.send),
        label: const Text(
          'Nuevo Mensaje',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No hay mensajes activos',
                        style: GoogleFonts.lexend(
                          fontSize: 20,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _alerts.length,
                  itemBuilder: (context, index) {
                    final a = _alerts[index];
                    IconData iconData = Icons.info;
                    Color iconColor = Colors.blue;

                    if (a['alert_type'] == 'reminder') {
                      iconData = Icons.alarm;
                      iconColor = Colors.orange;
                    } else if (a['alert_type'] == 'warning') {
                      iconData = Icons.warning;
                      iconColor = Colors.amber;
                    } else if (a['alert_type'] == 'critical') {
                      iconData = Icons.error;
                      iconColor = Colors.red;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: iconColor.withValues(alpha: 0.1),
                          child: Icon(iconData, color: iconColor),
                        ),
                        title: Text(
                          a['users']?['name'] ?? 'Usuario',
                          style: GoogleFonts.lexend(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              a['message'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text(
                                  '¿Eliminar Mensaje?',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: const Text(
                                  '¿Estás seguro de que deseas eliminar este mensaje? El paciente ya no lo verá.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Eliminar'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              final success = await _service.deleteAlert(
                                a['id'].toString(),
                              );
                              if (success) _load();
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
