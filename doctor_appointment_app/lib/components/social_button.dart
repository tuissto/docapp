import 'package:doctor_appointment_app/utils/config.dart';
import 'package:flutter/material.dart';

class SocialButton extends StatelessWidget {
  const SocialButton({Key? key, required this.social,this.text}) : super(key: key);

  final String social;
  final String? text;

  @override
  Widget build(BuildContext context) {
    Config().init(context);
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 60),
        side: const BorderSide(
          width: 1,
          color: Color.fromARGB(128, 232, 228, 214),
        ),
        backgroundColor: Color.fromARGB(255, 232, 228, 214),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0), // Adjust the radius as needed
        ),
        //fixedSize: Size(300, 25),
        minimumSize: Size(300,10),
      ),
      onPressed: () {},
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image.asset(
            'assets/$social.png',
            width: 15,
            height: 15,
          ),
          SizedBox(width: 20), // Space between icon and text
          Text(
            text ?? social.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
