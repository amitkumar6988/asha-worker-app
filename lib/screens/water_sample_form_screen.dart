import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/backend_models.dart';
import '../services/api_service.dart';
import '../services/offline_storage_service.dart';
import '../services/sync_service.dart';
import '../services/shared_prefs_helper.dart';

class WaterSampleFormScreen extends StatefulWidget {
  const WaterSampleFormScreen({super.key});

  @override
  State<WaterSampleFormScreen> createState() => _WaterSampleFormScreenState();
}

class _WaterSampleFormScreenState extends State<WaterSampleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phController = TextEditingController(text: '7.0');
  final _turbidityController = TextEditingController(text: '1.5');
  
  // New Water Source form controllers
  final _newSourceNameController = TextEditingController();
  final _newSourceLocationController = TextEditingController();
  String _selectedSourceType = 'Tube Well';
  String _selectedStatus = 'Active';

  List<Map<String, dynamic>> _waterSources = [];
  
  int _assignedVillageId = 1;
  String _villageName = 'Loading assigned village...';
  int? _selectedWaterSourceId;
  bool _isRegisteringNewSource = false;
  bool _isFetchingLocation = false;

  String _selectedContaminationStatus = 'Safe';
  String _selectedH2sResult = 'Yellow / Safe';
  bool _isLoading = false;

  final List<String> _statuses = ['Safe', 'Contaminated', 'Requires Treatment', 'Hazardous'];
  final List<String> _sourceTypes = ['Tube Well', 'Community Tap', 'Open Well', 'River / Stream', 'Pond'];
  final List<String> _sourceStatuses = ['Active', 'Inactive', 'Needs Repair'];
  
  final List<String> _h2sOptions = [
    'Yellow / Safe',
    'Black / Unsafe'
  ];

  @override
  void initState() {
    super.initState();
    _loadAssignedVillageAndSources();
  }

  void _loadAssignedVillageAndSources() async {
    final villageId = await SharedPrefsHelper.getVillageId();
    final villageData = await ApiService.getVillageById(villageId);
    
    setState(() {
      _assignedVillageId = villageId;
      _villageName = villageData != null ? '${villageData['name']} (${villageData['district']})' : 'Village ID: $villageId';
    });

    _loadWaterSources(villageId);
  }

  void _loadWaterSources(int villageId) async {
    final sources = await ApiService.getWaterSourcesByVillage(villageId);
    setState(() {
      _waterSources = sources;
      if (_waterSources.isNotEmpty) {
        _selectedWaterSourceId = _waterSources.first['id'];
        _isRegisteringNewSource = false;
      } else {
        _selectedWaterSourceId = -1;
        _isRegisteringNewSource = true;
        _autoFetchGpsLocation();
      }
    });
  }

  // Automatically fetch GPS location with runtime permission request popup
  void _autoFetchGpsLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isFetchingLocation = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled. Please enable GPS.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isFetchingLocation = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied.')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isFetchingLocation = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are permanently denied.')),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() {
        _newSourceLocationController.text = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)} (GPS Tagged)';
        _isFetchingLocation = false;
      });
    } catch (e) {
      setState(() => _isFetchingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  void _submitWater() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      int? waterSourceId = _selectedWaterSourceId;

      if (_isRegisteringNewSource) {
        waterSourceId = await ApiService.createWaterSource(
          villageId: _assignedVillageId,
          name: _newSourceNameController.text.trim(),
          sourceType: _selectedSourceType,
          location: _newSourceLocationController.text.trim().isEmpty ? null : _newSourceLocationController.text.trim(),
          status: _selectedStatus,
        );

        if (waterSourceId == null) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to register new water source. Please try again.')),
            );
          }
          return;
        }
      }

      if (waterSourceId == null || waterSourceId <= 0) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select or register a valid water source.')),
          );
        }
        return;
      }

      final email = await SharedPrefsHelper.getUserEmail();

      final payload = WaterQualityPayload(
        waterSourceId: waterSourceId,
        ph: double.tryParse(_phController.text.trim()),
        turbidity: double.tryParse(_turbidityController.text.trim()),
        h2sTestResult: _selectedH2sResult,
        contaminationStatus: _selectedContaminationStatus,
        testedBy: email,
        testedAt: DateTime.now().toIso8601String(),
      );

      final online = await SyncService.isConnected();
      bool success = false;

      if (online) {
        success = await ApiService.submitWaterReport(payload);
      }

      if (!success) {
        await OfflineStorageService.saveWater(payload);
      }

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Water quality report successfully sent to FastAPI backend!'
                : 'Offline: Water report saved locally & queued for sync.'),
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
        title: const Text('Water Quality Report & Source'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Fixed Assigned Village Banner
              Card(
                color: Colors.blue.shade50,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Assigned Village: $_villageName (Fixed)',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Water Source Selection (Existing vs Register New)
              const Text('Water Source Selection', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: _isRegisteringNewSource ? -1 : _selectedWaterSourceId,
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                items: [
                  ..._waterSources.map((s) => DropdownMenuItem<int>(
                        value: s['id'],
                        child: Text('${s['name']} (${s['source_type']})'),
                      )),
                  const DropdownMenuItem<int>(
                    value: -1,
                    child: Text('+ Register New Water Source', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    if (val == -1) {
                      _isRegisteringNewSource = true;
                      _selectedWaterSourceId = -1;
                      _autoFetchGpsLocation();
                    } else {
                      _isRegisteringNewSource = false;
                      _selectedWaterSourceId = val;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // If registering new water source, show fields with auto-filled GPS location
              if (_isRegisteringNewSource) ...[
                Card(
                  color: Colors.teal.shade50,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Register New Water Source', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                            if (_isFetchingLocation)
                              const Row(
                                children: [
                                  SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                                  SizedBox(width: 6),
                                  Text('Getting GPS...', style: TextStyle(fontSize: 11, color: Colors.teal)),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _newSourceNameController,
                          decoration: const InputDecoration(labelText: 'Source Name (e.g. Basti 4 Tube Well #2)', border: OutlineInputBorder(), isDense: true),
                          validator: (val) => _isRegisteringNewSource && (val == null || val.isEmpty) ? 'Enter source name' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedSourceType,
                          decoration: const InputDecoration(labelText: 'Source Type', border: OutlineInputBorder(), isDense: true),
                          items: _sourceTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (val) => setState(() => _selectedSourceType = val!),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _newSourceLocationController,
                          decoration: InputDecoration(
                            labelText: 'Location (Auto-filled via GPS)',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.my_location, color: Colors.teal),
                              onPressed: _autoFetchGpsLocation,
                              tooltip: 'Refresh GPS Location',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: const InputDecoration(labelText: 'Source Status', border: OutlineInputBorder(), isDense: true),
                          items: _sourceStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) => setState(() => _selectedStatus = val!),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const Divider(),
              const SizedBox(height: 10),

              // 3. Water Testing Parameters
              const Text('Water Testing Parameters', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'pH Level (e.g. 7.2)', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Enter pH' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _turbidityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Turbidity (NTU)', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Enter turbidity' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedH2sResult,
                decoration: const InputDecoration(labelText: 'H₂S Test Report', border: OutlineInputBorder()),
                items: _h2sOptions.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                onChanged: (val) => setState(() => _selectedH2sResult = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedContaminationStatus,
                decoration: const InputDecoration(labelText: 'Contamination Status', border: OutlineInputBorder()),
                items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => _selectedContaminationStatus = val!),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
                  onPressed: _isLoading ? null : _submitWater,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit / Cache Water Report', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
