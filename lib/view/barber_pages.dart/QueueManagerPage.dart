import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class QueueManagerPage extends StatefulWidget {
  const QueueManagerPage({super.key});

  @override
  State<QueueManagerPage> createState() => _QueueManagerPageState();
}

class _QueueManagerPageState extends State<QueueManagerPage> {
  String _selectedStatusFilter = 'All'; // Default filter

  // Reference to the barber's queue subcollection
  CollectionReference get _queueRef {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) {
      throw Exception('User not logged in');
    }
    return FirebaseFirestore.instance
        .collection('BarbersDetails')
        .doc(email)
        .collection('queue');
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

  // Update booking status
  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await _queueRef.doc(bookingId).update({'status': newStatus});

      // Update corresponding customer booking status
      final bookingDoc = await _queueRef.doc(bookingId).get();
      final bookingData = bookingDoc.data() as Map<String, dynamic>?;
      if (bookingData != null) {
        final customerId = bookingData['customerId'] as String?;
        if (customerId != null) {
          await FirebaseFirestore.instance
              .collection('CustomersDetails')
              .doc(customerId)
              .collection('bookings')
              .doc(bookingId)
              .update({'status': newStatus});
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking $newStatus successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
    }
  }

  // Fetch customer details
  Future<Map<String, dynamic>?> _getCustomerDetails(String customerId) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('CustomersDetails')
              .doc(customerId)
              .get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Manage Queue',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Status Filter
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Filter by Status:',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _selectedStatusFilter,
                    items:
                        ['All', 'Pending', 'Accepted', 'Rejected']
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(
                                  status,
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatusFilter = value!;
                      });
                    },
                    style: GoogleFonts.poppins(color: Colors.black),
                    dropdownColor: Colors.white,
                    iconEnabledColor: Colors.blue[800],
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    _selectedStatusFilter == 'All'
                        ? _queueRef
                            .orderBy('timestamp', descending: true)
                            .snapshots()
                        : _queueRef
                            .where(
                              'status',
                              isEqualTo: _selectedStatusFilter.toLowerCase(),
                            )
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
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
                              'Error loading queue: ${snapshot.error}',
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
                    return _buildQueueSkeleton();
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
                            'No ${_selectedStatusFilter.toLowerCase()} bookings in queue.',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Check other status filters or wait for new bookings.',
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
                      final bookingData =
                          booking.data() as Map<String, dynamic>;
                      final customerId =
                          bookingData['customerId'] as String? ?? '';
                      final customerName =
                          bookingData['customerName'] as String? ?? 'N/A';
                      final service =
                          bookingData['service'] as String? ?? 'N/A';
                      final status =
                          bookingData['status'] as String? ?? 'pending';
                      final timestamp =
                          (bookingData['timestamp'] as Timestamp?)?.toDate();
                      final bookingId = booking.id;

                      return FutureBuilder<Map<String, dynamic>?>(
                        future: _getCustomerDetails(customerId),
                        builder: (context, customerSnapshot) {
                          if (!customerSnapshot.hasData &&
                              customerId.isNotEmpty) {
                            return _buildQueueCardSkeleton();
                          }

                          final customerData = customerSnapshot.data;
                          final fullName =
                              customerData?['fullName'] as String? ??
                              customerName;

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
                                      Icon(
                                        Icons.person,
                                        color: Colors.blue[800],
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          fullName,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      Chip(
                                        label: Text(
                                          status.capitalize(),
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                        backgroundColor:
                                            status == 'pending'
                                                ? Colors.orange[600]
                                                : status == 'accepted'
                                                ? Colors.green[600]
                                                : Colors.red[600],
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
                                  if (status == 'pending') ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ElevatedButton(
                                          onPressed:
                                              () => _updateBookingStatus(
                                                bookingId,
                                                'accepted',
                                              ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green[600],
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                          ),
                                          child: Text(
                                            'Accept',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed:
                                              () => _updateBookingStatus(
                                                bookingId,
                                                'rejected',
                                              ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red[600],
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                          ),
                                          child: Text(
                                            'Reject',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Skeleton loading widgets
  Widget _buildQueueSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 3,
        itemBuilder: (context, index) {
          return _buildQueueCardSkeleton();
        },
      ),
    );
  }

  Widget _buildQueueCardSkeleton() {
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
                const Spacer(),
                Container(width: 60, height: 20, color: Colors.white),
              ],
            ),
            const SizedBox(height: 8),
            Container(width: 100, height: 14, color: Colors.white),
            const SizedBox(height: 4),
            Container(width: 80, height: 12, color: Colors.white),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(width: 60, height: 30, color: Colors.white),
                const SizedBox(width: 8),
                Container(width: 60, height: 30, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
