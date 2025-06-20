import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'patient_view.dart'; // Import the PatientView page
import 'chat_list_screen.dart';

class RiskLevel {
  final String label;
  final Color color;

  RiskLevel(this.label, this.color);
}

class DoctorPage extends StatefulWidget {
  final User user;

  const DoctorPage({Key? key, required this.user}) : super(key: key);

  @override
  _DoctorPageState createState() => _DoctorPageState();
}

class _DoctorPageState extends State<DoctorPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController searchController = TextEditingController();
  String _searchQuery = "";
  bool _isLoading = false;
  String _errorMessage = "";
  dynamic top10Diseases;
  Map<String, dynamic>? rocData;

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

  // Function to get prediction from Flask backend
  Future<void> _getPrediction(String patientId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'patient_id': patientId}),
      );

      print('Response status code: ${response.statusCode}'); // Debug print
      print('Response body: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Received prediction data: $data'); // Debug print
        
        // Update Firestore with the new prediction results
        await _firestore.collection('patients').doc(patientId).update({
          'prediction_results': data['predictions'] ?? data['top_10_diseases'],
          'roc_data': data['roc_data'],
          'prediction_timestamp': FieldValue.serverTimestamp(),
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Disease risk assessment updated successfully",
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = "Failed to get prediction: ${response.statusCode}";
        });
      }
    } catch (e) {
      print('Error in _getPrediction: $e'); // Debug print
      setState(() {
        _errorMessage = "Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                  "All Patients",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Search Bar
                _buildTextField(searchController, 'Search by ID or Name', Icons.search, false),
                const SizedBox(height: 20),

                // Error Message
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),

                // Patient List
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('patients').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      }

                      var patients = snapshot.data!.docs;

                      var filteredPatients = patients.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        String id = data['id'].toString().toLowerCase();
                        String name = data['name'].toString().toLowerCase();
                        return id.contains(_searchQuery) || name.contains(_searchQuery);
                      }).toList();

                      if (filteredPatients.isEmpty) {
                        return const Center(
                          child: Text(
                            'No patients found.',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: filteredPatients.length,
                        itemBuilder: (context, index) {
                          var patient = filteredPatients[index].data() as Map<String, dynamic>;
                          String patientId = patient['id'];
                          
                          // Get disease probabilities if available
                          List<Map<String, dynamic>>? diseaseProbabilities;
                          if (patient['prediction_results'] != null) {
                            try {
                              if (patient['prediction_results'] is Map) {
                                final Map<String, dynamic> results = Map<String, dynamic>.from(patient['prediction_results']);
                                if (results.containsKey('top_10_diseases')) {
                                  final List<dynamic> rawList = List<dynamic>.from(results['top_10_diseases']);
                                  diseaseProbabilities = rawList.map((item) {
                                    if (item is Map<String, dynamic>) {
                                      return item;
                                    }
                                    return <String, dynamic>{};
                                  }).toList();
                                }
                              } else if (patient['prediction_results'] is List) {
                                final List<dynamic> rawList = List<dynamic>.from(patient['prediction_results']);
                                diseaseProbabilities = rawList.map((item) {
                                  if (item is Map<String, dynamic>) {
                                    return item;
                                  }
                                  return <String, dynamic>{};
                                }).toList();
                              }
                            } catch (e) {
                              print('Error parsing disease probabilities: $e');
                              diseaseProbabilities = null;
                            }
                          }

                          List<Map<String, dynamic>>? top10Diseases;
                          if (patient['top_10_diseases'] != null) {
                            try {
                              final List<dynamic> rawList = List<dynamic>.from(patient['top_10_diseases']);
                              top10Diseases = rawList.map((item) {
                                if (item is Map<String, dynamic>) {
                                  return item;
                                }
                                return <String, dynamic>{};
                              }).toList();
                            } catch (e) {
                              print('Error parsing top 10 diseases: $e');
                              top10Diseases = null;
                            }
                          }

                          Map<String, dynamic>? rocData;
                          if (patient['prediction_results'] != null && 
                              patient['prediction_results'] is Map &&
                              (patient['prediction_results'] as Map).containsKey('roc_data')) {
                            try {
                              final Map<String, dynamic> results = Map<String, dynamic>.from(patient['prediction_results']);
                              rocData = Map<String, dynamic>.from(results['roc_data']);
                            } catch (e) {
                              print('Error parsing ROC data: $e');
                              rocData = null;
                            }
                          }

                          Timestamp? predictionTime = patient['prediction_timestamp'];

                          print('Patient data: $patient'); // Debug print
                          print('Disease probabilities: $diseaseProbabilities'); // Debug print
                          print('Top 10 diseases: $top10Diseases'); // Debug print
                          print('ROC data: $rocData'); // Debug print

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 3,
                            child: ExpansionTile(
                              title: Text(
                                patient['name'],
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text("ID: ${patient['id']}"),
                              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.blue),
                              children: [
                                // Prediction Section
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Disease Risk Assessment",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (diseaseProbabilities != null && diseaseProbabilities.isNotEmpty)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: diseaseProbabilities.map((disease) {
                                            final index = disease['index'] as int?;
                                            final probability = disease['probability'] as double?;
                                            if (index != null && probability != null) {
                                              return _buildDiseaseRiskItem(
                                                diseaseIndexMap[index] ?? 'Unknown Disease',
                                                probability,
                                                rocData,
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          }).toList(),
                                        )
                                      else if (top10Diseases != null && top10Diseases.isNotEmpty)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: top10Diseases.map((disease) {
                                            final index = disease['index'] as int?;
                                            final probability = disease['probability'] as double?;
                                            if (index != null && probability != null) {
                                              return _buildDiseaseRiskItem(
                                                diseaseIndexMap[index] ?? 'Unknown Disease',
                                                probability,
                                                rocData,
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          }).toList(),
                                        )
                                      else
                                        const Text(
                                          "No disease risk assessment available",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      
                                      if (predictionTime != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            "Assessed on: ${predictionTime.toDate().toString().split('.')[0]}",
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ),
                                      
                                      const SizedBox(height: 16),
                                      
                                      // Get New Prediction Button
                                      ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : () async {
                                                await _getPrediction(patientId);
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Text("Get New Assessment"),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // View Details Button
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PatientView(patientId: patientId),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.blue.shade900,
                                      minimumSize: const Size(double.infinity, 40),
                                    ),
                                    child: const Text("View Details"),
                                  ),
                                ),
                              ],
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

  // Helper function to get color based on risk level
  Color _getRiskColor(double probability) {
    if (probability < 0.3) {
      return Colors.green;
    } else if (probability < 0.7) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Helper function to get icon based on risk level
  IconData _getRiskIcon(double probability) {
    if (probability < 0.3) {
      return Icons.check_circle;
    } else if (probability < 0.7) {
      return Icons.warning;
    } else {
      return Icons.error;
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    IconData icon,
    bool isPassword,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
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
          fillColor: Colors.white.withOpacity(0.2),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  // Helper function to build ROC curve
  Widget _buildRocCurve(Map<String, dynamic> rocData, String disease) {
    List<double> fpr = List<double>.from(rocData['fpr']);
    List<double> tpr = List<double>.from(rocData['tpr']);
    double auc = rocData['auc'];
    
    return Container(
      height: 150,
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ROC Curve for $disease (AUC: ${auc.toStringAsFixed(3)})",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: CustomPaint(
              painter: RocCurvePainter(fpr: fpr, tpr: tpr),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseRiskItem(String disease, double probability, Map<String, dynamic>? rocData) {
    Color riskColor = _getRiskColor(probability);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getRiskIcon(probability),
                color: riskColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      disease,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    LinearProgressIndicator(
                      value: probability,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${(probability * 100).toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize: 12,
                        color: riskColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // ROC Curve for this disease
          if (rocData != null && rocData.containsKey(disease))
            _buildRocCurve(rocData[disease], disease),
        ],
      ),
    );
  }

  // Helper function to build disease risk items
  List<Widget> _buildDiseaseRiskItems(dynamic top10Diseases, Map<String, dynamic>? rocData) {
    List<Widget> items = [];
    
    print('Building disease risk items from: $top10Diseases'); // Debug print
    
    if (top10Diseases is List) {
      for (var disease in top10Diseases) {
        print('Processing disease: $disease'); // Debug print
        if (disease is Map) {
          final name = disease['name'] ?? 'Unknown Disease';
          final probability = disease['probability'] ?? 0.0;
          
          print('Disease name: $name, probability: $probability'); // Debug print
          
          items.add(_buildDiseaseRiskItem(
            name,
            _parseProbability(probability),
            rocData,
          ));
        } else {
          print('Invalid disease format: $disease'); // Debug print
        }
      }
    } else if (top10Diseases is Map) {
      for (var entry in top10Diseases.entries) {
        print('Processing entry: ${entry.key} -> ${entry.value}'); // Debug print
        
        if (entry.value is num) {
          items.add(_buildDiseaseRiskItem(
            entry.key,
            (entry.value as num).toDouble(),
            rocData,
          ));
        } else if (entry.value is Map) {
          final diseaseMap = entry.value as Map<String, dynamic>;
          final probability = diseaseMap['probability'] ?? 0.0;
          items.add(_buildDiseaseRiskItem(
            entry.key,
            _parseProbability(probability),
            rocData,
          ));
        } else if (entry.value is String) {
          items.add(_buildDiseaseRiskItem(
            entry.key,
            _parseProbability(entry.value),
            rocData,
          ));
        } else if (entry.value is List) {
          // Handle case where probability is in a list
          final probabilityList = entry.value as List;
          if (probabilityList.isNotEmpty) {
            final probability = probabilityList[0];
            items.add(_buildDiseaseRiskItem(
              entry.key,
              _parseProbability(probability),
              rocData,
            ));
          }
        } else {
          print('Invalid probability format for ${entry.key}: ${entry.value}');
        }
      }
    } else {
      print('Unexpected top10Diseases type: ${top10Diseases.runtimeType}'); // Debug print
    }
    
    print('Built ${items.length} disease risk items'); // Debug print
    return items;
  }

  // Helper function to parse probability value
  double _parseProbability(dynamic value) {
    print('Parsing probability value: $value (${value.runtimeType})'); // Debug print
    
    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error parsing probability string: $value');
        return 0.0;
      }
    } else if (value is List) {
      if (value.isNotEmpty) {
        if (value[0] is num) {
          return (value[0] as num).toDouble();
        } else if (value[0] is String) {
          try {
            return double.parse(value[0] as String);
          } catch (e) {
            print('Error parsing probability from list: ${value[0]}');
            return 0.0;
          }
        }
      }
      return 0.0;
    } else if (value is Map) {
      final probability = value['probability'];
      if (probability != null) {
        return _parseProbability(probability);
      }
      return 0.0;
    }
    return 0.0;
  }

  Widget _buildDiseaseList() {
    if (top10Diseases == null) {
      return Center(
        child: Text(
          'No disease predictions available',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    // Convert the dynamic list to a List<Map<String, dynamic>>
    List<Map<String, dynamic>> diseases = [];
    if (top10Diseases is List) {
      diseases = List<Map<String, dynamic>>.from(top10Diseases);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: diseases.length,
      itemBuilder: (context, index) {
        final disease = diseases[index];
        final name = disease['name'] ?? 'Unknown Disease';
        final probability = disease['probability'] ?? 0.0;
        final riskLevel = _getRiskLevel(probability);

        return Card(
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            title: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: riskLevel.color,
              ),
            ),
            subtitle: Text(
              'Risk Level: ${riskLevel.label}',
              style: TextStyle(color: riskLevel.color),
            ),
            trailing: Text(
              '${(probability * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: riskLevel.color,
              ),
            ),
          ),
        );
      },
    );
  }

  RiskLevel _getRiskLevel(double probability) {
    if (probability >= 0.7) {
      return RiskLevel('High', Colors.red);
    } else if (probability >= 0.4) {
      return RiskLevel('Medium', Colors.orange);
    } else {
      return RiskLevel('Low', Colors.green);
    }
  }
}

class RocCurvePainter extends CustomPainter {
  final List<double> fpr;
  final List<double> tpr;
  
  RocCurvePainter({required this.fpr, required this.tpr});
  
  @override
  void paint(Canvas canvas, Size size) {
    if (fpr.isEmpty || tpr.isEmpty) return;
    
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final path = Path();
    
    // Draw axes
    final axisPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // X-axis (FPR)
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      axisPaint,
    );
    
    // Y-axis (TPR)
    canvas.drawLine(
      Offset(0, 0),
      Offset(0, size.height),
      axisPaint,
    );
    
    // Draw ROC curve
    for (int i = 0; i < fpr.length; i++) {
      final x = fpr[i] * size.width;
      final y = (1 - tpr[i]) * size.height; // Invert Y axis
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
    
    // Draw diagonal reference line
    final diagonalPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, 0),
      diagonalPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
