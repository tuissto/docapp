// lib/models/auth_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current authenticated user
  User? get currentUser => _auth.currentUser;

  // User data
  Map<String, dynamic> _user = {};
  Map<String, dynamic> get user => _user;

  // Favorite doctor IDs
  List<String> _favDocIds = [];

  // Favorite doctors' details
  List<Map<String, dynamic>> _favDoc = [];
  List<Map<String, dynamic>> get favDoc => _favDoc;

  // Appointments
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> get appointments => _appointments;

  // All doctors for search functionality
  List<Map<String, dynamic>> _allDoctors = [];
  List<Map<String, dynamic>> get allDoctors => _allDoctors;

  // Authentication status
  bool _isLogin = false;
  bool get isLogin => _isLogin;

  // Constructor
  AuthModel() {
    _auth.authStateChanges().listen(_authStateChanged);
  }

  // ----------------------------
  // 1) Register / Add Doctor
  // ----------------------------

  Future<void> addDoctor({
    required String doctorName,
    required String managerName,
    required String address,
    required String phone,
    required String email,
  }) async {
    try {
      final uid = _auth.currentUser!.uid;
      await _firestore.collection('doctors').doc(uid).set({
        'doc_id': uid,
        'doctor_name': doctorName,
        'manager_name': managerName,
        'address': address,
        'phone': phone,
        'email': email,
        'patients': 0,
        'experience': 0,
        'qualifications': '',
        'category': '',
        'hospital': '',
        'rating': 0,
        'doctor_profile_url': '',
        'prestataires': [],
        // Ensure we have an empty list so 'images' always exists
        'images': [],
      });
      print('Doctor added successfully');
    } catch (e) {
      print('Error adding doctor: $e');
      throw Exception('Failed to add doctor');
    }
  }

  Future<bool> registerUser({
    required String username,
    required String phonenumber,
    required String email,
    required String password,
    required String userType,
    String? managerName,
    String? address,
  }) async {
    try {
      final userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        final uid = user.uid;
        // Send email verification
        await user.sendEmailVerification();

        // Save user details in Firestore
        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'phonenumber': phonenumber,
          'userType': userType,
          'profile_image_url': '',
          'fav': [],
          'username': username,
          'email': email,
          'verified': false,
        });
      }

      // If pro => add doctor doc
      if (userType == 'pro') {
        await addDoctor(
          doctorName: username,
          managerName: managerName!,
          address: address!,
          phone: phonenumber,
          email: email,
        );
      }

      await fetchUserData();
      return true;
    } catch (e) {
      print('Error registering user: $e');
      return false;
    }
  }

  Future<bool> registerProUser({
    required String username,
    required String phonenumber,
    required String email,
    required String userType,
    required String managerName,
    required String address,
    String status = 'not verified',
  }) async {
    try {
      print('Attempting to register pro user with email: $email');
      final userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: 'temporary_password',
      );

      final userId = userCredential.user?.uid;
      if (userId == null) {
        throw Exception('Firebase user creation failed.');
      }

      print('User created in Firebase Auth: UID: $userId');

      final proUserData = {
        'uid': userId,
        'username': username,
        'phonenumber': phonenumber,
        'email': email,
        'userType': userType,
        'managerName': managerName,
        'address': address,
        'status': status,
        'images': [],
      };

      await _firestore.collection('doctors').doc(userId).set(proUserData);

      print('Pro user registered successfully in Firestore: UID: $userId');
      return true;
    } catch (e) {
      print('Error registering pro user: $e');
      return false;
    }
  }

  // -------------------------------
  // 2) Email & Verification Logic
  // -------------------------------

  Future<bool> sendEmailViaFunction({
    required String subject,
    required String body,
    required String recipient,
  }) async {
    final url = Uri.parse(
        'https://us-central1-docapp-62a21.cloudfunctions.net/sendSignUpEmail');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'subject': subject,
          'body': body,
          'recipient': recipient,
        }),
      );

      if (response.statusCode == 200) {
        print("Email sent successfully via Firebase Function");
        return true;
      } else {
        print("Failed to send email: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error sending email: $e");
      return false;
    }
  }

  Future<void> checkVerificationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    await user?.reload();

    if (user != null && user.emailVerified) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'verified': true});
      print('Email verified successfully.');
    } else {
      print('Email is not verified yet.');
    }
  }

  Future<bool> checkProEmailVerified(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('doctors')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        return data['status'] == 'verified';
      }
      return false;
    } catch (e) {
      print('Error checking pro email verification: $e');
      return false;
    }
  }

  Future<void> resendVerificationEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      print('Verification email sent.');
    } else {
      print('User is already verified or not logged in.');
    }
  }

  // -------------------------------
  // 3) Doctors, Favorites, etc.
  // -------------------------------

  /// Make sure to fetch 'images' too
  Future<void> fetchAllDoctors() async {
    try {
      final snapshot = await _firestore.collection('doctors').get();
      _allDoctors = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'doc_id': data['doc_id'] ?? doc.id,
          'address': data['address'],
          'doctor_name': data['doctor_name'],
          'category': data['category'],
          'doctor_profile_url': data['doctor_profile_url'] ?? '',
          'images': data['images'] ?? [], // fetch images
          'patients': data['patients'] ?? 0,
          'experience': data['experience'] ?? 0,
          'qualifications': data['qualifications'] ?? '',
          'hospital': data['hospital'] ?? '',
          'prestataires': data.containsKey('prestataires')
              ? List<String>.from(data['prestataires'])
              : [],
          'prestations': data['prestations'] ?? {},
        };
      }).toList();

      notifyListeners();
    } catch (e) {
      print('Error fetching all doctors: $e');
    }
  }

  // --------------
  // Appointments
  // --------------

  /// Re-fetch each appointment doc,
  /// then fetch the relevant 'doctors/{doctorId}' doc => store 'images' in the appointment map
  Future<void> fetchAppointments() async {
    try {
      final userId = _auth.currentUser!.uid;
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('user_id', isEqualTo: userId)
          .orderBy('date', descending: false)
          .get();

      final List<Map<String, dynamic>> newAppointments = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final doctorId = data['doctor_id'] ?? '';
        List<dynamic> doctorImages = [];

        // If we have a doctorId, fetch that doc
        if (doctorId.isNotEmpty) {
          final docSnap =
          await _firestore.collection('doctors').doc(doctorId).get();
          if (docSnap.exists) {
            final docData = docSnap.data() as Map<String, dynamic>;
            // Pull out images from the doc
            doctorImages = docData['images'] ?? [];
          }
        }

        // Build the final appointment map with images
        final appointmentMap = {
          'appointment_id': data['appointment_id'],
          'doctor_id': doctorId,

          'doctor_name': data['doctor_name'] ?? '',
          'category': data['category'] ?? '',
          'doctor_profile_url': data['doctor_profile_url'] ?? '',
          'images': doctorImages, // store images

          'date': data['date'] ?? '',
          'day': data['day'] ?? '',
          'time': data['time'] ?? '',
          'prestataire': data['prestataire'] ?? '',

          'prestation_id': data['prestation_id'] ?? '',
          'prestation_duree': data['prestation_duree'] ?? 30,
          'prestation_nom': data['prestation_nom'] ?? '',
          'prestation_prix': data['prestation_prix'] ?? '',
          'status': data['status'] ?? 'upcoming',
        };

        // ---- CRITICAL CHANGE ----
        // (Remove the .where((appt) => appt['status'] != 'cancelled'))
        // so we keep all statuses => "annulé" + "passé" can show images
        // if you want to store them all locally:
        newAppointments.add(appointmentMap);
      }

      // Now _appointments has all statuses: upcoming, cancelled, completed
      _appointments = newAppointments;
      notifyListeners();
    } catch (e) {
      print('Error fetching appointments: $e');
    }
  }

  // -------------------------------
  // 4) Auth State Changes
  // -------------------------------

  Future<void> _authStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _isLogin = false;
      _user = {};
      _favDocIds = [];
      _favDoc = [];
      _appointments = [];
      _allDoctors = [];
    } else {
      _isLogin = true;
      await fetchUserData();
      await fetchFavoriteDoctors();
      await fetchAppointments();
      await fetchAllDoctors();
    }
    notifyListeners();
  }

  // --------------
  // Sign In / Out
  // --------------

  Future<bool> signIn(String email, String password) async {
    try {
      final userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null && !user.emailVerified) {
        await FirebaseAuth.instance.signOut();
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Please verify your email before signing in.',
        );
      }

      await fetchUserData();
      return true;
    } catch (e) {
      print('Error signing in: $e');
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        clientId:
        '511435478216-4tv4mafljbd95cc039npgt4glme50r3m.apps.googleusercontent.com',
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        return true;
      }

      await fetchUserData();
      return true;
    } catch (e) {
      print('Google Sign-In error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _isLogin = false;
      _user = {};
      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
      throw Exception('Failed to sign out');
    }
  }

  // ----------------------
  // 5) User Data & Fav
  // ----------------------

  Future<void> fetchUserData() async {
    try {
      final userId = _auth.currentUser!.uid;
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        _user = userDoc.data() as Map<String, dynamic>;
        _favDocIds = List<String>.from(_user['fav'] ?? []);
      } else {
        _user = {};
        _favDocIds = [];
      }
      notifyListeners();
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error logging out: $e');
    }
  }

  Future<void> fetchFavoriteDoctors() async {
    _favDoc = [];
    try {
      if (_favDocIds.isNotEmpty) {
        final List<Map<String, dynamic>> fetchedFavDocs = [];
        const batchSize = 10;
        for (int i = 0; i < _favDocIds.length; i += batchSize) {
          final end = (i + batchSize > _favDocIds.length)
              ? _favDocIds.length
              : i + batchSize;
          final batch = _favDocIds.sublist(i, end);

          final doctorSnapshot = await _firestore
              .collection('doctors')
              .where('doc_id', whereIn: batch)
              .get();

          fetchedFavDocs.addAll(doctorSnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'doc_id': data['doc_id'],
              'doctor_name': data['doctor_name'],
              'category': data['category'],
              'doctor_profile_url': data['doctor_profile_url'] ?? '',
              'images': data['images'] ?? [],
              'patients': data['patients'] ?? 0,
              'experience': data['experience'] ?? 0,
              'qualifications': data['qualifications'] ?? '',
              'hospital': data['hospital'] ?? '',
              'prestataires': data.containsKey('prestataires')
                  ? List<String>.from(data['prestataires'])
                  : [],
              'prestations': data['prestations'] ?? {},
            };
          }).toList());
        }
        _favDoc = fetchedFavDocs;
      } else {
        _favDoc = [];
      }
      notifyListeners();
    } catch (e) {
      print('Error fetching favorite doctors: $e');
    }
  }

  Future<void> addFavoriteDoctor(Map<String, dynamic> doctor) async {
    try {
      // The currently logged-in user's UID
      final String userId = _auth.currentUser!.uid;

      // Attempt to find a 'users/{userId}' doc
      final userSnap = await _firestore.collection('users').doc(userId).get();
      if (userSnap.exists) {
        // It's a normal user => store favorites in users/{uid}

        // Ensure doc_id is present in the doctor map
        final String doctorId = doctor['doc_id'] ?? '';
        if (doctorId.isEmpty) {
          throw Exception('No doc_id found in doctor map.');
        }

        // Update the 'fav' array in users/{uid}
        await _firestore.collection('users').doc(userId).update({
          'fav': FieldValue.arrayUnion([doctorId]),
        });
        print('Added $doctorId to fav for normal user $userId');

      } else {
        // No doc in 'users/' => check 'doctors/{uid}'
        final proSnap = await _firestore.collection('doctors').doc(userId).get();
        if (!proSnap.exists) {
          // Neither users/ nor doctors/ has a doc => error
          throw Exception('No doc in users/ or doctors/ for UID=$userId');
        }

        // It's a pro => store favorites in doctors/{uid}
        final String doctorId = doctor['doc_id'] ?? '';
        if (doctorId.isEmpty) {
          throw Exception('No doc_id found in doctor map.');
        }

        // We keep a 'fav' array in the "doctors/{uid}" doc
        await _firestore.collection('doctors').doc(userId).update({
          'fav': FieldValue.arrayUnion([doctorId]),
        });
        print('Added $doctorId to fav for pro user $userId');
      }

    } catch (e) {
      print('Error adding favorite doctor: $e');
      throw Exception('Failed to add favorite doctor');
    }
  }


  Future<void> removeFavoriteDoctor(String doctorId) async {
    try {
      final String userId = _auth.currentUser!.uid;

      if (_favDocIds.contains(doctorId)) {
        await _firestore.collection('users').doc(userId).update({
          'fav': FieldValue.arrayRemove([doctorId]),
        });

        _favDocIds.remove(doctorId);
        _favDoc.removeWhere((d) => d['doc_id'] == doctorId);

        notifyListeners();
      }
    } catch (e) {
      print('Error removing favorite doctor: $e');
      throw Exception('Failed to remove favorite doctor');
    }
  }

  Future<List<Map<String, dynamic>>> getAppointments() async {
    try {
      final userId = _auth.currentUser!.uid;
      final snapshot = await _firestore
          .collection('appointments')
          .where('user_id', isEqualTo: userId)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'status': data['status'] ?? 'upcoming',
        };
      }).toList();
    } catch (e) {
      print('Error fetching appointments: $e');
      return [];
    }
  }
  // ---------------------------
  // 6) Booking & Availability
  // ---------------------------

  /// Book an appointment (storing prestation info too)
  Future<bool> bookAppointment({
    required String date,
    required String day,
    required String time,
    required String doctorId,
    required String prestataire,
    required String prestationId,   // NOTE: Make sure this is a String
    required int prestationDuree,
  }) async {
    try {
      final String currentUid = _auth.currentUser!.uid;
      final docRef = _firestore.collection('appointments').doc();

      // ---------------------------------------
      // 1) Attempt to read from 'users/{uid}'
      //    If that doesn't exist, read 'doctors/{uid}'
      // ---------------------------------------
      final userDocRef = _firestore.collection('users').doc(currentUid);
      final userSnap = await userDocRef.get();

      String userName = 'Unknown';
      String userPhone = '';
      String userEmail = '';
      String userType = 'normal';

      if (!userSnap.exists) {
        // No doc in 'users/', assume pro
        print('No "users/{uid}" doc found => checking "doctors/{uid}"...');
        final proSnap = await _firestore.collection('doctors').doc(currentUid).get();
        if (!proSnap.exists) {
          throw Exception('No doc in users/ or doctors/ for userId=$currentUid');
        }
        final proData = proSnap.data() as Map<String, dynamic>;
        userType = 'pro';

        // Fill from pro doc
        userName = proData['doctor_name'] ?? 'Unknown Pro';
        userPhone = proData['phonenumber'] ?? '';
        userEmail = proData['email'] ?? '';
      } else {
        // We have a doc in 'users/'
        final userData = userSnap.data() as Map<String, dynamic>;
        userType = userData['userType'] ?? 'normal';
        userName = userData['username'] ?? 'Unknown User';
        userPhone = userData['phonenumber'] ?? '';
        userEmail = userData['email'] ?? '';
      }

      // ---------------------------------------
      // 2) Fetch the doc for "doctorId" to get prestations
      // ---------------------------------------
      final doctorSnap = await _firestore.collection('doctors').doc(doctorId).get();
      if (!doctorSnap.exists) {
        throw Exception('Doctor not found (doctorId=$doctorId)');
      }

      final doctorData = doctorSnap.data() as Map<String, dynamic>;
      print('DEBUG: doctorData => $doctorData');
      print('DEBUG: Attempting to find prestationId=$prestationId in doctorData["prestations"]');

      // Retrieve prestation name & price from "doctorData['prestations']"
      String prestationNom = 'Prestation?';
      String prestationPrix = 'N/A';

      if (doctorData.containsKey('prestations')) {
        final allPrestations = doctorData['prestations'];
        print('DEBUG: allPrestations keys => ${allPrestations is Map ? allPrestations.keys : allPrestations}');
        print('DEBUG: type of prestationId => ${prestationId.runtimeType}, val=$prestationId');

        if (allPrestations is Map<String, dynamic>) {
          // convert "prestationId" to string to be sure
          final thisPrestation = allPrestations[prestationId.toString()];
          print('DEBUG: thisPrestation => $thisPrestation');

          if (thisPrestation is Map) {
            prestationNom = thisPrestation['nom'] ?? 'Prestation?';
            prestationPrix = thisPrestation['prix'] ?? 'N/A';
          } else {
            print('WARNING: The doctor doc has no entry for prestationId=$prestationId');
          }
        } else {
          print('WARNING: "prestations" is not Map<String,dynamic> => $allPrestations');
        }
      } else {
        print('WARNING: The doctor doc has no "prestations" key');
      }

      // ---------------------------------------
      // 3) Create the doc in "appointments"
      // ---------------------------------------
      await docRef.set({
        'appointment_id': docRef.id,

        // The user who is booking (could be normal or pro)
        'user_id': currentUid,
        'user_type': userType,
        'user_name': userName,
        'user_phone': userPhone,
        'user_email': userEmail,

        // The pro doc that user is booking with
        'doctor_id': doctorId,
        'doctor_name': doctorData['doctor_name'] ?? 'Unknown Doctor',
        'category': doctorData['category'] ?? '',
        'doctor_profile_url': doctorData['doctor_profile_url'] ?? '',

        // date/time
        'date': date,
        'day': day,
        'time': time,

        // prestataire + prestation info
        'prestataire': prestataire,
        'prestation_id': prestationId,   // store it as string if you prefer
        'prestation_duree': prestationDuree,
        'prestation_nom': prestationNom,
        'prestation_prix': prestationPrix,

        'status': 'upcoming',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ---------------------------------------
      // 4) Also add to local _appointments
      // ---------------------------------------
      _appointments.add({
        'appointment_id': docRef.id,

        'user_id': currentUid,
        'user_type': userType,
        'user_name': userName,
        'user_phone': userPhone,
        'user_email': userEmail,

        'doctor_id': doctorId,
        'doctor_name': doctorData['doctor_name'] ?? 'Unknown Doctor',
        'category': doctorData['category'] ?? '',
        'doctor_profile_url': doctorData['doctor_profile_url'] ?? '',

        'date': date,
        'day': day,
        'time': time,

        'prestataire': prestataire,
        'prestation_id': prestationId.toString(), // force string
        'prestation_duree': prestationDuree,
        'prestation_nom': prestationNom,
        'prestation_prix': prestationPrix,

        'status': 'upcoming',
      });

      notifyListeners();
      print('DEBUG: Booked appointment with prestation_nom=$prestationNom, prestation_prix=$prestationPrix for userType=$userType');
      return true;
    } catch (e) {
      print('Error booking appointment: $e');
      return false;
    }
  }






  /// Cancel an appointment => reinstate slots
  Future<bool> cancelAppointment(String appointmentId) async {
    try {
      final appointmentRef = _firestore.collection('appointments').doc(appointmentId);
      final apSnap = await appointmentRef.get();
      if (!apSnap.exists) {
        print('Appointment $appointmentId not found');
        return false;
      }
      final data = apSnap.data() as Map<String, dynamic>;
      if (data['status'] == 'cancelled') {
        print('Appointment already cancelled');
        return true;
      }

      // set status to cancelled
      await appointmentRef.update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // remove from local
      _appointments.removeWhere((ap) => ap['appointment_id'] == appointmentId);

      // Reinstate the slot(s)
      final doctorId = data['doctor_id'] ?? '';
      final prestataireName = data['prestataire'] ?? '';
      final dateStr = data['date'] ?? '';
      final startTimeStr = data['time'] ?? '00:00';
      final duration = data['prestation_duree'] ?? 30;
      final slotsCount = (duration + 29) ~/ 30;

      if (doctorId.isNotEmpty && prestataireName.isNotEmpty && dateStr.isNotEmpty) {
        await addSlotsToAvailability(
          doctorId: doctorId,
          prestataireName: prestataireName,
          dateStr: dateStr,
          startTimeStr: startTimeStr,
          slotsCount: slotsCount,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      print('Error canceling appointment: $e');
      return false;
    }
  }

  /// Reprogram an appointment => add old slot, remove new slot
  Future<bool> reprogramAppointment({
    required String appointmentId,
    required String newDate,
    required String newTime,
  }) async {
    try {
      final appointmentRef = _firestore.collection('appointments').doc(appointmentId);
      final apSnap = await appointmentRef.get();
      if (!apSnap.exists) {
        print('Appointment $appointmentId not found');
        return false;
      }
      final data = apSnap.data() as Map<String, dynamic>;
      if (data['status'] == 'cancelled') {
        print('Appointment is already cancelled, cannot reprogram.');
        return false;
      }

      // 1) Re-add the old slot if it's still in the future
      final oldDateStr = data['date'] ?? '';
      final oldTimeStr = data['time'] ?? '00:00';
      final oldPrest = data['prestataire'] ?? '';
      final oldDuration = data['prestation_duree'] ?? 30;
      final oldSlotsCount = (oldDuration + 29) ~/ 30;

      // Check if old date/time is in the future
      if (oldDateStr.isNotEmpty) {
        final oldDate = DateTime.tryParse(oldDateStr);
        if (oldDate != null) {
          final oldDT = DateTime(oldDate.year, oldDate.month, oldDate.day);
          final now = DateTime.now();
          if (oldDT.isAfter(now)) {
            // Re-add old slot
            print('Re-adding old slot $oldTimeStr on $oldDateStr for $oldPrest');
            await addSlotsToAvailability(
              doctorId: data['doctor_id'],
              prestataireName: oldPrest,
              dateStr: oldDateStr,
              startTimeStr: oldTimeStr,
              slotsCount: oldSlotsCount,
            );
          } else {
            print('Old date/time is in the past; skipping re-adding old slot');
          }
        }
      }

      // 2) Remove the new slot
      final newDuration = data['prestation_duree'] ?? 30;
      // Typically the same service, but if you let them change the prestation,
      // you'd have to pass that in.
      final newSlotsCount = (newDuration + 29) ~/ 30;

      // The same prestataire?
      final newPrest = oldPrest;
      // If you let them pick a new Prestataire, you'd also pass that in.

      print('Removing new slot $newTime on $newDate for $newPrest');
      await removeSlotsFromAvailability(
        doctorId: data['doctor_id'],
        prestataireName: newPrest,
        dateStr: newDate,
        startTimeStr: newTime,
        slotsCount: newSlotsCount,
      );

      // 3) Update the appointment doc
      await appointmentRef.update({
        'date': newDate,
        'time': newTime,
        'status': 'upcoming',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4) Update local _appointments
      final int index = _appointments.indexWhere((ap) => ap['appointment_id'] == appointmentId);
      if (index != -1) {
        _appointments[index]['date'] = newDate;
        _appointments[index]['time'] = newTime;
        _appointments[index]['status'] = 'upcoming';
        notifyListeners();
      }

      print('Successfully reprogrammed appointment $appointmentId to $newDate @ $newTime');
      return true;
    } catch (e) {
      print('Error reprogramming appointment: $e');
      return false;
    }
  }

  /// If the appointment date is past, mark as completed
  Future<void> updatePastAppointmentsStatus() async {
    try {
      final now = DateTime.now();
      final userId = _auth.currentUser!.uid;

      final querySnapshot = await _firestore
          .collection('appointments')
          .where('user_id', isEqualTo: userId)
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final appointmentDateStr = data['date'] ?? '';

        if (appointmentDateStr.isNotEmpty) {
          final appointmentDate = DateFormat('yyyy-MM-dd').parse(appointmentDateStr);
          if (appointmentDate.isBefore(now)) {
            if (data['status'] == 'upcoming') {
              await _firestore
                  .collection('appointments')
                  .doc(doc.id)
                  .update({
                'status': 'completed',
                'updatedAt': FieldValue.serverTimestamp(),
              });
              print('Appointment ${doc.id} marked as completed.');
            }
          }
        }
      }
      await fetchAppointments();
    } catch (e) {
      print('Error updating past appointments status: $e');
    }
  }

  // -----------------------
  // 7) Review
  // -----------------------
  Future<bool> storeReview({
    required String reviewText,
    required double rating,
    required String appointmentId,
    required String doctorId,
  }) async {
    try {
      final String userId = _auth.currentUser!.uid;

      await _firestore.collection('reviews').add({
        'appointment_id': appointmentId,
        'doctor_id': doctorId,
        'review_text': reviewText,
        'rating': rating,
        'user_id': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final int index = _appointments.indexWhere((ap) => ap['appointment_id'] == appointmentId);
      if (index != -1) {
        _appointments[index]['status'] = 'completed';
        notifyListeners();
      }
      return true;
    } catch (e) {
      print('Error storing review: $e');
      return false;
    }
  }

  // -------------------------------------------
  // 8) Removing & Re-Adding Slots in Availability
  // -------------------------------------------

  String _englishDayOfWeek(DateTime date) {
    switch (date.weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return '';
    }
  }

  Future<bool> removeSlotsFromAvailability({
    required String doctorId,
    required String prestataireName,
    required String dateStr,
    required String startTimeStr,
    required int slotsCount,
  }) async {
    try {
      final snap = await _firestore
          .collection('availability')
          .where('doctor_id', isEqualTo: doctorId)
          .where('prestataire_name', isEqualTo: prestataireName)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        print('No availability doc found for removeSlots.');
        return false;
      }
      final docRef = snap.docs.first.reference;
      final availabilityData = snap.docs.first.data() as Map<String, dynamic>;

      if (availabilityData['batches'] is! List) {
        print('No batches array found for removeSlots.');
        return false;
      }
      final List batches = availabilityData['batches'];

      final selectedDate = DateTime.parse(dateStr);
      Map<String, dynamic>? targetBatch;
      for (var b in batches) {
        if (b is Map<String, dynamic>) {
          final startStr = b['start_date'] ?? '';
          final endStr = b['end_date'] ?? '';
          final startD = DateTime.tryParse(startStr);
          final endD = DateTime.tryParse(endStr);
          if (startD != null && endD != null) {
            if (!selectedDate.isBefore(startD) && !selectedDate.isAfter(endD)) {
              targetBatch = b;
              break;
            }
          }
        }
      }
      if (targetBatch == null) {
        print('No matching batch found for date=$dateStr');
        return true;
      }

      final dayOfWeek = _englishDayOfWeek(selectedDate);
      if (targetBatch['day_schedules'] is! Map) {
        return true;
      }
      final daySchedules = targetBatch['day_schedules'] as Map<String, dynamic>;
      if (!daySchedules.containsKey(dayOfWeek)) {
        return true;
      }
      final intervals = daySchedules[dayOfWeek];
      if (intervals is! List) {
        return true;
      }

      // Flatten
      final flattenList = <String>[];
      for (var interval in intervals) {
        if (interval is Map) {
          final st = interval['start_time'] ?? '';
          final et = interval['end_time'] ?? '';
          flattenList.addAll(_generateSlotStrings(st, et));
        }
      }

      // Remove
      final startIndex = flattenList.indexOf(startTimeStr);
      if (startIndex < 0) {
        print('Chosen slot $startTimeStr not found in flattenList');
      } else {
        final endIndex = startIndex + slotsCount;
        if (endIndex <= flattenList.length) {
          flattenList.removeRange(startIndex, endIndex);
        } else {
          flattenList.removeRange(startIndex, flattenList.length);
        }
      }

      final newIntervals = _rebuildIntervals(flattenList);
      daySchedules[dayOfWeek] = newIntervals;

      await docRef.update({'batches': batches});

      print('Removed $slotsCount slot(s) from $startTimeStr for day=$dayOfWeek');
      return true;
    } catch (e) {
      print('Error removing slots from availability: $e');
      return false;
    }
  }

  Future<bool> addSlotsToAvailability({
    required String doctorId,
    required String prestataireName,
    required String dateStr,
    required String startTimeStr,
    required int slotsCount,
  }) async {
    try {
      final snap = await _firestore
          .collection('availability')
          .where('doctor_id', isEqualTo: doctorId)
          .where('prestataire_name', isEqualTo: prestataireName)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        print('No availability doc found for addSlots.');
        return false;
      }
      final docRef = snap.docs.first.reference;
      final availabilityData = snap.docs.first.data() as Map<String, dynamic>;

      if (availabilityData['batches'] is! List) {
        print('No batches in addSlotsToAvailability');
        return false;
      }
      final List batches = availabilityData['batches'];

      final selectedDate = DateTime.parse(dateStr);
      Map<String, dynamic>? targetBatch;
      for (var b in batches) {
        if (b is Map<String, dynamic>) {
          final startStr = b['start_date'] ?? '';
          final endStr = b['end_date'] ?? '';
          final startD = DateTime.tryParse(startStr);
          final endD = DateTime.tryParse(endStr);
          if (startD != null && endD != null) {
            if (!selectedDate.isBefore(startD) && !selectedDate.isAfter(endD)) {
              targetBatch = b;
              break;
            }
          }
        }
      }
      if (targetBatch == null) {
        print('No batch covers date=$dateStr. Skipping addSlots.');
        return true;
      }

      final dayOfWeek = _englishDayOfWeek(selectedDate);
      if (targetBatch['day_schedules'] is! Map) {
        return true;
      }
      final ds = targetBatch['day_schedules'] as Map<String, dynamic>;
      if (!ds.containsKey(dayOfWeek)) {
        ds[dayOfWeek] = [];
      }
      final intervals = ds[dayOfWeek];
      if (intervals is! List) {
        return true;
      }

      // Flatten
      final flattenList = <String>[];
      for (var interval in intervals) {
        if (interval is Map) {
          final st = interval['start_time'] ?? '';
          final et = interval['end_time'] ?? '';
          flattenList.addAll(_generateSlotStrings(st, et));
        }
      }

      // Add the new slots
      final newSlots = <String>[];
      var current = startTimeStr;
      for (int i = 0; i < slotsCount; i++) {
        newSlots.add(current);
        current = _add30(current);
      }

      flattenList.addAll(newSlots);
      flattenList.sort(_compareSlotStrings);

      final newIntervals = _rebuildIntervals(flattenList);
      ds[dayOfWeek] = newIntervals;

      await docRef.update({'batches': batches});
      print('Reinstated $slotsCount slot(s) from $startTimeStr for day=$dayOfWeek');
      return true;
    } catch (e) {
      print('Error adding slots to availability: $e');
      return false;
    }
  }

  // ----------------------------------------
  // Helper methods to flatten intervals
  // ----------------------------------------

  /// Flatten an interval [start_time, end_time] into half-hour increments
  List<String> _generateSlotStrings(String startStr, String endStr) {
    final result = <String>[];
    try {
      final startParts = startStr.split(':');
      final endParts = endStr.split(':');
      int sh = int.parse(startParts[0]);
      int sm = int.parse(startParts[1]);
      int eh = int.parse(endParts[0]);
      int em = int.parse(endParts[1]);

      final startDT = DateTime(2000,1,1,sh,sm);
      final endDT = DateTime(2000,1,1,eh,em);
      var current = startDT;
      while (current.isBefore(endDT)) {
        final hh = current.hour.toString().padLeft(2,'0');
        final mm = current.minute.toString().padLeft(2,'0');
        result.add('$hh:$mm');
        current = current.add(const Duration(minutes:30));
      }
    } catch (e) {
      print('Error in _generateSlotStrings: $e');
    }
    return result;
  }

  /// Rebuild intervals from a sorted list of half-hour "HH:MM" strings
  List<Map<String, String>> _rebuildIntervals(List<String> halfHours) {
    final newIntervals = <Map<String, String>>[];
    if (halfHours.isEmpty) return newIntervals;

    String currentStart = halfHours.first;
    for (int i=0; i<halfHours.length - 1; i++) {
      final thisSlot = halfHours[i];
      final nextSlot = halfHours[i+1];
      if (_minutesBetween(thisSlot, nextSlot) > 30) {
        newIntervals.add({
          'start_time': currentStart,
          'end_time': _add30(thisSlot),
        });
        currentStart = nextSlot;
      }
    }
    // final one
    final lastSlot = halfHours.last;
    newIntervals.add({
      'start_time': currentStart,
      'end_time': _add30(lastSlot),
    });

    return newIntervals;
  }

  int _compareSlotStrings(String a, String b) {
    // sort "HH:MM"
    final ap = a.split(':');
    final bp = b.split(':');
    final ah = int.parse(ap[0]);
    final am = int.parse(ap[1]);
    final bh = int.parse(bp[0]);
    final bm = int.parse(bp[1]);
    final aMinutes = ah*60 + am;
    final bMinutes = bh*60 + bm;
    return aMinutes.compareTo(bMinutes);
  }

  int _minutesBetween(String a, String b) {
    try {
      final ap = a.split(':');
      final bp = b.split(':');
      final ah = int.parse(ap[0]);
      final am = int.parse(ap[1]);
      final bh = int.parse(bp[0]);
      final bm = int.parse(bp[1]);
      return (bh*60 + bm) - (ah*60 + am);
    } catch(_) {
      return 9999;
    }
  }

  String _add30(String timeStr) {
    final parts = timeStr.split(':');
    int h = int.parse(parts[0]);
    int m = int.parse(parts[1]);
    m += 30;
    if (m >= 60) {
      h += 1;
      m -= 60;
    }
    final hh = h.toString().padLeft(2,'0');
    final mm = m.toString().padLeft(2,'0');
    return '$hh:$mm';
  }
}
