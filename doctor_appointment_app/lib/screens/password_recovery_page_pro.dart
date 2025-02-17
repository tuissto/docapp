import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class PasswordRecoveryPagePro extends StatefulWidget {
  const PasswordRecoveryPagePro({Key? key}) : super(key: key);

  @override
  State<PasswordRecoveryPagePro> createState() =>
      _PasswordRecoveryPageProState();
}

class _PasswordRecoveryPageProState extends State<PasswordRecoveryPagePro> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetEmail(String email) async {
    print("Attempting to send password reset email to: $email");
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      print("Password reset email sent successfully.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Un e-mail de récupération a été envoyé à $email.'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.code} - ${e.message}");
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun compte trouvé avec cet e-mail.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.message}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  const Spacer(flex: 2),
                  const Text(
                    'Entrez votre adresse e-mail pour recevoir un lien de récupération.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 232, 228, 214),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      hintText: 'Adresse e-mail',
                      hintStyle: const TextStyle(
                        color: Color.fromARGB(255, 232, 228, 214),
                      ),
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: Color.fromARGB(255, 232, 228, 214),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 232, 228, 214),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 232, 228, 214),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 232, 228, 214),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 50,
                      ),
                    ),
                    onPressed: () {
                      String email = _emailController.text.trim();

                      if (email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Veuillez entrer votre adresse e-mail.',
                            ),
                          ),
                        );
                        return;
                      }

                      _sendPasswordResetEmail(email);
                    },
                    child: const Text(
                      'Envoyer le lien',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        "Vous avez déjà un compte ?",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color.fromARGB(255, 232, 228, 214),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/');
                        },
                        child: const Text(
                          'Se connecter',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 232, 228, 214),
                          ),
                        ),
                      )
                    ],
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
