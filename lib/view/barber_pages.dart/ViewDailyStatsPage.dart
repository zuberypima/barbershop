import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class ViewDailyStatsPage extends StatefulWidget {
  const ViewDailyStatsPage({super.key});

  @override
  State<ViewDailyStatsPage> createState() => _ViewDailyStatsPageState();
}

class _ViewDailyStatsPageState extends State<ViewDailyStatsPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;
  Map<DateTime, Map<String, dynamic>?> _statsCache = {};

  // Reference to the barber's document
  DocumentReference get _barberRef {
    final email = _auth.currentUser?.email;
    if (email == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('BarbersDetails').doc(email);
  }

  // Fetch stats for the selected date with fallback creation
  Future<Map<String, dynamic>> _fetchStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final dateKey = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    if (_statsCache.containsKey(dateKey)) {
      setState(() => _isLoading = false);
      return _statsCache[dateKey] ?? _createDefaultStats();
    }

    try {
      final date = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final statsDoc = await _barberRef
          .collection('DailyStats')
          .doc(date)
          .get()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw Exception(
                'Request timed out. Please check your network connection.',
              );
            },
          );

      if (!statsDoc.exists) {
        // Create default stats document
        final defaultStats = await _createDefaultStats();
        await _barberRef.collection('DailyStats').doc(date).set(defaultStats);
        _statsCache[dateKey] = defaultStats;
        setState(() => _isLoading = false);
        return defaultStats;
      }

      final data = statsDoc.data() as Map<String, dynamic>;
      _statsCache[dateKey] = data;
      return data;
    } catch (e) {
      print('Error fetching stats: $e'); // Debug log
      setState(() {
        _errorMessage = 'Error: $e';
      });
      return _createDefaultStats(); // Fallback to default stats on error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Create default stats with serviceEarnings based on BarbersDetails services
  Future<Map<String, dynamic>> _createDefaultStats() async {
    final barberDoc = await _barberRef.get();
    final services = barberDoc['services'] as List<dynamic>? ?? [];
    final serviceEarnings = {
      for (var service in services) service['name']: 0.0,
    };

    return {
      'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'dailyEarnings': 0.0,
      'dailyCustomers': 0,
      'dailyQueue': 0,
      'dailyBookings': 0,
      'serviceEarnings': serviceEarnings,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  // Show date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade800,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Refresh stats
  void _refreshStats() {
    _statsCache.clear(); // Clear cache to force refetch
    setState(() {});
  }

  @override
  void dispose() {
    _statsCache.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Daily Statistics',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: () => _selectDate(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshStats,
          ),
        ],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Header
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Stats for ${DateFormat('MMMM d, yyyy').format(_selectedDate)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _selectDate(context),
                          icon: const Icon(Icons.date_range, size: 18),
                          label: Text(
                            'Change Date',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Stats Summary
                FutureBuilder<Map<String, dynamic>>(
                  future: _fetchStats(),
                  builder: (context, snapshot) {
                    if (_isLoading || !snapshot.hasData) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummarySkeleton(),
                          const SizedBox(height: 20),
                          Text(
                            'Service Earnings',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildServiceEarningsSkeleton(),
                        ],
                      );
                    }

                    if (_errorMessage != null) {
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            children: [
                              Text(
                                _errorMessage!,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _refreshStats,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade800,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Retry',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final stats = snapshot.data!;
                    final dailyEarnings =
                        (stats['dailyEarnings'] as num?)?.toDouble() ?? 0.0;
                    final dailyCustomers = stats['dailyCustomers'] ?? 0;
                    final dailyQueue = stats['dailyQueue'] ?? 0;
                    final dailyBookings = stats['dailyBookings'] ?? 0;
                    final serviceEarnings =
                        stats['serviceEarnings'] as Map<String, dynamic>? ?? {};

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Card
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Summary',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatItem(
                                      'Earnings',
                                      'Tzs ${dailyEarnings.toStringAsFixed(2)}',
                                      Icons.attach_money,
                                    ),
                                    _buildStatItem(
                                      'Customers',
                                      dailyCustomers.toString(),
                                      Icons.people,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatItem(
                                      'Queue',
                                      dailyQueue.toString(),
                                      Icons.queue,
                                    ),
                                    _buildStatItem(
                                      'Bookings',
                                      dailyBookings.toString(),
                                      Icons.calendar_today,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Service Earnings
                        Text(
                          'Service Earnings',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child:
                                serviceEarnings.isEmpty
                                    ? Text(
                                      'No service earnings recorded',
                                      style: GoogleFonts.poppins(),
                                    )
                                    : Column(
                                      children:
                                          serviceEarnings.entries.map((entry) {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 5,
                                                  ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    entry.key,
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Tzs ${(entry.value as num).toDouble().toStringAsFixed(2)}',
                                                    style: GoogleFonts.poppins(
                                                      color:
                                                          Colors.green.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                    ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Skeleton for Summary Card
  Widget _buildSummarySkeleton() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(width: 100, height: 20, color: Colors.white),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(2, (index) => _buildStatSkeleton()),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(2, (index) => _buildStatSkeleton()),
            ),
          ],
        ),
      ),
    );
  }

  // Skeleton for Service Earnings
  Widget _buildServiceEarningsSkeleton() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: List.generate(
            1, // Reduced for performance
            (index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 80, height: 16, color: Colors.white),
                    Container(width: 50, height: 16, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Skeleton for individual stat item
  Widget _buildStatSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Container(width: 60, height: 18, color: Colors.white),
          const SizedBox(height: 5),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 16, height: 16, color: Colors.white),
              const SizedBox(width: 5),
              Container(width: 40, height: 12, color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}
