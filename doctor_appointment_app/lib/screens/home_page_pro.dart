import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class HomePagePro extends StatefulWidget {
  const HomePagePro({Key? key}) : super(key: key);

  @override
  State<HomePagePro> createState() => _HomePageProState();
}

class _HomePageProState extends State<HomePagePro> {
  CalendarView _calendarView = CalendarView.day; // Default to Day View
  final CalendarController _calendarController = CalendarController();
  DateTime _selectedDate = DateTime.now();

  Map<String, dynamic> _doctorInfo = {};
  String _selectedPrestataire = 'All'; // Default to show all
  bool _isLoading = true;

  // The final list of appointments to show in the calendar
  List<Appointment> _appointments = [];

  // A color map to color-code by prestation name
  // Expand or adjust as needed
  final Map<String, Color> _prestationColors = {
    'manicure': Colors.pink,
    'pedicure': Colors.purple,
    'haircut': Colors.blue,
    'coloring': Colors.orange,
    'makeup': Colors.teal,
  };

  @override
  void initState() {
    super.initState();
    _calendarController.view = _calendarView; // Set initial view to Day
    _fetchDoctorInfo();
  }

  // 1) Fetch the "doctors/{uid}" doc for the current pro user
  Future<void> _fetchDoctorInfo() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(uid)
          .get();
      if (doc.exists) {
        setState(() {
          _doctorInfo = doc.data() as Map<String, dynamic>;
        });
        // After fetching doc info, fetch the appointments
        await _fetchAppointments();
      } else {
        print('No doctor found for the current user.');
      }
    } catch (e) {
      print('Error fetching doctor info: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 2) Fetch appointments that belong to this pro user
  //    We'll parse each doc to create an Appointment for the SfCalendar
  Future<void> _fetchAppointments() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final querySnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctor_id', isEqualTo: uid)
          .get();

      final List<Appointment> appointments = [];

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // For clarity, print each doc:
        // print('DEBUG appointment doc => $data');

        // We expect fields like:
        // "date" (yyyy-MM-dd)
        // "time" (HH:mm)
        // "prestation_nom"
        // "prestation_duree" (int or string)
        // "user_name", "user_phone"
        // "prestataire"
        // "status"
        // etc.

        final dateStr = data['date'] ?? '';
        final timeStr = data['time'] ?? '';
        final duree = data['prestation_duree'] ?? 30;

        // Build startTime by parsing date/time
        // e.g. date=2024-12-26, time=10:00
        final startTime = _parseDateTime(dateStr, timeStr);
        // EndTime = startTime + Duree minutes
        final endTime = startTime.add(Duration(
          minutes: duree is int ? duree : int.tryParse(duree.toString()) ?? 30,
        ));

        // The subject can contain user name/phone + prestation
        final userName = data['user_name'] ?? 'Unknown User';
        final userPhone = data['user_phone'] ?? '';
        final prestationName = data['prestation_nom'] ?? 'Prestation?';

        final subject =
            '$userName ($userPhone) - $prestationName';

        // Color-code by prestationName
        final color = _getColorForPrestation(prestationName);

        // We can store the "prestataire" in notes or location
        final prestataire = data['prestataire'] ?? 'Unknown Prestataire';

        appointments.add(Appointment(
          startTime: startTime,
          endTime: endTime,
          subject: subject,
          color: color,
          notes: prestataire,
        ));
      }

      setState(() {
        _appointments = appointments;
      });
    } catch (e) {
      print('Error fetching appointments: $e');
    }
  }

  // Helper to parse "yyyy-MM-dd" and "HH:mm" into a DateTime
  DateTime _parseDateTime(String dateStr, String timeStr) {
    // dateStr like "2024-12-26", timeStr like "10:00"
    try {
      final dateParts = dateStr.split('-');
      final y = int.parse(dateParts[0]);
      final m = int.parse(dateParts[1]);
      final d = int.parse(dateParts[2]);

      final timeParts = timeStr.split(':');
      final hh = int.parse(timeParts[0]);
      final mm = int.parse(timeParts[1]);

      return DateTime(y, m, d, hh, mm);
    } catch (e) {
      print('Error parsing date/time: $e');
      return DateTime.now();
    }
  }

  // Return a color for a given prestation name
  Color _getColorForPrestation(String prestationName) {
    final lower = prestationName.toLowerCase();
    if (_prestationColors.containsKey(lower)) {
      return _prestationColors[lower]!;
    }
    // Default color if not found
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 232, 228, 214),
      body: Column(
        children: [
          // 1) A custom top area
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 232, 228, 214),
            ),
            child: Stack(
              children: [
                Center(
                  child: RichText(
                    text: const TextSpan(
                      text: 'Bookit',
                      style: TextStyle(
                        fontFamily: 'DreamAvenue',
                        fontSize: 46,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                      children: [
                        TextSpan(
                          text: ' Pro',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.logout,
                        color: Colors.black87, size: 28),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacementNamed(context, '/auth_pro');
                    },
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
              children: [
                // 2) A row of prestataire "filters"
                Wrap(
                  spacing: 8.0,
                  children: [
                    if (_doctorInfo['prestataires'] != null &&
                        _doctorInfo['prestataires'] is List &&
                        (_doctorInfo['prestataires'] as List).isNotEmpty)
                      ...(_doctorInfo['prestataires'] as List<dynamic>)
                          .map<Widget>((prestName) {
                        return ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedPrestataire = prestName;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedPrestataire == prestName
                                ? Colors.black
                                : const Color.fromARGB(255, 232, 228, 214),
                          ),
                          child: Text(
                            prestName.toString(),
                            style: TextStyle(
                              color: _selectedPrestataire == prestName
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        );
                      }).toList()
                    else
                      const Text('Aucun prestataire disponible'),

                    // Button for "All"
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedPrestataire = 'All';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedPrestataire == 'All'
                            ? Colors.black
                            : const Color.fromARGB(255, 232, 228, 214),
                      ),
                      child: Text(
                        'Tous',
                        style: TextStyle(
                          color: _selectedPrestataire == 'All'
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // 3) Toggle between Day/Week view
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _calendarView = _calendarView == CalendarView.day
                          ? CalendarView.week
                          : CalendarView.day;
                      _calendarController.view = _calendarView;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _calendarView == CalendarView.day
                        ? 'Vue semaine'
                        : 'Vue jour',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),

                const SizedBox(height: 10),

                // 4) The main SfCalendar
                Expanded(
                  child: SfCalendar(
                    controller: _calendarController,
                    initialSelectedDate: _selectedDate,
                    onTap: (details) {
                      if (details.date != null) {
                        setState(() {
                          _selectedDate = details.date!;
                        });
                      }
                    },
                    dataSource: _getCalendarDataSource(_selectedPrestataire),
                    view: _calendarView,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // A simple bottom nav
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 232, 228, 214),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Ajouter',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
            // Already on home
              break;
            case 1:
              Navigator.pushNamed(context, '/add_event_pro');
              break;
            case 2:
              Navigator.pushNamed(context, '/profile_pro');
              break;
          }
        },
      ),
    );
  }

  // Filter by selected prestataire or show "All"
  CalendarDataSource _getCalendarDataSource(String prestataireName) {
    final List<Appointment> filteredAppointments;
    if (prestataireName == 'All') {
      filteredAppointments = _appointments;
    } else {
      filteredAppointments = _appointments.where((appointment) {
        // Recall that we stored the "prestataire" in appointment.notes
        return appointment.notes == prestataireName;
      }).toList();
    }

    return _AppointmentDataSource(filteredAppointments);
  }
}

// The data source for SfCalendar
class _AppointmentDataSource extends CalendarDataSource {
  _AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}
