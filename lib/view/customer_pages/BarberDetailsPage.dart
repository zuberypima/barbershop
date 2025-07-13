import 'package:barber/view/barber_pages.dart/BarberMapDirectionsPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:barber/services/navigator.dart';

class BarberDetailsPage extends StatefulWidget {
  final String barberId; // Email or ID of the barber

  const BarberDetailsPage({super.key, required this.barberId});

  @override
  State<BarberDetailsPage> createState() => _BarberDetailsPageState();
}

class _BarberDetailsPageState extends State<BarberDetailsPage> {
  String? _selectedService;
  bool _isBooking = false;
  bool _canRate = false;

  // Reference to the barber's document
  DocumentReference get _barberRef => FirebaseFirestore.instance
      .collection('BarbersDetails')
      .doc(widget.barberId);

  // Reference to the current customer's document
  DocumentReference get _customerRef {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) {
      debugPrint('Error: Customer email is null');
      throw Exception('Customer email is null');
    }
    return FirebaseFirestore.instance.collection('CustomersDetails').doc(email);
  }

  @override
  void initState() {
    super.initState();
    _checkCanRate();
  }

  // Check if the customer has a completed booking to enable rating
  Future<void> _checkCanRate() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('Error: User not authenticated');
        return;
      }

      final bookingsSnapshot =
          await _customerRef
              .collection('bookings')
              .where('barberId', isEqualTo: widget.barberId)
              .where('status', isEqualTo: 'completed')
              .get();

      setState(() {
        _canRate = bookingsSnapshot.docs.isNotEmpty;
        debugPrint(
          'Can rate: $_canRate, Found ${bookingsSnapshot.docs.length} completed bookings',
        );
      });
    } catch (e) {
      debugPrint('Error checking rating eligibility: $e');
    }
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
      debugPrint(
        'Booking for customer: $customerName, service: $_selectedService',
      );

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
      debugPrint('Booking error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to book: $e')));
    } finally {
      setState(() {
        _isBooking = false;
      });
    }
  }

  // Submit a rating
  Future<void> _submitRating(int rating, String feedback) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Add rating to barber's ratings collection
      await _barberRef.collection('ratings').add({
        'customerId': user.email,
        'rating': rating,
        'feedback': feedback.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update barber's average rating and total ratings
      final ratingsSnapshot = await _barberRef.collection('ratings').get();
      final totalRatings = ratingsSnapshot.docs.length;
      final totalRatingSum = ratingsSnapshot.docs.fold<double>(
        0,
        (sum, doc) => sum + (doc['rating'] as num).toDouble(),
      );
      final averageRating =
          totalRatings > 0 ? totalRatingSum / totalRatings : 0.0;

      await _barberRef.update({
        'rating': averageRating,
        'totalRatings': totalRatings,
      });

      debugPrint(
        'Rating submitted: $rating, Feedback: $feedback, Average: $averageRating, Total: $totalRatings',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rating submitted successfully!')),
      );
    } catch (e) {
      debugPrint('Rating submission error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to submit rating: $e')));
    }
  }

  // Show rating popup
  void _showRatingDialog() {
    int? rating;
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              'Rate Barber',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<int>(
                  hint: Text('Select rating', style: GoogleFonts.poppins()),
                  value: rating,
                  items:
                      [1, 2, 3, 4, 5].map((value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(
                            '$value Stars',
                            style: GoogleFonts.poppins(),
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      rating = value;
                    });
                  },
                  isExpanded: true,
                  underline: Container(height: 1, color: Colors.blue.shade800),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: feedbackController,
                  decoration: InputDecoration(
                    hintText: 'Optional feedback',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (rating == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a rating')),
                    );
                    return;
                  }
                  _submitRating(rating!, feedbackController.text);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Submit',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
    );
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
                                            debugPrint(
                                              'Image load error: $error',
                                            );
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
                                        Text(
                                          rating.toStringAsFixed(1),
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Row(
                                          children: List.generate(5, (index) {
                                            return Icon(
                                              index < rating.round()
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: Colors.amber,
                                              size: 16,
                                            );
                                          }),
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

              // Rate Barber Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canRate ? _showRatingDialog : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _canRate ? Colors.blue.shade600 : Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Rate Barber',
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
