import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'patient_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method to check if the patient ID already exists
  Future<bool> patientExists(String patientId) async {
    try {
      if (_auth.currentUser == null) {
        throw Exception("User not logged in");  // Prevents unauthenticated access
      }

      final docSnapshot = await _db.collection('patients').doc(patientId).get();
      return docSnapshot.exists;
    } catch (e) {
      print("Error checking patient ID: $e");
      return false;
    }
  }

  // Method to add a patient
  Future<void> addPatient(Patient patient) async {
    try {
      if (_auth.currentUser == null) {
        throw Exception("User not logged in");
      }

      bool exists = await patientExists(patient.id);
      if (exists) {
        throw Exception('Patient ID already in use');
      }

      await _db.collection('patients').doc(patient.id).set(patient.toMap());

      print("Patient added: ${patient.name}");
    } catch (e) {
      print("Error adding patient: $e");
      rethrow;
    }
  }

  // **Method to update a patient**
  Future<void> updatePatient(Patient patient) async {
    try {
      if (_auth.currentUser == null) {
        throw Exception("User not logged in");
      }

      await _db.collection('patients').doc(patient.id).update(patient.toMap());

      print("Patient updated: ${patient.name}");
    } catch (e) {
      print("Error updating patient: $e");
      rethrow;
    }
  }

  // **Method to delete a patient**
  Future<void> deletePatient(String patientId) async {
    try {
      if (_auth.currentUser == null) {
        throw Exception("User not logged in");
      }

      await _db.collection('patients').doc(patientId).delete();

      print("Patient deleted: $patientId");
    } catch (e) {
      print("Error deleting patient: $e");
      rethrow;
    }
  }

  // Method to get all patients (streaming)
  Stream<List<Patient>> getPatients() {
    if (_auth.currentUser == null) {
      throw Exception("User not logged in");
    }

    return _db.collection('patients').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Patient.fromMap({
          'id': doc.id,
          ...data,
        });
      }).toList();
    });
  }
}
