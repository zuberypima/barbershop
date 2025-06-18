import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:barber/services/navigator.dart'; // Assuming your navigator service

class BarberMapDirectionsPage extends StatefulWidget {
  final String barberEmail;

  const BarberMapDirectionsPage({super.key, required this.barberEmail});

  @override
  State<BarberMapDirectionsPage> createState() =>
      _BarberMapDirectionsPageState();
}

class _BarberMapDirectionsPageState extends State<BarberMapDirectionsPage> {
  Position? _currentPosition;
  MapController _mapController = MapController();
  LatLng? _barberLocation;
  String? _barberShopName;
  List<LatLng> _routePoints = [];
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _directions = [];

  // Hardcoded Google Maps API key (replace with your own key)
  final String _googleMapsApiKey = '80NvXyCh9qPkoiZ66tnsrkQJ8lc=';

  // Default fallback location (New York City)
  final LatLng _defaultCenter = LatLng(40.7128, -74.0060);

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get customer location
      await _getCurrentLocation();

      // Get barber details
      await _getBarberDetails();

      // Get directions if both locations are available
      if (_currentPosition != null && _barberLocation != null) {
        await _fetchDirections();
        // Adjust map bounds to show both locations
        _fitBounds();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing map: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      _currentPosition = await Geolocator.getCurrentPosition();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _getBarberDetails() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('BarbersDetails')
              .doc(widget.barberEmail)
              .get();
      if (!doc.exists) {
        throw Exception('Barber not found.');
      }
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        final latitude = data['latitude'] as double?;
        final longitude = data['longitude'] as double?;
        if (latitude != null && longitude != null) {
          _barberLocation = LatLng(latitude, longitude);
          _barberShopName = data['shopName'] as String? ?? 'Barber Shop';
        } else {
          throw Exception('Barber location not available.');
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _fetchDirections() async {
    try {
      if (_googleMapsApiKey == 'YOUR_GOOGLE_MAPS_API_KEY_HERE') {
        throw Exception('Please provide a valid Google Maps API key.');
      }

      final origin =
          '${_currentPosition!.latitude},${_currentPosition!.longitude}';
      final destination =
          '${_barberLocation!.latitude},${_barberLocation!.longitude}';
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&mode=driving&key=$_googleMapsApiKey',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch directions.');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') {
        throw Exception('Directions API error: ${data['status']}');
      }

      final routes = data['routes'] as List<dynamic>;
      if (routes.isEmpty) {
        throw Exception('No routes found.');
      }

      final polylinePoints = routes[0]['overview_polyline']['points'] as String;
      final legs = routes[0]['legs'] as List<dynamic>;
      final steps = legs[0]['steps'] as List<dynamic>;

      // Decode polyline points
      _routePoints = _decodePolyline(polylinePoints);

      // Extract direction steps
      _directions =
          steps.map((step) {
            return {
              'instruction': _stripHtml(step['html_instructions'] as String),
              'distance': step['distance']['text'] as String,
              'duration': step['duration']['text'] as String,
            };
          }).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Fit map bounds to show both customer and barber locations
  void _fitBounds() {
    if (_currentPosition != null && _barberLocation != null) {
      // Initialize bounds with the two points
      final customerPoint = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      final barberPoint = _barberLocation!;

      // Create bounds by finding min/max coordinates
      final southWest = LatLng(
        customerPoint.latitude < barberPoint.latitude
            ? customerPoint.latitude
            : barberPoint.latitude,
        customerPoint.longitude < barberPoint.longitude
            ? customerPoint.longitude
            : barberPoint.longitude,
      );
      final northEast = LatLng(
        customerPoint.latitude > barberPoint.latitude
            ? customerPoint.latitude
            : barberPoint.latitude,
        customerPoint.longitude > barberPoint.longitude
            ? customerPoint.longitude
            : barberPoint.longitude,
      );

      final bounds = LatLngBounds(southWest, northEast);

      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
      );
    }
  }

  // Decode polyline string to list of LatLng
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  // Strip HTML tags from instructions
  String _stripHtml(String htmlText) {
    return htmlText.replaceAll(RegExp(r'<[^>]+>'), '');
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _barberShopName ?? 'Directions to Barber',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
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
                      'Loading map and directions...',
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
                        onPressed: _initializeMap,
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
              )
              : Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter:
                          _currentPosition != null
                              ? LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              )
                              : _defaultCenter,
                      initialZoom: _currentPosition != null ? 14 : 10,
                      minZoom: 8,
                      maxZoom: 18,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      if (_currentPosition != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.my_location,
                                color: Colors.blue,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      if (_barberLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _barberLocation!,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      if (_routePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              strokeWidth: 4,
                              color: Colors.blue[800]!,
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (_directions.isNotEmpty)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 8,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Directions to $_barberShopName',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: _directions.length,
                                itemBuilder: (context, index) {
                                  final step = _directions[index];
                                  return ListTile(
                                    leading: Icon(
                                      Icons.directions,
                                      color: Colors.blue[800],
                                    ),
                                    title: Text(
                                      step['instruction'],
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      '${step['distance']} (${step['duration']})',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // Home is default since this is a sub-page
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
              break;
            case 1:
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/nearby',
                (route) => false,
              );
              break;
            case 2:
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/profile',
                (route) => false,
              );
              break;
          }
        },
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Nearby',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Bookings'),
        ],
      ),
    );
  }
}
