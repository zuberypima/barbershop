import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class BarberStatsPage extends StatefulWidget {
  const BarberStatsPage({super.key});

  @override
  State<BarberStatsPage> createState() => _BarberStatsPageState();
}

class _BarberStatsPageState extends State<BarberStatsPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Form fields
  double _dailyEarnings = 0.0;
  int _dailyCustomers = 0;
  int _dailyQueue = 0;
  int _dailyBookings = 0;
  bool _isLoading = false;

  // Controllers
  final _earningsController = TextEditingController();
  final _customersController = TextEditingController();
  final _queueController = TextEditingController();
  final _bookingsController = TextEditingController();

  @override
  void dispose() {
    _earningsController.dispose();
    _customersController.dispose();
    _queueController.dispose();
    _bookingsController.dispose();
    super.dispose();
  }

  Future<void> _submitStats() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to continue')),
        );
        return;
      }

      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final barberRef = _firestore.collection('BarbersDetails').doc(user.email);
      final statsRef = barberRef.collection('DailyStats').doc(date);
      final totalStatsRef = barberRef.collection('TotalStats').doc('aggregate');

      // Update daily statistics
      await statsRef.set({
        'date': date,
        'dailyEarnings': _dailyEarnings,
        'dailyCustomers': _dailyCustomers,
        'dailyQueue': _dailyQueue,
        'dailyBookings': _dailyBookings,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update total customers in aggregate stats
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(totalStatsRef);

        int currentTotalCustomers = 0;
        if (snapshot.exists) {
          currentTotalCustomers = snapshot.data()?['totalCustomers'] ?? 0;
        }

        transaction.set(totalStatsRef, {
          'totalCustomers': currentTotalCustomers + _dailyCustomers,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Statistics saved successfully!')),
      );

      // Clear form
      _earningsController.clear();
      _customersController.clear();
      _queueController.clear();
      _bookingsController.clear();
      setState(() {
        _dailyEarnings = 0.0;
        _dailyCustomers = 0;
        _dailyQueue = 0;
        _dailyBookings = 0;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving stats: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Statistics', style: GoogleFonts.poppins()),
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Record Today\'s Statistics',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    label: 'Daily Earnings (\$)',
                    icon: Icons.attach_money,
                    controller: _earningsController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter daily earnings';
                      }
                      if (double.tryParse(value) == null ||
                          double.parse(value) < 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _dailyEarnings = double.tryParse(value) ?? 0.0;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    label: 'Customers Served Today',
                    icon: Icons.people,
                    controller: _customersController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter number of customers';
                      }
                      if (int.tryParse(value) == null || int.parse(value) < 0) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _dailyCustomers = int.tryParse(value) ?? 0;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    label: 'Queue Size Today',
                    icon: Icons.queue,
                    controller: _queueController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter queue size';
                      }
                      if (int.tryParse(value) == null || int.parse(value) < 0) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _dailyQueue = int.tryParse(value) ?? 0;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    label: 'Bookings Today',
                    icon: Icons.calendar_today,
                    controller: _bookingsController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter number of bookings';
                      }
                      if (int.tryParse(value) == null || int.parse(value) < 0) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _dailyBookings = int.tryParse(value) ?? 0;
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitStats,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                                'Save Statistics',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required Function(String) onChanged,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade800),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
    );
  }
}
