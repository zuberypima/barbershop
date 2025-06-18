import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class BarberCompleteProfilePage extends StatefulWidget {
  final String barberId;

  const BarberCompleteProfilePage({super.key, required this.barberId});

  @override
  State<BarberCompleteProfilePage> createState() =>
      _BarberCompleteProfilePageState();
}

class _BarberCompleteProfilePageState extends State<BarberCompleteProfilePage> {
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // Form fields
  String _bio = '';
  List<String> _services = [];
  String _newService = '';
  double _servicePrice = 0;
  int _serviceDuration = 30;
  Map<String, bool> _workingDays = {
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
    'Saturday': false,
    'Sunday': false,
  };
  TimeOfDay _openingTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _closingTime = TimeOfDay(hour: 17, minute: 0);
  List<File> _shopPhotos = [];
  bool _isLoading = false;

  Future<void> _pickShopPhotos() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null) {
      setState(() {
        _shopPhotos.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  void _addService() {
    if (_newService.isNotEmpty) {
      setState(() {
        _services.add('$_newService|\$$_servicePrice|$_serviceDuration min');
        _newService = '';
        _servicePrice = 0;
        _serviceDuration = 30;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one service')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload shop photos
      final photoUrls = await Future.wait(
        _shopPhotos.map(
          (file) => _uploadImage(
            file,
            'shop_${DateTime.now().millisecondsSinceEpoch}',
          ),
        ),
      );

      // Prepare working hours
      final workingHours = {};
      for (var day in _workingDays.entries) {
        if (day.value) {
          workingHours[day.key] = {
            'open': '${_openingTime.hour}:${_openingTime.minute}',
            'close': '${_closingTime.hour}:${_closingTime.minute}',
          };
        }
      }

      // Update barber document
      await _firestore.collection('barbers').doc(widget.barberId).update({
        'bio': _bio,
        'services': _services,
        'workingHours': workingHours,
        'shopPhotos': photoUrls,
        'profileCompleted': true,
      });

      // Navigate to barber dashboard
      Navigator.pushReplacementNamed(context, '/barber-dashboard');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save profile. Please try again'),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _uploadImage(File image, String name) async {
    final ref = FirebaseStorage.instance.ref().child('shop_photos/$name');
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Future<void> _selectTime(BuildContext context, bool isOpening) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isOpening ? _openingTime : _closingTime,
    );

    if (picked != null) {
      setState(() {
        if (isOpening) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Your Profile', style: GoogleFonts.poppins()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bio
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'About You',
                  hintText: 'Tell clients about your experience and style...',
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please write something about yourself';
                  return null;
                },
                onChanged: (value) => _bio = value,
              ),
              const SizedBox(height: 25),

              // Services
              Text(
                'Your Services',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Service Name',
                      ),
                      onChanged: (value) => _newService = value,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Price (\$)',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged:
                          (value) =>
                              _servicePrice = double.tryParse(value) ?? 0,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<int>(
                      value: _serviceDuration,
                      items:
                          [15, 30, 45, 60, 90, 120].map((duration) {
                            return DropdownMenuItem(
                              value: duration,
                              child: Text('$duration min'),
                            );
                          }).toList(),
                      onChanged: (value) => _serviceDuration = value ?? 30,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _addService,
                child: const Text('Add Service'),
              ),
              const SizedBox(height: 15),

              // Added Services List
              if (_services.isNotEmpty) ...[
                const Text('Your Service List:'),
                const SizedBox(height: 10),
                ..._services.map((service) {
                  final parts = service.split('|');
                  return ListTile(
                    title: Text(parts[0]),
                    subtitle: Text('${parts[1]} • ${parts[2]}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _services.remove(service);
                        });
                      },
                    ),
                  );
                }).toList(),
                const SizedBox(height: 20),
              ],

              // Working Days
              Text(
                'Working Days',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children:
                    _workingDays.entries.map((day) {
                      return FilterChip(
                        label: Text(day.key),
                        selected: day.value,
                        onSelected: (selected) {
                          setState(() {
                            _workingDays[day.key] = selected;
                          });
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 15),

              // Working Hours
              if (_workingDays.containsValue(true)) ...[
                Text(
                  'Working Hours',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Opening Time'),
                        subtitle: Text(_openingTime.format(context)),
                        onTap: () => _selectTime(context, true),
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text('Closing Time'),
                        subtitle: Text(_closingTime.format(context)),
                        onTap: () => _selectTime(context, false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Shop Photos
              Text(
                'Shop Photos',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text('Upload photos of your shop (3-5 recommended)'),
              const SizedBox(height: 10),
              InkWell(
                onTap: _pickShopPhotos,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate),
                      Text('Add Photos'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Preview Selected Photos
              if (_shopPhotos.isNotEmpty) ...[
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _shopPhotos.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            Image.file(
                              _shopPhotos[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _shopPhotos.removeAt(index);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Complete Profile Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue[800],
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                            'Complete Profile',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
