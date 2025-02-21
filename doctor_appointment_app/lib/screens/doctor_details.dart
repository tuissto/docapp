import 'dart:io';
import 'package:doctor_appointment_app/components/button.dart';
import 'package:doctor_appointment_app/models/auth_model.dart';
import 'package:doctor_appointment_app/utils/config.dart';
import 'package:flutter/gestures.dart';
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

    print('Doctor Data in Details: $doctor'); // Debug print
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthModel>(context, listen: false);

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
            onPressed: () async {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });

              try {
                // Ensure we have 'doc_id' so addFavoriteDoctor(...) works
                if (doctor['doc_id'] == null && doctor['uid'] != null) {
                  doctor['doc_id'] = doctor['uid'];
                }

                if (isFav) {
                  // remove from favorites
                  await auth.removeFavoriteDoctor(doctor['doc_id']);
                } else {
                  // add to favorites
                  await auth.addFavoriteDoctor(doctor);
                }

                setState(() {
                  isFav = !isFav;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isFav ? 'Ajouté aux favoris' : 'Retiré des favoris.',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: isFav ? Colors.green : Colors.red,
                  ),
                );
              } catch (e) {
                setState(() {
                  _errorMessage = 'Échec de la mise à jour des favoris. Veuillez réessayer.';
                });
                print('Erreur lors de la mise à jour des favoris: $e');
              } finally {
                setState(() {
                  _isLoading = false;
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
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Top section: horizontal slider for images + basic doctor info
            AboutDoctor(doctor: doctor),

            // Additional details below
            Expanded(
              child: SingleChildScrollView(
                child: DetailBody(doctor: doctor),
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.all(20),
              child: Button(
                width: double.infinity,
                title: 'Réservez un rendez-vous',
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    'booking_page', // Make sure this matches your route name (no leading slash if your route is 'booking_page')
                    arguments: doctor,
                  );
                },
                disable: false,
                color: const Color(0xFFF8F7F2),
              ),
            ),

            // Error message, if any
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A top section that displays all images in a horizontal slider (PageView)
/// with half the screen width each. If no images => grey box.
/// Clicking an image -> full-screen gallery with L/R arrows.
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
    // Set half screen width with viewportFraction
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
          // Horizontal image slider
          SizedBox(
            height: 220,
            child: (images.isEmpty)
                ? Container(
              color: Colors.grey,
              child: const Center(
                child: Text('Aucune image'),
              ),
            )
                : ScrollConfiguration(
              // ensure mouse dragging works by customizing scroll behavior
              behavior: MyCustomScrollBehavior(),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) {
                  setState(() => _currentIndex = idx);
                },
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (ctx, index) {
                  final url = images[index];
                  return GestureDetector(
                    onTap: () {
                      // Open a full-screen gallery
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
          Config.spaceMedium,

          // Basic info
          Text(
            widget.doctor['doctor_name'] ?? 'Nom non disponible',
            style: AppStyles.doctorName,
          ),
          Config.spaceSmall,
          Text(
            widget.doctor['address'] ?? 'Adresse inconnue',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          Config.spaceSmall,
          SizedBox(
            width: Config.widthSize * 0.75,
            child: Text(
              widget.doctor['qualifications'] ?? 'Qualifications non disponibles',
              style: AppStyles.doctorQualifications,
              softWrap: true,
              textAlign: TextAlign.center,
            ),
          ),
          Config.spaceSmall,
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

/// The rest of the doctor's details
/// (like "Toutes les prestations", "bio", etc.).
/// No separate images here, since we show them all in AboutDoctor.
class DetailBody extends StatelessWidget {
  final Map<String, dynamic> doctor;
  const DetailBody({Key? key, required this.doctor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Config().init(context);

    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Config.spaceSmall,
          const Text(
            'Toutes les prestations',
            style: AppStyles.aboutDoctorTitle,
          ),
          Config.spaceSmall,
          Text(
            doctor['bio'] ?? 'Biographie non disponible',
            style: AppStyles.aboutDoctorBio,
            softWrap: true,
            textAlign: TextAlign.justify,
          ),
          // Add more info here if needed
        ],
      ),
    );
  }
}

/// Full-screen gallery with left/right arrow navigation & InteractiveViewer for zoom
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

          // Left arrow
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

          // Right arrow
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

/// Custom scroll behavior to allow mouse dragging on web/desktop for PageView.
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}
