// firebase_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:js_util';


class FirebaseProvider {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign in
  Future<bool> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      print('Error signing in: $e');
      return false;
    }
  }

  // Register user
  Future<bool> registerUser(String username, String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      String uid = userCredential.user!.uid;

      // Save additional user data in Firestore
      await _firestore.collection('users').doc(uid).set({
        'username': username,
        'email': email,
        'fav': [],
        // Add other user details as needed
      });

      return true;
    } catch (e) {
      print('Error registering user: $e');
      return false;
    }
  }

  // Get current user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return doc.data() as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Book appointment
  Future<bool> bookAppointment(String date, String day, String time, int doctorId) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('appointments').add({
          'userId': user.uid,
          'doctorId': doctorId,
          'date': date,
          'day': day,
          'time': time,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
      return false;
    } catch (e) {
      print('Error booking appointment: $e');
      return false;
    }
  }

  // Get appointments
  Future<List<Map<String, dynamic>>> getAppointments() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        QuerySnapshot snapshot = await _firestore
            .collection('appointments')
            .where('userId', isEqualTo: user.uid)
            .get();
        return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      print('Error retrieving appointments: $e');
      return [];
    }
  }

  // Store reviews
  Future<bool> storeReviews(String reviewText, double rating, String appointmentId, int doctorId) async {
    try {
      await _firestore.collection('reviews').add({
        'appointmentId': appointmentId,
        'doctorId': doctorId,
        'reviewText': reviewText,
        'rating': rating,
        'userId': _auth.currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error storing review: $e');
      return false;
    }
  }

  // Store favorite doctors
  Future<bool> storeFavDoc(List<int> favList) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fav': favList,
        });
        return true;
      }
      return false;
    } catch (e) {
      print('Error storing favorite doctors: $e');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
