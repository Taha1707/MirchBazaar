import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:project/services/validation.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:project/user/my_orders.dart';

// Store location coordinates (Replace with your actual store coordinates)
const double STORE_LAT = 24.8607;  // Replace with your store's latitude
const double STORE_LNG = 67.0011;  // Replace with your store's longitude

// Delivery charges configuration
const double BASE_CHARGE = 80.0;
const double PER_KM_CHARGE = 10.0;
const double FREE_DELIVERY_THRESHOLD = 1.0; // 1 km

/// Get coordinates from address using OpenStreetMap Nominatim API
Future<LatLng?> getCoordinatesFromAddress(String address) async {
  try {
    final encodedAddress = Uri.encodeComponent(address);
    final url = "https://nominatim.openstreetmap.org/search?format=json&q=$encodedAddress&limit=1";

    final response = await http.get(Uri.parse(url), headers: {
      "User-Agent": "YourAppName/1.0 (your@email.com)"
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        final lat = double.parse(data[0]["lat"]);
        final lng = double.parse(data[0]["lon"]);
        return LatLng(lat, lng);
      }
    }
    return null;
  } catch (e) {
    print("Geocoding error: $e");
    return null;
  }
}

/// Calculate delivery charges based on distance
double calculateDeliveryCharges(double distanceInKm) {
  if (distanceInKm <= FREE_DELIVERY_THRESHOLD) {
    return BASE_CHARGE;
  }

  final extraKm = distanceInKm - FREE_DELIVERY_THRESHOLD;
  return BASE_CHARGE + (extraKm * PER_KM_CHARGE);
}

/// Universal function: mobile par geocoding plugin, web par OpenStreetMap API
Future<String> getAddressFromCoordinates(double lat, double lon) async {
  try {
    if (kIsWeb) {
      // Web → OpenStreetMap Nominatim API
      final url =
          "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon";
      final response = await http.get(Uri.parse(url), headers: {
        "User-Agent": "YourAppName/1.0 (your@email.com)" // Nominatim policy
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Full display name
        final displayName = data["display_name"];
        if (displayName != null && displayName.isNotEmpty) {
          return displayName;
        }

        // Fallback: nearest area name
        final address = data["address"];
        if (address != null) {
          return address["suburb"] ??
              address["city"] ??
              address["town"] ??
              address["village"] ??
              address["state"] ??
              "Nearest Area Not Found";
        }
      }
      return "Nearest Area Not Found";
    } else {
      // Mobile → Geocoding Plugin
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        String street = place.street ?? "";
        String subLocality = place.subLocality ?? "";
        String locality = place.locality ?? "";
        String area = place.administrativeArea ?? "";
        String country = place.country ?? "";

        // Full address build
        String address = "$street, $subLocality, $locality, $area, $country"
            .replaceAll(RegExp(r'(,+\\s*)+'), ", ")
            .trim();

        if (address.isNotEmpty && address != ",") {
          return address;
        }

        // Fallback: return nearest area
        return locality.isNotEmpty
            ? locality
            : (area.isNotEmpty ? area : "Nearest Area Not Found");
      }
      return "Nearest Area Not Found";
    }
  } catch (e) {
    return "Nearest Area Not Found";
  }
}

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _searchController = TextEditingController(); // Search bar controller
  String _selectedPayment = 'Cash on Delivery';

  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _isPlacingOrder = false;
  bool _isSearching = false; // For search loading state

  // Delivery charges variables
  double _deliveryCharges = BASE_CHARGE;
  double _distanceInKm = 0.0;
  bool _isCalculatingCharges = false;

  // Map controller for programmatic movement
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _detectCurrentLocation();
  }

  Future<void> _calculateDeliveryChargesFromMap() async {
    if (_selectedLocation == null) return;

    setState(() => _isCalculatingCharges = true);

    final distance = Geolocator.distanceBetween(
        STORE_LAT, STORE_LNG,
        _selectedLocation!.latitude, _selectedLocation!.longitude
    ) / 1000; // Convert to km

    setState(() {
      _distanceInKm = distance;
      _deliveryCharges = calculateDeliveryCharges(distance);
      _isCalculatingCharges = false;
    });
  }

  Future<void> _detectCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    final latLng = LatLng(pos.latitude, pos.longitude);
    final address = await getAddressFromCoordinates(pos.latitude, pos.longitude);

    setState(() {
      _selectedLocation = latLng;
      _selectedAddress = address;
    });

    // Calculate initial delivery charges
    _calculateDeliveryChargesFromMap();
  }

  // Search location function
  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final coordinates = await getCoordinatesFromAddress(query);

      if (coordinates != null) {
        // Move map to the searched location
        _mapController.move(coordinates, 15.0);

        // Get address for the coordinates
        final address = await getAddressFromCoordinates(
            coordinates.latitude,
            coordinates.longitude
        );

        setState(() {
          _selectedLocation = coordinates;
          _selectedAddress = address;
        });

        // Calculate delivery charges for new location
        _calculateDeliveryChargesFromMap();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Location found: ${address.length > 50 ? address.substring(0, 50) + '...' : address}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location not found. Please try a different search term.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error searching location. Please try again.")),
      );
    } finally {
      setState(() => _isSearching = false);
    }
  }

  // dropdown field
  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required String hint,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: Colors.black87,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(icon, hint),
      items: items
          .map(
            (item) => DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      )
          .toList(),
      onChanged: onChanged,
    );
  }

  // text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(icon, hint),
      validator: validator,
      maxLines: maxLines,
    );
  }

  // Search field with search button
  Widget _buildSearchField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              prefixIcon: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.orange, Colors.yellow],
                ).createShader(bounds),
                child: const Icon(Icons.search, color: Colors.white),
              ),
              hintText: "Search location with correct spellings",
              hintStyle: const TextStyle(color: Colors.white70),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.orange, width: 1.5),
              ),
            ),
            onFieldSubmitted: (_) => _searchLocation(),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.orange, Colors.red, Colors.yellow],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: _isSearching ? null : _searchLocation,
            icon: _isSearching
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Icon(Icons.search, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // common input decoration
  InputDecoration _inputDecoration(IconData icon, String hint) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      prefixIcon: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Colors.orange, Colors.yellow],
        ).createShader(bounds),
        child: Icon(icon, color: Colors.white),
      ),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.orange, width: 1.5),
      ),
    );
  }

  // gradient button
  Widget _buildGradientButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.red, Colors.yellow],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(
          text,
          style: const TextStyle(
            letterSpacing: 2,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // get cart items
  Future<List<Map<String, dynamic>>> getCartItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final cartSnapshot = await FirebaseFirestore.instance
        .collection("carts")
        .doc(user.uid)
        .collection("items")
        .get();

    return cartSnapshot.docs.map((doc) => doc.data()).toList();
  }

  // clear cart
  Future<void> _clearCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartRef = FirebaseFirestore.instance
        .collection("carts")
        .doc(user.uid)
        .collection("items");

    final cartSnapshot = await cartRef.get();

    for (var doc in cartSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  // place order
  Future<void> placeOrder(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    // Validate location selection
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your delivery location on the map or search for a location")),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final cartItems = await getCartItems();

      if (cartItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cart is empty")),
        );
        return;
      }

      final itemsTotal = cartItems.fold<double>(0.0, (sum, item) {
        final quantity = (item["quantity"] ?? 0) as int;
        final unitPrice = (item["unitPrice"] ?? 0).toDouble();
        return sum + (quantity * unitPrice);
      });

      final grandTotal = itemsTotal + _deliveryCharges;

      // Prepare order data
      Map<String, dynamic> orderData = {
        "userId": FirebaseAuth.instance.currentUser!.uid,
        "name": _nameController.text.trim(),
        "paymentMethod": _selectedPayment,
        "cartItems": cartItems,
        "itemsTotal": itemsTotal,
        "deliveryCharges": _deliveryCharges,
        "distanceInKm": _distanceInKm,
        "total": grandTotal,
        "status": "Pending",
        "timestamp": FieldValue.serverTimestamp(),
        "location": {
          "lat": _selectedLocation!.latitude,
          "lng": _selectedLocation!.longitude,
        },
        "address": _selectedAddress ?? "Location Selected on Map",
      };

      await FirebaseFirestore.instance.collection("orders").add(orderData);

      // Clear cart after order placed
      await _clearCart();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order placed successfully")),
      );

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyOrdersPage()));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error placing order: $e")),
      );
    } finally {
      setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(width: 1.5, color: Colors.white24),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          "Checkout",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getCartItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final rawCartItems = snapshot.data ?? [];
          if (rawCartItems.isEmpty) {
            return const Center(
              child: Text(
                "Cart is empty",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // Grouping Logic
          Map<String, Map<String, dynamic>> groupedItems = {};
          for (var item in rawCartItems) {
            final key = "${item['title']}_${item['selectedWeight']}";
            if (!groupedItems.containsKey(key)) {
              groupedItems[key] = {
                "title": item["title"],
                "selectedWeight": item["selectedWeight"],
                "quantity": (item["quantity"] ?? 0),
                "unitPrice": item["unitPrice"],
              };
            } else {
              groupedItems[key]!["quantity"] += (item["quantity"] ?? 0);
            }
          }
          final cartItems = groupedItems.values.toList();

          double itemsTotal = cartItems.fold(
            0,
                (sum, item) =>
            sum + ((item["quantity"] ?? 0) * (item["unitPrice"] ?? 0)),
          );

          double grandTotal = itemsTotal + _deliveryCharges;

          return Padding(
            padding: const EdgeInsets.only(top: 50),
            child: Stack(
              children: [
                Container(color: Colors.black),
                Container(color: Colors.black.withOpacity(0.65)),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          _buildTextField(
                            controller: _nameController,
                            hint: "Full Name",
                            icon: Icons.person,
                            validator: validateFullName,
                          ),
                          const SizedBox(height: 14),
                          _buildDropdownField(
                            value: _selectedPayment,
                            items: const [
                              'Cash on Delivery',
                              'Credit/Debit Card',
                              'Wallet',
                            ],
                            hint: "Payment Method",
                            icon: Icons.payment,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedPayment = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 20),

                          // Search Bar
                          _buildSearchField(),
                          const SizedBox(height: 14),

                          // Map Selection
                          SizedBox(
                            height: 250,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter:
                                  _selectedLocation ?? LatLng(24.8738, 67.0416),
                                  initialZoom: 13,
                                  onTap: (tapPosition, point) async {
                                    setState(() {
                                      _selectedLocation = point;
                                    });

                                    String address =
                                    await getAddressFromCoordinates(
                                      point.latitude,
                                      point.longitude,
                                    );

                                    setState(() {
                                      _selectedAddress = address;
                                    });

                                    // Calculate delivery charges when map location changes
                                    _calculateDeliveryChargesFromMap();
                                  },
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                    subdomains: const ['a', 'b', 'c'],
                                    userAgentPackageName: 'com.example.app',
                                  ),
                                  if (_selectedLocation != null)
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: _selectedLocation!,
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
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Selected address display
                          if (_selectedAddress != null &&
                              _selectedAddress!.isNotEmpty &&
                              !_selectedAddress!.contains("Nearest Area"))
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on, color: Colors.orange, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedAddress!,
                                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Delivery charges info
                          if (_distanceInKm > 0) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.local_shipping, color: Colors.orange, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Distance: ${_distanceInKm.toStringAsFixed(1)} km",
                                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                                    ),
                                  ),
                                  if (_isCalculatingCharges)
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 30),

                          // Order Details
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.05),
                                  Colors.white.withOpacity(0.02),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 14,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Theme(
                              data: Theme.of(context)
                                  .copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                collapsedIconColor: Colors.orangeAccent,
                                iconColor: Colors.orangeAccent,
                                textColor: Colors.orangeAccent,
                                backgroundColor: Colors.transparent,
                                tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                childrenPadding: EdgeInsets.zero,
                                expandedCrossAxisAlignment:
                                CrossAxisAlignment.start,
                                title: const Row(
                                  children: [
                                    Icon(
                                      Icons.receipt_long,
                                      color: Colors.orangeAccent,
                                      size: 22,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      "Order Details",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 19,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                children: [
                                  Column(
                                    children:
                                    List.generate(cartItems.length, (index) {
                                      final item = cartItems[index];
                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.06),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.1),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item["title"] ?? "",
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "Qty: ${item["quantity"] ?? 0} • ${item["selectedWeight"] ?? ""}",
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              "Rs. ${(item["quantity"] ?? 0) * (item["unitPrice"] ?? 0)}",
                                              style: const TextStyle(
                                                color: Colors.orangeAccent,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ),
                                  const Divider(
                                    color: Colors.white24,
                                    thickness: 0.5,
                                    height: 20,
                                  ),

                                  // Items Subtotal
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Items Total:",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          "Rs. ${itemsTotal.toStringAsFixed(0)}",
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Delivery Charges
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Text(
                                              "Delivery Charges:",
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            if (_isCalculatingCharges) ...[
                                              const SizedBox(width: 8),
                                              const SizedBox(
                                                width: 12,
                                                height: 12,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 1.5,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Text(
                                          "Rs. ${_deliveryCharges.toStringAsFixed(0)}",
                                          style: const TextStyle(
                                            color: Colors.orange,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const Divider(
                                    color: Colors.white24,
                                    thickness: 0.5,
                                    height: 20,
                                  ),

                                  // Grand Total
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Grand Total:",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          "Rs. ${grandTotal.toStringAsFixed(0)}",
                                          style: const TextStyle(
                                            color: Colors.orangeAccent,
                                            fontSize: 19,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          _isPlacingOrder
                              ? Container(
                            padding: const EdgeInsets.all(20),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.deepOrange,
                                strokeWidth: 4,
                              ),
                            ),
                          )
                              : _buildGradientButton(
                            text: "Place Order",
                            onTap: () => placeOrder(context),
                          )

                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}