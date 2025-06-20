import 'dart:convert';

class Patient {
  final String id;
  final String name;
  final String gender;
  final double anchorAge;
  final double heartRate;
  final double arterialBloodPressureSystolic;
  final double arterialBloodPressureDiastolic;
  final double respiratoryRate;
  final double spo2;
  final double temperatureCelsius;
  final double glucoseSerum;
  final double sodium;
  final double cholesterol;
  final double hemoglobin;
  final List<String>? imageUrls;
  final String? lastUpdatedBy;
  final String? doctorConclusion;
  final String? conclusionLastUpdatedBy;
  final DateTime? conclusionLastUpdatedAt;

  Patient({
    required this.id,
    required this.name,
    required this.gender,
    required this.anchorAge,
    required this.heartRate,
    required this.arterialBloodPressureSystolic,
    required this.arterialBloodPressureDiastolic,
    required this.respiratoryRate,
    required this.spo2,
    required this.temperatureCelsius,
    required this.glucoseSerum,
    required this.sodium,
    required this.cholesterol,
    required this.hemoglobin,
    this.imageUrls,
    this.lastUpdatedBy,
    this.doctorConclusion,
    this.conclusionLastUpdatedBy,
    this.conclusionLastUpdatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'anchorAge': anchorAge,
      'heartRate': heartRate,
      'arterialBloodPressureSystolic': arterialBloodPressureSystolic,
      'arterialBloodPressureDiastolic': arterialBloodPressureDiastolic,
      'respiratoryRate': respiratoryRate,
      'spo2': spo2,
      'temperatureCelsius': temperatureCelsius,
      'glucoseSerum': glucoseSerum,
      'sodium': sodium,
      'cholesterol': cholesterol,
      'hemoglobin': hemoglobin,
      'imageUrls': imageUrls,
      'lastUpdatedBy': lastUpdatedBy,
      'doctorConclusion': doctorConclusion,
      'conclusionLastUpdatedBy': conclusionLastUpdatedBy,
      'conclusionLastUpdatedAt': conclusionLastUpdatedAt,
    };
  }

  String toJson() => json.encode(toMap());

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      gender: map['gender'] ?? '',
      anchorAge: (map['anchorAge'] ?? 0.0).toDouble(),
      heartRate: (map['heartRate'] ?? 0.0).toDouble(),
      arterialBloodPressureSystolic: (map['arterialBloodPressureSystolic'] ?? 0.0).toDouble(),
      arterialBloodPressureDiastolic: (map['arterialBloodPressureDiastolic'] ?? 0.0).toDouble(),
      respiratoryRate: (map['respiratoryRate'] ?? 0.0).toDouble(),
      spo2: (map['spo2'] ?? 0.0).toDouble(),
      temperatureCelsius: (map['temperatureCelsius'] ?? 0.0).toDouble(),
      glucoseSerum: (map['glucoseSerum'] ?? 0.0).toDouble(),
      sodium: (map['sodium'] ?? 0.0).toDouble(),
      cholesterol: (map['cholesterol'] ?? 0.0).toDouble(),
      hemoglobin: (map['hemoglobin'] ?? 0.0).toDouble(),
      imageUrls: map['imageUrls'] != null ? List<String>.from(map['imageUrls']) : null,
      lastUpdatedBy: map['lastUpdatedBy'],
      doctorConclusion: map['doctorConclusion'],
      conclusionLastUpdatedBy: map['conclusionLastUpdatedBy'],
      conclusionLastUpdatedAt: map['conclusionLastUpdatedAt']?.toDate(),
    );
  }

  factory Patient.fromJson(String source) => Patient.fromMap(json.decode(source));
} 