import 'package:barber/view/customer_pages/BarberDetailsPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barber/services/navigator.dart'; // Assuming this is your navigator service

class NearbyBarbersPage extends StatefulWidget {
  const NearbyBarbersPage({super.key});

  @override
  State<NearbyBarbersPage> createState() => _NearbyBarbersPageState();
}

class _NearbyBarbersPageState extends State<NearbyBarbersPage> {
  Position? _currentPosition;
  List<DocumentSnapshot> _nearbyBarbers = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAndFetchBarbers();
  }

  Future<void> _getCurrentLocationAndFetchBarbers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled.';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permissions are denied.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage =
              'Location permissions are permanently denied, we cannot request permissions.';
          _isLoading = false;
        });
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition();
      await _fetchNearbyBarbers();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchNearbyBarbers() async {
    if (_currentPosition == null) {
      return;
    }

    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('BarbersDetails').get();

      setState(() {
        _nearbyBarbers =
            snapshot.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              if (data != null &&
                  data.containsKey('latitude') &&
                  data.containsKey('longitude')) {
                final barberLatitude = data['latitude'] as double?;
                final barberLongitude = data['longitude'] as double?;

                if (barberLatitude != null && barberLongitude != null) {
                  final distanceInMeters = Geolocator.distanceBetween(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                    barberLatitude,
                    barberLongitude,
                  );
                  return distanceInMeters <= 5000; // 5km radius
                }
              }
              return false;
            }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching barbers: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Barbers Near You',
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
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      strokeWidth: 5,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Finding barbers near you...',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              )
              : _errorMessage != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 60,
                        color: Colors.red[400],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _errorMessage!,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.red[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _getCurrentLocationAndFetchBarbers,
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
                          'Try Again',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : _nearbyBarbers.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 60, color: Colors.blue[400]),
                    const SizedBox(height: 20),
                    Text(
                      'No barbers found near your location.',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Try expanding your search radius.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.blue[800]),
                        const SizedBox(width: 8),
                        Text(
                          'Nearby Barbers (${_nearbyBarbers.length})',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[800],
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.refresh, color: Colors.blue[800]),
                          onPressed: _getCurrentLocationAndFetchBarbers,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _nearbyBarbers.length,
                      itemBuilder: (context, index) {
                        final barberData =
                            _nearbyBarbers[index].data()
                                as Map<String, dynamic>?;

                        if (barberData == null) {
                          return const SizedBox.shrink();
                        }

                        final fullName =
                            barberData['fullName'] as String? ?? 'N/A';
                        final shopName =
                            barberData['shopName'] as String? ?? 'N/A';
                        final profileImageUrl =
                            barberData['profileImageUrl'] as String?;
                        final latitude = barberData['latitude'] as double?;
                        final longitude = barberData['longitude'] as double?;

                        double? distance;
                        if (_currentPosition != null &&
                            latitude != null &&
                            longitude != null) {
                          distance = Geolocator.distanceBetween(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                            latitude,
                            longitude,
                          );
                        }

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
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
                                // Navigate to BarberDetailsPage using barberEmail as document ID
                                push_next_page(
                                  context,
                                  BarberDetailsPage(
                                    barberId: _nearbyBarbers[index].id,
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        image:
                                            profileImageUrl != null
                                                ? DecorationImage(
                                                  image: NetworkImage(
                                                    profileImageUrl,
                                                  ),
                                                  fit: BoxFit.cover,
                                                )
                                                : const DecorationImage(
                                                  image: AssetImage(
                                                    'assets/default_profile.png',
                                                  ),
                                                  fit: BoxFit.cover,
                                                ),
                                      ),
                                      child:
                                          profileImageUrl == null
                                              ? Center(
                                                child: Icon(
                                                  Icons.person,
                                                  size: 30,
                                                  color: Colors.grey[400],
                                                ),
                                              )
                                              : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fullName,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            shopName,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          if (distance != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.location_pin,
                                                    size: 14,
                                                    color: Colors.blue[400],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${(distance / 1000).toStringAsFixed(1)} km',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: Colors.blue[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey[400],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}
