import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class BarberShopsPage extends StatefulWidget {
  const BarberShopsPage({super.key});

  @override
  State<BarberShopsPage> createState() => _BarberShopsPageState();
}

class _BarberShopsPageState extends State<BarberShopsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Simulate network delay for demo purposes
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Barber Shops', style: GoogleFonts.poppins()),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search barber shops...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingShimmer();
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load barber shops',
              style: GoogleFonts.poppins(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('BarbersDetails').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final shops =
            snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = data['shopName']?.toString().toLowerCase() ?? '';
              final address =
                  data['shopAddress']?.toString().toLowerCase() ?? '';
              final specialties =
                  data['specialties']?.toString().toLowerCase() ?? '';

              // Apply search filter
              if (_searchQuery.isNotEmpty) {
                if (!name.contains(_searchQuery) &&
                    !address.contains(_searchQuery) &&
                    !specialties.contains(_searchQuery)) {
                  return false;
                }
              }

              // Apply category filter
              if (_selectedFilter != 'all') {
                if (data['category'] != _selectedFilter) {
                  return false;
                }
              }

              return true;
            }).toList();

        if (shops.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 48),
                const SizedBox(height: 16),
                Text(
                  'No barber shops found',
                  style: GoogleFonts.poppins(fontSize: 18),
                ),
                if (_searchQuery.isNotEmpty || _selectedFilter != 'all')
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _selectedFilter = 'all';
                        _searchController.clear();
                      });
                    },
                    child: const Text('Clear filters'),
                  ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: shops.length,
          itemBuilder: (context, index) {
            final shop = shops[index];
            final data = shop.data() as Map<String, dynamic>;
            return _buildShopCard(data, context);
          },
        );
      },
    );
  }

  Widget _buildShopCard(Map<String, dynamic> data, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to shop details page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BarberShopDetailPage(shopId: data['id']),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: data['imageUrl'] ?? '',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        color: Colors.grey[200],
                        width: 100,
                        height: 100,
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        color: Colors.grey[200],
                        width: 100,
                        height: 100,
                        child: const Icon(Icons.store, size: 40),
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['shopName'] ?? 'Unknown Shop',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          data['rating']?.toStringAsFixed(1) ?? '0.0',
                          style: GoogleFonts.poppins(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${data['reviewCount'] ?? 0} reviews)',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            data['shopAddress'] ?? 'No address provided',
                            style: GoogleFonts.poppins(color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (data['specialties'] != null)
                      Wrap(
                        spacing: 4,
                        children:
                            (data['specialties'] as String)
                                .split(',')
                                .map(
                                  (specialty) => Chip(
                                    label: Text(
                                      specialty.trim(),
                                      style: GoogleFonts.poppins(fontSize: 12),
                                    ),
                                    backgroundColor: Colors.blue[50],
                                    visualDensity: VisualDensity.compact,
                                  ),
                                )
                                .toList(),
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

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 100, height: 100, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Container(width: 100, height: 16, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showFilterDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Filter Shops', style: GoogleFonts.poppins()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('All Shops'),
                value: 'all',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  Navigator.pop(context, value);
                },
              ),
              RadioListTile<String>(
                title: const Text('Premium'),
                value: 'premium',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  Navigator.pop(context, value);
                },
              ),
              RadioListTile<String>(
                title: const Text('Traditional'),
                value: 'traditional',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  Navigator.pop(context, value);
                },
              ),
              RadioListTile<String>(
                title: const Text('Modern'),
                value: 'modern',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  Navigator.pop(context, value);
                },
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedFilter = result;
      });
    }
  }
}

// Placeholder for the detail page (you should implement this separately)
class BarberShopDetailPage extends StatelessWidget {
  final String shopId;

  const BarberShopDetailPage({super.key, required this.shopId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop Details')),
      body: Center(child: Text('Details for shop $shopId')),
    );
  }
}
