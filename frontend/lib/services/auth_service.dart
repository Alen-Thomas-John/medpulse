import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword(
      String email, String password, String role) async {
    try {
      // Create the user account
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Add user to pending users collection
      await _firestore.collection('pending_users').doc(userCredential.user!.uid).set({
        'email': email,
        'role': role,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      print('Error registering: $e');
      rethrow;
    }
  }

  // Check if user is approved
  Future<bool> isUserApproved(String email) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('approved_users').doc(email).get();
      return doc.exists;
    } catch (e) {
      print('Error checking if user is approved: $e');
      return false;
    }
  }

  // Check if user is admin
  Future<bool> isUserAdmin(String email) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('admins').doc(email).get();
      return doc.exists;
    } catch (e) {
      print('Error checking if user is admin: $e');
      return false;
    }
  }

  // Get user role
  Future<String?> getUserRole(String email) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('approved_users').doc(email).get();
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['role'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
} 