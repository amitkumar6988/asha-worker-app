class PatientReport {
  final String id;
  final String patientName;
  final int age;
  final String gender;
  final String contactNumber;
  final String village;
  final String symptoms;
  final String diseaseDiagnosis;
  final String timestamp;
  bool isSynced;

  PatientReport({
    required this.id,
    required this.patientName,
    required this.age,
    required this.gender,
    required this.contactNumber,
    required this.village,
    required this.symptoms,
    required this.diseaseDiagnosis,
    required this.timestamp,
    this.isSynced = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientName': patientName,
        'age': age,
        'gender': gender,
        'contactNumber': contactNumber,
        'village': village,
        'symptoms': symptoms,
        'diseaseDiagnosis': diseaseDiagnosis,
        'timestamp': timestamp,
        'isSynced': isSynced,
      };

  factory PatientReport.fromJson(Map<String, dynamic> json) => PatientReport(
        id: json['id'] ?? '',
        patientName: json['patientName'] ?? '',
        age: json['age'] ?? 0,
        gender: json['gender'] ?? '',
        contactNumber: json['contactNumber'] ?? '',
        village: json['village'] ?? '',
        symptoms: json['symptoms'] ?? '',
        diseaseDiagnosis: json['diseaseDiagnosis'] ?? '',
        timestamp: json['timestamp'] ?? '',
        isSynced: json['isSynced'] ?? false,
      );
}

class WaterSampleReport {
  final String id;
  final String sourceId;
  final String sourceType; // e.g., Tube Well, Open Well, River Stream, Tap Water
  final String turbidity; // Clear, Moderate, High
  final String phLevel;
  final String color;
  final String odor;
  final String village;
  final String gpsCoordinates;
  final String timestamp;
  bool isSynced;

  WaterSampleReport({
    required this.id,
    required this.sourceId,
    required this.sourceType,
    required this.turbidity,
    required this.phLevel,
    required this.color,
    required this.odor,
    required this.village,
    required this.gpsCoordinates,
    required this.timestamp,
    this.isSynced = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceId': sourceId,
        'sourceType': sourceType,
        'turbidity': turbidity,
        'phLevel': phLevel,
        'color': color,
        'odor': odor,
        'village': village,
        'gpsCoordinates': gpsCoordinates,
        'timestamp': timestamp,
        'isSynced': isSynced,
      };

  factory WaterSampleReport.fromJson(Map<String, dynamic> json) => WaterSampleReport(
        id: json['id'] ?? '',
        sourceId: json['sourceId'] ?? '',
        sourceType: json['sourceType'] ?? '',
        turbidity: json['turbidity'] ?? '',
        phLevel: json['phLevel'] ?? '',
        color: json['color'] ?? '',
        odor: json['odor'] ?? '',
        village: json['village'] ?? '',
        gpsCoordinates: json['gpsCoordinates'] ?? '',
        timestamp: json['timestamp'] ?? '',
        isSynced: json['isSynced'] ?? false,
      );
}

class BulkPatientItem {
  final String patientName;
  final int age;
  final String gender;
  final String contactNumber;

  BulkPatientItem({
    required this.patientName,
    required this.age,
    required this.gender,
    required this.contactNumber,
  });

  Map<String, dynamic> toJson() => {
        'patientName': patientName,
        'age': age,
        'gender': gender,
        'contactNumber': contactNumber,
      };

  factory BulkPatientItem.fromJson(Map<String, dynamic> json) => BulkPatientItem(
        patientName: json['patientName'] ?? '',
        age: json['age'] ?? 0,
        gender: json['gender'] ?? '',
        contactNumber: json['contactNumber'] ?? '',
      );
}

class BulkPatientReport {
  final String id;
  final String village;
  final String sharedSymptoms;
  final String sharedDisease;
  final List<BulkPatientItem> patients;
  final String timestamp;
  bool isSynced;

  BulkPatientReport({
    required this.id,
    required this.village,
    required this.sharedSymptoms,
    required this.sharedDisease,
    required this.patients,
    required this.timestamp,
    this.isSynced = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'village': village,
        'sharedSymptoms': sharedSymptoms,
        'sharedDisease': sharedDisease,
        'patients': patients.map((p) => p.toJson()).toList(),
        'timestamp': timestamp,
        'isSynced': isSynced,
      };

  factory BulkPatientReport.fromJson(Map<String, dynamic> json) => BulkPatientReport(
        id: json['id'] ?? '',
        village: json['village'] ?? '',
        sharedSymptoms: json['sharedSymptoms'] ?? '',
        sharedDisease: json['sharedDisease'] ?? '',
        patients: (json['patients'] as List<dynamic>?)
                ?.map((p) => BulkPatientItem.fromJson(p))
                .toList() ??
            [],
        timestamp: json['timestamp'] ?? '',
        isSynced: json['isSynced'] ?? false,
      );
}
