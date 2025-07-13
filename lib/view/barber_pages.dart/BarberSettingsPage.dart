import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barber/services/navigator.dart';

class BarberSettingsPage extends StatefulWidget {
  const BarberSettingsPage({super.key});

  @override
  State<BarberSettingsPage> createState() => _BarberSettingsPageState();
}

class _BarberSettingsPageState extends State<BarberSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _serviceStandardController = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBarberData();
  }

  // Fetch barber profile data
  Future<void> _fetchBarberData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('BarbersDetails')
          .doc(_currentUser?.email)
          .get();
      if (doc.exists) {
        setState(() {
          _shopNameController.text = doc['shopName'] ?? '';
          _serviceStandardController.text = doc['serviceStandard'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching barber data: $e');
      setState(() {
        _errorMessage = 'Error loading profile: $e';
        _isLoading = false;
      });
    }
  }

  // Update barber profile
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await FirebaseFirestore.instance
          .collection('BarbersDetails')
          .doc(_currentUser?.email)
          .update({
        'shopName': _shopNameController.text.trim(),
        'serviceStandard': _serviceStandardController.text.trim(),
      });
      print('Profile updated for ${_currentUser?.email}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error updating profile: $e');
      setState(() {
        _errorMessage = 'Error updating profile: $e';
        _isLoading = false;
      });
    }
  }

  // Logout function
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _serviceStandardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    strokeWidth: 5,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Loading...',
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 60, color: Colors.red[400]),
                        const SizedBox(height: 20),
                        Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(fontSize: 16, color: Colors.red[700]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _fetchBarberData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: Text(
                            'Retry',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile Settings',
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _shopNameController,
                          decoration: InputDecoration(
                            labelText: 'Shop Name',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Shop name is required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _serviceStandardController,
                          decoration: InputDecoration(
                            labelText: 'Service Standard',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Service standard is required' : null,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: Text(
                            'Save Changes',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Account',
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: Icon(Icons.logout, color: Colors.blue[800]),
                          title: Text('Logout', style: GoogleFonts.poppins()),
                          onTap: _logout,
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}