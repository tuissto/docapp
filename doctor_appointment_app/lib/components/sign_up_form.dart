// lib/screens/signup_form.dart

import 'package:doctor_appointment_app/components/button.dart';
import 'package:doctor_appointment_app/main.dart';
import 'package:doctor_appointment_app/models/auth_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/config.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({Key? key}) : super(key: key);

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phonenumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool obscurePass = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phonenumberController.dispose();
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
          // Username Field
          TextFormField(
            controller: _nameController,
            keyboardType: TextInputType.text,
            cursorColor: const Color.fromARGB(255, 232, 228, 214),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color.fromARGB(50, 232, 228, 214),
              hintText: 'Votre nom',
              labelText: 'Nom',
              floatingLabelStyle: const TextStyle(
                color: Color.fromARGB(255, 232, 228, 214),
              ),
              hintStyle: const TextStyle(
                color: Color.fromARGB(128, 232, 228, 214),
              ),
              labelStyle: const TextStyle(
                color: Color.fromARGB(255, 232, 228, 214),
              ),
              alignLabelWithHint: true,
              prefixIcon: const Icon(Icons.person_outlined),
              prefixIconColor: const Color.fromARGB(255, 232, 228, 214),
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
                  color: Color.fromARGB(255, 232, 228, 214),
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
                  color: Colors.red, // Typically, error borders are red
                  width: 2.0,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(
                  color: Colors.red, // Typically, error borders are red
                  width: 2.0,
                ),
              ),
            ),
            style: const TextStyle(
              color: Color.fromARGB(255, 232, 228, 214),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Entrez votre nom';
              }
              return null;
            },
          ),
          Config.spaceSmall,

          // Phone number Field
          TextFormField(
            controller: _phonenumberController,
            keyboardType: TextInputType.phone,
            cursorColor: const Color.fromARGB(255, 232, 228, 214),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color.fromARGB(50, 232, 228, 214),
              hintText: 'Numéro de téléphone',
              labelText: 'Numéro de téléphone',
              floatingLabelStyle: const TextStyle(
                color: Color.fromARGB(255, 232, 228, 214),
              ),
              hintStyle: const TextStyle(
                color: Color.fromARGB(128, 232, 228, 214),
              ),
              labelStyle: const TextStyle(
                color: Color.fromARGB(255, 232, 228, 214),
              ),
              alignLabelWithHint: true,
              prefixIcon: const Icon(Icons.phone_outlined),
              prefixIconColor: const Color.fromARGB(255, 232, 228, 214),
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
                  color: Color.fromARGB(255, 232, 228, 214),
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
                return 'Entrez votre numéro de téléphone';
              }
              return null;
            },
          ),
          Config.spaceSmall,

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
              floatingLabelStyle: const TextStyle(
                color: Color.fromARGB(255, 232, 228, 214),
              ),
              hintStyle: const TextStyle(
                color: Color.fromARGB(128, 232, 228, 214),
              ),
              labelStyle: const TextStyle(
                color: Color.fromARGB(255, 232, 228, 214),
              ),
              alignLabelWithHint: true,
              prefixIcon: const Icon(Icons.email_outlined),
              prefixIconColor: const Color.fromARGB(255, 232, 228, 214),
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
                  color: Color.fromARGB(255, 232, 228, 214),
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
                return 'Adresse e-mail invalide.';
              }
              return null;
            },
          ),
          Config.spaceSmall,

          // Password Field
          TextFormField(
            controller: _passController,
            obscureText: obscurePass,
            cursorColor: const Color.fromARGB(255, 232, 228, 214),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color.fromARGB(50, 232, 228, 214),
              hintText: 'Mot de passe',
              labelText: 'Mot de passe',
              floatingLabelStyle: const TextStyle(
                color: Color.fromARGB(255, 232, 228, 214),
              ),
              hintStyle: const TextStyle(
                color: Color.fromARGB(128, 232, 228, 214),
              ),
              labelStyle: const TextStyle(
                color: Color.fromARGB(255, 232, 228, 214),
              ),
              alignLabelWithHint: true,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    obscurePass = !obscurePass;
                  });
                },
                icon: obscurePass
                    ? const Icon(
                  Icons.visibility_off_outlined,
                  color: Color.fromARGB(255, 232, 228, 214),
                )
                    : const Icon(
                  Icons.visibility_outlined,
                  color: Color.fromARGB(255, 232, 228, 214),
                ),
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
                  color: Color.fromARGB(255, 232, 228, 214),
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
                return 'Le mot de passe doit contenir au moins 6 caractères.';
              }
              return null;
            },
          ),
          Config.spaceSmall,

          // Submit Button
          Consumer<AuthModel>(
            builder: (context, auth, child) {
              return _isLoading
                  ? const CircularProgressIndicator(
                color: Color.fromARGB(255, 232, 228, 214),
              )
                  : Button(
                width: double.infinity,
                title: 'S’inscrire',
                disable: _isLoading, // Added disable parameter
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _isLoading = true;
                    });

                    bool success = await auth.registerUser(
                      username: _nameController.text.trim(),
                      phonenumber: _phonenumberController.text.trim(),
                      email: _emailController.text.trim(),
                      password: _passController.text.trim(),
                      userType: 'normal', // Specify user type as 'normal'
                    );

                    setState(() {
                      _isLoading = false;
                    });

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Un e-mail de vérification a été envoyé. Veuillez vérifier votre e-mail avant de vous connecter.',
                          ),
                        ),
                      );

                      // Navigate to a "Waiting for Verification" page or redirect to the login page.
                      Navigator.pushReplacementNamed(context, '/');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Échec de l’inscription. Veuillez réessayer.'),
                        ),
                      );
                    }
                  }
                },
              );
            },
          ),

        ],
      ),
    );
  }
}