import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageServicesPage extends StatefulWidget {
  const ManageServicesPage({super.key});

  @override
  State<ManageServicesPage> createState() => _ManageServicesPageState();
}

class _ManageServicesPageState extends State<ManageServicesPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _serviceController = TextEditingController();
  final _priceRangeController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _editingService;
  String? _editingServiceName;

  // Reference to the barber's document
  DocumentReference get _barberRef {
    final email = _auth.currentUser?.email;
    return _firestore.collection('BarbersDetails').doc(email);
  }

  // Add or update a service
  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final serviceName = _serviceController.text;
      final priceRange = _priceRangeController.text;

      // Fetch current services
      final barberDoc = await _barberRef.get();
      List<dynamic> services = barberDoc['services'] as List<dynamic>? ?? [];

      if (_editingService != null) {
        // Update existing service
        services =
            services.map((service) {
              if (service['name'] == _editingServiceName) {
                return {
                  'name': serviceName,
                  'priceRange': priceRange,
                  'dailyEarnings': service['dailyEarnings'] ?? 0.0,
                };
              }
              return service;
            }).toList();
      } else {
        // Add new service
        services.add({
          'name': serviceName,
          'priceRange': priceRange,
          'dailyEarnings': 0.0,
        });
      }

      // Update Firestore
      await _barberRef.update({'services': services});

      // Update DailyStats serviceEarnings
      final currentDate = DateTime.now().toIso8601String().split('T')[0];
      final statsRef = _barberRef.collection('DailyStats').doc(currentDate);
      final statsDoc = await statsRef.get();
      Map<String, dynamic> serviceEarnings =
          statsDoc.exists
              ? statsDoc['serviceEarnings'] as Map<String, dynamic>? ?? {}
              : {};

      if (_editingService != null && _editingServiceName != serviceName) {
        // If service name changed, update serviceEarnings key
        final earnings = serviceEarnings[_editingServiceName] ?? 0.0;
        serviceEarnings.remove(_editingServiceName);
        serviceEarnings[serviceName] = earnings;
      } else // Initialize new service in serviceEarnings
        serviceEarnings[serviceName] = 0.0;

      await statsRef.set({
        'serviceEarnings': serviceEarnings,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editingService != null ? 'Service updated' : 'Service added',
          ),
        ),
      );

      // Clear form
      _serviceController.clear();
      _priceRangeController.clear();
      setState(() {
        _editingService = null;
        _editingServiceName = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Delete a service
  Future<void> _deleteService(String serviceName) async {
    setState(() => _isLoading = true);

    try {
      // Fetch current services
      final barberDoc = await _barberRef.get();
      List<dynamic> services = barberDoc['services'] as List<dynamic>? ?? [];

      // Remove the service
      services =
          services.where((service) => service['name'] != serviceName).toList();

      // Update Firestore
      await _barberRef.update({'services': services});

      // Update DailyStats serviceEarnings
      final currentDate = DateTime.now().toIso8601String().split('T')[0];
      final statsRef = _barberRef.collection('DailyStats').doc(currentDate);
      final statsDoc = await statsRef.get();
      Map<String, dynamic> serviceEarnings =
          statsDoc.exists
              ? statsDoc['serviceEarnings'] as Map<String, dynamic>? ?? {}
              : {};
      serviceEarnings.remove(serviceName);

      await statsRef.set({
        'serviceEarnings': serviceEarnings,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Service deleted')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting service: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Start editing a service
  void _editService(Map<String, dynamic> service) {
    setState(() {
      _editingService = service;
      _editingServiceName = service['name'];
      _serviceController.text = service['name'];
      _priceRangeController.text = service['priceRange'];
    });
  }

  @override
  void dispose() {
    _serviceController.dispose();
    _priceRangeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Services',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade50, Colors.white],
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add/Update Service Form
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _editingService != null
                                ? 'Edit Service'
                                : 'Add New Service',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _serviceController,
                            decoration: InputDecoration(
                              labelText: 'Service Name',
                              prefixIcon: Icon(
                                Icons.cut,
                                color: Colors.blue.shade800,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter service name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _priceRangeController,
                            decoration: InputDecoration(
                              labelText: 'Price Range (e.g., \$20-\$30)',
                              prefixIcon: Icon(
                                Icons.attach_money,
                                color: Colors.blue.shade800,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter price range';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveService,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade800,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child:
                                  _isLoading
                                      ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                      : Text(
                                        _editingService != null
                                            ? 'Update Service'
                                            : 'Add Service',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                            ),
                          ),
                          if (_editingService != null) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _serviceController.clear();
                                    _priceRangeController.clear();
                                    _editingService = null;
                                    _editingServiceName = null;
                                  });
                                },
                                child: Text(
                                  'Cancel Edit',
                                  style: GoogleFonts.poppins(color: Colors.red),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Current Services List
                Text(
                  'Current Services',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 10),
                StreamBuilder<DocumentSnapshot>(
                  stream: _barberRef.snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final services =
                        snapshot.data!['services'] as List<dynamic>? ?? [];

                    if (services.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(15),
                        child: Text(
                          'No services listed',
                          style: GoogleFonts.poppins(),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        final service = services[index] as Map<String, dynamic>;
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            title: Text(
                              service['name'] ?? 'Unknown',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Price: ${service['priceRange'] ?? 'Not specified'}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Daily Earnings: \$${service['dailyEarnings']?.toStringAsFixed(2) ?? '0.00'}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.green.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color: Colors.blue.shade800,
                                  ),
                                  onPressed: () => _editService(service),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed:
                                      () => _deleteService(service['name']),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
