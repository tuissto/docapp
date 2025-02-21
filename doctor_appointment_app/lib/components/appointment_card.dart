import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctor_appointment_app/models/auth_model.dart';
import 'package:doctor_appointment_app/utils/config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AppointmentCard extends StatefulWidget {
  const AppointmentCard({
    Key? key,
    required this.appointment,
    required this.color,
  }) : super(key: key);

  final Map<String, dynamic> appointment;
  final Color color;

  @override
  State<AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<AppointmentCard> {
  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;

    // Debug print so you can see the entire map
    print('DEBUG: appointment => $appointment');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white,
          width: 1.0,
        ),
      ),
      child: Material(
        color: const Color.fromARGB(300, 232, 228, 214),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              _buildDoctorInfoRow(appointment),
              Config.spaceSmall,
              // Day/Date/Time + Prestation
              ScheduleCard(appointment: appointment),
              Config.spaceSmall,
              // Buttons
              _buildButtonsRow(appointment),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the row with the doctor avatar and name
  Widget _buildDoctorInfoRow(Map<String, dynamic> appointment) {
    final avatarWidget = _buildDoctorAvatar(appointment);

    final doctorName = appointment['doctor_name'] ?? 'Unknown Doctor';
    final category = appointment['category'] ?? 'Unknown Category';

    return Row(
      children: [
        // The custom avatar
        avatarWidget,
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                doctorName,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                category,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Picks the first item in `appointment['images']`, else `doctor_profile_url`, else icon
  Widget _buildDoctorAvatar(Map<String, dynamic> appointment) {
    final dynamicImages = (appointment['images'] is List)
        ? appointment['images'] as List
        : [];
    final List<String> images = dynamicImages.map((e) => e.toString()).toList();

    String avatarUrl = '';
    if (images.isNotEmpty) {
      avatarUrl = images[0]; // use the first image
    } else {
      // fallback to 'doctor_profile_url'
      final profileUrl = (appointment['doctor_profile_url'] ?? '').toString();
      if (profileUrl.trim().isNotEmpty) {
        avatarUrl = profileUrl;
      }
    }

    if (avatarUrl.isEmpty) {
      return const CircleAvatar(
        radius: 30,
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, color: Colors.white),
      );
    }

    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.grey,
      backgroundImage: NetworkImage(avatarUrl),
    );
  }

  /// Row with "Annuler" + "Reprogrammer" buttons
  Widget _buildButtonsRow(Map<String, dynamic> appointment) {
    final auth = Provider.of<AuthModel>(context, listen: false);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Cancel Button
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () async {
              final appointmentId = appointment['appointment_id'];

              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Annuler le rendez-vous'),
                    content: const Text(
                      'Êtes-vous sûr de vouloir annuler ce rendez-vous?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Non'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Oui'),
                      ),
                    ],
                  );
                },
              );

              if (confirm == true) {
                final success = await auth.cancelAppointment(appointmentId);
                if (success) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rendez-vous annulé avec succès.'),
                    ),
                  );
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                      Text('Échec de l’annulation du rendez-vous.'),
                    ),
                  );
                }
              }
            },
          ),
        ),
        const SizedBox(width: 20),

        // Reprogrammer Button
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              await _handleReprogram(appointment);
            },
            child: const Text(
              'Reprogrammer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  /// Instead of cancelling right away,
  /// we pass the old appointment ID to BookingPage, so it can cancel only after the new booking is successful.
  Future<void> _handleReprogram(Map<String, dynamic> appointment) async {
    // Confirm user wants to reprogram
    final doReprogram = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reprogrammer'),
        content: const Text(
          'Souhaitez-vous reprogrammer ce rendez-vous? '
              'Vous choisirez un nouvel horaire, et l’ancien sera annulé seulement après la nouvelle réservation.',
        ),
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

    if (doReprogram != true) return;

    final doctorId = appointment['doctor_id'] ?? '';
    if (doctorId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de trouver le salon.')),
        );
      }
      return;
    }

    try {
      final docSnap = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .get();
      if (!docSnap.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Salon introuvable.')),
          );
        }
        return;
      }

      // Build data for BookingPage
      final docData = docSnap.data() ?? {};
      docData['uid'] = doctorId;

      // Pass the old appointment ID
      final routeArgs = {
        'doctor': docData,
        'oldAppointmentId': appointment['appointment_id'],
      };

      if (!mounted) return;
      Navigator.pushNamed(context, 'booking_page', arguments: routeArgs);

    } catch (e) {
      print('Error in reprogram: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur de reprogrammation.')),
        );
      }
    }
  }
}

/// Displays day/date/time + prestation info
class ScheduleCard extends StatelessWidget {
  const ScheduleCard({
    Key? key,
    required this.appointment,
  }) : super(key: key);

  final Map<String, dynamic> appointment;

  @override
  Widget build(BuildContext context) {
    print('DEBUG: ScheduleCard => $appointment');

    final day = appointment['day'] ?? 'Unknown Day';
    final date = appointment['date'] ?? 'Unknown Date';
    final time = appointment['time'] ?? 'Unknown Time';

    // Possibly a submap
    String prestationName = 'Prestation?';
    int prestationDuree = 30;
    String prestationPrix = 'N/A';

    final pData = appointment['prestation'];
    if (pData is Map) {
      prestationName = pData['nom'] ?? 'Prestation?';
      prestationDuree = pData['duree'] ?? 30;
      prestationPrix = pData['prix'] ?? 'N/A';
    } else {
      // fallback top-level
      prestationName =
          appointment['prestation_nom'] ??
              appointment['prestation_name'] ??
              'Prestation?';
      prestationDuree = appointment['prestation_duree'] ?? 30;
      prestationPrix = appointment['prestation_prix'] ?? 'N/A';
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F2),
        borderRadius: BorderRadius.circular(10),
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // row with day/date/time
          Row(
            children: <Widget>[
              const Icon(Icons.calendar_today, color: Colors.black, size: 20),
              const SizedBox(width: 5),
              Text('$day, $date',
                  style: const TextStyle(color: Colors.black, fontSize: 14)),
              const SizedBox(width: 20),
              const Icon(Icons.access_alarm, color: Colors.black, size: 20),
              const SizedBox(width: 5),
              Text(
                time,
                style: const TextStyle(color: Colors.black, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Prestation name
          Text(
            'Prestation: $prestationName',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),

          // Duration + Price
          Text(
            'Durée: $prestationDuree min | Prix: $prestationPrix',
            style: const TextStyle(color: Colors.black, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
