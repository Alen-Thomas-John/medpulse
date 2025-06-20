import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up with email, password, and role
  Future<String?> signUp(String email, String password, String role) async {
    try {
      print("Starting signUp process for email: $email, role: $role");
      
      // Check if the email is already in use
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        return "Email already in use";
      }
      
      // For admin role, proceed with normal signup
      if (role == 'admin') {
        // Check if admin already exists
        final adminDoc = await _firestore.collection('user_roles').doc(email).get();
        if (adminDoc.exists) {
          return "Admin account already exists";
        }
        
        // Create the user account
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        print("User account created successfully: ${userCredential.user?.uid}");
        
        // Save role to Firestore
        try {
          await _firestore.collection('user_roles').doc(email).set({
            'role': role,
            'uid': userCredential.user?.uid,
          });
          print("Saving role to Firestore in user_roles collection");
        } catch (e) {
          print("Error saving role to Firestore: $e");
          // Continue even if Firestore update fails
        }
        
        // Save user info to users collection
        try {
          await _firestore.collection('users').doc(email).set({
            'email': email,
            'role': role,
            'uid': userCredential.user?.uid,
          });
          print("User info saved to users collection");
        } catch (e) {
          print("Error saving user info: $e");
          // Continue even if Firestore update fails
        }
        
        return null;
      } 
      // For doctor and data_entry roles, save as a request instead
      else if (role == 'doctor' || role == 'data_entry') {
        // Check if request already exists
        final requestDoc = await _firestore.collection('requests').doc(email).get();
        if (requestDoc.exists) {
          return "A request with this email already exists";
        }
        
        // Save the request to Firestore
        try {
          await _firestore.collection('requests').doc(email).set({
            'email': email,
            'password': password, // Note: In a production app, this should be hashed
            'role': role,
            'status': 'pending',
            'timestamp': FieldValue.serverTimestamp(),
          });
          print("Signup request saved to Firestore");
          return null;
        } catch (e) {
          print("Error saving request to Firestore: $e");
          return "Failed to save request: $e";
        }
      } else {
        return "Invalid role";
      }
    } catch (e) {
      print("Error during signup: $e");
      return "Signup failed: $e";
    }
  }

  // Sign in with email, password, and role
  Future<String?> signIn(String email, String password, String role) async {
    try {
      // For admin role, proceed with normal signin
      if (role == 'admin') {
        // Verify admin role in Firestore
        try {
          final roleDoc = await _firestore.collection('user_roles').doc(email).get();
          if (!roleDoc.exists || roleDoc.data()?['role'] != 'admin') {
            return "Invalid admin credentials";
          }
        } catch (e) {
          print("Error verifying role in Firestore: $e");
          return "Error verifying credentials";
        }
        
        // Sign in with Firebase Auth
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return null;
      } 
      // For doctor and data_entry roles, check if request is approved
      else if (role == 'doctor' || role == 'data_entry') {
        // Check if request exists and is approved
        final requestDoc = await _firestore.collection('requests').doc(email).get();
        
        if (!requestDoc.exists) {
          return "No account found with this email";
        }
        
        final requestData = requestDoc.data();
        if (requestData == null) {
          return "Invalid request data";
        }
        
        if (requestData['status'] != 'approved') {
          return "Your account is pending approval";
        }
        
        if (requestData['role'] != role) {
          return "Invalid role for this account";
        }
        
        // Check if user exists in Firebase Auth
        final methods = await _auth.fetchSignInMethodsForEmail(email);
        if (methods.isEmpty) {
          // Create the user account if it doesn't exist yet
          try {
            await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
            
            // Save role to Firestore
            await _firestore.collection('user_roles').doc(email).set({
              'role': role,
              'uid': _auth.currentUser?.uid,
            });
          } catch (e) {
            // If the email is already in use, try to sign in directly
            if (e.toString().contains('email-already-in-use')) {
              print("Email already in use, attempting to sign in directly");
            } else {
              print("Error creating user account: $e");
              return "Error creating account: $e";
            }
          }
        }
        
        // Sign in with Firebase Auth
        try {
          await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          return null;
        } catch (e) {
          print("Error during signin: $e");
          if (e.toString().contains('wrong-password')) {
            return "Incorrect password";
          } else if (e.toString().contains('user-not-found')) {
            return "No account found with this email";
          } else {
            return "Signin failed: $e";
          }
        }
      } else {
        return "Invalid role";
      }
    } catch (e) {
      print("Error during signin: $e");
      return "Signin failed: $e";
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get Current User
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get User Role
  Future<String?> getUserRole(String email) async {
    try {
      DocumentSnapshot roleDoc = await _firestore.collection('user_roles').doc(email).get();
      if (roleDoc.exists) {
        return (roleDoc.data() as Map<String, dynamic>)['role'] as String;
      }
      return null;
    } catch (e) {
      print("Error getting user role: $e");
      return null;
    }
  }
}
