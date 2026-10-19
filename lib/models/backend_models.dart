class PatientPayload {
  final int villageId;
  final String name;
  final int age;
  final String gender;
  final String? contactNumber;
  final String diagnosis;
  final String severity;
  final String? notes;

  PatientPayload({
    required this.villageId,
    required this.name,
    required this.age,
    required this.gender,
    this.contactNumber,
    required this.diagnosis,
    required this.severity,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'village_id': villageId,
        'name': name,
        'age': age,
        'gender': gender,
        'contact_number': contactNumber,
        'diagnosis': diagnosis,
        'severity': severity,
        'notes': notes,
      };

  factory PatientPayload.fromJson(Map<String, dynamic> json) => PatientPayload(
        villageId: json['village_id'] ?? 1,
        name: json['name'] ?? '',
        age: json['age'] ?? 0,
        gender: json['gender'] ?? '',
        contactNumber: json['contact_number'],
        diagnosis: json['diagnosis'] ?? '',
        severity: json['severity'] ?? 'Moderate',
        notes: json['notes'],
      );
}

class WaterQualityPayload {
  final int waterSourceId;
  final double? ph;
  final double? turbidity;
  final String? h2sTestResult;
  final String contaminationStatus;
  final String? testedBy;
  final String testedAt;

  WaterQualityPayload({
    required this.waterSourceId,
    this.ph,
    this.turbidity,
    this.h2sTestResult,
    required this.contaminationStatus,
    this.testedBy,
    required this.testedAt,
  });

  Map<String, dynamic> toJson() => {
        'water_source_id': waterSourceId,
        'ph': ph,
        'turbidity': turbidity,
        'h2s_test_result': h2sTestResult,
        'contamination_status': contaminationStatus,
        'tested_by': testedBy,
        'tested_at': testedAt,
      };

  factory WaterQualityPayload.fromJson(Map<String, dynamic> json) => WaterQualityPayload(
        waterSourceId: json['water_source_id'] ?? 1,
        ph: json['ph'] != null ? (json['ph'] as num).toDouble() : null,
        turbidity: json['turbidity'] != null ? (json['turbidity'] as num).toDouble() : null,
        h2sTestResult: json['h2s_test_result'],
        contaminationStatus: json['contamination_status'] ?? 'Safe',
        testedBy: json['tested_by'],
        testedAt: json['tested_at'] ?? DateTime.now().toIso8601String(),
      );
}

class BulkPatientBatchPayload {
  final int villageId;
  final String diagnosis;
  final String severity;
  final String? notes;
  final List<PatientBatchItem> patients;

  BulkPatientBatchPayload({
    required this.villageId,
    required this.diagnosis,
    required this.severity,
    this.notes,
    required this.patients,
  });

  Map<String, dynamic> toJson() => {
        'village_id': villageId,
        'diagnosis': diagnosis,
        'severity': severity,
        'notes': notes,
        'patients': patients.map((p) => p.toJson()).toList(),
      };
}

class PatientBatchItem {
  final String name;
  final int age;
  final String gender;
  final String? contactNumber;

  PatientBatchItem({
    required this.name,
    required this.age,
    required this.gender,
    this.contactNumber,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'gender': gender,
        'contact_number': contactNumber,
      };

  factory PatientBatchItem.fromJson(Map<String, dynamic> json) => PatientBatchItem(
        name: json['name'] ?? '',
        age: json['age'] ?? 0,
        gender: json['gender'] ?? '',
        contactNumber: json['contact_number'],
      );
}
