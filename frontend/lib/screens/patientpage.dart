import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'patient_model.dart';
import 'patient_details_page.dart'; // For navigating to the details page
import 'chat_list_screen.dart';

class PatientPage extends StatefulWidget {
  final User user;

  const PatientPage({required this.user, super.key});

  @override
  State<PatientPage> createState() => _PatientPageState();
}

class _PatientPageState extends State<PatientPage> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController searchController = TextEditingController(); // For search bar
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = ""; // To store the search query

  void _clearFields() {
    idController.clear();
    nameController.clear();
    ageController.clear();
  }

  Future<void> _addPatient() async {
    if (idController.text.trim().isEmpty || nameController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Patient ID and Name are required!")),
      );
      return;
    }

    // Check if the patient ID already exists
    final patientDoc = await _firestore.collection('patients').doc(idController.text.trim()).get();
    if (patientDoc.exists) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text("A patient with this ID already exists."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          );
        },
      );
      return;
    }

    // Add the new patient with default values for required fields
    Patient newPatient = Patient(
      id: idController.text.trim(),
      name: nameController.text.trim(),
      gender: 'M', // Default gender
      anchorAge: double.tryParse(ageController.text.trim()) ?? 0.0,
      heartRate: 70.0, // Default value
      arterialBloodPressureSystolic: 120.0, // Default value
      arterialBloodPressureDiastolic: 80.0, // Default value
      respiratoryRate: 16.0, // Default value
      spo2: 98.0, // Default value
      glucoseSerum: 100.0, // Default value
      sodium: 140.0, // Default value
      temperatureCelsius: 37.0, // Default value
      cholesterol: 200.0, // Default value
      hemoglobin: 14.0, // Default value
      imageUrls: [], // Empty list for images
    );

    await _firestore.collection('patients').doc(newPatient.id).set(newPatient.toMap());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Patient added successfully!")),
    );

    _clearFields();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1565C0), Color.fromARGB(255, 252, 166, 45)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Back Button and Chat Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat, color: Colors.white, size: 30),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChatListScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                const Text(
                  "Patient Management",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Patient ID Field
                _buildTextField(idController, 'Patient ID', Icons.person, false),
                const SizedBox(height: 16),

                // Name Field
                _buildTextField(nameController, 'Name', Icons.person_outline, false),
                const SizedBox(height: 16),

                // Age Field
                _buildTextField(ageController, 'Age (Anchor Age)', Icons.calendar_today, false),
                const SizedBox(height: 20),

                // Add Patient Button
                ElevatedButton(
                  onPressed: _addPatient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue.shade900,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                  ),
                  child: const Text('Add Patient', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 20),

                // Search Bar
                _buildTextField(searchController, 'Search by ID or Name', Icons.search, false),
                const SizedBox(height: 20),

                // List of Patients
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('patients').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator(color: Colors.white));
                      }

                      var patients = snapshot.data!.docs;

                      // Filter patients based on the search query
                      var filteredPatients = patients.where((patient) {
                        var patientData = patient.data() as Map<String, dynamic>;
                        String patientId = patientData['id'].toString().toLowerCase();
                        String patientName = patientData['name'].toString().toLowerCase();
                        return patientId.contains(_searchQuery) || patientName.contains(_searchQuery);
                      }).toList();

                      return ListView.builder(
                        itemCount: filteredPatients.length,
                        itemBuilder: (context, index) {
                          var patientData = filteredPatients[index].data() as Map<String, dynamic>;
                          String patientId = patientData['id'];

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 3,
                            child: ListTile(
                              title: Text(
                                patientData['name'],
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text("ID: ${patientData['id']}"),
                              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.blue),
                              onTap: () {
                                // Navigate to the PatientDetailsPage
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PatientDetailsPage(
                                      patientId: patientId,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // **Reusable Widgets**
  Widget _buildTextField(
      TextEditingController controller, String hintText, IconData icon, bool isPassword) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: Colors.white70),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white.withAlpha(51),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase(); // Update the search query
          });
        },
      ),
    );
  }
}