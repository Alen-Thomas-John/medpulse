import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart'; // For SHA-256 hashing
import 'patient_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientDetailsPage extends StatefulWidget {
  final String patientId;

  const PatientDetailsPage({required this.patientId, Key? key}) : super(key: key);

  @override
  _PatientDetailsPageState createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController anchorAgeController = TextEditingController();
  final TextEditingController heartRateController = TextEditingController();
  final TextEditingController arterialBloodPressureSystolicController = TextEditingController();
  final TextEditingController arterialBloodPressureDiastolicController = TextEditingController();
  final TextEditingController respiratoryRateController = TextEditingController();
  final TextEditingController spo2Controller = TextEditingController();
  final TextEditingController glucoseSerumController = TextEditingController();
  final TextEditingController sodiumController = TextEditingController();
  final TextEditingController temperatureCelsiusController = TextEditingController();
  final TextEditingController cholesterolController = TextEditingController();
  final TextEditingController hemoglobinController = TextEditingController();

  // Gender selection
  String _selectedGender = 'M';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _imageUrls = []; // For images fetched from Firestore
  List<Uint8List> _pickedImages = []; // For newly uploaded images
  List<String> _imageNames = []; // For names of newly uploaded images

  @override
  void initState() {
    super.initState();
    _loadPatientDetails();
  }

  Future<void> _loadPatientDetails() async {
    final patientDoc = await _firestore.collection('patients').doc(widget.patientId).get();
    if (patientDoc.exists) {
      Map<String, dynamic> patient = patientDoc.data() as Map<String, dynamic>;

      setState(() {
        idController.text = patient['id'] ?? '';
        nameController.text = patient['name'] ?? '';
        _selectedGender = patient['gender'] ?? 'M';
        anchorAgeController.text = patient['anchorAge']?.toString() ?? '';
        heartRateController.text = patient['heartRate']?.toString() ?? '';
        arterialBloodPressureSystolicController.text = patient['arterialBloodPressureSystolic']?.toString() ?? '';
        arterialBloodPressureDiastolicController.text = patient['arterialBloodPressureDiastolic']?.toString() ?? '';
        respiratoryRateController.text = patient['respiratoryRate']?.toString() ?? '';
        spo2Controller.text = patient['spo2']?.toString() ?? '';
        glucoseSerumController.text = patient['glucoseSerum']?.toString() ?? '';
        sodiumController.text = patient['sodium']?.toString() ?? '';
        temperatureCelsiusController.text = patient['temperatureCelsius']?.toString() ?? '';
        cholesterolController.text = patient['cholesterol']?.toString() ?? '';
        hemoglobinController.text = patient['hemoglobin']?.toString() ?? '';

        // Fetch multiple image URLs
        _imageUrls = List<String>.from(patient['imageUrls'] ?? []);
      });
    } else {
      print("Patient document does not exist");
    }
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _pickedImages.add(result.files.single.bytes!);
        _imageNames.add(result.files.single.name);
      });
    } else {
      print("No image selected");
    }
  }

  Future<void> _uploadImageToCloudinary(Uint8List imageBytes, String imageName) async {
    const String cloudinaryUrl = "https://api.cloudinary.com/v1_1/dradg3yen/image/upload";
    const String uploadPreset = "medpulse";

    try {
      var request = http.MultipartRequest("POST", Uri.parse(cloudinaryUrl))
        ..fields['upload_preset'] = uploadPreset
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: imageName,
        ));

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseData);
        String imageUrl = jsonResponse["secure_url"];

        setState(() {
          _imageUrls.add(imageUrl); // Add the new image URL to the list
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Image uploaded successfully!")),
        );
      } else {
        print("Failed to upload image: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image!")),
      );
    }
  }

  Future<void> _deleteImageFromCloudinary(String imageUrl) async {
    // Find the public_id from the image URL (if needed)
    // For simplicity, assume the imageUrl contains the public_id
    String publicId = imageUrl.split('/').last.split('.').first;

    const String cloudinaryUrl = "https://api.cloudinary.com/v1_1/dradg3yen/image/destroy";
    const String apiKey = "771362683939584"; // Replace with your Cloudinary API key
    const String apiSecret = "HRAQkLeOYmw1jM7-sGyvvkRlNY8"; // Replace with your Cloudinary API secret

    // Generate a timestamp
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    // Generate the signature
    String signatureString = "public_id=$publicId&timestamp=$timestamp$apiSecret";
    var bytes = utf8.encode(signatureString);
    var digest = sha256.convert(bytes);
    String signature = digest.toString();

    try {
      var response = await http.post(
        Uri.parse(cloudinaryUrl),
        body: {
          'public_id': publicId,
          'api_key': apiKey,
          'timestamp': timestamp,
          'signature': signature,
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _imageUrls.remove(imageUrl); // Remove the image from the list
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Image deleted successfully!")),
        );
      } else {
        print("Failed to delete image: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Error deleting image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete image!")),
      );
    }
  }

  void _removePickedImage(int index) {
    setState(() {
      _pickedImages.removeAt(index);
      _imageNames.removeAt(index);
    });
  }

  Future<void> _savePatient() async {
    // Upload any new images first
    for (int i = 0; i < _pickedImages.length; i++) {
      await _uploadImageToCloudinary(_pickedImages[i], _imageNames[i]);
    }

    // Get current user's email
    final currentUser = FirebaseAuth.instance.currentUser;
    final userEmail = currentUser?.email ?? 'Unknown User';

    // Create updated patient object
    final updatedPatient = Patient(
      id: idController.text.trim(),
      name: nameController.text.trim(),
      gender: _selectedGender,
      anchorAge: double.tryParse(anchorAgeController.text.trim()) ?? 0.0,
      heartRate: double.tryParse(heartRateController.text.trim()) ?? 0.0,
      arterialBloodPressureSystolic: double.tryParse(arterialBloodPressureSystolicController.text.trim()) ?? 0.0,
      arterialBloodPressureDiastolic: double.tryParse(arterialBloodPressureDiastolicController.text.trim()) ?? 0.0,
      respiratoryRate: double.tryParse(respiratoryRateController.text.trim()) ?? 0.0,
      spo2: double.tryParse(spo2Controller.text.trim()) ?? 0.0,
      glucoseSerum: double.tryParse(glucoseSerumController.text.trim()) ?? 0.0,
      sodium: double.tryParse(sodiumController.text.trim()) ?? 0.0,
      temperatureCelsius: double.tryParse(temperatureCelsiusController.text.trim()) ?? 0.0,
      cholesterol: double.tryParse(cholesterolController.text.trim()) ?? 0.0,
      hemoglobin: double.tryParse(hemoglobinController.text.trim()) ?? 0.0,
      imageUrls: _imageUrls,
      lastUpdatedBy: userEmail,
    );

    await _firestore.collection('patients').doc(updatedPatient.id).set(updatedPatient.toJson());

    // Clear the picked images and their names after saving
    setState(() {
      _pickedImages.clear();
      _imageNames.clear();
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Patient updated successfully!")),
    );

    // Navigate back to the previous page
    Navigator.pop(context);
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                const Text(
                  "Patient Details",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // First Row: Basic Information and Lab Results
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Information Card
                    Expanded(
                      child: _buildSectionCard(
                        "Basic Information",
                        Column(
                          children: [
                            // Patient ID Field
                            _buildTextField(idController, 'Patient ID', Icons.person, false, isReadOnly: true),
                            const SizedBox(height: 16),

                            // Name Field
                            _buildTextField(nameController, 'Name', Icons.person_outline, false),
                            const SizedBox(height: 16),

                            // Gender Selection
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Gender:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedGender,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(Icons.person, color: Colors.white70),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(30),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.2),
                                    ),
                                    dropdownColor: Colors.blue.shade900,
                                    style: const TextStyle(color: Colors.white),
                                    items: const [
                                      DropdownMenuItem(value: 'M', child: Text('Male')),
                                      DropdownMenuItem(value: 'F', child: Text('Female')),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedGender = value;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Anchor Age Field
                            _buildTextField(anchorAgeController, 'Anchor Age', Icons.calendar_today, false),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Lab Results Card
                    Expanded(
                      child: _buildSectionCard(
                        "Lab Results",
                        Column(
                          children: [
                            // Glucose Serum Field
                            _buildTextField(glucoseSerumController, 'Glucose Serum', Icons.bloodtype, false),
                            const SizedBox(height: 16),

                            // Sodium Field
                            _buildTextField(sodiumController, 'Sodium', Icons.science, false),
                            const SizedBox(height: 16),

                            // Cholesterol Field
                            _buildTextField(cholesterolController, 'Cholesterol', Icons.health_and_safety, false),
                            const SizedBox(height: 16),

                            // Hemoglobin Field
                            _buildTextField(hemoglobinController, 'Hemoglobin', Icons.medical_services, false),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Second Row: Vital Signs
                _buildSectionCard(
                  "Vital Signs",
                  Column(
                    children: [
                      // Heart Rate Field
                      _buildTextField(heartRateController, 'Heart Rate', Icons.favorite, false),
                      const SizedBox(height: 16),

                      // Blood Pressure Fields
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              arterialBloodPressureSystolicController, 
                              'Systolic BP', 
                              Icons.monitor_heart, 
                              false
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTextField(
                              arterialBloodPressureDiastolicController, 
                              'Diastolic BP', 
                              Icons.monitor_heart, 
                              false
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Respiratory Rate Field
                      _buildTextField(respiratoryRateController, 'Respiratory Rate', Icons.airline_seat_recline_normal, false),
                      const SizedBox(height: 16),

                      // SpO2 Field
                      _buildTextField(spo2Controller, 'SpO2', Icons.air, false),
                      const SizedBox(height: 16),

                      // Temperature Field
                      _buildTextField(temperatureCelsiusController, 'Temperature (°C)', Icons.thermostat, false),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Images Card
                _buildSectionCard(
                  "Patient Images",
                  Column(
                    children: [
                      // Display fetched images (already in the database)
                      if (_imageUrls.isEmpty && _pickedImages.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              "No images available",
                              style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: _imageUrls.length + _pickedImages.length,
                          itemBuilder: (context, index) {
                            if (index < _imageUrls.length) {
                              // Display fetched images
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      _imageUrls[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 5,
                                    right: 5,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                                        onPressed: () => _deleteImageFromCloudinary(_imageUrls[index]),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              // Display newly picked images
                              final pickedIndex = index - _imageUrls.length;
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      _pickedImages[pickedIndex],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 5,
                                    right: 5,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                                        onPressed: () => _removePickedImage(pickedIndex),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      const SizedBox(height: 16),

                      // Pick Image Button
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Add Images'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue.shade900,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Doctor's Conclusion Section
                StreamBuilder<DocumentSnapshot>(
                  stream: _firestore.collection('patients').doc(widget.patientId).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    final conclusion = data?['doctorConclusion'] as String?;
                    final lastUpdatedBy = data?['conclusionLastUpdatedBy'] as String?;
                    final lastUpdatedAt = data?['conclusionLastUpdatedAt'] as Timestamp?;

                    return _buildSectionCard(
                      "Doctor's Conclusion",
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (conclusion != null) ...[
                            Text(
                              conclusion,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (lastUpdatedBy != null && lastUpdatedAt != null)
                              Text(
                                'Last updated by $lastUpdatedBy on ${lastUpdatedAt.toDate().toString().split('.')[0]}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ] else
                            const Text(
                              'No conclusion available yet.',
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Save Changes Button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _savePatient,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade900,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // **Reusable Widgets**
  Widget _buildTextField(
      TextEditingController controller, String hintText, IconData icon, bool isPassword, {bool isReadOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$hintText:',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            readOnly: isReadOnly,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.white70),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.2),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(String title, Widget content) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.blue.shade900.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Divider(color: Colors.white30),
            const SizedBox(height: 8),
            content,
          ],
        ),
      ),
    );
  }
}