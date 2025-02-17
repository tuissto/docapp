import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auth_model.dart';
import '../utils/config.dart';
import '../components/button.dart';

class SignUpProScreen extends StatefulWidget {
  final VoidCallback? onSignUpSuccess; // Optional callback for success

  const SignUpProScreen({Key? key, this.onSignUpSuccess}) : super(key: key);

  @override
  State<SignUpProScreen> createState() => _SignUpProScreenState();
}

class _SignUpProScreenState extends State<SignUpProScreen> {
  final _formKey = GlobalKey<FormState>();
  final _etablissementController = TextEditingController();
  final _gerantController = TextEditingController();
  final _adresseController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;


  @override
  void dispose() {
    _etablissementController.dispose();
    _gerantController.dispose();
    _adresseController.dispose();
    _phoneController.dispose();
    _emailController.dispose();

    super.dispose();
  }

  InputDecoration _buildInputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70),
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      prefixIcon: Icon(
        icon,
        color: Colors.white, // Set icon color to white
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white), // Set border color to white
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white, width: 2.0), // Set border color to white when focused
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/Images/Login.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 20),
                  const Text(
                    'Ajouter votre établissement',
                    style: TextStyle(
                      fontFamily: 'DreamAvenue',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _etablissementController,
                    decoration: _buildInputDecoration(
                      'Etablissement',
                      'Nom de l’établissement',
                      Icons.business_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Entrez Etablissement';
                      }
                      return null;
                    },
                  ),
                  Config.spaceSmall,
                  TextFormField(
                    controller: _gerantController,
                    decoration: _buildInputDecoration(
                      'Gérant de l’établissement',
                      'Nom du gérant',
                      Icons.person_outline,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Entrez Gérant de l’établissement';
                      }
                      return null;
                    },
                  ),
                  Config.spaceSmall,
                  TextFormField(
                    controller: _adresseController,
                    decoration: _buildInputDecoration(
                      'Adresse postale',
                      'Adresse complète',
                      Icons.location_on_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Entrez Adresse postale';
                      }
                      return null;
                    },
                  ),
                  Config.spaceSmall,
                  TextFormField(
                    controller: _phoneController,
                    decoration: _buildInputDecoration(
                      'Numéro de téléphone',
                      'Ex: +33 6 12 34 56 78',
                      Icons.phone_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Entrez Numéro de téléphone';
                      }
                      return null;
                    },
                  ),
                  Config.spaceSmall,
                  TextFormField(
                    controller: _emailController,
                    decoration: _buildInputDecoration(
                      'Email',
                      'Adresse e-mail',
                      Icons.email_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Entrez Email';
                      }
                      return null;
                    },
                  ),

                  Config.spaceSmall,
                  Consumer<AuthModel>(
                    builder: (context, auth, child) {
                      return _isLoading
                          ? const CircularProgressIndicator()
                          : Button(
                        width: double.infinity,
                        title: 'Valider',
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isLoading = true;
                            });

                            bool success = await auth.registerProUser(
                              username: _etablissementController.text.trim(),
                              phonenumber: _phoneController.text.trim(),
                              email: _emailController.text.trim(),
                              userType: 'pro',
                              managerName: _gerantController.text.trim(),
                              address: _adresseController.text.trim(),
                            );

                            setState(() {
                              _isLoading = false;
                            });

                            if (success && widget.onSignUpSuccess != null) {
                              widget.onSignUpSuccess!();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Échec de l’inscription. Veuillez réessayer.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        disable: _isLoading,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
