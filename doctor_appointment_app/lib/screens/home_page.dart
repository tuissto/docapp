import 'dart:async';
import 'package:doctor_appointment_app/components/appointment_card.dart';
import 'package:doctor_appointment_app/components/doctor_card.dart';
import 'package:doctor_appointment_app/models/auth_model.dart';
import 'package:doctor_appointment_app/utils/config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  bool _showDropdown = false;
  List<Map<String, dynamic>> _filteredResults = [];

  @override
  void initState() {
    super.initState();
    _fetchHomeData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Debounce the search input changes
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final auth = Provider.of<AuthModel>(context, listen: false);
      final allDoctors = auth.allDoctors;

      setState(() {
        _searchQuery = _searchController.text.trim();

        if (_searchQuery.isNotEmpty) {
          _filteredResults = allDoctors.where((doctor) {
            final doctorName =
            (doctor['doctor_name'] ?? '').toString().toLowerCase();
            final category =
            (doctor['category'] ?? '').toString().toLowerCase();
            final query = _searchQuery.toLowerCase();
            return doctorName.contains(query) || category.contains(query);
          }).toList();
          _showDropdown = _filteredResults.isNotEmpty;
        } else {
          _filteredResults = [];
          _showDropdown = false;
        }
      });
    });
  }

  /// Fetch user data, appointments, favorites, and all doctors
  Future<void> _fetchHomeData() async {
    try {
      final auth = Provider.of<AuthModel>(context, listen: false);
      // 1) Basic user data
      await auth.fetchUserData();
      // 2) Load appointments
      await auth.fetchAppointments();
      // 3) Load favorites
      await auth.fetchFavoriteDoctors();
      // 4) Load all doctors
      await auth.fetchAllDoctors();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Échec du chargement des données. Veuillez réessayer.';
        _isLoading = false;
      });
      print('Error fetching home data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Config().init(context);

    return Scaffold(
      backgroundColor: Config.primaryColor,
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.black),
      )
          : _errorMessage != null
          ? Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.red, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchHomeData,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 15,
              ),
              child: Consumer<AuthModel>(
                builder: (context, auth, child) {
                  final appointments = auth.appointments;
                  final favList = auth.favDoc;

                  // Filter upcoming appointments
                  final upcomingAppointments = appointments.where((appt) {
                    final scheduleStatus =
                    (appt['status'] ?? '').toLowerCase();
                    return scheduleStatus == 'upcoming';
                  }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Search Box
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText:
                          'Rechercher un salon, une prestation...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _showDropdown = false;
                              });
                            },
                          )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFFF8F7F2),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: Color(0xFFF8F7F2),
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: Color(0xFFF8F7F2),
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: Color(0xFFE8E4D6),
                              width: 2.0,
                            ),
                          ),
                        ),
                      ),

                      // Dropdown for search results
                      if (_showDropdown)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filteredResults.length,
                            itemBuilder: (context, index) {
                              final docMap = _filteredResults[index];
                              final docId = docMap['doc_id'] ?? '';
                              final isFavorite = favList.any(
                                    (fav) => fav['doc_id'] == docId,
                              );

                              return ListTile(
                                leading: _buildDoctorAvatar(docMap),
                                title: Text(
                                    docMap['doctor_name'] ?? 'No Name'),
                                subtitle: Text(
                                  docMap['category'] ?? 'No Category',
                                ),
                                onTap: () async {
                                  // Re-fetch the doc from Firestore
                                  if (docId.isNotEmpty) {
                                    try {
                                      final freshSnap =
                                      await FirebaseFirestore
                                          .instance
                                          .collection('doctors')
                                          .doc(docId)
                                          .get();
                                      if (freshSnap.exists) {
                                        final freshData =
                                            freshSnap.data() ?? {};
                                        // Merge isFav status
                                        final mergedData = {
                                          ...freshData,
                                          'isFav': isFavorite,
                                        };

                                        // Now go to DoctorDetails
                                        Navigator.pushNamed(
                                          context,
                                          '/doctor_details',
                                          arguments: mergedData,
                                        );
                                      } else {
                                        print(
                                            'No doc found for docId=$docId');
                                      }
                                    } catch (err) {
                                      print(
                                          'Error re-fetching doc: $err');
                                    }
                                  } else {
                                    print(
                                        'Invalid docId in search result');
                                  }
                                },
                              );
                            },
                          ),
                        ),

                      Config.spaceMedium,

                      // Upcoming Appointments
                      const Text(
                        'Mes rendez-vous',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Config.spaceSmall,
                      if (upcomingAppointments.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics:
                          const NeverScrollableScrollPhysics(),
                          itemCount: upcomingAppointments.length,
                          itemBuilder: (context, index) {
                            return AppointmentCard(
                              appointment:
                              upcomingAppointments[index],
                              color: Colors.blue,
                            );
                          },
                        )
                      else
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(
                                255, 232, 228, 214),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'Vous n’avez pas de rendez-vous à venir',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),

                      Config.spaceMedium,

                      // Favorites Section
                      const Text(
                        'Favoris',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Config.spaceSmall,
                      if (favList.isNotEmpty)
                        Column(
                          children: List.generate(
                            favList.length,
                                (index) {
                              final favDoc = favList[index];
                              // Show the doctor card. Tapping it calls
                              // the onTap from DoctorCard => DoctorDetails
                              return DoctorCard(
                                doctor: favDoc,
                                isFav: true,
                              );
                            },
                          ),
                        )
                      else
                        const Center(
                          child: Text(
                            'Vous n’avez pas encore ajouté de favori',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build the CircleAvatar for the doc in search results
  Widget _buildDoctorAvatar(Map<String, dynamic> docMap) {
    final dynamicImages =
    docMap['images'] is List ? docMap['images'] as List : [];
    final List<String> images = dynamicImages.map((e) => e.toString()).toList();

    // If images exist, use the first one; otherwise check 'doctor_profile_url'
    String avatarUrl = '';
    if (images.isNotEmpty) {
      avatarUrl = images[0];
    } else {
      final profileUrl = (docMap['doctor_profile_url'] ?? '').toString();
      if (profileUrl.trim().isNotEmpty) {
        avatarUrl = profileUrl;
      }
    }

    if (avatarUrl.isEmpty) {
      return const CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, color: Colors.white),
      );
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.grey[300],
      backgroundImage: NetworkImage(avatarUrl),
    );
  }
}
