import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatefulWidget {
  final bool isBarber;
  const ProfilePage({super.key, required this.isBarber});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  // Profile data
  String _name = "John Doe";
  String _email = "john@example.com";
  String _phone = "+1 234 567 890";
  String _bio = "Professional barber with 5 years experience";
  String _specialty = "Fades & Beard Trims";
  String _address = "123 Barber St, New York";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('My Profile', style: GoogleFonts.poppins()),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (_isEditing && _formKey.currentState!.validate()) {
                // Save changes
                _formKey.currentState!.save();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Profile updated successfully')),
                );
              }
              setState(() => _isEditing = !_isEditing);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Header
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[800],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Positioned(
                  top: 20,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 46,
                      backgroundImage: AssetImage(
                        'assets/images/default_profile.jpg',
                      ),
                    ),
                  ),
                ),
                if (_isEditing)
                  Positioned(
                    right: 120,
                    bottom: 10,
                    child: IconButton(
                      icon: Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: () {
                        // Implement image picker
                      },
                    ),
                  ),
              ],
            ),
            SizedBox(height: 30),

            // Profile Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildEditableField(
                    label: 'Full Name',
                    value: _name,
                    icon: Icons.person,
                    onSaved: (value) => _name = value!,
                  ),
                  SizedBox(height: 15),
                  _buildEditableField(
                    label: 'Email',
                    value: _email,
                    icon: Icons.email,
                    onSaved: (value) => _email = value!,
                  ),
                  SizedBox(height: 15),
                  _buildEditableField(
                    label: 'Phone',
                    value: _phone,
                    icon: Icons.phone,
                    onSaved: (value) => _phone = value!,
                  ),
                  SizedBox(height: 15),

                  if (widget.isBarber) ...[
                    _buildEditableField(
                      label: 'Specialty',
                      value: _specialty,
                      icon: Icons.cut,
                      onSaved: (value) => _specialty = value!,
                    ),
                    SizedBox(height: 15),
                  ],

                  _buildEditableField(
                    label: widget.isBarber ? 'Shop Address' : 'Home Address',
                    value: _address,
                    icon: Icons.location_on,
                    onSaved: (value) => _address = value!,
                  ),
                  SizedBox(height: 20),

                  // Bio Section
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blueGrey),
                              SizedBox(width: 10),
                              Text(
                                'About Me',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          _isEditing
                              ? TextFormField(
                                initialValue: _bio,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.all(10),
                                ),
                                onSaved: (value) => _bio = value!,
                              )
                              : Text(_bio, style: GoogleFonts.poppins()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),

            // Role-Specific Features
            if (widget.isBarber) _buildBarberFeatures(),
            if (!widget.isBarber) _buildClientFeatures(),

            SizedBox(height: 20),
            Divider(),
            SizedBox(height: 10),

            // Account Actions
            ListTile(
              leading: Icon(Icons.settings, color: Colors.blueGrey),
              title: Text('Account Settings', style: GoogleFonts.poppins()),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Log Out', style: GoogleFonts.poppins()),
              onTap: () {
                // Implement logout
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required IconData icon,
    required FormFieldSetter<String> onSaved,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(color: Colors.blueGrey, fontSize: 12),
            ),
            Row(
              children: [
                Icon(icon, color: Colors.blueGrey, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child:
                      _isEditing
                          ? TextFormField(
                            initialValue: value,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: GoogleFonts.poppins(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter $label';
                              }
                              return null;
                            },
                            onSaved: onSaved,
                          )
                          : Text(
                            value,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarberFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Barber Tools',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _buildFeatureButton('My Schedule', Icons.calendar_today),
            _buildFeatureButton('Services', Icons.attractions),
            _buildFeatureButton('Earnings', Icons.monetization_on),
            _buildFeatureButton('Clients', Icons.people),
          ],
        ),
      ],
    );
  }

  Widget _buildClientFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Appointments',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.cut, color: Colors.blue),
            ),
            title: Text('Haircut with Mario', style: GoogleFonts.poppins()),
            subtitle: Text('Tomorrow, 2:00 PM', style: GoogleFonts.poppins()),
            trailing: Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: Icon(Icons.search),
                label: Text('Find Barbers'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {},
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                icon: Icon(Icons.history),
                label: Text('History'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureButton(String text, IconData icon) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(text, style: GoogleFonts.poppins(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        side: BorderSide(color: Colors.grey[300]!),
      ),
      onPressed: () {},
    );
  }
}
