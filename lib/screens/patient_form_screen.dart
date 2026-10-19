import 'package:flutter/material.dart';
import '../models/backend_models.dart';
import '../services/api_service.dart';
import '../services/offline_storage_service.dart';
import '../services/sync_service.dart';

class PatientFormScreen extends StatefulWidget {
  const PatientFormScreen({super.key});

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _villageIdController = TextEditingController(text: '1');
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedGender = 'Female';
  String _selectedSeverity = 'Moderate';
  bool _isLoading = false;

  final List<String> _genders = ['Female', 'Male', 'Other'];
  final List<String> _severities = ['Mild', 'Moderate', 'Severe', 'Critical'];

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final payload = PatientPayload(
        villageId: int.parse(_villageIdController.text.trim()),
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        gender: _selectedGender,
        contactNumber: _contactController.text.trim(),
        diagnosis: _diagnosisController.text.trim(),
        severity: _selectedSeverity,
        notes: _notesController.text.trim(),
      );

      final online = await SyncService.isConnected();
      bool success = false;

      if (online) {
        success = await ApiService.submitPatientReport(payload);
      }

      if (!success) {
        // Save to offline cache queue
        await OfflineStorageService.savePatient(payload);
      }

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Patient record successfully sent to FastAPI backend!'
                : 'Offline: Patient record saved locally & queued for sync.'),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Individual Patient Report'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _villageIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Village ID', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Enter village ID' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Patient Full Name', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Enter patient name' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
                      validator: (val) => val == null || val.isEmpty ? 'Enter age' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                      items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (val) => setState(() => _selectedGender = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Contact Number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _diagnosisController,
                decoration: const InputDecoration(labelText: 'Diagnosis / Disease (e.g. Cholera, Typhoid)', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Enter diagnosis' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSeverity,
                decoration: const InputDecoration(labelText: 'Severity', border: OutlineInputBorder()),
                items: _severities.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => _selectedSeverity = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Clinical Notes / Symptoms', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit / Cache Patient Record', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
