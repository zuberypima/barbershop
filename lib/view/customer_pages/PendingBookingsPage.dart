import 'package:barber/view/customer_pages/BarberDetailsPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:barber/services/navigator.dart'; // Assuming your navigator service

class PendingBookingsPage extends StatefulWidget {
  const PendingBookingsPage({super.key});

  @override
  State<PendingBookingsPage> createState() => _PendingBookingsPageState();
}

class _PendingBookingsPageState extends State<PendingBookingsPage> {
  // Reference to the current customer's bookings subcollection
  CollectionReference get _bookingsRef {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) {
      throw Exception('User not logged in');
    }
    return FirebaseFirestore.instance
        .collection('CustomersDetails')
        .doc(email)
        .collection('bookings');
  }

  // Logout function
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
    }
  }

  // Fetch barber details for a booking
  Future<Map<String, dynamic>?> _getBarberDetails(String barberId) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('BarbersDetails')
              .doc(barberId)
              .get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  // Estimate wait time based on queue position
  Future<int> _getEstimatedWaitTime(String barberId, String bookingId) async {
    try {
      final queueSnapshot =
          await FirebaseFirestore.instance
              .collection('BarbersDetails')
              .doc(barberId)
              .collection('queue')
              .where('status', isEqualTo: 'pending')
              .orderBy('timestamp')
              .get();
      final queue = queueSnapshot.docs;
      final position = queue.indexWhere((doc) => doc.id == bookingId) + 1;
      return position * 15; // 15 minutes per customer
    } catch (e) {
      return 0; // Default to 0 if error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              _bookingsRef.where('status', isEqualTo: 'pending').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 60, color: Colors.red[400]),
                      const SizedBox(height: 20),
                      Text(
                        'Error loading bookings: ${snapshot.error}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.red[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!snapshot.hasData) {
              return _buildBookingsSkeleton();
            }

            final bookings = snapshot.data!.docs;
            if (bookings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.hourglass_empty,
                      size: 60,
                      color: Colors.blue[400],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No pending bookings found.',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Book a service to get started!',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                final bookingData = booking.data() as Map<String, dynamic>;
                final barberId = bookingData['barberId'] as String? ?? '';
                final service = bookingData['service'] as String? ?? 'N/A';
                final timestamp =
                    (bookingData['timestamp'] as Timestamp?)?.toDate();
                final bookingId = booking.id;

                return FutureBuilder<Map<String, dynamic>?>(
                  future: _getBarberDetails(barberId),
                  builder: (context, barberSnapshot) {
                    if (!barberSnapshot.hasData) {
                      return _buildBookingCardSkeleton();
                    }

                    final barberData = barberSnapshot.data;
                    final shopName =
                        barberData?['shopName'] as String? ?? 'Unknown Shop';

                    return FutureBuilder<int>(
                      future: _getEstimatedWaitTime(barberId, bookingId),
                      builder: (context, waitTimeSnapshot) {
                        final waitTime = waitTimeSnapshot.data ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                if (barberId.isNotEmpty) {
                                  push_next_page(
                                    context,
                                    BarberDetailsPage(barberId: barberId),
                                  );
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.store,
                                          color: Colors.blue[800],
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            shopName,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Service: $service',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      timestamp != null
                                          ? 'Booked: ${timestamp.toLocal().toString().split('.')[0]}'
                                          : 'Booked: N/A',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Est. Wait: $waitTime min',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.blue[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Chip(
                                        label: Text(
                                          'Pending',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                        backgroundColor: Colors.orange[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Skeleton loading widgets
  Widget _buildBookingsSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 3,
        itemBuilder: (context, index) {
          return _buildBookingCardSkeleton();
        },
      ),
    );
  }

  Widget _buildBookingCardSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 24, height: 24, color: Colors.white),
                const SizedBox(width: 8),
                Container(width: 150, height: 16, color: Colors.white),
              ],
            ),
            const SizedBox(height: 8),
            Container(width: 100, height: 14, color: Colors.white),
            const SizedBox(height: 4),
            Container(width: 80, height: 12, color: Colors.white),
            const SizedBox(height: 4),
            Container(width: 60, height: 12, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
