import 'package:flutter/material.dart';
import '../models/backend_models.dart';
import '../services/offline_storage_service.dart';
import '../services/sync_service.dart';
import '../services/api_service.dart';

class BulkPatientFormScreen extends StatefulWidget {
  const BulkPatientFormScreen({super.key});

  @override
  State<BulkPatientFormScreen> createState() => _BulkPatientFormScreenState();
}

class _BulkPatientFormScreenState extends State<BulkPatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _villageIdController = TextEditingController(text: '1');
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedSeverity = 'Moderate';

  final List<String> _severities = ['Mild', 'Moderate', 'Severe', 'Critical'];
  final List<BulkPatientItemInput> _patientInputs = [];

  @override
  void initState() {
    super.initState();
    _addRow();
  }

  void _addRow() {
    setState(() {
      _patientInputs.add(BulkPatientItemInput());
    });
  }

  void _removeRow(int index) {
    if (_patientInputs.length > 1) {
      setState(() {
        _patientInputs.removeAt(index);
      });
    }
  }

  void _submitBulk() async {
    if (_formKey.currentState!.validate()) {
      for (var p in _patientInputs) {
        if (!p.validate()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill all patient details correctly in the batch')),
          );
          return;
        }
      }

      final items = _patientInputs.map((p) => p.toItem()).toList();
      final villageId = int.parse(_villageIdController.text.trim());
      final diagnosis = _diagnosisController.text.trim();
      final severity = _selectedSeverity;
      final notes = _notesController.text.trim();

      final batch = BulkPatientBatchPayload(
        villageId: villageId,
        diagnosis: diagnosis,
        severity: severity,
        notes: notes,
        patients: items,
      );

      final online = await SyncService.isConnected();
      bool allSuccess = true;

      if (online) {
        for (var item in items) {
          final p = PatientPayload(
            villageId: villageId,
            name: item.name,
            age: item.age,
            gender: item.gender,
            contactNumber: item.contactNumber,
            diagnosis: diagnosis,
            severity: severity,
            notes: notes,
          );
          final res = await ApiService.submitPatientReport(p);
          if (!res) allSuccess = false;
        }
      } else {
        allSuccess = false;
      }

      if (!allSuccess) {
        await OfflineStorageService.saveBulk(batch);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(allSuccess
                ? 'Bulk batch of ${items.length} patients successfully submitted to backend!'
                : 'Offline: Bulk batch saved locally & queued for backend sync.'),
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
        title: const Text('Bulk Patients Report (Same Diagnosis)'),
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
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _diagnosisController,
                decoration: const InputDecoration(labelText: 'Shared Diagnosis / Disease', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Enter shared diagnosis' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSeverity,
                decoration: const InputDecoration(labelText: 'Shared Severity', border: OutlineInputBorder()),
                items: _severities.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => _selectedSeverity = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Shared Notes / Symptoms', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Patients in Batch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                    onPressed: _addRow,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Patient'),
                  ),
                ],
              ),
              const Divider(),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _patientInputs.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Patient #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeRow(index),
                              ),
                            ],
                          ),
                          TextFormField(
                            controller: _patientInputs[index].nameController,
                            decoration: const InputDecoration(labelText: 'Full Name', isDense: true),
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _patientInputs[index].ageController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Age', isDense: true),
                                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _patientInputs[index].gender,
                                  decoration: const InputDecoration(labelText: 'Gender', isDense: true),
                                  items: ['Female', 'Male', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                                  onChanged: (val) => setState(() => _patientInputs[index].gender = val!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _patientInputs[index].contactController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(labelText: 'Contact Number', isDense: true),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade800, foregroundColor: Colors.white),
                  onPressed: _submitBulk,
                  child: const Text('Submit / Cache Bulk Batch', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BulkPatientItemInput {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final contactController = TextEditingController();
  String gender = 'Female';

  bool validate() => nameController.text.isNotEmpty && ageController.text.isNotEmpty;

  PatientBatchItem toItem() => PatientBatchItem(
        name: nameController.text.trim(),
        age: int.tryParse(ageController.text.trim()) ?? 0,
        gender: gender,
        contactNumber: contactController.text.trim().isEmpty ? null : contactController.text.trim(),
      );
}
