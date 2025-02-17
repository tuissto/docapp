// lib/screens/success_booked.dart

import 'package:doctor_appointment_app/utils/config.dart';
import 'package:flutter/material.dart';


class SuccessBooked extends StatelessWidget {
  const SuccessBooked({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Config().init(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 50,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Image or Icon
              Container(
                height: Config.heightSize * 0.4,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/success.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Config.spaceMedium,
              // Success Message
              const Text(
                'Appointment Booked Successfully!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Config.spaceSmall,
              const Text(
                'You will receive a confirmation email with the appointment details shortly.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              Config.spaceMedium,
              // Back to Home Button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('main', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Config.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 15,
                  ),
                ),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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

