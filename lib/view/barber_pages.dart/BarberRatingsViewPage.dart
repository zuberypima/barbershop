import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

// Custom Star Rating Widget
class StarRating extends StatefulWidget {
  final double initialRating;
  final Function(double) onRatingChanged;

  const StarRating({
    super.key,
    this.initialRating = 0.0,
    required this.onRatingChanged,
  });

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < _rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _rating = index + 1.0;
              widget.onRatingChanged(_rating);
            });
          },
        );
      }),
    );
  }
}

class BarberRatingsViewPage extends StatefulWidget {
  const BarberRatingsViewPage({super.key});

  @override
  State<BarberRatingsViewPage> createState() => _BarberRatingsViewPageState();
}

class _BarberRatingsViewPageState extends State<BarberRatingsViewPage> {
  final _currentUser = FirebaseAuth.instance.currentUser;

  // Reference to the barber's document
  DocumentReference get _barberRef {
    final email = _currentUser?.email;
    return FirebaseFirestore.instance.collection('BarbersDetails').doc(email);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'Ratings',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.blue.shade800,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 60, color: Colors.red[400]),
              const SizedBox(height: 20),
              Text(
                'User not authenticated. Please log in.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.red[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Go to Login',
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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'My Ratings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade800,
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
            // Summary Card
            Padding(
              padding: const EdgeInsets.all(15),
              child: StreamBuilder<DocumentSnapshot>(
                stream: _barberRef.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return _buildSummarySkeleton();
                  }
                  final data =
                      snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
                  final totalRatings = data['totalRatings'] as int? ?? 0;

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Average Rating',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  StarRating(
                                    initialRating: rating,
                                    onRatingChanged: (_) {}, // Read-only
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                ],
                              ),
                              Text(
                                '$totalRatings reviews',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.star_border,
                            color: Colors.blue.shade800,
                            size: 30,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Ratings List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    _barberRef
                        .collection('ratings')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return _buildRatingsSkeleton();
                  }
                  final ratings = snapshot.data!.docs;
                  if (ratings.isEmpty) {
                    return Center(
                      child: Text(
                        'No ratings yet.',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: ratings.length,
                    itemBuilder: (context, index) {
                      final ratingData =
                          ratings[index].data() as Map<String, dynamic>;
                      final rating =
                          (ratingData['rating'] as num?)?.toDouble() ?? 0.0;
                      final feedback = ratingData['feedback'] as String? ?? '';
                      final customerId =
                          ratingData['customerId'] as String? ?? 'Unknown';
                      final timestamp =
                          (ratingData['timestamp'] as Timestamp?)?.toDate();

                      return FutureBuilder<DocumentSnapshot>(
                        future:
                            FirebaseFirestore.instance
                                .collection('CustomersDetails')
                                .doc(customerId)
                                .get(),
                        builder: (context, customerSnapshot) {
                          final customerData =
                              customerSnapshot.data?.data()
                                  as Map<String, dynamic>? ??
                              {};
                          final customerName =
                              customerData['fullName'] as String? ??
                              'Anonymous';

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        customerName,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      StarRating(
                                        initialRating: rating,
                                        onRatingChanged: (_) {}, // Read-only
                                      ),
                                    ],
                                  ),
                                  if (feedback.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      feedback,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    timestamp != null
                                        ? '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}'
                                        : '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
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
  Widget _buildSummarySkeleton() {
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
                  Container(width: 120, height: 16, color: Colors.white),
                  const SizedBox(height: 5),
                  Container(width: 80, height: 12, color: Colors.white),
                  const SizedBox(height: 5),
                  Container(width: 60, height: 12, color: Colors.white),
                ],
              ),
              Container(width: 30, height: 30, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingsSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(
          3,
          (index) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(width: 100, height: 14, color: Colors.white),
                      Container(width: 80, height: 12, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(width: 200, height: 12, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: 60, height: 10, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
