import 'package:doctor_appointment_app/main_layout.dart';
import 'package:doctor_appointment_app/models/auth_model.dart';
import 'package:doctor_appointment_app/screens/auth_page.dart';
import 'package:doctor_appointment_app/screens/auth_pro_page.dart';
import 'package:doctor_appointment_app/screens/booking_page.dart';
import 'package:doctor_appointment_app/screens/home_page_pro.dart';
import 'package:doctor_appointment_app/screens/add_event_pro.dart';
import 'package:doctor_appointment_app/screens/success_booked.dart';
import 'package:doctor_appointment_app/screens/password_recovery_page.dart';
import 'package:doctor_appointment_app/screens/password_recovery_page_pro.dart';
import 'package:doctor_appointment_app/utils/config.dart';
import 'package:doctor_appointment_app/screens/appointment_page.dart';
import 'package:doctor_appointment_app/screens/fav_page.dart';
import 'package:doctor_appointment_app/screens/profile_page_pro.dart';
import 'package:doctor_appointment_app/components/sign_up_form.dart';
import 'package:doctor_appointment_app/components/sign_up_form_pro.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase core package
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart'; // Firebase options generated file
import 'package:doctor_appointment_app/screens/doctor_details.dart';
import 'package:doctor_appointment_app/screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase initialized successfully.");
  } catch (e) {
    print("❌ Error initializing Firebase: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Navigator key for global navigation
  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthModel>(
      create: (_) => AuthModel(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Doctor Appointment App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'MaterialIcons',
          textTheme: Typography.material2021().white,
          inputDecorationTheme: const InputDecorationTheme(
            focusColor: Config.primaryColor,
            border: Config.outlinedBorder,
            focusedBorder: Config.focusBorder,
            errorBorder: Config.errorBorder,
            enabledBorder: Config.outlinedBorder,
            floatingLabelStyle: TextStyle(color: Config.primaryColor),
            prefixIconColor: Colors.black38,
          ),
          scaffoldBackgroundColor: Colors.white,
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.transparent,
            selectedItemColor: Colors.white,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            unselectedItemColor: Colors.grey.shade700,
            elevation: 10,
            type: BottomNavigationBarType.fixed,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthPage(),
          'main': (context) => const MainLayout(),
          'booking_page': (context) => BookingPage(),
          'success_booking': (context) => const SuccessBooked(),
          '/register': (context) => const SignUpForm(),
          '/auth_pro': (context) => const AuthProPage(),
          '/sign_up_pro': (context) => const SignUpProScreen(),
          '/home_pro': (context) => const HomePagePro(),
          '/add_event_pro': (context) => const AddEventProPage(),
          '/profile_pro': (context) => const ProfileProPage(),
          '/password_recovery': (context) => const PasswordRecoveryPage(),
          '/password_recovery_pro': (context) => const PasswordRecoveryPagePro(),
          '/doctor_details': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
            return DoctorDetails(doctor: args, isFav: args['isFav'] ?? false);
          },
        },
      ),
    );
  }
}
