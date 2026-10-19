import 'package:flutter/material.dart';
import '../services/offline_storage_service.dart';
import '../services/sync_service.dart';
import '../models/backend_models.dart';

class SyncManagerScreen extends StatefulWidget {
  const SyncManagerScreen({super.key});

  @override
  State<SyncManagerScreen> createState() => _SyncManagerScreenState();
}

class _SyncManagerScreenState extends State<SyncManagerScreen> {
  List<PatientPayload> _patients = [];
  List<WaterQualityPayload> _waterReports = [];
  List<BulkPatientBatchPayload> _bulkReports = [];
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadCache();
  }

  void _loadCache() async {
    setState(() => _isLoading = true);
    final p = await OfflineStorageService.getPatients();
    final w = await OfflineStorageService.getWaterReports();
    final b = await OfflineStorageService.getBulkReports();
    setState(() {
      _patients = p;
      _waterReports = w;
      _bulkReports = b;
      _isLoading = false;
    });
  }

  void _syncNow() async {
    setState(() => _isSyncing = true);
    final result = await SyncService.syncAllPending();
    setState(() => _isSyncing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
      _loadCache();
    }
  }

  @override
  Widget build(BuildContext context) {
    int total = _patients.length + _waterReports.length + _bulkReports.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Sync Manager'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: total > 0 ? Colors.orange.shade50 : Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                total > 0 ? '$total Pending Cached Item(s)' : 'All Data Synced to Backend!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: total > 0 ? Colors.orange.shade800 : Colors.green.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text('Stored locally until internet restores.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                            onPressed: (_isSyncing || total == 0) ? null : _syncNow,
                            icon: _isSyncing
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.sync),
                            label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Cached Data Queue Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      children: [
                        ExpansionTile(
                          leading: const Icon(Icons.person, color: Colors.teal),
                          title: Text('Individual Patients (${_patients.length})'),
                          children: _patients.map((p) => ListTile(
                                title: Text(p.name),
                                subtitle: Text('Diagnosis: ${p.diagnosis} | Village ID: ${p.villageId}'),
                              )).toList(),
                        ),
                        ExpansionTile(
                          leading: const Icon(Icons.group, color: Colors.teal),
                          title: Text('Bulk Batches (${_bulkReports.length})'),
                          children: _bulkReports.map((b) => ListTile(
                                title: Text('Batch: ${b.diagnosis} (${b.patients.length} patients)'),
                                subtitle: Text('Village ID: ${b.villageId} | Severity: ${b.severity}'),
                              )).toList(),
                        ),
                        ExpansionTile(
                          leading: const Icon(Icons.water_drop, color: Colors.blue),
                          title: Text('Water Quality Reports (${_waterReports.length})'),
                          children: _waterReports.map((w) => ListTile(
                                title: Text('Water Source ID: ${w.waterSourceId}'),
                                subtitle: Text('Status: ${w.contaminationStatus} | pH: ${w.ph} | Turbidity: ${w.turbidity}'),
                              )).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
