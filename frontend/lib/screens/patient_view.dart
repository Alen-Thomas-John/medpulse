import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chat_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientView extends StatefulWidget {
  final String patientId;

  const PatientView({Key? key, required this.patientId}) : super(key: key);

  @override
  State<PatientView> createState() => _PatientViewState();
}

class _PatientViewState extends State<PatientView> {
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Patient? _patient;
  String? _error;
  dynamic top10Diseases;
  Map<String, dynamic>? rocData;
  final TextEditingController _conclusionController = TextEditingController();
  bool _isSubmitting = false;

  // Disease index mapping
  final Map<int, String> diseaseIndexMap = {
    0: "Orthostatic hypotension",
    1: "Hypotension, unspecified",
    2: "Other acute and subacute forms of ischemic heart disease, other",
    3: "Tachycardia, unspecified",
    4: "Chronic total occlusion of coronary artery",
    5: "Acute diastolic heart failure",
    6: "Other iatrogenic hypotension",
    7: "Family history of ischemic heart disease",
    8: "Acute systolic heart failure",
    9: "Acute venous embolism and thrombosis of deep vessels of proximal lower extremity"
  };

  @override
  void initState() {
    super.initState();
    _loadPatientData();
    _loadPredictionData();
  }

  @override
  void dispose() {
    _conclusionController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    try {
      final doc = await _firestore.collection('patients').doc(widget.patientId).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _patient = Patient.fromMap(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Patient not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading patient data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPredictionData() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'patient_id': widget.patientId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Received prediction data: $data'); // Debug print
        
        // Check if the response contains the predictions data
        if (data.containsKey('predictions')) {
          setState(() {
            top10Diseases = data['predictions'];
            rocData = Map<String, dynamic>.from(data['roc_data'] ?? {});
          });
          print('Updated state with predictions: $top10Diseases'); // Debug print
        } else if (data.containsKey('top_10_diseases')) {
          setState(() {
            top10Diseases = data['top_10_diseases'];
            rocData = Map<String, dynamic>.from(data['roc_data'] ?? {});
          });
          print('Updated state with top_10_diseases: $top10Diseases'); // Debug print
        } else {
          print('Response does not contain predictions or top_10_diseases: $data');
        }
      } else {
        print('Error loading prediction data: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error loading prediction data: $e');
    }
  }

  Future<void> _submitConclusion() async {
    if (_conclusionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a conclusion before submitting')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userEmail = user?.email ?? 'Unknown';

      await _firestore.collection('patients').doc(widget.patientId).update({
        'doctorConclusion': _conclusionController.text.trim(),
        'conclusionLastUpdatedBy': userEmail,
        'conclusionLastUpdatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conclusion submitted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting conclusion: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Details'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : Container(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Patient Information",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Basic Information
                            _buildInfoCard(
                              title: 'Basic Information',
                              children: [
                                _buildInfoRow('ID', _patient!.id),
                                _buildInfoRow('Name', _patient!.name),
                                _buildInfoRow('Gender', _patient!.gender == 'M' ? 'Male' : 'Female'),
                                _buildInfoRow('Age', _patient!.anchorAge.toString()),
                                if (_patient!.lastUpdatedBy != null)
                                  _buildInfoRow('Last Updated By', _patient!.lastUpdatedBy!),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Vital Signs
                            _buildInfoCard(
                              title: 'Vital Signs',
                              children: [
                                _buildInfoRow('Heart Rate', '${_patient!.heartRate} bpm'),
                                _buildInfoRow('Arterial Blood Pressure', '${_patient!.arterialBloodPressureSystolic}/${_patient!.arterialBloodPressureDiastolic} mmHg'),
                                _buildInfoRow('Respiratory Rate', '${_patient!.respiratoryRate} breaths/min'),
                                _buildInfoRow('SpO2', '${_patient!.spo2}%'),
                                _buildInfoRow('Temperature', '${_patient!.temperatureCelsius}°C'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Lab Results
                            _buildInfoCard(
                              title: 'Lab Results',
                              children: [
                                _buildInfoRow('Glucose (serum)', '${_patient!.glucoseSerum} mg/dL'),
                                _buildInfoRow('Sodium', '${_patient!.sodium} mEq/L'),
                                _buildInfoRow('Cholesterol', '${_patient!.cholesterol} mg/dL'),
                                _buildInfoRow('Hemoglobin', '${_patient!.hemoglobin} g/dL'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Disease Risk Assessment
                            _buildInfoCard(
                              title: 'Disease Risk Assessment',
                              children: [
                                const Text(
                                  "Disease Risk Assessment",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_patient?.imageUrls?.isNotEmpty ?? false) ...[
                                  Text(
                                    'Medical Images',
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                  SizedBox(height: 16),
                                  Container(
                                    height: 200,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _patient?.imageUrls?.length ?? 0,
                                      itemBuilder: (context, index) {
                                        final imageUrl = _patient?.imageUrls?[index];
                                        if (imageUrl == null) return SizedBox.shrink();
                                        return Padding(
                                          padding: EdgeInsets.only(right: 8.0),
                                          child: Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                                SizedBox(height: 24),
                                Text(
                                  'Disease Risk Assessment',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                SizedBox(height: 16),
                                if (top10Diseases != null) ...[
                                  if (top10Diseases is List && top10Diseases.isNotEmpty)
                                    ..._buildDiseaseRiskItems(top10Diseases, rocData)
                                  else if (top10Diseases is Map && top10Diseases.isNotEmpty)
                                    ..._buildDiseaseRiskItems(top10Diseases, rocData)
                                  else
                                    const Text(
                                      'No disease risk assessment available',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ] else
                                  const Text(
                                    'No disease risk assessment available',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Doctor's Conclusion
                            _buildInfoCard(
                              title: 'Doctor\'s Conclusion',
                              children: [
                                if (_patient?.doctorConclusion != null) ...[
                                  Text(
                                    _patient!.doctorConclusion!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Last updated by: ${_patient!.conclusionLastUpdatedBy ?? 'Unknown'}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                ],
                                TextField(
                                  controller: _conclusionController,
                                  maxLines: 5,
                                  decoration: InputDecoration(
                                    hintText: 'Enter your conclusion about the patient\'s condition...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _isSubmitting ? null : _submitConclusion,
                                      icon: _isSubmitting 
                                        ? const SizedBox(
                                            width: 20, 
                                            height: 20, 
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.save),
                                      label: Text(_isSubmitting ? 'Submitting...' : 'Submit Conclusion'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade700,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ],
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

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          if (label == 'Last Updated By')
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chat, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(otherUserEmail: value),
                      ),
                    );
                  },
                ),
              ],
            )
          else
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRiskRow(String disease, double risk) {
    final color = _getRiskColor(risk);
    final icon = _getRiskIcon(risk);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            disease,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                '${(risk * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(double risk) {
    if (risk >= 0.7) return Colors.red;
    if (risk >= 0.4) return Colors.orange;
    return Colors.green;
  }

  IconData _getRiskIcon(double risk) {
    if (risk >= 0.7) return Icons.warning;
    if (risk >= 0.4) return Icons.info;
    return Icons.check_circle;
  }

  Widget _buildDiseaseRiskItem(String diseaseName, double probability, Map<String, dynamic>? rocData) {
    final riskColor = probability > 0.7
        ? Colors.red
        : probability > 0.4
            ? Colors.orange
            : Colors.green;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            diseaseName,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: probability,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(riskColor),
          ),
          const SizedBox(height: 4),
          Text(
            'Probability: ${(probability * 100).toStringAsFixed(1)}%',
            style: TextStyle(color: riskColor),
          ),
          if (rocData != null && rocData[diseaseName] != null) ...[
            const SizedBox(height: 4),
            Text(
              'ROC AUC: ${rocData[diseaseName].toStringAsFixed(3)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // Helper function to build disease risk items
  List<Widget> _buildDiseaseRiskItems(dynamic top10Diseases, Map<String, dynamic>? rocData) {
    List<Map<String, dynamic>> sortedDiseases = [];
    
    print('Building disease risk items from: $top10Diseases'); // Debug print
    
    if (top10Diseases is List) {
      for (var disease in top10Diseases) {
        print('Processing disease: $disease'); // Debug print
        if (disease is Map && disease.containsKey('index') && disease.containsKey('probability')) {
          final index = disease['index'];
          final probability = disease['probability'];
          
          print('Disease index: $index, probability: $probability'); // Debug print
          
          if (diseaseIndexMap.containsKey(index)) {
            sortedDiseases.add({
              'name': diseaseIndexMap[index]!,
              'probability': (probability as num).toDouble(),
            });
          } else {
            print('No mapping found for disease index: $index'); // Debug print
          }
        } else {
          print('Invalid disease format: $disease'); // Debug print
        }
      }
    } else if (top10Diseases is Map) {
      for (var entry in top10Diseases.entries) {
        if (diseaseIndexMap.containsKey(int.parse(entry.key))) {
          sortedDiseases.add({
            'name': diseaseIndexMap[int.parse(entry.key)]!,
            'probability': (entry.value as num).toDouble(),
          });
        }
      }
    } else {
      print('Unexpected top10Diseases type: ${top10Diseases.runtimeType}'); // Debug print
    }
    
    // Sort diseases by probability in descending order
    sortedDiseases.sort((a, b) => b['probability'].compareTo(a['probability']));
    
    List<Widget> items = [];
    
    // Add the highest probability disease with special highlighting
    if (sortedDiseases.isNotEmpty) {
      final highestProbability = sortedDiseases[0];
      items.add(
        Card(
          elevation: 8,
          color: Colors.blue.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.blue.shade300, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, 
                      color: Colors.blue.shade700,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Highest Risk Prediction',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDiseaseRiskItem(
                  highestProbability['name'],
                  highestProbability['probability'],
                  rocData,
                ),
              ],
            ),
          ),
        ),
      );
      
      // Add the rest of the diseases
      for (var i = 1; i < sortedDiseases.length; i++) {
        items.add(_buildDiseaseRiskItem(
          sortedDiseases[i]['name'],
          sortedDiseases[i]['probability'],
          rocData,
        ));
      }

      // Add bar graph visualization
      items.add(
        Card(
          elevation: 4,
          margin: const EdgeInsets.only(top: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Disease Probability Comparison',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 1,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${sortedDiseases[groupIndex]['name']}\n${(rod.toY * 100).toStringAsFixed(1)}%',
                              const TextStyle(color: Colors.white),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  (value.toInt() + 1).toString(),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${(value * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            },
                            reservedSize: 40,
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        horizontalInterval: 0.1,
                        drawVerticalLine: false,
                      ),
                      barGroups: List.generate(
                        sortedDiseases.length,
                        (index) => BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: sortedDiseases[index]['probability'],
                              color: index == 0 
                                ? Colors.red 
                                : index == 1 
                                  ? Colors.orange 
                                  : Colors.blue.withOpacity(0.7),
                              width: 16,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap on bars to see disease names and exact probabilities',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    print('Built ${items.length} disease risk items'); // Debug print
    return items;
  }
} 