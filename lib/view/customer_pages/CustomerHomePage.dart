import 'package:barber/services/navigator.dart';
import 'package:barber/view/barber_pages.dart/BarberShopsPage.dart';
import 'package:barber/view/customer_pages/NearbyBarbersPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:geolocator/geolocator.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final _searchController = TextEditingController();
  GeoPoint? _customerLocation;
  int _loyaltyPoints = 0;

  @override
  void initState() {
    super.initState();
    _fetchCustomerData();
  }

  // Fetch customer data (location, loyalty points)
  Future<void> _fetchCustomerData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('CustomersDetails')
          .doc(user.email)
          .get()
          .timeout(const Duration(seconds: 5));

      if (doc.exists) {
        setState(() {
          _customerLocation = doc.data()?['location'] as GeoPoint?;
          _loyaltyPoints = doc.data()?['loyaltyPoints'] as int? ?? 0;
        });
      }
    } catch (e) {
      print('Error fetching customer data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load customer data: $e')),
      );
    }
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission permanently denied'),
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 5));
      setState(() {
        _customerLocation = GeoPoint(position.latitude, position.longitude);
      });

      // Update customer location in Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('CustomersDetails')
            .doc(user.email)
            .update({'location': _customerLocation});
      }
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
    }
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Find Your Barber',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // Implement notifications
            },
          ),
        ],
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
              // Location-based search
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find Nearby Barbers',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.blue.shade800,
                              ),
                              hintText: 'Search by name or address',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {}); // Trigger rebuild for search
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: Icon(Icons.my_location, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                          ),
                          onPressed: _getCurrentLocation,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Featured Barbers
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Featured Barbers',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        TextButton(
                          child: Text(
                            'See all',
                            style: GoogleFonts.poppins(
                              color: Colors.blue.shade800,
                            ),
                          ),
                          onPressed: () {
                            push_next_page(context, const BarberShopsPage());
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('BarbersDetails')
                              .where('rating', isGreaterThanOrEqualTo: 4.0)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 3,
                              itemBuilder: (context, index) {
                                return _buildFeaturedBarberSkeleton();
                              },
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Text(
                            'Error: ${snapshot.error}',
                            style: GoogleFonts.poppins(),
                          );
                        }
                        final docs =
                            snapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final name =
                                  data['fullName']?.toString().toLowerCase() ??
                                  '';
                              final address =
                                  data['address']?.toString().toLowerCase() ??
                                  '';
                              final search =
                                  _searchController.text.toLowerCase();
                              return name.contains(search) ||
                                  address.contains(search);
                            }).toList();
                        if (docs.isEmpty) {
                          return Text(
                            'No featured barbers found',
                            style: GoogleFonts.poppins(color: Colors.grey),
                          );
                        }
                        return SizedBox(
                          height: 180,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data =
                                  docs[index].data() as Map<String, dynamic>;
                              return _buildFeaturedBarberCard(data);
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Services Categories
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Services',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      children: [
                        _buildServiceCategory('Haircut', Icons.cut),
                        _buildServiceCategory('Beard', Icons.face),
                        _buildServiceCategory('Shave', Icons.radar),
                        _buildServiceCategory('Color', Icons.palette),
                      ],
                    ),
                  ],
                ),
              ),

              // Nearby Barbers
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Near You',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        TextButton(
                          child: Text(
                            'See all',
                            style: GoogleFonts.poppins(
                              color: Colors.blue.shade800,
                            ),
                          ),
                          onPressed: () {
                            push_next_page(context, NearbyBarbersPage());
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('BarbersDetails')
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Column(
                            children: List.generate(
                              3,
                              (index) => _buildBarberShopSkeleton(),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Text(
                            'Error: ${snapshot.error}',
                            style: GoogleFonts.poppins(),
                          );
                        }
                        final docs =
                            snapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final name =
                                  data['fullName']?.toString().toLowerCase() ??
                                  '';
                              final address =
                                  data['address']?.toString().toLowerCase() ??
                                  '';
                              final search =
                                  _searchController.text.toLowerCase();
                              return name.contains(search) ||
                                  address.contains(search);
                            }).toList();
                        // Sort by distance if customer location is available
                        if (_customerLocation != null) {
                          docs.sort((a, b) {
                            final aData = a.data() as Map<String, dynamic>;
                            final bData = b.data() as Map<String, dynamic>;
                            final aLoc = aData['location'] as GeoPoint?;
                            final bLoc = bData['location'] as GeoPoint?;
                            final aDist =
                                aLoc != null
                                    ? Geolocator.distanceBetween(
                                          _customerLocation!.latitude,
                                          _customerLocation!.longitude,
                                          aLoc.latitude,
                                          aLoc.longitude,
                                        ) /
                                        1000 // Convert to km
                                    : double.infinity;
                            final bDist =
                                bLoc != null
                                    ? Geolocator.distanceBetween(
                                          _customerLocation!.latitude,
                                          _customerLocation!.longitude,
                                          bLoc.latitude,
                                          bLoc.longitude,
                                        ) /
                                        1000
                                    : double.infinity;
                            return aDist.compareTo(bDist);
                          });
                        }
                        if (docs.isEmpty) {
                          return Text(
                            'No barbers found',
                            style: GoogleFonts.poppins(color: Colors.grey),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data =
                                docs[index].data() as Map<String, dynamic>;
                            final barberLoc = data['location'] as GeoPoint?;
                            final distance =
                                _customerLocation != null && barberLoc != null
                                    ? Geolocator.distanceBetween(
                                          _customerLocation!.latitude,
                                          _customerLocation!.longitude,
                                          barberLoc.latitude,
                                          barberLoc.longitude,
                                        ) /
                                        1000
                                    : null;
                            return _buildBarberShopCard(
                              barberData: data,
                              distance: distance,
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Loyalty Program
              Padding(
                padding: const EdgeInsets.all(15),
                child: Card(
                  color: Colors.blue.shade800,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.card_giftcard, color: Colors.white),
                            const SizedBox(width: 10),
                            Text(
                              'Loyalty Program',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '5 visits = 1 free haircut!',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: _loyaltyPoints / 5.0,
                          backgroundColor: Colors.blue.shade200,
                          valueColor: const AlwaysStoppedAnimation(
                            Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '$_loyaltyPoints/5 visits completed',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
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

  Widget _buildFeaturedBarberCard(Map<String, dynamic> data) {
    final name = data['fullName'] as String? ?? 'No Name';
    final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
    final totalRatings = data['totalRatings'] as int? ?? 0;
    final imageUrl = data['profileImageUrl'] as String? ?? '';

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 10),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            print('Tapped on $name');
            // Navigate to barber details
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child:
                    imageUrl.isNotEmpty
                        ? Image.network(
                          imageUrl,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 100,
                              color: Colors.blue.shade100,
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.blue.shade800,
                              ),
                            );
                          },
                        )
                        : Container(
                          height: 100,
                          color: Colors.blue.shade100,
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.blue.shade800,
                          ),
                        ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        Text(
                          ' ($totalRatings)',
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
        ),
      ),
    );
  }

  Widget _buildFeaturedBarberSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 10),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 100,
                width: double.infinity,
                color: Colors.white,
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 100, height: 16, color: Colors.white),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(width: 16, height: 16, color: Colors.white),
                        const SizedBox(width: 5),
                        Container(width: 40, height: 12, color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCategory(String name, IconData icon) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.blue.shade100,
          child: Icon(icon, color: Colors.blue.shade800),
        ),
        const SizedBox(height: 5),
        Text(name, style: GoogleFonts.poppins(fontSize: 12)),
      ],
    );
  }

  Widget _buildBarberShopCard({
    required Map<String, dynamic> barberData,
    double? distance,
  }) {
    final name = barberData['fullName'] as String? ?? 'No Name';
    final rating = (barberData['rating'] as num?)?.toDouble() ?? 0.0;
    final totalRatings = barberData['totalRatings'] as int? ?? 0;
    final imageUrl = barberData['profileImageUrl'] as String? ?? '';
    final address = barberData['address'] as String? ?? 'No address';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          print('Tapped on $name');
          // Navigate to barber details
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
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
                          errorBuilder: (context, error, stackTrace) {
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
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      address,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        Text(
                          ' ($totalRatings)',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    if (distance != null) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey,
                          ),
                          Text(
                            '${distance.toStringAsFixed(1)} km away',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.blue),
                onPressed: () {
                  // Implement favorite functionality
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarberShopSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(width: 70, height: 70, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 150, height: 16, color: Colors.white),
                    const SizedBox(height: 5),
                    Container(width: 100, height: 12, color: Colors.white),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(width: 16, height: 16, color: Colors.white),
                        const SizedBox(width: 5),
                        Container(width: 60, height: 12, color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 40, height: 40, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
