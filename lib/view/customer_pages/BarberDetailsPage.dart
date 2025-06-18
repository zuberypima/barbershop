import 'package:barber/view/barber_pages.dart/BarberMapDirectionsPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:barber/services/navigator.dart'; // Assuming your navigator service

class BarberDetailsPage extends StatefulWidget {
  final String barberId; // Email or ID of the barber

  const BarberDetailsPage({super.key, required this.barberId});

  @override
  State<BarberDetailsPage> createState() => _BarberDetailsPageState();
}

class _BarberDetailsPageState extends State<BarberDetailsPage> {
  String? _selectedService;
  bool _isBooking = false;

  // Reference to the barber's document
  DocumentReference get _barberRef => FirebaseFirestore.instance
      .collection('BarbersDetails')
      .doc(widget.barberId);

  // Reference to the current customer's document
  DocumentReference get _customerRef {
    final email = FirebaseAuth.instance.currentUser?.email;
    return FirebaseFirestore.instance.collection('CustomersDetails').doc(email);
  }

  // Book a service
  Future<void> _bookService() async {
    if (_selectedService == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a service')));
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Fetch customer name
      final customerDoc = await _customerRef.get();
      final customerData = customerDoc.data() as Map<String, dynamic>?;
      final customerName = customerData?['fullName'] as String? ?? 'Anonymous';

      // Add to barber's queue
      await _barberRef.collection('queue').add({
        'customerId': user.email,
        'customerName': customerName,
        'service': _selectedService,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // Update customer's bookings
      await _customerRef.collection('bookings').add({
        'barberId': widget.barberId,
        'service': _selectedService,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking successful! You are in the queue.'),
        ),
      );

      setState(() {
        _selectedService = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to book: $e')));
    } finally {
      setState(() {
        _isBooking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: _barberRef.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(width: 150, height: 20, color: Colors.white),
              );
            }
            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            final shopName = data['shopName'] ?? 'Barber Shop';
            return Text(
              shopName,
              style: GoogleFonts.poppins(color: Colors.white),
            );
          },
        ),
        backgroundColor: Colors.blue.shade800,
        actions: [],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barber Profile
              StreamBuilder<DocumentSnapshot>(
                stream: _barberRef.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return _buildProfileSkeleton();
                  }
                  final data =
                      snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  final shopName = data['shopName'] ?? 'Barber Shop';
                  final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
                  final totalRatings = data['totalRatings'] as int? ?? 0;
                  final address = data['address'] ?? 'No address';
                  final imageUrl = data['profileImageUrl'] ?? '';

                  return Card(
                    margin: const EdgeInsets.all(15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child:
                                    imageUrl.isNotEmpty
                                        ? Image.network(
                                          imageUrl,
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Container(
                                              width: 70,
                                              height: 70,
                                              color: Colors.blue.shade100,
                                              child: Icon(
                                                Icons.person,
                                                size: 30,
                                                color: Colors.blue.shade800,
                                              ),
                                            );
                                          },
                                        )
                                        : Container(
                                          width: 70,
                                          height: 70,
                                          color: Colors.blue.shade100,
                                          child: Icon(
                                            Icons.person,
                                            size: 30,
                                            color: Colors.blue.shade800,
                                          ),
                                        ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shopName,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      address,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 16,
                                        ),
                                        Text(
                                          rating.toStringAsFixed(1),
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          ' ($totalRatings reviews)',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Queue Status
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Queue Status',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot>(
                      stream: _barberRef.collection('queue').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return _buildQueueSkeleton();
                        }
                        final queueCount = snapshot.data!.docs.length;
                        final estimatedWait =
                            queueCount * 15; // 15 min per customer
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$queueCount customers in queue',
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                    Text(
                                      'Est. wait: $estimatedWait min',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.timer,
                                  color: Colors.blue.shade800,
                                  size: 30,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Services Offered
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Services Offered',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<DocumentSnapshot>(
                      stream: _barberRef.snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return _buildServicesSkeleton();
                        }
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>? ??
                            {};
                        final services =
                            data['services'] as List<dynamic>? ?? [];
                        if (services.isEmpty) {
                          return Text(
                            'No services available',
                            style: GoogleFonts.poppins(color: Colors.grey),
                          );
                        }
                        return Column(
                          children:
                              services.map((service) {
                                final serviceData =
                                    service as Map<String, dynamic>;
                                final name = serviceData['name'] ?? 'Unknown';
                                final priceRange =
                                    serviceData['priceRange'] ??
                                    'Not specified';
                                return RadioListTile<String>(
                                  title: Text(
                                    name,
                                    style: GoogleFonts.poppins(),
                                  ),
                                  subtitle: Text(
                                    'Price: $priceRange',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  value: name,
                                  groupValue: _selectedService,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedService = value;
                                    });
                                  },
                                  activeColor: Colors.blue.shade800,
                                );
                              }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Book Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isBooking ? null : _bookService,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isBooking
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : Text(
                              'Book Now',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
              ),

              // View Directions Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      push_next_page(
                        context,
                        BarberMapDirectionsPage(barberEmail: widget.barberId),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'View Directions',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  // Skeleton loading widgets
  Widget _buildProfileSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        margin: const EdgeInsets.all(15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(width: 70, height: 70, color: Colors.white),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 150, height: 18, color: Colors.white),
                    const SizedBox(height: 5),
                    Container(width: 100, height: 12, color: Colors.white),
                    const SizedBox(height: 5),
                    Container(width: 80, height: 12, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQueueSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 120, height: 14, color: Colors.white),
                  const SizedBox(height: 5),
                  Container(width: 80, height: 12, color: Colors.white),
                ],
              ),
              Container(width: 30, height: 30, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(
          2,
          (index) => ListTile(
            title: Container(width: 150, height: 16, color: Colors.white),
            subtitle: Container(width: 100, height: 12, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
