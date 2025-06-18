// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';

// class CreateBookingPage extends StatefulWidget {
//   final Barber selectedBarber;

//   const CreateBookingPage({super.key, required this.selectedBarber});

//   @override
//   State<CreateBookingPage> createState() => _CreateBookingPageState();
// }

// class _CreateBookingPageState extends State<CreateBookingPage> {
//   DateTime _selectedDate = DateTime.now();
//   TimeOfDay _selectedTime = TimeOfDay.now();
//   String _selectedService = '';
//   String _specialInstructions = '';
//   final _formKey = GlobalKey<FormState>();

//   // Sample services data
//   final List<Service> _services = [
//     Service(id: '1', name: 'Haircut', duration: 30, price: 25.00),
//     Service(id: '2', name: 'Beard Trim', duration: 15, price: 15.00),
//     Service(id: '3', name: 'Haircut & Beard', duration: 45, price: 35.00),
//     Service(id: '4', name: 'Hair Color', duration: 90, price: 65.00),
//     Service(id: '5', name: 'Traditional Shave', duration: 30, price: 20.00),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Book Appointment', style: GoogleFonts.poppins()),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Barber Info Card
//               Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(12.0),
//                   child: Row(
//                     children: [
//                       CircleAvatar(
//                         radius: 30,
//                         backgroundImage: NetworkImage(
//                           widget.selectedBarber.photoUrl,
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               widget.selectedBarber.name,
//                               style: GoogleFonts.poppins(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 18,
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Row(
//                               children: [
//                                 const Icon(
//                                   Icons.star,
//                                   color: Colors.amber,
//                                   size: 16,
//                                 ),
//                                 const SizedBox(width: 4),
//                                 Text(
//                                   widget.selectedBarber.rating.toString(),
//                                   style: GoogleFonts.poppins(),
//                                 ),
//                                 const SizedBox(width: 8),
//                                 const Icon(
//                                   Icons.place,
//                                   size: 16,
//                                   color: Colors.grey,
//                                 ),
//                                 const SizedBox(width: 4),
//                                 Text(
//                                   '${widget.selectedBarber.distance} km',
//                                   style: GoogleFonts.poppins(
//                                     color: Colors.grey,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 24),

//               // Service Selection
//               Text(
//                 'Select Service',
//                 style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               ..._services
//                   .map((service) => _buildServiceCard(service))
//                   .toList(),
//               const SizedBox(height: 24),

//               // Date Selection
//               Text(
//                 'Select Date',
//                 style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               InkWell(
//                 onTap: () => _selectDate(context),
//                 child: Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey.shade300),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         DateFormat('EEEE, MMMM d, y').format(_selectedDate),
//                         style: GoogleFonts.poppins(),
//                       ),
//                       const Icon(Icons.calendar_today),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),

//               // Time Selection
//               Text(
//                 'Select Time',
//                 style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               InkWell(
//                 onTap: () => _selectTime(context),
//                 child: Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey.shade300),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         _selectedTime.format(context),
//                         style: GoogleFonts.poppins(),
//                       ),
//                       const Icon(Icons.access_time),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 24),

//               // Special Instructions
//               Text(
//                 'Special Instructions (Optional)',
//                 style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               TextFormField(
//                 maxLines: 3,
//                 decoration: InputDecoration(
//                   hintText: 'Any special requests or notes for your barber...',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 onChanged: (value) => _specialInstructions = value,
//               ),
//               const SizedBox(height: 32),

//               // Confirm Booking Button
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     backgroundColor: Colors.blue[800],
//                   ),
//                   onPressed: _submitBooking,
//                   child: Text(
//                     'Confirm Booking',
//                     style: GoogleFonts.poppins(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildServiceCard(Service service) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 8),
//       color: _selectedService == service.id ? Colors.blue[50] : null,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(8),
//         side: BorderSide(
//           color:
//               _selectedService == service.id
//                   ? Colors.blue[800]!
//                   : Colors.grey.shade300,
//         ),
//       ),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(8),
//         onTap: () {
//           setState(() {
//             _selectedService = service.id;
//           });
//         },
//         child: Padding(
//           padding: const EdgeInsets.all(12.0),
//           child: Row(
//             children: [
//               Icon(
//                 Icons.cut,
//                 color:
//                     _selectedService == service.id
//                         ? Colors.blue[800]
//                         : Colors.grey,
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       service.name,
//                       style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       '${service.duration} min • \$${service.price.toStringAsFixed(2)}',
//                       style: GoogleFonts.poppins(
//                         color: Colors.grey,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               if (_selectedService == service.id)
//                 const Icon(Icons.check_circle, color: Colors.blue),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate,
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 60)),
//     );
//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = picked;
//       });
//     }
//   }

//   Future<void> _selectTime(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: _selectedTime,
//       builder: (BuildContext context, Widget? child) {
//         return MediaQuery(
//           data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
//           child: child!,
//         );
//       },
//     );
//     if (picked != null && picked != _selectedTime) {
//       setState(() {
//         _selectedTime = picked;
//       });
//     }
//   }

//   void _submitBooking() {
//     if (_selectedService.isEmpty) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Please select a service')));
//       return;
//     }

//     final selectedService = _services.firstWhere(
//       (s) => s.id == _selectedService,
//     );

//     // Create booking object
//     final booking = Booking(
//       barber: widget.selectedBarber,
//       service: selectedService,
//       dateTime: DateTime(
//         _selectedDate.year,
//         _selectedDate.month,
//         _selectedDate.day,
//         _selectedTime.hour,
//         _selectedTime.minute,
//       ),
//       specialInstructions: _specialInstructions,
//     );

//     // Here you would typically send the booking to your backend
//     print('Booking created: $booking');

//     // Show confirmation
//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: Text('Booking Confirmed', style: GoogleFonts.poppins()),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'With ${widget.selectedBarber.name}',
//                   style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(selectedService.name, style: GoogleFonts.poppins()),
//                 const SizedBox(height: 4),
//                 Text(
//                   DateFormat('EEEE, MMMM d').format(booking.dateTime),
//                   style: GoogleFonts.poppins(),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   DateFormat('h:mm a').format(booking.dateTime),
//                   style: GoogleFonts.poppins(),
//                 ),
//                 if (_specialInstructions.isNotEmpty) ...[
//                   const SizedBox(height: 8),
//                   Text(
//                     'Special Instructions:',
//                     style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
//                   ),
//                   Text(_specialInstructions),
//                 ],
//               ],
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Close'),
//               ),
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context); // Close dialog
//                   Navigator.pop(context); // Return to previous screen
//                 },
//                 child: const Text('View Booking'),
//               ),
//             ],
//           ),
//     );
//   }
// }

// // Data Models
// class Barber {
//   final String id;
//   final String name;
//   final String photoUrl;
//   final double rating;
//   final double distance;

//   Barber({
//     required this.id,
//     required this.name,
//     required this.photoUrl,
//     required this.rating,
//     required this.distance,
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

// class Booking {
//   final Barber barber;
//   final Service service;
//   final DateTime dateTime;
//   final String specialInstructions;

//   Booking({
//     required this.barber,
//     required this.service,
//     required this.dateTime,
//     required this.specialInstructions,
//   });

//   @override
//   String toString() {
//     return 'Booking with ${barber.name} for ${service.name} on ${DateFormat('MMM d, y h:mm a').format(dateTime)}';
//   }
// }
