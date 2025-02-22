import 'dart:io';
import 'dart:async'; // for Future.microtask
import 'dart:ui' as ui;  // Added for PointerDeviceKind
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctor_appointment_app/components/button.dart';
import 'package:doctor_appointment_app/models/auth_model.dart';
import 'package:doctor_appointment_app/utils/config.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../components/custom_appbar.dart';
import '../utils/styles.dart';

class DoctorDetails extends StatefulWidget {
  final Map<String, dynamic> doctor;
  final bool isFav;

  const DoctorDetails({
    Key? key,
    required this.doctor,
    required this.isFav,
  }) : super(key: key);

  @override
  State<DoctorDetails> createState() => _DoctorDetailsState();
}

class _DoctorDetailsState extends State<DoctorDetails> {
  late Map<String, dynamic> doctor;
  late bool isFav;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    doctor = widget.doctor;
    isFav = widget.isFav;
    print('Initial Doctor Data in Details: $doctor');
    // If prestations are missing, fetch the full doctor document.
    if (doctor['prestations'] == null ||
        (doctor['prestations'] is Map && (doctor['prestations'] as Map).isEmpty)) {
      fetchFullDoctorData();
    }
  }

  Future<void> fetchFullDoctorData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Use either 'doc_id' or 'uid'
      final docId = doctor['doc_id'] ?? doctor['uid'];
      if (docId == null || docId.toString().isEmpty) {
        throw Exception('Doctor UID is missing.');
      }
      final docSnap =
      await FirebaseFirestore.instance.collection('doctors').doc(docId.toString()).get();
      if (docSnap.exists) {
        final fullData = docSnap.data() as Map<String, dynamic>;
        setState(() {
          doctor = {
            ...doctor,
            ...fullData,
          };
        });
        print('Full Doctor Data Fetched: $doctor');
      } else {
        print('Doctor not found in Firestore.');
      }
    } catch (e) {
      print('Error fetching full doctor details: $e');
      setState(() {
        _errorMessage = 'Erreur de chargement des détails du docteur.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Config.primaryColor,
      appBar: CustomAppBar(
        appTitle: '',
        icon: const FaIcon(
          FontAwesomeIcons.arrowLeft,
          color: Colors.black,
        ),
        actions: [
          // Favorite Button
          IconButton(
            onPressed: _isLoading
                ? null
                : () async {
              setState(() => _isLoading = true);
              try {
                // Ensure doc_id is present
                if (doctor['doc_id'] == null && doctor['uid'] != null) {
                  doctor['doc_id'] = doctor['uid'];
                }
                final auth = Provider.of<AuthModel>(context, listen: false);
                if (isFav) {
                  await auth.removeFavoriteDoctor(doctor['doc_id']);
                } else {
                  await auth.addFavoriteDoctor(doctor);
                }
                final newIsFav = !isFav;
                Future.microtask(() {
                  if (!mounted) return;
                  setState(() {
                    isFav = newIsFav;
                    _errorMessage = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        newIsFav ? 'Ajouté aux favoris' : 'Retiré des favoris.',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: newIsFav ? Colors.green : Colors.red,
                    ),
                  );
                });
              } catch (e) {
                print('Erreur lors de la mise à jour des favoris: $e');
                Future.microtask(() {
                  if (!mounted) return;
                  setState(() {
                    _errorMessage = 'Échec de la mise à jour des favoris. Veuillez réessayer.';
                  });
                });
              } finally {
                Future.microtask(() {
                  if (!mounted) return;
                  setState(() {
                    _isLoading = false;
                  });
                });
              }
            },
            icon: _isLoading
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.red,
                strokeWidth: 2,
              ),
            )
                : FaIcon(
              isFav ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
              color: Colors.red,
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      )
          : Column(
        children: <Widget>[
          AboutDoctor(doctor: doctor),
          Expanded(
            child: SingleChildScrollView(
              child: DetailBody(doctor: doctor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays doctor images, name, address, etc.
class AboutDoctor extends StatefulWidget {
  final Map<String, dynamic> doctor;
  const AboutDoctor({Key? key, required this.doctor}) : super(key: key);

  @override
  State<AboutDoctor> createState() => _AboutDoctorState();
}

class _AboutDoctorState extends State<AboutDoctor> {
  PageController? _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.5);
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Config().init(context);
    final dynamicImages =
    (widget.doctor['images'] is List) ? widget.doctor['images'] as List : [];
    final images = dynamicImages.map((e) => e.toString()).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: images.isEmpty
                ? Container(
              color: Colors.grey,
              child: const Center(child: Text('Aucune image')),
            )
                : ScrollConfiguration(
              behavior: MyCustomScrollBehavior(),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentIndex = idx),
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (ctx, index) {
                  final url = images[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenGalleryPage(
                            images: images,
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey,
                              child: const Center(
                                child: Text('Erreur de chargement'),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.doctor['doctor_name'] ?? 'Nom non disponible',
            style: AppStyles.doctorName,
          ),
          const SizedBox(height: 5),
          Text(
            widget.doctor['address'] ?? 'Adresse inconnue',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: Config.widthSize * 0.75,
            child: Text(
              widget.doctor['qualifications'] ?? 'Qualifications non disponibles',
              style: AppStyles.doctorQualifications,
              softWrap: true,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: Config.widthSize * 0.75,
            child: Text(
              widget.doctor['hospital'] ?? 'Hôpital non spécifié',
              style: AppStyles.doctorHospital,
              softWrap: true,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays the doctor's bio and a list of prestations with Book buttons.
class DetailBody extends StatelessWidget {
  final Map<String, dynamic> doctor;
  const DetailBody({Key? key, required this.doctor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Config().init(context);
    final bio = doctor['bio'] ?? 'Biographie non disponible';

    // Build prestations list from the doctor document.
    List<Map<String, dynamic>> prestationList = [];
    if (doctor.containsKey('prestations') && doctor['prestations'] is Map) {
      final raw = doctor['prestations'] as Map;
      raw.forEach((k, v) {
        if (v is Map) {
          prestationList.add({
            'id': k,
            'nom': v['nom'] ?? 'Unnamed',
            'description': v['description'] ?? '',
            'prix': v['prix']?.toString() ?? '',
            'duree': v['duree']?.toString() ?? '',
          });
        }
      });
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 10),
          const Text(
            'Toutes les prestations',
            style: AppStyles.aboutDoctorTitle,
          ),
          const SizedBox(height: 10),
          Text(
            bio,
            style: AppStyles.aboutDoctorBio,
            softWrap: true,
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 20),
          if (prestationList.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: prestationList.map((p) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['nom'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text('Description: ${p['description']}'),
                        Text('Durée: ${p['duree']} min'),
                        Text('Prix: ${p['prix']}'),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                'booking_page',
                                arguments: {
                                  'doctor': doctor,
                                  'prestationId': p['id'],
                                },
                              );
                            },
                            icon: const Icon(Icons.event_available),
                            label: const Text('Book'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            )
          else
            const Text(
              'Aucune prestation disponible',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}

class FullScreenGalleryPage extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenGalleryPage({
    Key? key,
    required this.images,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<FullScreenGalleryPage> createState() => _FullScreenGalleryPageState();
}

class _FullScreenGalleryPageState extends State<FullScreenGalleryPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  void _goToPage(int index) {
    if (index >= 0 && index < widget.images.length) {
      setState(() {
        _currentIndex = index;
        _pageController.jumpToPage(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentIndex = idx),
            itemCount: images.length,
            itemBuilder: (context, index) {
              final imageUrl = images[index];
              return InteractiveViewer(
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, error, stackTrace) {
                      return Container(
                        color: Colors.grey,
                        child: const Center(
                          child: Text(
                            "Erreur de chargement",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          if (_currentIndex > 0)
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.arrow_left, size: 40, color: Colors.white),
                  onPressed: () => _goToPage(_currentIndex - 1),
                ),
              ),
            ),
          if (_currentIndex < images.length - 1)
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.arrow_right, size: 40, color: Colors.white),
                  onPressed: () => _goToPage(_currentIndex + 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<ui.PointerDeviceKind> get dragDevices => {
    ui.PointerDeviceKind.touch,
    ui.PointerDeviceKind.mouse,
    ui.PointerDeviceKind.trackpad,
  };
}
