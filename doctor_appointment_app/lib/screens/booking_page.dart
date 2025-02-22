import 'dart:math'; // for random picking
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctor_appointment_app/components/button.dart';
import 'package:doctor_appointment_app/components/custom_appbar.dart';
import 'package:doctor_appointment_app/main.dart';
import 'package:doctor_appointment_app/models/auth_model.dart';
import 'package:doctor_appointment_app/utils/config.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({Key? key}) : super(key: key);

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? _selectedDay;
  String? _selectedTime;

  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? doctor;
  String? _oldAppointmentId;

  List<Map<String, dynamic>> _prestationsList = [];
  Map<String, dynamic>? _selectedPrestation;

  List<String> _prestataires = [];
  String? _selectedPrestataire;

  Map<String, Set<String>> _timeToPrestSet = {};
  List<String> _sortedTimes = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route.settings.arguments != null) {
      final arg = route.settings.arguments as Map<String, dynamic>;
      if (arg.containsKey('doctor')) {
        doctor = arg['doctor'] as Map<String, dynamic>;
        _oldAppointmentId = arg['oldAppointmentId'] as String?;
        // Also see if there's a 'prestationId'
        final preId = arg['prestationId'] as String?;
        _initDoctorAndPrestation(preId);
      } else {
        // old style
        doctor = arg;
        _initDoctorAndPrestation(null);
      }
      print('--- BookingPage: doctor data received ---');
      print(doctor);
    } else {
      print('Error: No arguments passed to BookingPage');
    }
  }

  void _initDoctorAndPrestation(String? preId) {
    _extractPrestations();
    if (preId != null && _prestationsList.isNotEmpty) {
      final match = _prestationsList.firstWhere(
            (p) => p['id'].toString() == preId,
        orElse: () => {},
      );
      if (match.isNotEmpty) {
        _onPrestationSelected(match);
      }
    }
  }

  void _extractPrestations() {
    if (doctor == null) return;
    if (!doctor!.containsKey('prestations')) return;

    final raw = doctor!['prestations'];
    if (raw is Map) {
      _prestationsList.clear();
      raw.forEach((k, v) {
        if (v is Map) {
          final pData = Map<String, dynamic>.from(v);
          _prestationsList.add({
            'id': k,
            'nom': pData['nom'] ?? '',
            'description': pData['description'] ?? '',
            'duree': pData['duree'] ?? '30',
            'prix': pData['prix'] ?? '',
            'prestataires': pData.containsKey('prestataires')
                ? List<String>.from(pData['prestataires'])
                : [],
          });
        }
      });
      print('Resulting _prestationsList: $_prestationsList');
    }
  }

  void _onPrestationSelected(Map<String, dynamic> p) {
    setState(() {
      _selectedPrestation = p;
      _selectedTime = null;
      _errorMessage = null;
      _timeToPrestSet.clear();
      _sortedTimes.clear();

      final listP = p['prestataires'] as List<String>;
      // No "Any" now; just real names
      _prestataires = listP.map((s) => s.trim()).toList();
      _selectedPrestataire = null;
    });
    print('Selected prestation: $_selectedPrestation');
  }

  @override
  Widget build(BuildContext context) {
    Config().init(context);

    if (doctor == null) {
      return Scaffold(
        appBar: CustomAppBar(
          appTitle: 'Appointment',
          icon: const FaIcon(Icons.arrow_back_ios),
        ),
        body: const Center(child: Text('Error: No doctor data available')),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        appTitle: 'Appointment',
        icon: const FaIcon(Icons.arrow_back_ios),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          child: Column(
            children: [
              // If not preselected, show list
              if (_selectedPrestation == null && _prestationsList.isNotEmpty)
                _buildPrestationsList(),

              const SizedBox(height: 20),
              if (_selectedPrestation != null) _buildSelectedPrestationDetails(),

              // The inline Calendar
              _buildCalendar(),

              // If we have prestataires
              if (_prestataires.isNotEmpty)
                _buildPrestataireButtons(),

              if (_sortedTimes.isNotEmpty)
                _buildTimeSlots()
              else if (_selectedPrestation != null &&
                  _selectedPrestataire != null &&
                  _selectedDay != null &&
                  !_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  child: Text(
                    'No available times for the selected date/prestataire.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),

              if (_isLoading) const SizedBox(height: 20),
              if (_isLoading) const CircularProgressIndicator(),
              const SizedBox(height: 40),

              Button(
                width: double.infinity,
                title: 'Make Appointment',
                onPressed: () async {
                  if (_selectedPrestation != null &&
                      _selectedPrestataire != null &&
                      _selectedDay != null &&
                      _selectedTime != null) {
                    await _makeAppointment();
                  } else {
                    setState(() {
                      _errorMessage =
                      'Please select prestation, prestataire, date & time.';
                    });
                  }
                },
                disable: !(_selectedPrestation != null &&
                    _selectedPrestataire != null &&
                    _selectedDay != null &&
                    _selectedTime != null),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                )
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrestationsList() {
    if (_prestationsList.isEmpty) {
      return const Text(
        'No prestations available',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose a prestation:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          itemCount: _prestationsList.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, idx) {
            final p = _prestationsList[idx];
            final isSelected = _selectedPrestation?['id'] == p['id'];
            return Card(
              color: isSelected ? Config.primaryColor.withOpacity(0.1) : null,
              child: ListTile(
                title: Text(
                  p['nom'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Durée: ${p['duree']} min | Prix: ${p['prix']}'),
                trailing: Icon(
                  isSelected ? Icons.check_circle : Icons.check_circle_outline,
                  color: isSelected ? Config.primaryColor : Colors.grey,
                ),
                onTap: () => _onPrestationSelected(p),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSelectedPrestationDetails() {
    if (_selectedPrestation == null) return const SizedBox.shrink();
    final p = _selectedPrestation!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10, bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Config.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Prestation: ${p['nom']}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Description: ${p['description']}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            'Duration: ${p['duree']} min',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            'Price: ${p['prix']}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// The inline calendar
  Widget _buildCalendar() {
    final now = DateTime.now();
    final firstDate = now;
    final lastDate = DateTime(now.year + 1);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Config.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CalendarDatePicker(
        initialDate: _selectedDay ?? now,
        firstDate: firstDate,
        lastDate: lastDate,
        onDateChanged: (newDate) {
          setState(() {
            _selectedDay = newDate;
            _selectedTime = null;
            _timeToPrestSet.clear();
            _sortedTimes.clear();
          });
          if (_selectedPrestation != null && _selectedPrestataire != null) {
            _fetchAvailableTimeSlots();
          }
        },
      ),
    );
  }

  /// A row of buttons to pick prestataire
  Widget _buildPrestataireButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Wrap(
        spacing: 8.0,
        children: _prestataires.map((pName) {
          final isSelected = pName == _selectedPrestataire;
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? Config.primaryColor : Colors.grey,
            ),
            onPressed: () => _onPrestataireChosen(pName),
            child: Text(
              pName,
              style: const TextStyle(color: Colors.white),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _onPrestataireChosen(String pName) {
    setState(() {
      _selectedPrestataire = pName;
      _selectedTime = null;
      _errorMessage = null;
      _timeToPrestSet.clear();
      _sortedTimes.clear();
    });
    if (_selectedDay != null && _selectedPrestation != null) {
      _fetchAvailableTimeSlots();
    }
  }

  Widget _buildTimeSlots() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _sortedTimes.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 2.0,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, idx) {
          final timeStr = _sortedTimes[idx];
          final isSelected = (_selectedTime == timeStr);
          return InkWell(
            onTap: () {
              setState(() => _selectedTime = timeStr);
              print('Selected time slot: $_selectedTime');
            },
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                    color: isSelected ? Colors.white : Colors.black),
                borderRadius: BorderRadius.circular(15),
                color: isSelected ? Config.primaryColor : Colors.transparent,
              ),
              child: Text(
                timeStr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _fetchAvailableTimeSlots() async {
    if (_selectedPrestataire == null ||
        _selectedDay == null ||
        doctor == null ||
        _selectedPrestation == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _timeToPrestSet.clear();
      _sortedTimes.clear();
    });

    try {
      final docUid = doctor!['uid']?.toString();
      if (docUid == null || docUid.isEmpty) {
        throw Exception('No valid doctor uid found in the doc');
      }

      print('Fetching availability for doc=$docUid, date=$_selectedDay, p=$_selectedPrestataire');

      Query query = FirebaseFirestore.instance
          .collection('availability')
          .where('doctor_id', isEqualTo: docUid)
          .where('prestataire_name', isEqualTo: _selectedPrestataire);

      final snap = await query.get();
      if (snap.docs.isEmpty) {
        print('No availability docs found => empty result');
        setState(() => _isLoading = false);
        return;
      }

      for (var docSnap in snap.docs) {
        final data = docSnap.data() as Map<String, dynamic>;
        if (data['batches'] is! List) continue;
        final List batches = data['batches'];

        for (var batch in batches) {
          if (batch is Map) {
            final startDateStr = batch['start_date'] ?? '';
            final endDateStr = batch['end_date'] ?? '';
            final daySchedules = batch['day_schedules'] ?? {};
            final startD = DateTime.tryParse(startDateStr);
            final endD = DateTime.tryParse(endDateStr);
            if (startD == null || endD == null) continue;

            if (!_selectedDay!.isBefore(startD) && !_selectedDay!.isAfter(endD)) {
              final dayKey = _englishDayOfWeek(_selectedDay!);
              if (daySchedules is Map && daySchedules.containsKey(dayKey)) {
                final intervals = daySchedules[dayKey];
                if (intervals is List) {
                  for (var slot in intervals) {
                    if (slot is Map) {
                      final st = slot['start_time'] ?? '';
                      final et = slot['end_time'] ?? '';
                      final stTOD = _parseTimeOfDay(st);
                      final etTOD = _parseTimeOfDay(et);
                      if (stTOD != null && etTOD != null) {
                        final subSlots = _generate30MinSlots(stTOD, etTOD);
                        for (var sub in subSlots) {
                          _timeToPrestSet[sub] = _timeToPrestSet[sub] ?? <String>{};
                          _timeToPrestSet[sub]!.add(_selectedPrestataire!);
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      final allTimes = _timeToPrestSet.keys.toList();
      allTimes.sort((a, b) =>
          _compareTimes(_timeOfDayFromString(a), _timeOfDayFromString(b)));
      setState(() {
        _sortedTimes = allTimes;
        _isLoading = false;
      });
      print('_timeToPrestSet => $_timeToPrestSet');
    } catch (e) {
      print('Error fetching availability: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching availability.';
      });
    }
  }

  Future<void> _makeAppointment() async {
    if (_selectedTime == null ||
        _selectedPrestataire == null ||
        _selectedDay == null ||
        _selectedPrestation == null) {
      setState(() {
        _errorMessage = 'Please select prestation, prestataire, date & time.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
      final timeStr = _selectedTime!;
      int duree = 30;
      try {
        duree = int.parse(_selectedPrestation!['duree'].toString());
      } catch (_) {}

      final dayOfWeek = _englishDayOfWeek(_selectedDay!);
      final chosenPrest = _selectedPrestataire!;

      final auth = Provider.of<AuthModel>(context, listen: false);

      final docUid = doctor!['uid']?.toString();
      if (docUid == null || docUid.isEmpty) {
        throw Exception('No valid doctor uid found in the doc.');
      }

      final prestationId = _selectedPrestation!['id'].toString();

      final success = await auth.bookAppointment(
        date: dateStr,
        day: dayOfWeek,
        time: timeStr,
        doctorId: docUid,
        prestataire: chosenPrest,
        prestationId: prestationId,
        prestationDuree: duree,
      );
      if (!success) {
        setState(() => _errorMessage = 'Failed to book appointment.');
        return;
      }

      // If there's an old appt to cancel
      if (_oldAppointmentId != null) {
        final cancelOk = await auth.cancelAppointment(_oldAppointmentId!);
        if (!cancelOk) {
          print('Warning: Could not cancel old appointment $_oldAppointmentId');
        } else {
          print('Old appointment $_oldAppointmentId canceled successfully.');
        }
      }

      Navigator.pushReplacementNamed(context, 'success_booking');
    } catch (e) {
      print('Error booking appointment: $e');
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Helpers
  String _englishDayOfWeek(DateTime d) {
    switch (d.weekday) {
      case DateTime.monday:
        return 'monday';
      case DateTime.tuesday:
        return 'tuesday';
      case DateTime.wednesday:
        return 'wednesday';
      case DateTime.thursday:
        return 'thursday';
      case DateTime.friday:
        return 'friday';
      case DateTime.saturday:
        return 'saturday';
      case DateTime.sunday:
        return 'sunday';
      default:
        return '';
    }
  }

  TimeOfDay? _parseTimeOfDay(String str) {
    try {
      final parts = str.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      return TimeOfDay(hour: h, minute: m);
    } catch (_) {
      return null;
    }
  }

  TimeOfDay _timeOfDayFromString(String str) {
    final parts = str.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  int _compareTimes(TimeOfDay a, TimeOfDay b) {
    final aM = a.hour * 60 + a.minute;
    final bM = b.hour * 60 + b.minute;
    return aM.compareTo(bM);
  }

  List<String> _generate30MinSlots(TimeOfDay st, TimeOfDay et) {
    final result = <String>[];
    var current = DateTime(2000, 1, 1, st.hour, st.minute);
    final end = DateTime(2000, 1, 1, et.hour, et.minute);
    while (current.isBefore(end)) {
      final td = TimeOfDay.fromDateTime(current);
      final hh = td.hour.toString().padLeft(2, '0');
      final mm = td.minute.toString().padLeft(2, '0');
      result.add('$hh:$mm');
      current = current.add(const Duration(minutes: 30));
    }
    return result;
  }
}
