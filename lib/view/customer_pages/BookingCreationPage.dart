// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:shimmer/shimmer.dart';

// class BookingCreationPage extends StatefulWidget {
//   const BookingCreationPage({super.key});

//   @override
//   State<BookingCreationPage> createState() => _BookingCreationPageState();
// }

// class _BookingCreationPageState extends State<BookingCreationPage> {
//   final _auth = FirebaseAuth.instance;
//   final _firestore = FirebaseFirestore.instance;
//   bool _isLoading = true;
//   List<QueryDocumentSnapshot> _barbers = [];
//   Map<String, dynamic>? _customerData;
//   String? _selectedBarberEmail;
//   String? _selectedService;
//   DateTime? _selectedDate;
//   String? _selectedTime;
//   List<String> _availableTimes = [];

//   @override
//   void initState() {
//     super.initState();
//     _fetchData();
//   }

//   Future<void> _fetchData() async {
//     try {
//       final user = _auth.currentUser;
//       if (user == null) {
//         throw 'No user logged in';
//       }

//       // Fetch customer data
//       final customerDoc = await _firestore
//           .collection('CustomersDetails')
//           .doc(user.email)
//           .get()
//           .timeout(const Duration(seconds: 5));

//       if (!customerDoc.exists) {
//         throw 'Customer data not found';
//       }

//       // Fetch barbers
//       final barbersSnapshot = await _firestore
//           .collection('BarbersDetails')
//           .get()
//           .timeout(const Duration(seconds: 5));

//       setState(() {
//         _customerData = customerDoc.data();
//         _barbers = barbersSnapshot.docs;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() => _isLoading = false);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to load data: $e')),
//         );
//       }
//     }
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final now = DateTime.now();
//     final lastDate = now.add(const Duration(days: 7));
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: now,
//       firstDate: now,
//       lastDate: lastDate,
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: ColorScheme.light(
//               primary: Colors.blue.shade800,
//               onPrimary: Colors.white,
//               onSurface: Colors.blue.shade800,
//             ),
//             textButtonTheme: TextButtonThemeData(
//               style: TextButton.styleFrom(foregroundColor: Colors.blue.shade800),
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (picked != null && mounted) {
//       setState(() {
//         _selectedDate = picked;
//         _selectedTime = null; // Reset time when date changes
//         _updateAvailableTimes();
//       });
//     }
//   }

//   void _updateAvailableTimes() {
//     if (_selectedBarberEmail == null || _selectedDate == null) {
//       _availableTimes = [];
//       return;
//     }

//     final barber = _barbers.firstWhere(
//       (doc) => doc.id == _selectedBarberEmail,
//       orElse: () => throw 'Barber not found',
//     );
//     final barberData = barber.data() as Map<String, dynamic>;
//     final availability = barberData['availability'] as Map<String, dynamic>? ?? {};
//     final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate!);
//     _availableTimes = List<String>.from(availability[dateKey] ?? []);

//     // Filter out already booked times
//     _firestore
//         .collection('Bookings')
//         .where('barberEmail', isEqualTo: _selectedBarberEmail)
//         .where('status', isEqualTo: 'confirmed')
//         .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(_selectedDate!))
//         .where('dateTime',
//             isLessThan: Timestamp.fromDate(_selectedDate!.add(const Duration(days: 1))))
//         .get()
//         .then((snapshot) {
//       final bookedTimes = snapshot.docs
//           .map((doc) => DateFormat('HH:mm')
//               .format((doc['dateTime'] as Timestamp).toDate()))
//           .toList();
//       setState(() {
//         _availableTimes = _availableTimes
//             .where((time) => !bookedTimes.contains(time))
//             .toList();
//       });
//     });
//   }

//   Future<void> _createBooking() async {
//     if (_selectedBarberEmail == null ||
//         _selectedService == null ||
//         _selectedDate == null ||
//         _selectedTime == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please complete all selections')),
//       );
//       return;
//     }

//     try {
//       final user = _auth.currentUser;
//       if (user == null) {
//         throw 'No user logged in';
//       }

//       final barber = _barbers.firstWhere(
//         (doc) => doc.id == _selectedBarberEmail,
//         orElse: () => throw 'Barber not found',
//       );
//       final barberData = barber.data() as Map<String, dynamic>;

//       final dateTimeStr = '${DateFormat('yyyy-MM-dd').format(_selectedDate!)} $_selectedTime';
//       final dateTime = DateTime.parse(dateTimeStr.replaceAll(' ', 'T'));

//       await _firestore
//           .collection('Bookings')
//           .add({
//             'customerEmail': user.email,
//             'customerName': _customerData?['fullName'] ?? 'Guest',
//             'barberEmail': _selectedBarberEmail,
//             'barberName': barberData['fullName'] ?? 'Unknown',
//             'barberAddress': barberData['address'] ?? 'No address',
//             'service': _selectedService,
//             'dateTime': Timestamp.fromDate(dateTime),
//             'status': 'confirmed',
//             'createdAt': Timestamp.now(),
//             'loyaltyPointsEarned': 0,
//           })
//           .timeout(const Duration(seconds: 5));

//       if (mounted) {
//         Navigator.pop(context); // Return to BookingsPage
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Booking created successfully')),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to create booking: $e')),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Book Appointment',
//           style: GoogleFonts.poppins(
//             color: Colors.white,
//             fontWeight: FontWeight.w600,
//             fontSize: 20,
//           ),
//         ),
//         backgroundColor: Colors.blue.shade800,
//         centerTitle: true,
//         elevation: 0,
//       ),
//       body: _isLoading
//           ? _buildSkeletonLoader(context)
//           : Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [Colors.blue.shade50, Colors.white],
//                 ),
//               ),
//               child: _barbers.isEmpty
//                   ? _buildEmptyState()
//                   : SingleChildScrollView(
//                       padding: const EdgeInsets.all(20),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // Select Barber
//                           Card(
//                             elevation: 4,
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                             child: Padding(
//                               padding: const EdgeInsets.all(16),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     'Select Barber',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 18,
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.blue.shade800,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 12),
//                                   DropdownButtonFormField<String>(
//                                     value: _selectedBarberEmail,
//                                     decoration: InputDecoration(
//                                       filled: true,
//                                       fillColor: Colors.blue.shade50,
//                                       border: OutlineInputBorder(
//                                         borderRadius: BorderRadius.circular(12),
//                                         borderSide: BorderSide.none,
//                                       ),
//                                     ),
//                                     hint: Text(
//                                       'Choose a barber',
//                                       style: GoogleFonts.poppins(color: Colors.grey.shade600),
//                                     ),
//                                     items: _barbers
//                                         .map((barber) => DropdownMenuItem(
//                                               value: barber.id,
//                                               child: Text(
//                                                 barber['fullName'] ?? 'Unknown',
//                                                 style: GoogleFonts.poppins(fontSize: 16),
//                                               ),
//                                             ))
//                                         .toList(),
//                                     onChanged: (value) {
//                                       setState(() {
//                                         _selectedBarberEmail = value;
//                                         _selectedService = null;
//                                         _selectedDate = null;
//                                         _selectedTime = null;
//                                         _availableTimes = [];
//                                       });
//                                     },
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 24),

//                           // Select Service
//                           if (_selectedBarberEmail != null)
//                             Card(
//                               elevation: 4,
//                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                               child: Padding(
//                                 padding: const EdgeInsets.all(16),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       'Select Service',
//                                       style: GoogleFonts.poppins(
//                                         fontSize: 18,
//                                         fontWeight: FontWeight.w600,
//                                         color: Colors.blue.shade800,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 12),
//                                     DropdownButtonFormField<String>(
//                                       value: _selectedService,
//                                       decoration: InputDecoration(
//                                         filled: true,
//                                         fillColor: Colors.blue.shade50,
//                                         border: OutlineInputBorder(
//                                           borderRadius: BorderRadius.circular(12),
//                                           borderSide: BorderSide.none,
//                                         ),
//                                       ),
//                                       hint: Text(
//                                         'Choose a service',
//                                         style: GoogleFonts.poppins(color: Colors.grey.shade600),
//                                       ),
//                                       items: (_barbers
//                                                   .firstWhere((doc) => doc.id == _selectedBarberEmail)
//                                                   ['services'] as List<dynamic>?)
//                                               ?.map((service) => DropdownMenuItem(
//                                                     value: service,
//                                                     child: Text(
//                                                       service,
//                                                       style: GoogleFonts.poppins(fontSize: 16),
//                                                     ),
//                                                   ))
//                                               .toList() ??
//                                           [],
//                                       onChanged: (value) {
//                                         setState(() {
//                                           _selectedService = value;
//                                           _selectedDate = null;
//                                           _selectedTime = null;
//                                           _availableTimes = [];
//                                         });
//                                       },
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           if (_selectedBarberEmail != null) const SizedBox(height: 24),

//                           // Select Date and Time
//                           if (_selectedService != null)
//                             Card(
//                               elevation: 4,
//                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                               child: Padding(
//                                 padding: const EdgeInsets.all(16),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       'Select Date & Time',
//                                       style: GoogleFonts.poppins(
//                                         fontSize: 18,
//                                         fontWeight: FontWeight.w600,
//                                         color: Colors.blue.shade800,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 12),
//                                     Row(
//                                       children: [
//                                         Expanded(
//                                           child: OutlinedButton(
//                                             onPressed: () => _selectDate(context),
//                                             style: OutlinedButton.styleFrom(
//                                               side: BorderSide(color: Colors.blue.shade600),
//                                               padding: const EdgeInsets.symmetric(vertical: 16),
//                                               shape: RoundedRectangleBorder(
//                                                 borderRadius: BorderRadius.circular(12),
//                                               ),
//                                             ),
//                                             child: Text(
//                                               _selectedDate == null
//                                                   ? 'Choose Date'
//                                                   : DateFormat('MMM d, yyyy').format(_selectedDate!),
//                                               style: GoogleFonts.poppins(
//                                                 fontSize: 16,
//                                                 color: Colors.blue.shade800,
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                         const SizedBox(width: 12),
//                                         if (_selectedDate != null)
//                                           Expanded(
//                                             child: DropdownButtonFormField<String>(
//                                               value: _selectedTime,
//                                               decoration: InputDecoration(
//                                                 filled: true,
//                                                 fillColor: Colors.blue.shade50,
//                                                 border: OutlineInputBorder(
//                                                   borderRadius: BorderRadius.circular(12),
//                                                   borderSide: BorderSide.none,
//                                                 ),
//                                               ),
//                                               hint: Text(
//                                                 'Choose Time',
//                                                 style: GoogleFonts.poppins(color: Colors.grey.shade600),
//                                               ),
//                                               items: _availableTimes
//                                                   .map((time) => DropdownMenuItem(
//                                                         value: time,
//                                                         child: Text(
//                                                           time,
//                                                           style: GoogleFonts.poppins(fontSize: 16),
//                                                         ),
//                                                       ))
//                                                   .toList(),
//                                               onChanged: (value) {
//                                                 setState(() {
//                                                   _selectedTime = value;
//                                                 });
//                                               },
//                                             ),
//                                           ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           if (_selectedService != null) const SizedBox(height: 24),

//                           // Confirm Button
//                           SizedBox(
//                             width: double.infinity,
//                             child: ElevatedButton(
//                               onPressed: _createBooking,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.blue.shade800,
//                                 padding: const EdgeInsets.symmetric(vertical: 16),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 elevation: 2,
//                               ),
//                               child: Text(
//                                 'Confirm Booking',
//                                 style: GoogleFonts.poppins(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 32),
//                         ],
//                       ),
//                     ),
//             ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.person_search,
//               size: 80,
//               color: Colors.blue.shade300,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'No Barbers Available',
//               style: GoogleFonts.poppins(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.blue.shade800,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Please try again later.',
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 color: Colors.grey.shade600,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSkeletonLoader(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;

//     return Shimmer.fromColors(
//       baseColor: Colors.grey[300]!,
//       highlightColor: Colors.grey[100]!,
//       child: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.blue.shade50, Colors.white],
//           ),
//         ),
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Barber Selection Skeleton
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Container(width: 150, height: 18, color: Colors.white),
//                     const SizedBox(height: 12),
//                     Container(width: double.infinity, height: 50, color: Colors.white),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),
//               // Service Selection Skeleton
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Container(width: 150, height: 18, color: Colors.white),
//                     const SizedBox(height: 12),
//                     Container(width: double.infinity, height: 50, color: Colors.white),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),
//               // Date and Time Selection Skeleton
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Container(width: 150, height: 18, color: Colors.white),
//                     const SizedBox(height: 12),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Container(height: 50, color: Colors.white),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Container(height: 50, color: Colors.white),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),
//               // Confirm Button Skeleton
//               Container(
//                 width: double.infinity,
//                 height: 50,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
