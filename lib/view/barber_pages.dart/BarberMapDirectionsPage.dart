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

  // Your Google Maps API key
  final String _googleMapsApiKey = 'AIzaSyBOpRefK-45E8lUfGUaicXtSklxLA-XWaY';

  // Default fallback location (Dar es Salaam)
  final LatLng _defaultCenter = LatLng(-6.7894791, 39.1861046);

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
      await _getCurrentLocation();
      await _getBarberDetails();
      if (_currentPosition != null && _barberLocation != null) {
        try {
          await _fetchDirections();
        } catch (e) {
          print('Directions failed, but map will still render: $e');
          setState(() {
            _errorMessage = 'Failed to load directions: $e';
          });
        }
      }
      setState(() {
        _isLoading = false;
      });
      // Delay _fitBounds until after the first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentPosition != null && _barberLocation != null) {
          _fitBounds();
        }
      });
    } catch (e) {
      print('Error in _initializeMap: $e');
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
        setState(() {
          _errorMessage = 'Please enable location services.';
        });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permissions are denied.';
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage =
              'Location permissions are permanently denied. Please enable them in settings.';
        });
        return;
      }
      _currentPosition = await Geolocator.getCurrentPosition();
      print(
        'Current position: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}',
      );
    } catch (e) {
      print('Error in _getCurrentLocation: $e');
      setState(() {
        _errorMessage = 'Error getting location: $e';
      });
    }
  }

  Future<void> _getBarberDetails() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('BarbersDetails')
              .doc(widget.barberEmail)
              .get();
      print('Barber document exists: ${doc.exists}');
      if (!doc.exists) {
        throw Exception('Barber not found.');
      }
      final data = doc.data() as Map<String, dynamic>?;
      print('Barber document data: $data');
      if (data != null) {
        final latitude = data['latitude'] as double?;
        final longitude = data['longitude'] as double?;
        if (latitude != null && longitude != null) {
          _barberLocation = LatLng(latitude, longitude);
          _barberShopName = data['shopName'] as String? ?? 'Barber Shop';
          print('Barber location: $latitude, $longitude');
        } else {
          throw Exception('Barber location not available.');
        }
      }
    } catch (e) {
      print('Error in _getBarberDetails: $e');
      rethrow;
    }
  }

  Future<void> _fetchDirections() async {
    try {
      final origin =
          '${_currentPosition!.latitude},${_currentPosition!.longitude}';
      final destination =
          '${_barberLocation!.latitude},${_barberLocation!.longitude}';
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&mode=driving&key=$_googleMapsApiKey',
      );
      print('Fetching directions from URL: $url');
      final response = await http.get(url);
      print('Directions API response status: ${response.statusCode}');
      print('Directions API response body: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch directions: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      print('Directions API status: ${data['status']}');
      if (data['status'] != 'OK') {
        throw Exception(
          'Directions API error: ${data['status']} - ${data['error_message'] ?? 'No error message'}',
        );
      }
      final routes = data['routes'] as List<dynamic>;
      if (routes.isEmpty) {
        throw Exception('No routes found.');
      }
      final polylinePoints = routes[0]['overview_polyline']['points'] as String;
      final legs = routes[0]['legs'] as List<dynamic>;
      final steps = legs[0]['steps'] as List<dynamic>;
      _routePoints = _decodePolyline(polylinePoints);
      _directions =
          steps.map((step) {
            return {
              'instruction': _stripHtml(step['html_instructions'] as String),
              'distance': step['distance']['text'] as String,
              'duration': step['duration']['text'] as String,
            };
          }).toList();
    } catch (e) {
      print('Error in _fetchDirections: $e');
      rethrow;
    }
  }

  void _fitBounds() {
    if (_currentPosition != null && _barberLocation != null) {
      final customerPoint = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      final barberPoint = _barberLocation!;
      if (customerPoint == barberPoint) {
        _mapController.move(customerPoint, 14);
        return;
      }
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

  String _stripHtml(String htmlText) {
    return htmlText.replaceAll(RegExp(r'<[^>]+>'), '');
  }

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
              : _currentPosition == null && _barberLocation == null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 60, color: Colors.red[400]),
                      const SizedBox(height: 20),
                      Text(
                        _errorMessage ?? 'Unable to load locations.',
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
                  Container(
                    height: MediaQuery.of(context).size.height,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter:
                            _currentPosition != null
                                ? LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                )
                                : _barberLocation ?? _defaultCenter,
                        initialZoom: 14,
                        minZoom: 8,
                        maxZoom: 18,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                          errorTileCallback: (tile, error, stackTrace) {
                            print('Tile loading error: $error');
                          },
                        ),
                        MarkerLayer(
                          markers: [
                            if (_currentPosition != null)
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
                            if (_barberLocation != null)
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
                  ),
                  if (_errorMessage != null && _routePoints.isEmpty)
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.red.withOpacity(0.8),
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
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
    );
  }
}
