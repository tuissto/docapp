// lib/screens/fav_page.dart

import "package:doctor_appointment_app/components/doctor_card.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../models/auth_model.dart";

class FavPage extends StatefulWidget {
  const FavPage({Key? key}) : super(key: key);

  @override
  State<FavPage> createState() => _FavPageState();
}

class _FavPageState extends State<FavPage> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchFavoriteDoctors();
  }

  // Fetch favorite doctors using AuthModel
  Future<void> _fetchFavoriteDoctors() async {
    try {
      final auth = Provider.of<AuthModel>(context, listen: false);
      await auth.fetchFavoriteDoctors(); // Ensure this method is implemented
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Échec du chargement de la liste de favoris';
        _isLoading = false;
      });
      print('Error fetching favorite doctors: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8E4D6), // Set the desired background color
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 20, right: 20),
          child: Column(
            children: [
              // Removed the 'Favoris' Text widget and SizedBox
              Expanded(
                child: Consumer<AuthModel>(
                  builder: (context, auth, child) {
                    if (_isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (_errorMessage != null) {
                      return Center(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      );
                    } else if (auth.favDoc.isEmpty) {
                      return const Center(
                        child: Text(
                          'Vous n’avez pas encore ajouté de favori',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    } else {
                      return ListView.builder(
                        itemCount: auth.favDoc.length,
                        itemBuilder: (context, index) {
                          return DoctorCard(
                            doctor: auth.favDoc[index],
                            isFav: true,
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
