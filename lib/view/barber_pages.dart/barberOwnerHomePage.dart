import 'package:barber/services/navigator.dart';
import 'package:barber/view/barber_pages.dart/ManageServicesPage.dart';
import 'package:barber/view/barber_pages.dart/QueueManagerPage.dart';
import 'package:barber/view/barber_pages.dart/ViewDailyStatsPage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class BarberOwnerHomePage extends StatelessWidget {
  const BarberOwnerHomePage({super.key});

  // Reference to the current user's barber document
  DocumentReference get _barberRef {
    final email = FirebaseAuth.instance.currentUser?.email;
    return FirebaseFirestore.instance.collection('BarbersDetails').doc(email);
  }

  // Logout function
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
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
            final shopName = snapshot.data?['shopName'] ?? 'My Barber Shop';
            return Text(
              shopName,
              style: GoogleFonts.poppins(color: Colors.white),
            );
          },
        ),
        backgroundColor: Colors.blue.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
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
            child: Column(
              children: [
                // Shop Overview Card
                StreamBuilder<DocumentSnapshot>(
                  stream: _barberRef.snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return _buildShopOverviewSkeleton();
                    }

                    final barberData =
                        snapshot.data!.data() as Map<String, dynamic>? ?? {};
                    final rating = barberData['rating']?.toDouble() ?? 0.0;
                    final totalRatings = barberData['totalRatings'] ?? 0;
                    final serviceStandard =
                        barberData['serviceStandard'] ?? 'Not set';

                    return Card(
                      margin: const EdgeInsets.all(15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage:
                                      barberData['profileImageUrl'] != null
                                          ? NetworkImage(
                                            barberData['profileImageUrl'],
                                          )
                                          : const AssetImage(
                                                'assets/images/default_barber.jpg',
                                              )
                                              as ImageProvider,
                                  backgroundColor: Colors.blue.shade100,
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        barberData['shopName'] ??
                                            'My Barber Shop',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Standard: $serviceStandard',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
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
                                            '${rating.toStringAsFixed(1)} ($totalRatings reviews)',
                                            style: GoogleFonts.poppins(),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color: Colors.blue.shade800,
                                  ),
                                  onPressed: () {
                                    // Navigate to edit profile page
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            StreamBuilder<DocumentSnapshot>(
                              stream:
                                  _barberRef
                                      .collection('DailyStats')
                                      .doc(
                                        DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(DateTime.now()),
                                      )
                                      .snapshots(),
                              builder: (context, statsSnapshot) {
                                final statsData =
                                    statsSnapshot.data?.data()
                                        as Map<String, dynamic>? ??
                                    {};
                                final todayEarnings =
                                    statsData['dailyEarnings']?.toDouble() ??
                                    0.0;
                                final dailyCustomers =
                                    statsData['dailyCustomers'] ?? 0;
                                final dailyBookings =
                                    statsData['dailyBookings'] ?? 0;

                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatItem(
                                      'Customers',
                                      dailyCustomers.toString(),
                                      Icons.people,
                                    ),
                                    _buildStatItem(
                                      'Bookings',
                                      dailyBookings.toString(),
                                      Icons.calendar_today,
                                    ),
                                    _buildStatItem(
                                      'Earnings',
                                      '\$${todayEarnings.toStringAsFixed(2)}',
                                      Icons.attach_money,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Quick Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _buildQuickAction('Manage Queue', Icons.queue, () {
                        push_next_page(context, QueueManagerPage());
                      }),
                      _buildQuickAction('Manage Service', Icons.add_circle, () {
                        push_next_page(context, ManageServicesPage());
                      }),
                      _buildQuickAction(
                        'View Bookings',
                        Icons.calendar_month,
                        () {
                          // Navigate to bookings
                        },
                      ),
                      _buildQuickAction('Daily Stats', Icons.bar_chart, () {
                        push_next_page(context, ViewDailyStatsPage());
                      }),
                    ],
                  ),
                ),

                // Current Queue
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Current Queue',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            child: Text(
                              'Manage',
                              style: GoogleFonts.poppins(
                                color: Colors.blue.shade800,
                              ),
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: StreamBuilder<QuerySnapshot>(
                          stream:
                              _barberRef
                                  .collection('queue')
                                  .orderBy('timestamp')
                                  .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return _buildQueueSkeleton();
                            }

                            final queueItems = snapshot.data!.docs;

                            if (queueItems.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(15),
                                child: Text(
                                  'No customers in queue',
                                  style: GoogleFonts.poppins(),
                                ),
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                children: [
                                  for (
                                    var i = 0;
                                    i < queueItems.length;
                                    i++
                                  ) ...[
                                    if (i > 0) const Divider(),
                                    _buildQueueItem(
                                      queueItems[i]['customerName'] ??
                                          'Unknown',
                                      queueItems[i]['service'] ??
                                          'Not specified',
                                      i == 0 ? 'Now' : '${i * 15} min',
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Services Offered',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            child: Text(
                              'Edit',
                              style: GoogleFonts.poppins(
                                color: Colors.blue.shade800,
                              ),
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: StreamBuilder<DocumentSnapshot>(
                          stream: _barberRef.snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return _buildServicesSkeleton();
                            }

                            final services =
                                snapshot.data!['services'] as List<dynamic>? ??
                                [];

                            if (services.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(15),
                                child: Text(
                                  'No services listed',
                                  style: GoogleFonts.poppins(),
                                ),
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                children:
                                    services
                                        .map(
                                          (service) => _buildServiceItem(
                                            service['name'] ?? 'Unknown',
                                            service['priceRange'] ??
                                                'Not specified',
                                          ),
                                        )
                                        .toList(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Business Insights
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Business Insights',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: StreamBuilder<DocumentSnapshot>(
                          stream:
                              _barberRef
                                  .collection('TotalStats')
                                  .doc('aggregate')
                                  .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return _buildInsightsSkeleton();
                            }

                            final stats =
                                snapshot.data!.data()
                                    as Map<String, dynamic>? ??
                                {};
                            final totalCustomers = stats['totalCustomers'] ?? 0;

                            return StreamBuilder<QuerySnapshot>(
                              stream:
                                  _barberRef
                                      .collection('DailyStats')
                                      .orderBy('timestamp', descending: true)
                                      .limit(7)
                                      .snapshots(),
                              builder: (context, weekSnapshot) {
                                double weeklyEarnings = 0;
                                int weeklyCustomers = 0;

                                if (weekSnapshot.hasData) {
                                  for (var doc in weekSnapshot.data!.docs) {
                                    weeklyEarnings +=
                                        (doc['dailyEarnings'] as num?)
                                            ?.toDouble() ??
                                        0.0;
                                    weeklyCustomers +=
                                        (doc['dailyCustomers'] as num?)
                                            ?.toInt() ??
                                        0;
                                  }
                                }

                                return Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'This Week',
                                            style: GoogleFonts.poppins(),
                                          ),
                                          Text(
                                            '\$${weeklyEarnings.toStringAsFixed(2)}',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      LinearProgressIndicator(
                                        value:
                                            weeklyEarnings > 0
                                                ? (weeklyEarnings / 2000).clamp(
                                                  0.0,
                                                  1.0,
                                                )
                                                : 0.0,
                                        backgroundColor: Colors.grey[200],
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.blue.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '$weeklyCustomers customers this week',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            '$totalCustomers total customers',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // bottomNavigationBar: BottomNavigationBar(
      //   selectedItemColor: Colors.blue.shade800,
      //   unselectedItemColor: Colors.grey,
      //   items: const [
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.dashboard),
      //       label: 'Dashboard',
      //     ),
      //     BottomNavigationBarItem(icon: Icon(Icons.queue), label: 'Queue'),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.insights),
      //       label: 'Insights',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.settings),
      //       label: 'Settings',
      //     ),
      //   ],
      //   onTap: (index) {
      //     // Handle navigation
      //   },
      // ),
    );
  }

  // Skeleton loading widgets
  Widget _buildShopOverviewSkeleton() {
    return Card(
      margin: const EdgeInsets.all(15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 150,
                          height: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 100,
                          height: 15,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(width: 24, height: 24, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(3, (index) => _buildStatSkeleton()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: List.generate(
          3,
          (index) => Column(
            children: [
              if (index > 0) const Divider(),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.white),
                  title: Container(width: 100, height: 16, color: Colors.white),
                  subtitle: Container(
                    width: 150,
                    height: 12,
                    color: Colors.white,
                  ),
                  trailing: Container(
                    width: 50,
                    height: 24,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: List.generate(
          2,
          (index) => Column(
            children: [
              if (index > 0) const Divider(),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: ListTile(
                  title: Container(width: 150, height: 16, color: Colors.white),
                  subtitle: Container(
                    width: 100,
                    height: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightsSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(width: 80, height: 16, color: Colors.white),
              ),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(width: 60, height: 16, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 8,
              width: double.infinity,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(width: 100, height: 12, color: Colors.white),
              ),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(width: 80, height: 12, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Container(width: 30, height: 18, color: Colors.white),
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

  Widget _buildQuickAction(
    String title,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.blue.shade800),
      label: Text(
        title,
        style: GoogleFonts.poppins(color: Colors.blue.shade800),
      ),
      style: ElevatedButton.styleFrom(
        alignment: Alignment.centerLeft,
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildQueueItem(String name, String service, String time) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade100,
        child: Text(
          name.isNotEmpty ? name[0] : '?',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
      ),
      title: Text(name, style: GoogleFonts.poppins()),
      subtitle: Text(
        service,
        style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
      ),
      trailing: Chip(
        label: Text(time),
        backgroundColor:
            time == 'Now' ? Colors.green.shade100 : Colors.grey.shade200,
        labelStyle: GoogleFonts.poppins(
          color: time == 'Now' ? Colors.green.shade800 : Colors.black,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildServiceItem(String name, String priceRange) {
    return ListTile(
      title: Text(name, style: GoogleFonts.poppins()),
      subtitle: Text(
        'Price: $priceRange',
        style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
      ),
    );
  }
}
