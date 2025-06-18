import 'package:barber/view/barber_pages.dart/barberOwnerHomePage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class BarberRegistrationPage extends StatefulWidget {
  final String email;
  final String password;

  const BarberRegistrationPage({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<BarberRegistrationPage> createState() => _BarberRegistrationPageState();
}

class _BarberRegistrationPageState extends State<BarberRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // Form fields
  String _fullName = '';
  String _phoneNumber = '';
  String _shopName = '';
  String _shopAddress = '';
  double? _latitude;
  double? _longitude;
  File? _profileImage;
  File? _shopLicenseImage;
  bool _isLoading = false;
  String? _serviceStandard;
  final List<Map<String, dynamic>> _services = [];
  final _serviceController = TextEditingController();
  final _priceRangeController = TextEditingController();

  Future<void> _pickImage(bool isProfile) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (isProfile) {
          _profileImage = File(pickedFile.path);
        } else {
          _shopLicenseImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permissions are permanently denied, we cannot request permissions.',
          ),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location picked successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addService() {
    if (_serviceController.text.isNotEmpty &&
        _priceRangeController.text.isNotEmpty) {
      setState(() {
        _services.add({
          'name': _serviceController.text,
          'priceRange': _priceRangeController.text,
          'dailyEarnings': 0.0, // Initialize daily earnings for tracking
        });
        _serviceController.clear();
        _priceRangeController.clear();
      });
    }
  }

  Future<void> _registerBarber() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profileImage == null || _shopLicenseImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload both profile image and license'),
        ),
      );
      return;
    }
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick your shop location on the map'),
        ),
      );
      return;
    }
    if (_serviceStandard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service standard')),
      );
      return;
    }
    if (_services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one service')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create user in Firebase Auth
      await _auth.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      // 2. Upload images to Firebase Storage
      final profileUrl = await _uploadImage(
        _profileImage!,
        'profile_${widget.email}',
      );
      final licenseUrl = await _uploadImage(
        _shopLicenseImage!,
        'license_${widget.email}',
      );

      // 3. Create barber document in Firestore
      final barberDoc = _firestore
          .collection('BarbersDetails')
          .doc(widget.email);
      await barberDoc.set({
        'email': widget.email,
        'fullName': _fullName,
        'phoneNumber': _phoneNumber,
        'shopName': _shopName,
        'shopAddress': _shopAddress,
        'latitude': _latitude,
        'longitude': _longitude,
        'profileImageUrl': profileUrl,
        'licenseImageUrl': licenseUrl,
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'rating': 0.0,
        'totalRatings': 0,
        'serviceStandard': _serviceStandard,
        'services': _services,
        'workingHours': {
          'Monday': {'open': '09:00', 'close': '18:00'},
          'Tuesday': {'open': '09:00', 'close': '18:00'},
          'Wednesday': {'open': '09:00', 'close': '18:00'},
          'Thursday': {'open': '09:00', 'close': '18:00'},
          'Friday': {'open': '09:00', 'close': '18:00'},
          'Saturday': {'open': '10:00', 'close': '16:00'},
          'Sunday': {'open': '10:00', 'close': '14:00'},
        },
      });

      // 4. Initialize DailyStats for the current day
      final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await barberDoc.collection('DailyStats').doc(currentDate).set({
        'date': currentDate,
        'dailyEarnings': 0.0,
        'dailyCustomers': 0,
        'dailyQueue': 0,
        'dailyBookings': 0,
        'timestamp': FieldValue.serverTimestamp(),
        'serviceEarnings': {
          for (var service in _services) service['name']: 0.0,
        },
      });

      // 5. Initialize TotalStats
      await barberDoc.collection('TotalStats').doc('aggregate').set({
        'totalCustomers': 0,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // 6. Navigate to BarberOwnerHomePage
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const BarberOwnerHomePage()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Registration failed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String> _uploadImage(File image, String name) async {
    final ref = _storage.ref().child('barber_images/$name');
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Complete Barber Profile',
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.blue.shade100,
                          backgroundImage:
                              _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : null,
                          child:
                              _profileImage == null
                                  ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.blue.shade800,
                                  )
                                  : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.shade800,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                              ),
                              onPressed: () => _pickImage(true),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildFormField(
                    'Full Name',
                    Icons.person,
                    (value) => _fullName = value,
                    validator: _validateName,
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    'Phone Number',
                    Icons.phone,
                    (value) => _phoneNumber = value,
                    keyboardType: TextInputType.phone,
                    validator: _validatePhone,
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    'Shop Name',
                    Icons.store,
                    (value) => _shopName = value,
                    validator: _validateShopName,
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    'Shop Address',
                    Icons.location_on,
                    (value) => _shopAddress = value,
                    maxLines: 2,
                    validator: _validateAddress,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Service Standard',
                      prefixIcon: Icon(Icons.star, color: Colors.blue.shade800),
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
                    items:
                        ['Premium', 'Traditional', 'Modern']
                            .map(
                              (standard) => DropdownMenuItem(
                                value: standard,
                                child: Text(standard),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _serviceStandard = value;
                      });
                    },
                    validator:
                        (value) =>
                            value == null
                                ? 'Please select a service standard'
                                : null,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Services & Price Ranges',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildFormField(
                    'Service Name',
                    Icons.cut,
                    (value) {},
                    controller: _serviceController,
                  ),
                  const SizedBox(height: 10),
                  _buildFormField(
                    'Price Range (e.g., \$20-\$30)',
                    Icons.attach_money,
                    (value) {},
                    controller: _priceRangeController,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _addService,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Add Service',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _services.isNotEmpty
                      ? ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _services.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_services[index]['name']),
                            subtitle: Text(
                              'Price: ${_services[index]['priceRange']}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _services.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      )
                      : const Text('No services added yet'),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _getCurrentLocation,
                    icon: Icon(Icons.map, color: Colors.white),
                    label:
                        _latitude == null || _longitude == null
                            ? Text(
                              'Pick Shop Location',
                              style: GoogleFonts.poppins(color: Colors.white),
                            )
                            : Text(
                              'Location Picked! (Lat: ${_latitude!.toStringAsFixed(2)}, Lng: ${_longitude!.toStringAsFixed(2)})',
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Shop License',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => _pickImage(false),
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          _shopLicenseImage == null
                              ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.upload_file,
                                    size: 40,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Upload License Document',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              )
                              : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _shopLicenseImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _registerBarber,
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
                                'Complete Registration',
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

  Widget _buildFormField(
    String label,
    IconData icon,
    Function(String) onChanged, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hintText,
    String? Function(String?)? validator,
    TextEditingController? controller,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
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
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator,
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your name';
    if (value.length < 3) return 'Name must be at least 3 characters';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Please enter phone number';
    if (!RegExp(r'^[0-9]{10,15}$').hasMatch(value))
      return 'Enter valid phone number';
    return null;
  }

  String? _validateShopName(String? value) {
    if (value == null || value.isEmpty) return 'Please enter shop name';
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.isEmpty) return 'Please enter shop address';
    if (value.length < 10) return 'Address is too short';
    return null;
  }
}
