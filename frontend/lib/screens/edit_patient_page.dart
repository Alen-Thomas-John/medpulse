import 'package:flutter/material.dart';
import 'firestore_service.dart';
import 'patient_model.dart';
import 'package:cardiovascular_web/widgets/custom_text_field.dart';

class EditPatientPage extends StatefulWidget {
  final Patient patient;

  const EditPatientPage({super.key, required this.patient});

  @override
  State<EditPatientPage> createState() => _EditPatientPageState();
}

class _EditPatientPageState extends State<EditPatientPage> {
  final FirestoreService firestoreService = FirestoreService();
  
  // Controllers for text fields
  late TextEditingController nameController;
  late TextEditingController anchorAgeController;
  late TextEditingController heartRateController;
  late TextEditingController arterialBloodPressureSystolicController;
  late TextEditingController arterialBloodPressureDiastolicController;
  late TextEditingController respiratoryRateController;
  late TextEditingController spo2Controller;
  late TextEditingController glucoseSerumController;
  late TextEditingController sodiumController;
  late TextEditingController temperatureCelsiusController;
  late TextEditingController cholesterolController;
  late TextEditingController hemoglobinController;
  
  // Gender selection
  late String selectedGender;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current patient data
    nameController = TextEditingController(text: widget.patient.name);
    anchorAgeController = TextEditingController(text: widget.patient.anchorAge.toString());
    heartRateController = TextEditingController(text: widget.patient.heartRate.toString());
    arterialBloodPressureSystolicController = TextEditingController(text: widget.patient.arterialBloodPressureSystolic.toString());
    arterialBloodPressureDiastolicController = TextEditingController(text: widget.patient.arterialBloodPressureDiastolic.toString());
    respiratoryRateController = TextEditingController(text: widget.patient.respiratoryRate.toString());
    spo2Controller = TextEditingController(text: widget.patient.spo2.toString());
    glucoseSerumController = TextEditingController(text: widget.patient.glucoseSerum.toString());
    sodiumController = TextEditingController(text: widget.patient.sodium.toString());
    temperatureCelsiusController = TextEditingController(text: widget.patient.temperatureCelsius.toString());
    cholesterolController = TextEditingController(text: widget.patient.cholesterol.toString());
    hemoglobinController = TextEditingController(text: widget.patient.hemoglobin.toString());
    
    selectedGender = widget.patient.gender;
  }

  @override
  void dispose() {
    nameController.dispose();
    anchorAgeController.dispose();
    heartRateController.dispose();
    arterialBloodPressureSystolicController.dispose();
    arterialBloodPressureDiastolicController.dispose();
    respiratoryRateController.dispose();
    spo2Controller.dispose();
    glucoseSerumController.dispose();
    sodiumController.dispose();
    temperatureCelsiusController.dispose();
    cholesterolController.dispose();
    hemoglobinController.dispose();
    super.dispose();
  }

  void _updatePatient() async {
    try {
      // Create updated patient with all required fields
      final updatedPatient = Patient(
        id: widget.patient.id,
        name: nameController.text.trim(),
        gender: selectedGender,
        anchorAge: double.parse(anchorAgeController.text.trim()),
        heartRate: double.parse(heartRateController.text.trim()),
        arterialBloodPressureSystolic: double.parse(arterialBloodPressureSystolicController.text.trim()),
        arterialBloodPressureDiastolic: double.parse(arterialBloodPressureDiastolicController.text.trim()),
        respiratoryRate: double.parse(respiratoryRateController.text.trim()),
        spo2: double.parse(spo2Controller.text.trim()),
        glucoseSerum: double.parse(glucoseSerumController.text.trim()),
        sodium: double.parse(sodiumController.text.trim()),
        temperatureCelsius: double.parse(temperatureCelsiusController.text.trim()),
        cholesterol: double.parse(cholesterolController.text.trim()),
        hemoglobin: double.parse(hemoglobinController.text.trim()),
        imageUrls: widget.patient.imageUrls,
      );

      await firestoreService.updatePatient(updatedPatient);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient updated successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _deletePatient() async {
    try {
      await firestoreService.deletePatient(widget.patient.id);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient deleted successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Patient"),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade500,
              Colors.orange.shade400,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Edit Patient Information",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Name
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CustomTextField(
                      controller: nameController,
                      label: 'Name',
                      icon: Icons.person,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Gender
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedGender,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'M', child: Text('Male')),
                        DropdownMenuItem(value: 'F', child: Text('Female')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedGender = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Age
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CustomTextField(
                      controller: anchorAgeController,
                      label: 'Age (Anchor Age)',
                      icon: Icons.cake,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Heart Rate
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CustomTextField(
                      controller: heartRateController,
                      label: 'Heart Rate (bpm)',
                      icon: Icons.favorite,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Blood Pressure
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: CustomTextField(
                            controller: arterialBloodPressureSystolicController,
                            label: 'Systolic (mmHg)',
                            icon: Icons.speed,
                            isNumber: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: CustomTextField(
                            controller: arterialBloodPressureDiastolicController,
                            label: 'Diastolic (mmHg)',
                            icon: Icons.speed,
                            isNumber: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Respiratory Rate
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CustomTextField(
                      controller: respiratoryRateController,
                      label: 'Respiratory Rate (breaths/min)',
                      icon: Icons.air,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // SpO2
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CustomTextField(
                      controller: spo2Controller,
                      label: 'SpO2 (%)',
                      icon: Icons.bloodtype,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Glucose
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CustomTextField(
                      controller: glucoseSerumController,
                      label: 'Glucose (serum) (mg/dL)',
                      icon: Icons.water_drop,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Sodium
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CustomTextField(
                      controller: sodiumController,
                      label: 'Sodium (mEq/L)',
                      icon: Icons.science,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Temperature
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CustomTextField(
                      controller: temperatureCelsiusController,
                      label: 'Temperature (°C)',
                      icon: Icons.thermostat,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Cholesterol
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CustomTextField(
                      controller: cholesterolController,
                      label: 'Cholesterol (mg/dL)',
                      icon: Icons.bloodtype,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Hemoglobin
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CustomTextField(
                      controller: hemoglobinController,
                      label: 'Hemoglobin (g/dL)',
                      icon: Icons.bloodtype,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _updatePatient,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Update",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _deletePatient,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Delete",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
