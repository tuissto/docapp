// lib/screens/appointment_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctor_appointment_app/models/auth_model.dart';
import 'package:doctor_appointment_app/utils/config.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum FilterStatus { upcoming, completed, cancelled }

// Provide French display names for FilterStatus
extension FilterStatusExtension on FilterStatus {
  String get displayName {
    switch (this) {
      case FilterStatus.upcoming:
        return 'À venir';
      case FilterStatus.completed:
        return 'Passés';
      case FilterStatus.cancelled:
        return 'Annulés';
      default:
        return '';
    }
  }
}

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({Key? key}) : super(key: key);

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  FilterStatus status = FilterStatus.upcoming;
  Alignment _alignment = Alignment.centerLeft;

  List<Map<String, dynamic>> schedules = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchAppointments();
  }

  // Fetch appointments from your AuthModel
  Future<void> fetchAppointments() async {
    try {
      final auth = Provider.of<AuthModel>(context, listen: false);

      // Update the status of old appointments to 'completed'
      await auth.updatePastAppointmentsStatus();
      // Then refetch them (which also merges 'images' from doc)
      await auth.fetchAppointments();

      // Get the newly updated list
      final fetched = await auth.getAppointments();
      setState(() {
        schedules = fetched; // store them all
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Échec du chargement des rendez-vous.';
      });
      print('Error in fetchAppointments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter by status
    final filtered = schedules.where((schedule) {
      final schedStatus = (schedule['status'] ?? '').toLowerCase();
      if (status == FilterStatus.upcoming) {
        return schedStatus == 'upcoming';
      } else if (status == FilterStatus.completed) {
        return schedStatus == 'completed';
      } else if (status == FilterStatus.cancelled) {
        return schedStatus == 'cancelled';
      }
      return false;
    }).toList();

    return Container(
      color: const Color(0xFFE8E4D6),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Config.spaceSmall,

              // Status toggle bar
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: FilterStatus.values.map((f) {
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                status = f;
                                if (f == FilterStatus.upcoming) {
                                  _alignment = Alignment.centerLeft;
                                } else if (f == FilterStatus.completed) {
                                  _alignment = Alignment.center;
                                } else {
                                  _alignment = Alignment.centerRight;
                                }
                              });
                            },
                            child: Center(
                              child: Text(
                                f.displayName,
                                style: TextStyle(
                                  color:
                                  (status == f) ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  AnimatedAlign(
                    alignment: _alignment,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: MediaQuery.of(context).size.width / 3,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          status.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              Config.spaceSmall,

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                  ),
                )
                    : filtered.isEmpty
                    ? const Center(
                  child: Text(
                    'Aucun rendez-vous trouvé',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
                    : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final schedule = filtered[index];
                    final isLast = index == filtered.length - 1;
                    return Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          color: Color(0xFFE8E4D6),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: !isLast
                          ? const EdgeInsets.only(bottom: 20)
                          : EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Doctor row
                            _doctorRow(schedule),

                            const SizedBox(height: 15),

                            // Additional info
                            _buildScheduleInfo(schedule),

                            const SizedBox(height: 15),

                            // If it is 'cancelled' or 'completed', show text
                            // else show reprogram/cancel buttons
                            if (schedule['status'] == 'cancelled' ||
                                schedule['status'] == 'completed')
                              Text(
                                (schedule['status'] == 'cancelled')
                                    ? 'Annulé'
                                    : 'Passé',
                                style: TextStyle(
                                  color: (schedule['status'] == 'cancelled')
                                      ? Colors.red
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            else
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      onPressed: () =>
                                          _cancelAppointment(schedule),
                                      child: const Text(
                                        'Annuler',
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                      onPressed: () =>
                                          _reprogramAppointment(schedule),
                                      child: const Text(
                                        'Reprogrammer',
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
        ),
      ),
    );
  }

  /// Builds the row for the doctor info, using images[0] or doctor_profile_url
  Widget _doctorRow(Map<String, dynamic> schedule) {
    final avatar = _buildDoctorAvatar(schedule);

    final doctorName = schedule['doctor_name'] ?? 'Inconnu';
    final category = schedule['category'] ?? '';

    return Row(
      children: [
        avatar,
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doctorName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                category,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Picks images[0], else doctor_profile_url, else icon
  Widget _buildDoctorAvatar(Map<String, dynamic> schedule) {
    final dynamicImages = (schedule['images'] is List)
        ? schedule['images'] as List
        : [];
    final List<String> images = dynamicImages.map((e) => e.toString()).toList();

    String avatarUrl = '';
    if (images.isNotEmpty) {
      avatarUrl = images[0];
    } else {
      final docProfile = (schedule['doctor_profile_url'] ?? '').toString();
      if (docProfile.trim().isNotEmpty) {
        avatarUrl = docProfile;
      }
    }

    if (avatarUrl.isEmpty) {
      return const CircleAvatar(
        radius: 25,
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, color: Colors.white),
      );
    }

    return CircleAvatar(
      radius: 25,
      backgroundColor: Colors.grey[300],
      backgroundImage: NetworkImage(avatarUrl),
    );
  }

  /// Build the schedule info: date/time + prestation
  Widget _buildScheduleInfo(Map<String, dynamic> schedule) {
    final day = schedule['day'] ?? '??';
    final date = schedule['date'] ?? '??';
    final time = schedule['time'] ?? '??';

    final nom = schedule['prestation_nom'] ?? 'Prestation?';
    final prix = schedule['prestation_prix'] ?? 'N/A';
    final duree = schedule['prestation_duree'] ?? 30;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F2),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row for day/date/time
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.black),
              const SizedBox(width: 5),
              Text('$day, $date', style: const TextStyle(color: Colors.black)),
              const SizedBox(width: 20),
              const Icon(Icons.access_alarm, size: 16, color: Colors.black),
              const SizedBox(width: 5),
              Text(time, style: const TextStyle(color: Colors.black)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Prestation: $nom',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Durée: $duree min | Prix: $prix',
            style: const TextStyle(
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// Cancel the appointment => calls your AuthModel
  Future<void> _cancelAppointment(Map<String, dynamic> schedule) async {
    final appointmentId = schedule['appointment_id'];
    final auth = Provider.of<AuthModel>(context, listen: false);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler le rendez-vous'),
        content: const Text('Êtes-vous sûr de vouloir annuler ce rendez-vous ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final success = await auth.cancelAppointment(appointmentId);
      if (success) {
        await fetchAppointments(); // re-fetch so we see new status
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rendez-vous annulé avec succès.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de l’annulation du rendez-vous.')),
        );
      }
    }
  }

  /// Reprogram => calls AuthModel for reprogramming
  Future<void> _reprogramAppointment(Map<String, dynamic> schedule) async {
    final appointmentId = schedule['appointment_id'];
    final now = DateTime.now();

    final newDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (newDate == null) return;

    final newTimeOfDay = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (newTimeOfDay == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(newDate);
    final hh = newTimeOfDay.hour.toString().padLeft(2, '0');
    final mm = newTimeOfDay.minute.toString().padLeft(2, '0');
    final timeStr = "$hh:$mm";

    final auth = Provider.of<AuthModel>(context, listen: false);
    final success = await auth.reprogramAppointment(
      appointmentId: appointmentId,
      newDate: dateStr,
      newTime: timeStr,
    );
    if (success) {
      await fetchAppointments();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rendez-vous reprogrammé au $dateStr à $timeStr.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de la reprogrammation.')),
      );
    }
  }
}
