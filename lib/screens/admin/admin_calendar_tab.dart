import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../services/insforge_service.dart';

class AdminCalendarTab extends StatefulWidget {
  const AdminCalendarTab({super.key});

  @override
  State<AdminCalendarTab> createState() => _AdminCalendarTabState();
}

class _AdminCalendarTabState extends State<AdminCalendarTab> {
  final _service = InsForgeService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _users = [];
  List<String> _selectedUserIds = [];
  List<Map<String, dynamic>> _allSchedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadData();
  }

  Future<void> _loadData() async {
    final users = await _service.getApprovedUsers();
    final schedules = await _service.getSchedule();
    if (mounted) {
      setState(() {
        _users = users;
        _allSchedules = schedules;
        if (_selectedUserIds.isEmpty && users.isNotEmpty) {
          _selectedUserIds = users.map((u) => u['id'].toString()).toList();
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _scheduleAppointment(DateTime day) async {
    if (_selectedUserIds.isEmpty) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    for (final uid in _selectedUserIds) {
      await _service.addSchedule(userId: uid, date: dateStr);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Citas programadas con éxito')),
      );
    }
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final allSelected =
        _selectedUserIds.length == _users.length && _users.isNotEmpty;

    return Container(
      color: AppColors.adminBackground,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        color: AppColors.primary,
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Calendario de Citas',
                          style: GoogleFonts.lexend(
                            fontWeight: FontWeight.w900,
                            fontSize: 26,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecciona usuarios y haz clic en los días para programar citas',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: AppColors.blueLight, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.people,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Seleccionar usuarios:',
                              style: GoogleFonts.lexend(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        CheckboxListTile(
                          title: Text(
                            'Todos los pacientes (${_users.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          value: allSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedUserIds = _users
                                    .map((u) => u['id'].toString())
                                    .toList();
                              } else {
                                _selectedUserIds.clear();
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          activeColor: AppColors.primary,
                        ),
                        const Divider(),
                        ..._users.map(
                          (u) => CheckboxListTile(
                            title: Text(
                              '${u['name']} (${u['username']})',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            value: _selectedUserIds.contains(u['id'].toString()),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedUserIds.add(u['id'].toString());
                                } else {
                                  _selectedUserIds.remove(u['id'].toString());
                                }
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            activeColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (_selectedUserIds.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 80,
                              color: Colors.black26,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Selecciona al menos un\npaciente para programar\ncitas',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.black38,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.blueLight, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: TableCalendar(
                        locale: 'es_ES',
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                          _scheduleAppointment(selectedDay);
                        },
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          markerDecoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                        eventLoader: (day) {
                          final dateStr = DateFormat('yyyy-MM-dd').format(day);
                          return _allSchedules
                              .where((s) =>
                                  s['scheduled_date']
                                      .toString()
                                      .startsWith(dateStr) &&
                                  _selectedUserIds
                                      .contains(s['user_id'].toString()))
                              .toList();
                        },
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, day, events) {
                            if (events.isNotEmpty) {
                              return Positioned(
                                bottom: 1,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.orange,
                                  ),
                                ),
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
