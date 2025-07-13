import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barber/services/navigator.dart';

class BarberMessagesPage extends StatefulWidget {
  const BarberMessagesPage({super.key});

  @override
  State<BarberMessagesPage> createState() => _BarberMessagesPageState();
}

class _BarberMessagesPageState extends State<BarberMessagesPage> {
  final _messageController = TextEditingController();
  String? _selectedCustomerEmail;
  Map<String, dynamic>? _selectedCustomerData;
  bool _isLoading = true;
  String? _errorMessage;
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (_currentUser == null) {
      setState(() {
        _errorMessage = 'User not authenticated. Please log in.';
        _isLoading = false;
      });
      return;
    }
    print('Current user: ${_currentUser!.email}');
    _fetchCustomers();
  }

  // Fetch customers who have messaged the barber
  Future<void> _fetchCustomers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('BarbersDetails')
              .doc(_currentUser!.email)
              .collection('messages')
              .limit(100)
              .get();

      final customerEmails =
          snapshot.docs
              .map((doc) => doc['senderId'] as String?)
              .where((email) => email != null && email != _currentUser!.email)
              .toSet()
              .toList();
      print(
        'Fetched ${customerEmails.length} unique customers: $customerEmails',
      );

      final customerData = <String, Map<String, dynamic>>{};
      for (var email in customerEmails) {
        final doc =
            await FirebaseFirestore.instance
                .collection('CustomersDetails')
                .doc(email)
                .get();
        if (doc.exists && doc.data() != null) {
          customerData[email!] = doc.data()!;
          print('Fetched data for $email: ${doc.data()}');
        }
      }

      setState(() {
        _isLoading = false;
        if (customerEmails.isNotEmpty) {
          _selectedCustomerEmail = customerEmails.first;
          _selectedCustomerData = customerData[customerEmails.first];
        }
      });
    } catch (e) {
      print('Error fetching customers: $e');
      setState(() {
        _errorMessage = 'Error loading customers: $e';
        _isLoading = false;
      });
    }
  }

  // Send a message to Firestore
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty ||
        _selectedCustomerEmail == null ||
        _currentUser == null) {
      print('Cannot send message: empty text or null customer/user');
      setState(() {
        _errorMessage = 'Please select a customer and enter a message.';
      });
      return;
    }
    try {
      final messageData = {
        'senderId': _currentUser!.email,
        'receiverId': _selectedCustomerEmail,
        'text': _messageController.text.trim(),
        'timestamp': Timestamp.now(),
        'senderType': 'barber',
      };
      print('Sending message to $_selectedCustomerEmail: $messageData');

      // Send to barber's messages collection
      await FirebaseFirestore.instance
          .collection('BarbersDetails')
          .doc(_currentUser!.email)
          .collection('messages')
          .add(messageData);

      // Send to customer's messages collection for bidirectional sync
      await FirebaseFirestore.instance
          .collection('CustomersDetails')
          .doc(_selectedCustomerEmail)
          .collection('messages')
          .add(messageData);

      print('Message sent successfully to $_selectedCustomerEmail');
      _messageController.clear();
      setState(() {
        _errorMessage = null;
      });
    } catch (e) {
      print('Error sending message: $e');
      setState(() {
        _errorMessage = 'Error sending message: $e';
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'Messages',
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 60, color: Colors.red[400]),
              const SizedBox(height: 20),
              Text(
                'User not authenticated. Please log in.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.red[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
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
                  'Go to Login',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _selectedCustomerData != null
              ? _selectedCustomerData!['fullName'] ?? 'Messages'
              : 'Messages',
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
                      'Loading...',
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
                        onPressed: _fetchCustomers,
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
              : _selectedCustomerEmail == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.message, size: 60, color: Colors.blue[400]),
                    const SizedBox(height: 20),
                    Text(
                      'No messages yet.',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              )
              : _buildChatView(),
    );
  }

  // Widget to display chat with selected customer
  Widget _buildChatView() {
    return Column(
      children: [
        // Customer selection dropdown
        Padding(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('BarbersDetails')
                    .doc(_currentUser!.email)
                    .collection('messages')
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                print('Error in customer stream: ${snapshot.error}');
                return Center(
                  child: Text(
                    'Error loading customers: ${snapshot.error}',
                    style: GoogleFonts.poppins(color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              final customerEmails =
                  snapshot.data!.docs
                      .map((doc) => doc['senderId'] as String?)
                      .where(
                        (email) =>
                            email != null && email != _currentUser!.email,
                      )
                      .toSet()
                      .toList();
              print('Customer emails in dropdown: $customerEmails');
              if (customerEmails.isEmpty) {
                return Center(
                  child: Text(
                    'No customers found.',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                );
              }
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: Future.wait(
                  customerEmails.map((email) async {
                    final doc =
                        await FirebaseFirestore.instance
                            .collection('CustomersDetails')
                            .doc(email)
                            .get();
                    return {
                      'email': email,
                      'data': doc.exists ? doc.data() ?? {} : {},
                    };
                  }),
                ),
                builder: (context, customerSnapshot) {
                  if (customerSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (customerSnapshot.hasError) {
                    print('Customer snapshot error: ${customerSnapshot.error}');
                    return Center(
                      child: Text(
                        'Error loading customer data: ${customerSnapshot.error}',
                        style: GoogleFonts.poppins(color: Colors.red[700]),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  final customers = customerSnapshot.data ?? [];
                  print('Customers in dropdown: $customers');
                  if (customers.isEmpty) {
                    return Center(
                      child: Text(
                        'No customers found.',
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    );
                  }
                  return DropdownButton<String>(
                    value: _selectedCustomerEmail,
                    isExpanded: true,
                    items:
                        customers.map((customer) {
                          final data =
                              customer['data'] as Map<String, dynamic>? ?? {};
                          final name =
                              data['fullName'] as String? ??
                              customer['email'] ??
                              'Unknown';
                          return DropdownMenuItem(
                            value: customer['email'] as String?,
                            child: Text(
                              name,
                              style: GoogleFonts.poppins(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCustomerEmail = value;
                          _selectedCustomerData =
                              customers.firstWhere(
                                (c) => c['email'] == value,
                                orElse: () => {'data': {}},
                              )['data'];
                        });
                        print(
                          'Selected customer: $value, data: $_selectedCustomerData',
                        );
                      }
                    },
                    style: GoogleFonts.poppins(color: Colors.blue.shade800),
                    underline: Container(),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: Colors.blue.shade800,
                    ),
                  );
                },
              );
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('BarbersDetails')
                    .doc(_currentUser!.email)
                    .collection('messages')
                    .where(
                      'senderId',
                      whereIn: [_selectedCustomerEmail, _currentUser!.email],
                    )
                    .where(
                      'receiverId',
                      whereIn: [_selectedCustomerEmail, _currentUser!.email],
                    )
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                print('Error loading messages: ${snapshot.error}');
                return Center(
                  child: Text(
                    'Error loading messages: ${snapshot.error}',
                    style: GoogleFonts.poppins(color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              final messages = snapshot.data!.docs;
              if (messages.isEmpty) {
                return Center(
                  child: Text(
                    'No messages yet. Start the conversation!',
                    style: GoogleFonts.poppins(color: Colors.grey[700]),
                  ),
                );
              }
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final messageData =
                      messages[index].data() as Map<String, dynamic>;
                  final isBarber = messageData['senderType'] == 'barber';
                  final text = messageData['text'] as String? ?? '';
                  final timestamp =
                      (messageData['timestamp'] as Timestamp?)?.toDate();
                  return Align(
                    alignment:
                        isBarber ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      decoration: BoxDecoration(
                        color: isBarber ? Colors.blue[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            isBarber
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                        children: [
                          Text(
                            text,
                            style: GoogleFonts.poppins(
                              color: isBarber ? Colors.white : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timestamp != null
                                ? '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}'
                                : '',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color:
                                  isBarber ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.send, color: Colors.blue[800]),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
