// import 'package:barber/constants/constants.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:intl/intl.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class BarberDetailsPage extends StatefulWidget {
//   final String barberEmail;

//   const BarberDetailsPage({super.key, required this.barberEmail});

//   @override
//   State<BarberDetailsPage> createState() => _BarberDetailsPageState();
// }

// class _BarberDetailsPageState extends State<BarberDetailsPage> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   Barber? _barber;
//   bool _isLoading = true;
//   int _selectedServiceIndex = 0;
//   DateTime? _selectedDate;
//   TimeOfDay? _selectedTime;

//   @override
//   void initState() {
//     super.initState();
//     _fetchBarberDetails();
//   }

//   Future<void> _fetchBarberDetails() async {
//     try {
//       final doc =
//           await _firestore
//               .collection('BarbersDetails')
//               .doc(widget.barberEmail)
//               .get();

//       if (doc.exists) {
//         final data = doc.data()!;
//         final services =
//             (data['services'] as List<dynamic>?)
//                 ?.map(
//                   (service) => Service(
//                     id: service['id'] ?? '',
//                     name: service['name'] ?? '',
//                     duration: service['duration'] ?? 0,
//                     price: service['price']?.toDouble() ?? 0.0,
//                   ),
//                 )
//                 .toList() ??
//             [];

//         setState(() {
//           _barber = Barber(
//             // id: doc.id,
//             email: data['email'] ?? '',
//             fullName: data['fullName'] ?? '',
//             shopName: data['shopName'] ?? '',
//             shopAddress: data['shopAddress'] ?? '',
//             profileImageUrl: data['profileImageUrl'] ?? '',
//             rating: (data['rating'] ?? 0).toDouble(),
//             bio: data['bio'],
//             phoneNumber: data['phoneNumber'] ?? '',
//             specialties: data['specialties'] ?? '',
//             services: services,
//           );
//           _isLoading = false;
//         });
//       } else {
//         setState(() => _isLoading = false);
//         if (mounted) {
//           ScaffoldMessenger.of(
//             context,
//           ).showSnackBar(const SnackBar(content: Text('Barber not found')));
//           Navigator.pop(context);
//         }
//       }
//     } catch (e) {
//       setState(() => _isLoading = false);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error loading barber details: ${e.toString()}'),
//           ),
//         );
//         Navigator.pop(context);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return Scaffold(
//         body: Center(child: CircularProgressIndicator(color: Colors.blue[800])),
//       );
//     }

//     if (_barber == null) {
//       return Scaffold(
//         appBar: AppBar(backgroundColor: mainColor),
//         body: Center(child: Text('Barber information not available')),
//       );
//     }

//     return Scaffold(
//       body: CustomScrollView(
//         slivers: [
//           SliverAppBar(
//             expandedHeight: 200,
//             flexibleSpace: FlexibleSpaceBar(
//               background: CachedNetworkImage(
//                 imageUrl: _barber!.profileImageUrl,
//                 fit: BoxFit.cover,
//                 placeholder:
//                     (context, url) => Container(color: Colors.grey[200]),
//                 errorWidget:
//                     (context, url, error) =>
//                         const Icon(Icons.person, size: 100),
//               ),
//             ),
//             pinned: true,
//             actions: [
//               IconButton(
//                 icon: const Icon(Icons.favorite_border),
//                 onPressed: () => _toggleFavorite(),
//               ),
//             ],
//           ),
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Barber Info Section
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               _barber!.shopName,
//                               style: GoogleFonts.poppins(
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               _barber!.fullName,
//                               style: GoogleFonts.poppins(
//                                 fontSize: 16,
//                                 color: Colors.grey[600],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Row(
//                         children: [
//                           const Icon(Icons.star, color: Colors.amber, size: 20),
//                           const SizedBox(width: 4),
//                           Text(
//                             _barber!.rating.toStringAsFixed(1),
//                             style: GoogleFonts.poppins(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),

//                   // Contact Section
//                   _buildInfoRow(Icons.phone, _barber!.phoneNumber),
//                   _buildInfoRow(Icons.email, _barber!.email),
//                   _buildInfoRow(
//                     Icons.location_on,
//                     _barber!.shopAddress,
//                     isAddress: true,
//                   ),

//                   if (_barber!.specialties.isNotEmpty) ...[
//                     const SizedBox(height: 16),
//                     _buildSectionTitle('Specialties'),
//                     Text(_barber!.specialties, style: GoogleFonts.poppins()),
//                   ],

//                   if (_barber!.bio?.isNotEmpty ?? false) ...[
//                     const SizedBox(height: 16),
//                     _buildSectionTitle('About'),
//                     Text(_barber!.bio!, style: GoogleFonts.poppins()),
//                   ],

//                   const SizedBox(height: 20),
//                   const Divider(),

//                   // Services Section
//                   _buildSectionTitle('Services'),
//                   const SizedBox(height: 12),
//                   SizedBox(
//                     height: 120,
//                     child: ListView.builder(
//                       scrollDirection: Axis.horizontal,
//                       itemCount: _barber!.services.length,
//                       itemBuilder: (context, index) => _buildServiceCard(index),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   const Divider(),

//                   // Schedule Section
//                   _buildSectionTitle('Schedule Appointment'),
//                   const SizedBox(height: 16),
//                   _buildDateTimeSelectors(),
//                   const SizedBox(height: 30),

//                   // Book Now Button
//                   _buildBookButton(),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoRow(IconData icon, String text, {bool isAddress = false}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         children: [
//           Icon(icon, color: Colors.blue[800], size: 20),
//           const SizedBox(width: 12),
//           Expanded(child: Text(text, style: GoogleFonts.poppins())),
//           if (isAddress)
//             TextButton(
//               onPressed: () => _openMaps(),
//               child: Text(
//                 'View Map',
//                 style: GoogleFonts.poppins(
//                   color: Colors.blue,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Text(
//       title,
//       style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
//     );
//   }

//   Widget _buildServiceCard(int index) {
//     final service = _barber!.services[index];
//     return GestureDetector(
//       onTap: () => setState(() => _selectedServiceIndex = index),
//       child: Container(
//         width: 200,
//         margin: const EdgeInsets.only(right: 12),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color:
//               _selectedServiceIndex == index
//                   ? Colors.blue[50]
//                   : Colors.grey[100],
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color:
//                 _selectedServiceIndex == index
//                     ? Colors.blue
//                     : Colors.transparent,
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               service.name,
//               style: GoogleFonts.poppins(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               '${service.duration} min',
//               style: GoogleFonts.poppins(color: Colors.grey[600]),
//             ),
//             const Spacer(),
//             Text(
//               '\$${service.price.toStringAsFixed(2)}',
//               style: GoogleFonts.poppins(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//                 color: Colors.blue[800],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDateTimeSelectors() {
//     return Row(
//       children: [
//         Expanded(
//           child: OutlinedButton.icon(
//             icon: const Icon(Icons.calendar_today),
//             label: Text(
//               _selectedDate == null
//                   ? 'Select Date'
//                   : DateFormat('MMM d, y').format(_selectedDate!),
//             ),
//             onPressed: () => _selectDate(context),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: OutlinedButton.icon(
//             icon: const Icon(Icons.access_time),
//             label: Text(
//               _selectedTime == null
//                   ? 'Select Time'
//                   : _selectedTime!.format(context),
//             ),
//             onPressed: () => _selectTime(context),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildBookButton() {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed:
//             _selectedDate == null || _selectedTime == null
//                 ? null
//                 : () => _bookAppointment(),
//         style: ElevatedButton.styleFrom(
//           padding: const EdgeInsets.symmetric(vertical: 16),
//           backgroundColor: Colors.blue[800],
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//         child: Text(
//           'Book Now',
//           style: GoogleFonts.poppins(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 60)),
//     );
//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = picked;
//         _selectedTime = null;
//       });
//     }
//   }

//   Future<void> _selectTime(BuildContext context) async {
//     if (_selectedDate == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a date first')),
//       );
//       return;
//     }

//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.now(),
//     );
//     if (picked != null) {
//       setState(() => _selectedTime = picked);
//     }
//   }

//   void _toggleFavorite() {
//     // Implement favorite functionality
//   }

//   void _openMaps() {
//     // Implement map opening functionality
//   }

//   void _bookAppointment() {
//     final selectedService = _barber!.services[_selectedServiceIndex];
//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: Text('Confirm Booking', style: GoogleFonts.poppins()),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Barber: ${_barber!.fullName}'),
//                 Text('Service: ${selectedService.name}'),
//                 Text('Duration: ${selectedService.duration} min'),
//                 Text('Price: \$${selectedService.price.toStringAsFixed(2)}'),
//                 const SizedBox(height: 10),
//                 Text(
//                   'Date: ${DateFormat('EEEE, MMM d').format(_selectedDate!)} at ${_selectedTime!.format(context)}',
//                   style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Cancel'),
//               ),
//               ElevatedButton(
//                 onPressed: () => _processBooking(selectedService),
//                 child: const Text('Confirm'),
//               ),
//             ],
//           ),
//     );
//   }

//   Future<void> _processBooking(Service service) async {
//     try {
//       // Create booking document in Firestore
//       await _firestore.collection('appointments').add({
//         'barberEmail': _barber!.email,
//         'barberName': _barber!.fullName,
//         'customerId': FirebaseAuth.instance.currentUser?.uid,
//         'serviceId': service.id,
//         'serviceName': service.name,
//         'price': service.price,
//         'date': Timestamp.fromDate(
//           DateTime(
//             _selectedDate!.year,
//             _selectedDate!.month,
//             _selectedDate!.day,
//             _selectedTime!.hour,
//             _selectedTime!.minute,
//           ),
//         ),
//         'createdAt': FieldValue.serverTimestamp(),
//         'status': 'pending',
//       });

//       if (mounted) {
//         Navigator.pop(context);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Appointment booked successfully!')),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Booking failed: ${e.toString()}')),
//         );
//       }
//     }
//   }
// }

// // Data Models
// class Barber {
//   final String email;
//   final String fullName;
//   final String shopName;
//   final String shopAddress;
//   final String profileImageUrl;
//   final double rating;
//   final String? bio;
//   final String phoneNumber;
//   final String specialties;
//   final List<Service> services;

//   Barber({
//     required this.email,
//     required this.fullName,
//     required this.shopName,
//     required this.shopAddress,
//     required this.profileImageUrl,
//     required this.rating,
//     this.bio,
//     required this.phoneNumber,
//     required this.specialties,
//     required this.services,
//   });
// }

// class Service {
//   final String id;
//   final String name;
//   final int duration;
//   final double price;

//   Service({
//     required this.id,
//     required this.name,
//     required this.duration,
//     required this.price,
//   });
// }
