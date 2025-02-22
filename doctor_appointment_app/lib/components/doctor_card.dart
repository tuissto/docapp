import 'package:doctor_appointment_app/main.dart';
import 'package:doctor_appointment_app/screens/doctor_details.dart';
import 'package:doctor_appointment_app/utils/config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doctor_appointment_app/models/auth_model.dart';

class DoctorCard extends StatelessWidget {
  const DoctorCard({
    Key? key,
    required this.doctor,
    required this.isFav,
  }) : super(key: key);

  final Map<String, dynamic> doctor;
  final bool isFav;

  @override
  Widget build(BuildContext context) {
    Config().init(context);
    final auth = Provider.of<AuthModel>(context, listen: false);

    // 1) Build the main image URL: 'images'[0] or 'doctor_profile_url'
    final dynamicImages = (doctor['images'] is List) ? doctor['images'] as List : [];
    final List<String> images = dynamicImages.map((e) => e.toString()).toList();

    String mainImageUrl = '';
    if (images.isNotEmpty) {
      mainImageUrl = images[0];
    } else {
      // fallback
      final profileUrl = (doctor['doctor_profile_url'] ?? '').toString();
      if (profileUrl.isNotEmpty) {
        mainImageUrl = profileUrl;
      }
    }

    // The image widget
    Widget buildImageWidget() {
      if (mainImageUrl.trim().isEmpty) {
        // Show a fallback container with an icon
        return Container(
          color: Colors.grey[300],
          child: const Center(
            child: Icon(
              Icons.person,
              size: 50,
              color: Colors.black54,
            ),
          ),
        );
      } else {
        // Show the image from network
        return Image.network(
          mainImageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Center(
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.black54,
                ),
              ),
            );
          },
        );
      }
    }

    // 2) The card UI
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      height: 150,
      child: InkWell(
        // Instead of a pop-up, do a named route push to "/doctor_details"
        onTap: () {
          // Merge isFav into the doc so DoctorDetails can see it
          final mergedDoc = {
            ...doctor,
            'isFav': isFav,
          };

          Navigator.pushNamed(
            context,
            '/doctor_details',
            arguments: mergedDoc,
          );
        },
        child: Card(
          elevation: 5,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Row(
            children: [
              // Left: Image area
              SizedBox(
                width: Config.widthSize * 0.33,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10.0),
                    bottomLeft: Radius.circular(10.0),
                  ),
                  child: buildImageWidget(),
                ),
              ),

              // Right: Info
              Expanded(
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Doctor Name
                      Text(
                        doctor['doctor_name'] ?? 'Nom Inconnu',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),

                      // Doctor Category
                      Text(
                        doctor['category'] ?? 'Spécialisation Inconnue',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),

                      // A row with rating placeholder & Fav button
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.star,
                            color: Colors.yellow,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '4.5',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Reviews',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '(20)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.red : Colors.grey,
                            ),
                            onPressed: () async {
                              final doctorId = doctor['doc_id'] ?? doctor['uid'];
                              if (doctorId == null) {
                                print('Cannot toggle favorite, missing doc_id/uid');
                                return;
                              }
                              if (isFav) {
                                await auth.removeFavoriteDoctor(doctorId);
                              } else {
                                await auth.addFavoriteDoctor(doctor);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
