import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'cart_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int quantity = 1;
  String selectedWeight = "250g";
  bool isSaving = false;
  double _spiceMeter = 0.0;

  // Cart notification state - stays visible
  bool _showCartNotification = false;
  int _totalCartItems = 0;
  double _totalCartPrice = 0.0;

  @override
  void initState() {
    super.initState();

    final raw = widget.product['spiceMeter']; // 👈 check field name yahi hai?
    if (raw is int) {
      _spiceMeter = raw.toDouble();
    } else if (raw is double) {
      _spiceMeter = raw;
    } else {
      _spiceMeter = 0;
    }

    print("🔥 spiceMeter = $_spiceMeter"); // debug print

    // Load cart data on init
    _loadCartData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Load cart data to show current cart status
  Future<void> _loadCartData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('carts')
          .doc(user.uid)
          .collection('items')
          .get();

      if (cartSnapshot.docs.isNotEmpty) {
        int totalItems = 0;
        double totalPrice = 0.0;

        for (var doc in cartSnapshot.docs) {
          final data = doc.data();
          totalItems += (data['quantity'] ?? 0) as int;
          totalPrice += (data['totalPrice'] ?? 0.0) as double;
        }

        setState(() {
          _totalCartItems = totalItems;
          _totalCartPrice = totalPrice;
          _showCartNotification = totalItems > 0;
        });
      }
    } catch (e) {
      print("Error loading cart data: $e");
    }
  }

  void _updateCartNotification() {
    setState(() {
      _totalCartItems = _totalCartItems + quantity;
      _totalCartPrice = _totalCartPrice + (getPrice() * quantity);
      _showCartNotification = true;
    });
  }

  Uint8List? decodeImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (_) {
      return null;
    }
  }

  double getPrice() {
    final num raw = (widget.product['pricePer250g'] ?? 0);
    final double pricePer250g = raw.toDouble();
    switch (selectedWeight) {
      case "250g":
        return pricePer250g;
      case "500g":
        return pricePer250g * 2;
      case "1kg":
        return pricePer250g * 4;
      case "2kg":
        return pricePer250g * 8;
      default:
        return pricePer250g;
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 350,
                pinned: true,
                backgroundColor: Colors.grey[900],
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5), // glassy black bg
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
                flexibleSpace: FlexibleSpaceBar(
                  background: decodeImage(product['image']) != null
                      ? ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    child: Image.memory(
                      decodeImage(product['image'])!,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: Icon(Icons.image, size: 100, color: Colors.grey),
                    ),
                  ),
                ),
              ),

              // 🔥 Detail Container
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey[900]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          height: 5,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.white38,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // 🔥 Title & Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              (product['title'] ?? 'No Title').toString(),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          // price
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.orange, Colors.red],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "Rs. ${getPrice()}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 🔥 Description
                          Expanded(
                            child: Text(
                              (product['description'] ?? 'No Description')
                                  .toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ⚖️ Weight Selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: ["250g", "500g", "1kg", "2kg"].map((weight) {
                              final bool isSelected = selectedWeight == weight;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedWeight = weight;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? const LinearGradient(
                                      colors: [Colors.orange, Colors.red],
                                    )
                                        : null,
                                    color: isSelected ? null : Colors.grey[800],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    weight,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    if (quantity > 1) {
                                      setState(() => quantity--);
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  quantity.toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    setState(() => quantity++);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // 📂 Category
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Category",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),

                          if (product['category'] != null &&
                              (product['category'] as List).isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: (product['category'] as List).map((cat) {
                                return Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "•  ",
                                        style: TextStyle(
                                          color: Colors.orangeAccent,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          cat.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            )
                          else
                            const Text(
                              "No categories available",
                              style: TextStyle(color: Colors.white54),
                            ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // 🌶 Spice Meter
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Spice Level",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: List.generate(6, (index) {
                              final int spiceValue = _spiceMeter.round().clamp(
                                0,
                                6,
                              );

                              // Color logic
                              final Color bandColor = (index < 2)
                                  ? Colors.green
                                  : (index < 4 ? Colors.yellow : Colors.red);

                              final bool filled = index < spiceValue;
                              final Color iconColor = filled
                                  ? bandColor
                                  : Colors.white24;

                              return Padding(
                                padding: const EdgeInsets.only(right: 3),
                                child: Icon(
                                  Icons.whatshot, // 🔥
                                  color: iconColor,
                                  size: 22,
                                ),
                              );
                            }),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ⭐ Reviews
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Reviews",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: List.generate(5, (index) {
                              final num raw =
                              (product['review'] ?? product['rating'] ?? 0);
                              final double rating = raw.toDouble();
                              return Padding(
                                padding: const EdgeInsets.only(right: 3),
                                child: Icon(
                                  Icons.star,
                                  color: index < rating
                                      ? Colors.orangeAccent
                                      : Colors.grey,
                                  size: 20,
                                ),
                              );
                            }),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // 🛒 Add to Cart
                      SizedBox(
                        width: double.infinity,
                        child: isSaving
                            ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.deepOrange,
                              ),
                            ),
                          ),
                        )
                            : _buildGradientButton(
                          text: "ADD TO CART",
                          onTap: () {
                            addToCart();
                          },
                        ),
                      ),

                      // const SizedBox(height: 40),

                      // // 🛡️ Key Points Section
                      // _sectionHeading("What We Offer"),
                      // const SizedBox(height: 12),
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                      //   child: Column(
                      //     crossAxisAlignment: CrossAxisAlignment.center,
                      //     children: [
                      //       Row(
                      //         mainAxisAlignment: MainAxisAlignment.center, // 👈 center align
                      //         children: [
                      //           _statCard("🚚", "Fast", "Delivery"),
                      //           const SizedBox(width: 20),
                      //           _statCard("🌱", "100%", "Natural"),
                      //         ],
                      //       ),
                      //       const SizedBox(height: 20),
                      //       Row(
                      //         mainAxisAlignment: MainAxisAlignment.center, // 👈 center align
                      //         children: [
                      //           _statCard("💎", "Top", "Quality"),
                      //           const SizedBox(width: 20),
                      //           _statCard("⭐", "Most", "Loved"),
                      //         ],
                      //       ),
                      //     ],
                      //   ),
                      // ),

                      const SizedBox(height: 30),

                      // 🛍 More Products Section (random 4 products)
                      _sectionHeading("More Products"),
                      const SizedBox(height: 26),
                      StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection('products')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          // 🔹 Firestore data list
                          final docs = snapshot.data!.docs;

                          // 🔹 Availability = true filter
                          final availableProducts = docs
                              .where(
                                (doc) =>
                            (doc.data()
                            as Map<String, dynamic>)['availability'] ==
                                true,
                          )
                              .toList();

                          if (availableProducts.isEmpty) {
                            return const Text(
                              "No available products",
                              style: TextStyle(color: Colors.white70),
                            );
                          }

                          // 🔹 Random shuffle and pick 4
                          availableProducts.shuffle();
                          final randomProducts = availableProducts.take(4).toList();

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: randomProducts.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 15,
                              mainAxisSpacing: 15,
                              childAspectRatio: 0.9,
                            ),
                            itemBuilder: (context, index) {
                              final data = randomProducts[index].data() as Map<String, dynamic>;

                              return Material(
                                elevation: 6,
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.white.withOpacity(0.12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductDetailPage(
                                          product: {
                                            "title": data['title'],
                                            "description": data['description'],
                                            "pricePer250g": data['pricePer250g'],
                                            "image": data['image'],
                                            "category": data['category'],
                                            "availability": data['availability'],
                                            "review": data['review'],
                                            "spiceMeter": data['spiceMeter'],
                                            "timestamp": data['timestamp']?.toString(),
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 12,
                                        sigmaY: 12,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            width: 1.5,
                                            color: Colors.white.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // 🔹 Product Image
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius: const BorderRadius.vertical(
                                                  top: Radius.circular(16),
                                                ),
                                                child: Image.memory(
                                                  base64Decode(data['image']),
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),

                                            // 🔹 Product Details
                                            Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    data['title'] ?? 'No Title',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 8),

                                                  // Price Row
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 7,
                                                          vertical: 3,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          gradient: const LinearGradient(
                                                            colors: [Colors.orange, Colors.red],
                                                          ),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          "Rs. ${data['pricePer250g'] ?? '0'}",
                                                          style: const TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      const Text(
                                                        "(250g)",
                                                        style: TextStyle(
                                                          color: Colors.white54,
                                                          fontSize: 8,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      // ✨ Ending Line
                      const Center(
                        child: Text(
                          "🌶️ Bringing Authentic Spices to Your Kitchen — Pure, Fresh & Full of Flavor!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                      // Add extra padding at bottom for cart notification space
                      SizedBox(height: _showCartNotification ? 100 : 20),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 🛒 FoodPanda-style Persistent Cart Bar
          if (_showCartNotification)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.red],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CartPage(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    children: [
                      // Cart Icon with items count
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.shopping_cart,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          // Items count badge
                          if (_totalCartItems > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _totalCartItems.toString(),
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(width: 16),

                      // Cart details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "$_totalCartItems item${_totalCartItems > 1 ? 's' : ''} in cart",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Total: Rs. ${_totalCartPrice.toStringAsFixed(0)}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Arrow icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

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

  Future<void> addToCart() async {
    setState(() {
      isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Show a simple error message for login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please login to add items to cart")),
        );
        return;
      }

      final productId = widget.product['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();

      final cartRef = FirebaseFirestore.instance
          .collection('carts') // ✅ ye rules ke hisaab se match karega
          .doc(user.uid)       // ✅ yahan apna user id lagega
          .collection('items')
          .doc(productId + "_" + selectedWeight);

      final unitPrice = getPrice();
      final doc = await cartRef.get();

      if (doc.exists) {
        final currentQty = doc['quantity'] ?? 1;
        await cartRef.update({
          'quantity': currentQty + quantity,
          'totalPrice': (currentQty + quantity) * unitPrice,
        });
      } else {
        await cartRef.set({
          'productId': productId,
          'title': widget.product['title'],
          'selectedWeight': selectedWeight,
          'unitPrice': unitPrice,
          'quantity': quantity,
          'totalPrice': unitPrice * quantity,
          'image': widget.product['image'],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Update cart notification with new totals
      _updateCartNotification();

    } catch (e) {
      // Handle error - could show error version of notification
      print("Error adding to cart: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  Widget _statCard(String emoji, String number, String label) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)), // icon chhota
          const SizedBox(height: 4),
          Text(
            number,
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 14, // text chhota
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(String title) {
    return Center(
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 3,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}