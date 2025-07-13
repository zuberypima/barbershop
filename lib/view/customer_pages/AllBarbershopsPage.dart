import 'package:barber/view/customer_pages/BarberDetailsPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barber/services/navigator.dart'; // Assuming your navigator service

class AllBarbershopsPage extends StatefulWidget {
  const AllBarbershopsPage({super.key});

  @override
  State<AllBarbershopsPage> createState() => _AllBarbershopsPageState();
}

class _AllBarbershopsPageState extends State<AllBarbershopsPage> {
  Position? _currentPosition;
  List<DocumentSnapshot> _allBarbers = [];
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
      // Attempt to get location, but don't fail if it’s unavailable
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            print('Location permissions denied.');
          }
        } else if (permission == LocationPermission.deniedForever) {
          print('Location permissions permanently denied.');
        } else {
          _currentPosition = await Geolocator.getCurrentPosition();
          print(
            'Current position: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}',
          );
        }
      } else {
        print('Location services disabled.');
      }

      await _fetchAllBarbers();
    } catch (e) {
      print('Error in _getCurrentLocationAndFetchBarbers: $e');
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAllBarbers() async {
    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('BarbersDetails').get();
      print('Fetched ${snapshot.docs.length} barbers from Firestore');

      setState(() {
        _allBarbers =
            snapshot.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              if (data != null &&
                  data.containsKey('latitude') &&
                  data.containsKey('longitude')) {
                final barberLatitude = data['latitude'] as double?;
                final barberLongitude = data['longitude'] as double?;
                return barberLatitude != null && barberLongitude != null;
              }
              return false;
            }).toList();
        print(
          'Filtered to ${_allBarbers.length} barbers with valid coordinates',
        );
        _isLoading = false;
      });
    } catch (e) {
      print('Error in _fetchAllBarbers: $e');
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
          'All Barbershops',
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
                      'Loading barbershops...',
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
                      Icon(Icons.error, size: 60, color: Colors.red[400]),
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
              : _allBarbers.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 60, color: Colors.blue[400]),
                    const SizedBox(height: 20),
                    Text(
                      'No barbershops found.',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Check back later for new registrations.',
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
                        Icon(Icons.store, color: Colors.blue[800]),
                        const SizedBox(width: 8),
                        Text(
                          'All Barbershops (${_allBarbers.length})',
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
                      itemCount: _allBarbers.length,
                      itemBuilder: (context, index) {
                        final barberData =
                            _allBarbers[index].data() as Map<String, dynamic>?;

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
                                push_next_page(
                                  context,
                                  BarberDetailsPage(
                                    barberId: _allBarbers[index].id,
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
