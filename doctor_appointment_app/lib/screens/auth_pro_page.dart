import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auth_model.dart';
import '../utils/config.dart';
import '../utils/text.dart';
import '../components/button.dart';
import 'package:doctor_appointment_app/components/login_form_pro.dart';
import 'package:doctor_appointment_app/screens/password_recovery_page_pro.dart';

class AuthProPage extends StatefulWidget {
  const AuthProPage({Key? key}) : super(key: key);

  @override
  State<AuthProPage> createState() => _AuthProPageState();
}

class _AuthProPageState extends State<AuthProPage> {
  bool isSignIn = true;

  final _formKey = GlobalKey<FormState>();
  final _etablissementController = TextEditingController();
  final _gerantController = TextEditingController();
  final _adresseController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  final OutlineInputBorder _border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(
      color: Color.fromARGB(255, 232, 228, 214),
    ),
  );

  final InputDecoration _inputDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.white.withOpacity(0.1),
    hintStyle: const TextStyle(color: Color.fromARGB(255, 232, 228, 214)),
    labelStyle: const TextStyle(color: Color.fromARGB(255, 232, 228, 214)),
    prefixIconColor: Color.fromARGB(255, 232, 228, 214),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color.fromARGB(255, 232, 228, 214)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color.fromARGB(255, 232, 228, 214), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
  );

  @override
  void dispose() {
    _etablissementController.dispose();
    _gerantController.dispose();
    _adresseController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration.copyWith(
        hintText: hint,
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      style: const TextStyle(color: Color.fromARGB(255, 232, 228, 214)),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Entrez $label';
        }
        return null;
      },
    );
  }

  Widget _buildSignUpForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextFormField(
            controller: _etablissementController,
            label: 'Etablissement',
            hint: 'Nom de l’établissement',
            icon: Icons.business_outlined,
          ),
          Config.spaceSmall,
          _buildTextFormField(
            controller: _gerantController,
            label: 'Gérant de l’établissement',
            hint: 'Nom du gérant',
            icon: Icons.person_outline,
          ),
          Config.spaceSmall,
          _buildTextFormField(
            controller: _adresseController,
            label: 'Adresse postale',
            hint: 'Adresse complète',
            icon: Icons.location_on_outlined,
          ),
          Config.spaceSmall,
          _buildTextFormField(
            controller: _phoneController,
            label: 'Numéro de téléphone',
            hint: 'Ex: +33 6 12 34 56 78',
            icon: Icons.phone_outlined,
          ),
          Config.spaceSmall,
          _buildTextFormField(
            controller: _emailController,
            label: 'Email',
            hint: 'Adresse e-mail',
            icon: Icons.email_outlined,
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

                    try {
                      // Compose email content
                      final emailBody = '''
        Nouvelle demande de création de compte:
        - Etablissement: ${_etablissementController.text.trim()}
        - Gérant: ${_gerantController.text.trim()}
        - Adresse: ${_adresseController.text.trim()}
        - Téléphone: ${_phoneController.text.trim()}
        - Email: ${_emailController.text.trim()}
      ''';

                      // Send email via Firebase function
                      final emailSent = await auth.sendEmailViaFunction(
                        subject: 'Nouvelle demande de création de compte',
                        body: emailBody,
                        recipient: 'hajarchbiki@gmail.com',
                      );

                      if (!emailSent) {
                        throw Exception("Erreur lors de l'envoi de l'email.");
                      }

                      // Register the pro user
                      final success = await auth.registerProUser(
                        username: _etablissementController.text.trim(),
                        phonenumber: _phoneController.text.trim(),
                        email: _emailController.text.trim(),
                        managerName: _gerantController.text.trim(),
                        address: _adresseController.text.trim(),
                        userType: 'pro',
                        status: 'not verified',
                      );

                      setState(() {
                        _isLoading = false;
                      });

                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Votre demande de création de compte a été bien prise en compte. Un conseiller va prendre contact avec vous pour activer votre compte.',
                            ),
                          ),
                        );
                      } else {
                        throw Exception("Erreur lors de la création de l'utilisateur.");
                      }
                    } catch (e) {
                      setState(() {
                        _isLoading = false;
                      });

                      print('Error during registration: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Une erreur s'est produite : ${e.toString()}",
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
    );
  }

  @override
  Widget build(BuildContext context) {
    Config().init(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/Images/Login.png',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(top: 110.0),
                            child: Column(
                              children: [
                                RichText(
                                  text: TextSpan(
                                    text: AppText.enText['Welcome_text'] ?? 'Bookit',
                                    style: const TextStyle(
                                      fontFamily: 'DreamAvenue',
                                      fontSize: 60,
                                      fontWeight: FontWeight.w500,
                                      color: Color.fromARGB(255, 232, 228, 214),
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: ' Pro',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 232, 228, 214),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                isSignIn
                                    ? const LoginFormPro()
                                    : _buildSignUpForm(),
                                isSignIn
                                    ? Center(
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/password_recovery_pro');
                                    },
                                    child: Text(
                                      AppText.enText['forgo-password'] ?? 'Mot de passe oublié ?',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Color.fromARGB(255, 232, 228, 214),
                                      ),
                                    ),
                                  ),
                                )
                                    : Container(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isSignIn
                                    ? AppText.enText['signup_text'] ?? 'Première connexion ?'
                                    : AppText.enText['registerup_text'] ?? 'Vous avez déjà un compte ?',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color.fromARGB(255, 232, 228, 214),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    isSignIn = !isSignIn;
                                  });
                                },
                                child: Text(
                                  isSignIn ? 'Ajouter votre établissement' : 'Se connecter',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 232, 228, 214),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Add "Bookit Pro" Button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              const Color.fromARGB(255, 232, 228, 214),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 50,
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(
                                  context, '/'); // Define this route
                            },
                            child: const Text(
                              'Bookit',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
