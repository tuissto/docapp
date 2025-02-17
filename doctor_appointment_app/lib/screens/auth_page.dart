import 'package:doctor_appointment_app/components/login_form.dart';
import 'package:doctor_appointment_app/components/sign_up_form.dart';
import 'package:doctor_appointment_app/components/social_button.dart';
import 'package:doctor_appointment_app/utils/text.dart';
import 'package:flutter/material.dart';
import 'package:doctor_appointment_app/screens/password_recovery_page.dart';
import '../utils/config.dart';
import 'package:provider/provider.dart';
import 'package:doctor_appointment_app/models/auth_model.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isSignIn = true;

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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 110.0),
                                child: Column(
                                  children: [
                                    Text(
                                      AppText.enText['Welcome_text'] ?? 'Bookit',
                                      style: const TextStyle(
                                        fontFamily: 'DreamAvenue',
                                        fontSize: 60,
                                        fontWeight: FontWeight.w500,
                                        color: Color.fromARGB(255, 232, 228, 214),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      isSignIn
                                          ? AppText.enText['signin_text'] ??
                                          'La beauté en un clic, réservez \n          votre rendez-vous :'
                                          : AppText.enText['register_text'] ??
                                          'Nouveau sur Bookit ?',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color.fromARGB(255, 232, 228, 214),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    isSignIn
                                        ? const LoginForm()
                                        : const SignUpForm(),
                                    isSignIn
                                        ? Center(
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.pushNamed(context, '/password_recovery');
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
                            ],
                          ),
                          const SizedBox(height: 75),
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  const SizedBox(
                                    width: 150,
                                    child: Divider(
                                      color: Color.fromARGB(255, 232, 228, 214),
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      AppText.enText['Social-login'] ?? 'Ou',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Color.fromARGB(255, 232, 228, 214),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 150,
                                    child: Divider(
                                      color: Color.fromARGB(255, 232, 228, 214),
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.login),
                                    label: const Text('Continuer avec Google'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () async {
                                      final auth = Provider.of<AuthModel>(context, listen: false);

                                      final success = await auth.signInWithGoogle();

                                      if (success) {
                                        // Navigate to the main screen
                                        Navigator.of(context).pushReplacementNamed('main');
                                      } else {
                                        // Show error message if sign-in fails
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Google Sign-In failed. Please try again.'),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 40),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    //AppText.enText['signup_text'] ??
                                    isSignIn ? "vous n'avez pas de compte ?" : "vous avez déja un compte ?",
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
                                      isSignIn ? 'S’inscrire' : 'Se connecter',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 232, 228, 214),
                                      ),
                                    ),
                                  )
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
                                      context, '/auth_pro'); // Define this route
                                },
                                child: const Text(
                                  'Bookit Pro',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
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
        ],
      ),
    );
  }
}