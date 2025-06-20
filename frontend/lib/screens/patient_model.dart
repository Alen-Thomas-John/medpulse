class Patient {
  final String id;
  final String name;
  final String gender; // 'F' or 'M'
  final double anchorAge;
  final double heartRate;
  final double arterialBloodPressureSystolic;
  final double arterialBloodPressureDiastolic;
  final double respiratoryRate;
  final double spo2;
  final double glucoseSerum;
  final double sodium;
  final double temperatureCelsius;
  final double cholesterol;
  final double hemoglobin;
  final List<String>? imageUrls;
  final String? lastUpdatedBy;

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
    required this.glucoseSerum,
    required this.sodium,
    required this.temperatureCelsius,
    required this.cholesterol,
    required this.hemoglobin,
    this.imageUrls,
    this.lastUpdatedBy,
  });

  // Convert a Patient object to a map (for Firestore or database storage)
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
      'glucoseSerum': glucoseSerum,
      'sodium': sodium,
      'temperatureCelsius': temperatureCelsius,
      'cholesterol': cholesterol,
      'hemoglobin': hemoglobin,
      'imageUrls': imageUrls,
      'lastUpdatedBy': lastUpdatedBy,
    };
  }

  // Add toJson() method (same as toMap())
  Map<String, dynamic> toJson() => toMap();

  // Convert a map to a Patient object (for retrieving data)
  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      name: map['name'],
      gender: map['gender'] ?? 'M',
      anchorAge: (map['anchorAge'] as num?)?.toDouble() ?? 0.0,
      heartRate: (map['heartRate'] as num?)?.toDouble() ?? 0.0,
      arterialBloodPressureSystolic: (map['arterialBloodPressureSystolic'] as num?)?.toDouble() ?? 0.0,
      arterialBloodPressureDiastolic: (map['arterialBloodPressureDiastolic'] as num?)?.toDouble() ?? 0.0,
      respiratoryRate: (map['respiratoryRate'] as num?)?.toDouble() ?? 0.0,
      spo2: (map['spo2'] as num?)?.toDouble() ?? 0.0,
      glucoseSerum: (map['glucoseSerum'] as num?)?.toDouble() ?? 0.0,
      sodium: (map['sodium'] as num?)?.toDouble() ?? 0.0,
      temperatureCelsius: (map['temperatureCelsius'] as num?)?.toDouble() ?? 0.0,
      cholesterol: (map['cholesterol'] as num?)?.toDouble() ?? 0.0,
      hemoglobin: (map['hemoglobin'] as num?)?.toDouble() ?? 0.0,
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      lastUpdatedBy: map['lastUpdatedBy'],
    );
  }

  // Add fromJson() method
  factory Patient.fromJson(Map<String, dynamic> json) => Patient.fromMap(json);
}