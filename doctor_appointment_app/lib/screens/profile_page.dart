// lib/screens/profile_page.dart

import 'package:doctor_appointment_app/components/custom_appbar.dart';
import 'package:doctor_appointment_app/models/auth_model.dart';
import 'package:doctor_appointment_app/utils/config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Config().init(context);
    final auth = Provider.of<AuthModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFE8E4D6), // Set the desired background color
      //appBar: CustomAppBar(
        //appTitle: '', // Removed the 'Profile' title by setting it to empty
      //),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 15,
          ),
          child: auth.isLogin
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(
                  auth.user['profile_image_url'] ??
                      'https://via.placeholder.com/150',
                ),
              ),
              Config.spaceMedium,
              Text(
                auth.user['username'] ?? 'User Name',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Config.spaceSmall,
              Text(
                auth.user['email'] ?? 'user@example.com',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              Config.spaceMedium,
               // ElevatedButton(
                //onPressed: () async {
                  //await auth.logout();
                  //Navigator.of(context)
                      //.pushNamedAndRemoveUntil('login', (route) => false);
              //  },
                //style: ElevatedButton.styleFrom(
                  //backgroundColor: Color.fromARGB(300, 232, 228, 214),
                 // padding: const EdgeInsets.symmetric(
                   // horizontal: 50,
                   // vertical: 15,
                 // ),
                //),
               // child: const Text(
                 // 'Se déconnecter',
                 // style: TextStyle(
                 //   color: Colors.black,
                  //  fontSize: 16,
               //   ),
                //),
             // ),
            ],
          )
              : const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}
