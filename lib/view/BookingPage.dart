import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class BarberBookingPage extends StatefulWidget {
  const BarberBookingPage({super.key});

  @override
  State<BarberBookingPage> createState() => _BarberBookingPageState();
}

class _BarberBookingPageState extends State<BarberBookingPage> {
  String _selectedFilter = 'today'; // today, upcoming, past
  final List<Booking> _bookings = [
    Booking(
      id: '1',
      customerName: 'Michael Scott',
      service: 'Haircut & Beard Trim',
      dateTime: DateTime.now().add(Duration(hours: 2)),
      duration: 45,
      price: 35.00,
      status: 'confirmed',
      customerPhoto: 'assets/backgroun.jpg',
    ),
    Booking(
      id: '2',
      customerName: 'Jim Halpert',
      service: 'Classic Haircut',
      dateTime: DateTime.now().add(Duration(days: 1, hours: 3)),
      duration: 30,
      price: 25.00,
      status: 'confirmed',
      customerPhoto: 'assets/backgroun.jpg',
    ),
    Booking(
      id: '3',
      customerName: 'Pam Beesly',
      service: 'Hair Color',
      dateTime: DateTime.now().subtract(Duration(days: 1)),
      duration: 90,
      price: 65.00,
      status: 'completed',
      customerPhoto: 'assets/backgroun.jpg',
    ),
    Booking(
      id: '4',
      customerName: 'Dwight Schrute',
      service: 'Traditional Shave',
      dateTime: DateTime.now().add(Duration(days: 2)),
      duration: 30,
      price: 20.00,
      status: 'pending',
      customerPhoto: 'assets/backgroun.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredBookings =
        _bookings.where((booking) {
          final now = DateTime.now();
          if (_selectedFilter == 'today') {
            return booking.dateTime.year == now.year &&
                booking.dateTime.month == now.month &&
                booking.dateTime.day == now.day;
          } else if (_selectedFilter == 'upcoming') {
            return booking.dateTime.isAfter(now) &&
                !(booking.dateTime.year == now.year &&
                    booking.dateTime.month == now.month &&
                    booking.dateTime.day == now.day);
          } else {
            return booking.dateTime.isBefore(now);
          }
        }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Bookings', style: GoogleFonts.poppins()),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () {
              // Open calendar view
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 10),
              children: [
                _buildFilterChip('Today', 'today'),
                SizedBox(width: 8),
                _buildFilterChip('Upcoming', 'upcoming'),
                SizedBox(width: 8),
                _buildFilterChip('Past', 'past'),
                SizedBox(width: 8),
                _buildFilterChip('All', 'all'),
              ],
            ),
          ),

          // Stats summary
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Today', '5', Icons.calendar_today),
                _buildStatCard('Pending', '2', Icons.pending_actions),
                _buildStatCard('Earnings', '\$175', Icons.attach_money),
              ],
            ),
          ),

          // Bookings list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: filteredBookings.length,
              itemBuilder: (context, index) {
                final booking = filteredBookings[index];
                return _buildBookingCard(booking);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          // Add manual booking
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedFilter == value,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: Colors.blue[800],
      labelStyle: GoogleFonts.poppins(
        color: _selectedFilter == value ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Colors.blue[800]),
            SizedBox(height: 5),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final isPast = booking.dateTime.isBefore(DateTime.now());
    final isToday =
        booking.dateTime.year == DateTime.now().year &&
        booking.dateTime.month == DateTime.now().month &&
        booking.dateTime.day == DateTime.now().day;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      child: InkWell(
        onTap: () {
          _showBookingDetails(booking);
        },
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer photo
              CircleAvatar(
                radius: 25,
                backgroundImage: AssetImage(booking.customerPhoto),
              ),
              SizedBox(width: 12),

              // Booking info - Made this column flexible
              Flexible(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            booking.customerName,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isToday && !isPast)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Today',
                              style: GoogleFonts.poppins(
                                color: Colors.blue[800],
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      booking.service,
                      style: GoogleFonts.poppins(color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d, y').format(booking.dateTime),
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer, size: 14, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              '${booking.duration} min',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status indicator - Made this column flexible
              Flexible(
                flex: 1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(booking.status),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        booking.status.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '\$${booking.price.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showBookingDetails(Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Booking Details',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(),
              SizedBox(height: 10),

              // Customer info
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage(booking.customerPhoto),
                  ),
                  SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.customerName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        '3 previous visits',
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Booking details
              _buildDetailRow(Icons.cut, 'Service', booking.service),
              _buildDetailRow(
                Icons.calendar_today,
                'Date',
                DateFormat('EEEE, MMMM d, y').format(booking.dateTime),
              ),
              _buildDetailRow(
                Icons.access_time,
                'Time',
                DateFormat('h:mm a').format(booking.dateTime),
              ),
              _buildDetailRow(
                Icons.timer,
                'Duration',
                '${booking.duration} minutes',
              ),
              _buildDetailRow(
                Icons.attach_money,
                'Price',
                '\$${booking.price.toStringAsFixed(2)}',
              ),
              _buildDetailRow(
                Icons.star,
                'Status',
                booking.status.toUpperCase(),
                statusColor: _getStatusColor(booking.status),
              ),

              Spacer(),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      child: Text('Message', style: GoogleFonts.poppins()),
                      onPressed: () {
                        // Open chat
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getStatusColor(booking.status),
                      ),
                      child: Text(
                        'Update Status',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      onPressed: () {
                        _showStatusOptions(booking);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? statusColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          SizedBox(width: 15),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(color: statusColor ?? Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusOptions(Booking booking) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Update Booking Status',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              _buildStatusOption(
                'Confirmed',
                Colors.green,
                'confirmed',
                booking,
              ),
              _buildStatusOption('Pending', Colors.orange, 'pending', booking),
              _buildStatusOption(
                'Completed',
                Colors.blue,
                'completed',
                booking,
              ),
              _buildStatusOption('Cancelled', Colors.red, 'cancelled', booking),
              SizedBox(height: 20),
              TextButton(
                child: Text('Cancel', style: GoogleFonts.poppins()),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusOption(
    String label,
    Color color,
    String status,
    Booking booking,
  ) {
    return ListTile(
      leading: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      title: Text(label, style: GoogleFonts.poppins()),
      trailing: booking.status == status ? Icon(Icons.check) : null,
      onTap: () {
        setState(() {
          booking.status = status;
        });
        Navigator.pop(context); // Close status options
        Navigator.pop(context); // Close details sheet
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Status updated to $label')));
      },
    );
  }
}

class Booking {
  final String id;
  final String customerName;
  final String service;
  final DateTime dateTime;
  final int duration;
  final double price;
  String status;
  final String customerPhoto;

  Booking({
    required this.id,
    required this.customerName,
    required this.service,
    required this.dateTime,
    required this.duration,
    required this.price,
    required this.status,
    required this.customerPhoto,
  });
}
