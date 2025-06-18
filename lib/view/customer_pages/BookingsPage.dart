import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<QueryDocumentSnapshot> _bookings = [];

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw 'No user logged in';
      }

      final querySnapshot = await _firestore
          .collection('Bookings')
          .where('customerEmail', isEqualTo: user.email)
          .orderBy('dateTime', descending: true)
          .get()
          .timeout(const Duration(seconds: 5));

      setState(() {
        _bookings = querySnapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load bookings: $e')));
      }
    }
  }

  Future<void> _cancelBooking(String bookingId, int loyaltyPoints) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw 'No user logged in';
      }

      await _firestore
          .collection('Bookings')
          .doc(bookingId)
          .update({'status': 'cancelled'})
          .timeout(const Duration(seconds: 5));

      // Optionally adjust loyalty points if already awarded
      if (loyaltyPoints > 0) {
        await _firestore
            .collection('CustomersDetails')
            .doc(user.email)
            .update({'loyaltyPoints': FieldValue.increment(-loyaltyPoints)})
            .timeout(const Duration(seconds: 5));
      }

      await _fetchBookings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to cancel booking: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Bookings',
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
              ? _buildSkeletonLoader(context)
              : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.blue.shade50, Colors.white],
                  ),
                ),
                child:
                    _bookings.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _bookings.length,
                          itemBuilder: (context, index) {
                            final booking =
                                _bookings[index].data() as Map<String, dynamic>;
                            final bookingId = _bookings[index].id;
                            final dateTime =
                                (booking['dateTime'] as Timestamp?)?.toDate();
                            final status =
                                booking['status'] as String? ?? 'Unknown';
                            final isUpcoming =
                                status == 'confirmed' &&
                                dateTime != null &&
                                dateTime.isAfter(DateTime.now());
                            final formattedDate =
                                dateTime != null
                                    ? DateFormat(
                                      'MMM d, yyyy, h:mm a',
                                    ).format(dateTime)
                                    : 'N/A';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            color: Colors.blue.shade800,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              booking['barberName'] ??
                                                  'Unknown Barber',
                                              style: GoogleFonts.poppins(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue.shade800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        booking['barberAddress'] ??
                                            'No address',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildBookingDetail(
                                        Icons.cut,
                                        'Service',
                                        booking['service'] ?? 'N/A',
                                      ),
                                      const SizedBox(height: 8),
                                      _buildBookingDetail(
                                        Icons.schedule,
                                        'Date & Time',
                                        formattedDate,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildBookingDetail(
                                        Icons.info_outline,
                                        'Status',
                                        status.capitalize(),
                                      ),
                                      if (booking['loyaltyPointsEarned'] !=
                                              null &&
                                          booking['loyaltyPointsEarned'] > 0)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: _buildBookingDetail(
                                            Icons.loyalty,
                                            'Loyalty Points',
                                            '+${booking['loyaltyPointsEarned']} points',
                                          ),
                                        ),
                                      if (isUpcoming)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 16,
                                          ),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton(
                                              onPressed:
                                                  () => _cancelBooking(
                                                    bookingId,
                                                    booking['loyaltyPointsEarned'] ??
                                                        0,
                                                  ),
                                              style: OutlinedButton.styleFrom(
                                                side: BorderSide(
                                                  color: Colors.red.shade600,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: Text(
                                                'Cancel Booking',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.red.shade600,
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
                          },
                        ),
              ),
      floatingActionButton:
          _isLoading
              ? null
              : FloatingActionButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/book');
                },
                backgroundColor: Colors.blue.shade800,
                child: const Icon(Icons.add, color: Colors.white),
                tooltip: 'Book Appointment',
              ),
    );
  }

  Widget _buildBookingDetail(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue.shade600, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 80,
              color: Colors.blue.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No Bookings Yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Book your next appointment to get started!',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/book');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Book Now',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: 3, // Simulate 3 loading cards
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 24, height: 24, color: Colors.white),
                        const SizedBox(width: 12),
                        Container(width: 150, height: 18, color: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(width: 200, height: 14, color: Colors.white),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(width: 20, height: 20, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 80,
                                height: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 120,
                                height: 14,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(width: 20, height: 20, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 80,
                                height: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 120,
                                height: 14,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(width: 20, height: 20, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 80,
                                height: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 120,
                                height: 14,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
