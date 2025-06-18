import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CreateBookingPage extends StatefulWidget {
  const CreateBookingPage({super.key});

  @override
  State<CreateBookingPage> createState() => _CreateBookingPageState();
}

class _CreateBookingPageState extends State<CreateBookingPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedServiceId = '';
  String _specialInstructions = '';
  bool _isLoading = true;
  Map<String, dynamic>? _barberData;
  List<Map<String, dynamic>> _services = [];
  String? _barberEmail;

  @override
  void initState() {
    super.initState();
    _fetchBarberData();
  }

  Future<void> _fetchBarberData() async {
    try {
      // Get barberEmail from route arguments
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args == null || args['barberEmail'] == null) {
        throw 'No barber selected';
      }
      _barberEmail = args['barberEmail'];

      // Fetch barber details
      final barberDoc = await _firestore
          .collection('BarbersDetails')
          .doc(_barberEmail)
          .get()
          .timeout(const Duration(seconds: 5));

      if (!barberDoc.exists) {
        throw 'Barber not found';
      }

      setState(() {
        _barberData = barberDoc.data() as Map<String, dynamic>;
        _services = List<Map<String, dynamic>>.from(
          _barberData!['services'] ?? [],
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load barber data: $e')),
        );
        Navigator.pop(context); // Return to previous page
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitBooking() async {
    if (_selectedServiceId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a service')));
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to create a booking')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final selectedService = _services.firstWhere(
        (s) => s['id'] == _selectedServiceId,
      );
      final bookingDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Create booking document
      final bookingData = {
        'customerEmail': user.email,
        'barberEmail': _barberEmail,
        'service': selectedService,
        'dateTime': Timestamp.fromDate(bookingDateTime),
        'specialInstructions': _specialInstructions,
        'status': 'pending',
        'createdAt': Timestamp.now(),
      };

      // Save to Firestore
      await _firestore
          .collection('Bookings')
          .add(bookingData)
          .timeout(const Duration(seconds: 5));

      // Show confirmation dialog
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Booking Confirmed', style: GoogleFonts.poppins()),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'With ${_barberData!['fullName']}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(selectedService['name'], style: GoogleFonts.poppins()),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMMM d').format(bookingDateTime),
                      style: GoogleFonts.poppins(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('h:mm a').format(bookingDateTime),
                      style: GoogleFonts.poppins(),
                    ),
                    if (_specialInstructions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Special Instructions:',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      Text(_specialInstructions, style: GoogleFonts.poppins()),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close', style: GoogleFonts.poppins()),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pushReplacementNamed(
                        context,
                        '/bookings',
                      ); // Go to bookings page
                    },
                    child: Text('View Bookings', style: GoogleFonts.poppins()),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create booking: $e')));
      }
    }
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: _selectedServiceId == service['id'] ? Colors.blue.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color:
              _selectedServiceId == service['id']
                  ? Colors.blue.shade800
                  : Colors.grey.shade300,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            _selectedServiceId = service['id'];
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(
                Icons.cut,
                color:
                    _selectedServiceId == service['id']
                        ? Colors.blue.shade800
                        : Colors.grey,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service['name'],
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${service['duration']} min • \$${service['price'].toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedServiceId == service['id'])
                Icon(Icons.check_circle, color: Colors.blue.shade800),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Book Appointment',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blue.shade800,
        centerTitle: true,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              )
              : _barberData == null
              ? Center(
                child: Text(
                  'Failed to load barber data',
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Barber Info Card
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.blue.shade100,
                                backgroundImage:
                                    _barberData!['profileImageUrl'] != null
                                        ? NetworkImage(
                                          _barberData!['profileImageUrl'],
                                        )
                                        : null,
                                child:
                                    _barberData!['profileImageUrl'] == null
                                        ? Icon(
                                          Icons.person,
                                          color: Colors.blue.shade800,
                                          size: 30,
                                        )
                                        : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _barberData!['fullName'] ?? 'Unknown',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: Colors.yellow.shade700,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_barberData!['rating']?.toStringAsFixed(1) ?? 'N/A'} (${_barberData!['totalRatings'] ?? 0})',
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _barberData!['address'] ?? 'No address',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Service Selection
                      Text(
                        'Select Service',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_services.isEmpty)
                        Text(
                          'No services available',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        )
                      else
                        ..._services
                            .map((service) => _buildServiceCard(service))
                            .toList(),
                      const SizedBox(height: 24),

                      // Date Selection
                      Text(
                        'Select Date',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat(
                                  'EEEE, MMMM d, y',
                                ).format(_selectedDate),
                                style: GoogleFonts.poppins(),
                              ),
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Time Selection
                      Text(
                        'Select Time',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectTime(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedTime.format(context),
                                style: GoogleFonts.poppins(),
                              ),
                              const Icon(Icons.access_time, color: Colors.blue),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Special Instructions
                      Text(
                        'Special Instructions (Optional)',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'Any special requests or notes for your barber...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          hintStyle: GoogleFonts.poppins(),
                        ),
                        onChanged: (value) => _specialInstructions = value,
                      ),
                      const SizedBox(height: 32),

                      // Confirm Booking Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.blue.shade800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isLoading ? null : _submitBooking,
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : Text(
                                    'Confirm Booking',
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
    );
  }
}
