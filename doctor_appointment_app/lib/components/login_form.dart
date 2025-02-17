import 'package:doctor_appointment_app/components/button.dart';
import 'package:doctor_appointment_app/main.dart';
import 'package:doctor_appointment_app/models/auth_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/config.dart';

class LoginForm extends StatefulWidget {
  final VoidCallback? onLoginSuccess; // Optional callback for login success

  const LoginForm({Key? key, this.onLoginSuccess}) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool obscurePass = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            cursorColor: const Color.fromARGB(255, 232, 228, 214),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color.fromARGB(50, 232, 228, 214),
              hintText: 'Adresse e-mail',
              labelText: 'Email',
              alignLabelWithHint: true,
              prefixIcon: const Icon(Icons.email_outlined),
              prefixIconColor: const Color.fromARGB(255, 232, 228, 214),
              hintStyle: const TextStyle(
                color: Color.fromARGB(128, 232, 228, 214),
              ),
              labelStyle: const TextStyle(
                color: Color.fromARGB(255, 232, 228, 214),
              ),
              floatingLabelStyle: const TextStyle(
                color: Color.fromARGB(255, 232, 228, 214),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 232, 228, 214),
                  width: 2.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(
                  color: Color.fromARGB(128, 232, 228, 214),
                  width: 2.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 232, 228, 214),
                  width: 2.0,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 2.0,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 2.0,
                ),
              ),
            ),
            style: const TextStyle(
              color: Color.fromARGB(255, 232, 228, 214),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Entrez votre adresse e-mail';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'L’e-mail entré n’est pas valide.';
              }
              return null;
            },
          ),
          Config.spaceSmall,
          // Password Field
          TextFormField(
            controller: _passController,
            keyboardType: TextInputType.visiblePassword,
            cursorColor: const Color.fromARGB(255, 232, 228, 214),
            obscureText: obscurePass,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color.fromARGB(50, 232, 228, 214),
              hintText: 'Mot de passe',
              labelText: 'Mot de passe',
              alignLabelWithHint: true,
              prefixIcon: const Icon(Icons.lock_outline),
              prefixIconColor: const Color.fromARGB(255, 232, 228, 214),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    obscurePass = !obscurePass;
                  });
                },
                icon: obscurePass
                    ? const Icon(
                  Icons.visibility_off_outlined,
                  color: Color.fromARGB(128, 232, 228, 214),
                )
                    : const Icon(
                  Icons.visibility_outlined,
                  color: Color.fromARGB(255, 232, 228, 214),
                ),
              ),
              hintStyle: const TextStyle(
                color: Color.fromARGB(128, 232, 228, 214),
              ),
              labelStyle: const TextStyle(
                color: Color.fromARGB(255, 232, 228, 214),
              ),
              floatingLabelStyle: const TextStyle(
                color: Color.fromARGB(255, 232, 228, 214),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 232, 228, 214),
                  width: 2.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(
                  color: Color.fromARGB(128, 232, 228, 214),
                  width: 2.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 232, 228, 214),
                  width: 2.0,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 2.0,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 2.0,
                ),
              ),
            ),
            style: const TextStyle(
              color: Color.fromARGB(255, 232, 228, 214),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Entrez votre mot de passe';
              }
              if (value.length < 6) {
                return 'Le mot de passe doit comporter au moins 6 caractères.';
              }
              return null;
            },
          ),
          Config.spaceSmall,
          // Display Error Message if exists
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          // Login Button
          Consumer<AuthModel>(
            builder: (context, auth, child) {
              return Button(
                width: double.infinity,
                title: 'Se connecter',
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    bool success = await auth.signIn(
                      _emailController.text.trim(),
                      _passController.text,
                    );

                    if (success) {
                      final user = auth.currentUser;

                      // Check if the email is verified
                      if (user != null && !user.emailVerified) {
                        await auth.signOut(); // Sign out the unverified user

                        setState(() {
                          _errorMessage =
                          'Votre e-mail n\'est pas vérifié. Veuillez vérifier votre e-mail avant de vous connecter.';
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Votre e-mail n\'est pas vérifié. Veuillez vérifier votre boîte de réception.',
                            ),
                          ),
                        );

                        return; // Exit the function without navigating
                      }

                      // Email is verified; proceed with the navigation
                      if (widget.onLoginSuccess != null) {
                        widget.onLoginSuccess!(); // Trigger callback if provided
                      } else {
                        MyApp.navigatorKey.currentState!
                            .pushReplacementNamed('main'); // Default navigation
                      }
                    } else {
                      setState(() {
                        _errorMessage =
                        'Échec de la connexion. Veuillez vérifier vos informations.';
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Échec de la connexion. Veuillez vérifier vos informations.'),
                        ),
                      );
                    }
                  }
                },
                disable: false,
              );
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}