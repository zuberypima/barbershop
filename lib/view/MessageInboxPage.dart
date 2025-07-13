import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barber/services/navigator.dart'; // Assuming your navigator service

class MessageInboxPage extends StatefulWidget {
  final String? initialBarberEmail; // Optional: Pre-select a barber

  const MessageInboxPage({super.key, this.initialBarberEmail});

  @override
  State<MessageInboxPage> createState() => _MessageInboxPageState();
}

class _MessageInboxPageState extends State<MessageInboxPage> {
  final _messageController = TextEditingController();
  String? _selectedBarberEmail;
  Map<String, dynamic>? _selectedBarberData;
  bool _isLoading = true;
  String? _errorMessage;
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _selectedBarberEmail = widget.initialBarberEmail;
    _fetchBarbers();
  }

  // Fetch all barbers from Firestore
  Future<void> _fetchBarbers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final snapshot = await FirebaseFirestore.instance.collection('BarbersDetails').get();
      print('Fetched ${snapshot.docs.length} barbers');
      if (_selectedBarberEmail != null) {
        final barberDoc = snapshot.docs.firstWhere(
          (doc) => doc.id == _selectedBarberEmail,
          orElse: () => throw Exception('Barber not found'),
        );
        setState(() {
          _selectedBarberData = barberDoc.data();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching barbers: $e');
      setState(() {
        _errorMessage = 'Error loading barbers: $e';
        _isLoading = false;
      });
    }
  }

  // Send a message to Firestore
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _selectedBarberEmail == null || _currentUser == null) {
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('BarbersDetails')
          .doc(_selectedBarberEmail)
          .collection('messages')
          .add({
        'senderId': _currentUser.email,
        'receiverId': _selectedBarberEmail,
        'text': _messageController.text.trim(),
        'timestamp': Timestamp.now(),
        'senderType': 'customer',
      });
      print('Message sent to $_selectedBarberEmail');
      _messageController.clear();
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _selectedBarberData != null
              ? _selectedBarberData!['shopName'] ?? 'Chat'
              : 'Message Inbox',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_selectedBarberEmail != null)
            IconButton(
              icon: const Icon(Icons.person_search, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedBarberEmail = null;
                  _selectedBarberData = null;
                });
              },
              tooltip: 'Change Barber',
            ),
        ],
      ),
      body: _isLoading
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
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
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
                          style: GoogleFonts.poppins(fontSize: 16, color: Colors.red[700]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _fetchBarbers,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: Text(
                            'Retry',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _selectedBarberEmail == null
                  ? _buildBarberSelection()
                  : _buildChatView(),
    );
  }

  // Widget to select a barber
  Widget _buildBarberSelection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('BarbersDetails').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: GoogleFonts.poppins(color: Colors.red[700]),
            ),
          );
        }
        final barbers = snapshot.data!.docs;
        if (barbers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off, size: 60, color: Colors.blue[400]),
                const SizedBox(height: 20),
                Text(
                  'No barbers found.',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: barbers.length,
          itemBuilder: (context, index) {
            final barberData = barbers[index].data() as Map<String, dynamic>;
            final fullName = barberData['fullName'] as String? ?? 'N/A';
            final shopName = barberData['shopName'] as String? ?? 'N/A';
            final profileImageUrl = barberData['profileImageUrl'] as String?;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    _selectedBarberEmail = barbers[index].id;
                    _selectedBarberData = barberData;
                  });
                  print('Selected barber: $_selectedBarberEmail');
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: profileImageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(profileImageUrl),
                                  fit: BoxFit.cover,
                                )
                              : const DecorationImage(
                                  image: AssetImage('assets/default_profile.png'),
                                  fit: BoxFit.cover,
                                ),
                        ),
                        child: profileImageUrl == null
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              shopName,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.message, color: Colors.blue[800]),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Widget to display chat with selected barber
  Widget _buildChatView() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('BarbersDetails')
                .doc(_selectedBarberEmail)
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: GoogleFonts.poppins(color: Colors.red[700]),
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
                reverse: true, // Newest messages at the bottom
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final messageData = messages[index].data() as Map<String, dynamic>;
                  final isCustomer = messageData['senderType'] == 'customer';
                  final text = messageData['text'] as String;
                  final timestamp = (messageData['timestamp'] as Timestamp?)?.toDate();
                  return Align(
                    alignment: isCustomer ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                      decoration: BoxDecoration(
                        color: isCustomer ? Colors.blue[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            isCustomer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            text,
                            style: GoogleFonts.poppins(
                              color: isCustomer ? Colors.white : Colors.black87,
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
                              color: isCustomer ? Colors.white70 : Colors.grey[600],
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