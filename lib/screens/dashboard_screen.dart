import 'package:flutter/material.dart';
import '../services/shared_prefs_helper.dart';
import '../services/offline_storage_service.dart';
import '../services/sync_service.dart';
import 'patient_form_screen.dart';
import 'bulk_patient_form_screen.dart';
import 'water_sample_form_screen.dart';
import 'sync_manager_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userName = 'ASHA Worker';
  int _pendingCount = 0;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkStatus();
  }

  void _loadData() async {
    final name = await SharedPrefsHelper.getUserName();
    final count = await OfflineStorageService.getPendingCount();
    setState(() {
      _userName = name;
      _pendingCount = count;
    });
  }

  void _checkStatus() async {
    final online = await SyncService.isConnected();
    setState(() => _isOnline = online);
  }

  void _logout() async {
    await SharedPrefsHelper.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ASHA Worker Portal'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
          _checkStatus();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                color: Colors.teal.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.teal,
                        child: Icon(Icons.person, size: 32, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Logged in as:', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(_userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                            const SizedBox(height: 4),
                            const Text('Role: ASHA Worker', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: _isOnline ? Colors.green.shade50 : Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(_isOnline ? Icons.wifi : Icons.wifi_off, color: _isOnline ? Colors.green : Colors.orange),
                            const SizedBox(width: 8),
                            Text(_isOnline ? 'Online' : 'Offline (Cached)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const SyncManagerScreen()));
                      _loadData();
                    },
                    child: Card(
                      color: Colors.teal.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            const Icon(Icons.sync, color: Colors.teal),
                            const SizedBox(width: 8),
                            Text('Queue: $_pendingCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Data Reporting', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildCard(
                    context,
                    title: 'Individual Patient',
                    subtitle: 'Post patient & health record to API',
                    icon: Icons.person_add,
                    color: Colors.teal,
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const PatientFormScreen()));
                      _loadData();
                    },
                  ),
                  _buildCard(
                    context,
                    title: 'Bulk Patient Batch',
                    subtitle: 'Post multiple patients with shared diagnosis',
                    icon: Icons.group_add,
                    color: Colors.teal.shade800,
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const BulkPatientFormScreen()));
                      _loadData();
                    },
                  ),
                  _buildCard(
                    context,
                    title: 'Water Quality Report',
                    subtitle: 'Post pH, turbidity & contamination to API',
                    icon: Icons.water_drop,
                    color: Colors.blue.shade700,
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const WaterSampleFormScreen()));
                      _loadData();
                    },
                  ),
                  _buildCard(
                    context,
                    title: 'Sync Manager',
                    subtitle: 'View offline cache & sync with backend',
                    icon: Icons.cloud_sync,
                    color: Colors.orange.shade800,
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const SyncManagerScreen()));
                      _loadData();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 36, color: color),
              const Spacer(),
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
