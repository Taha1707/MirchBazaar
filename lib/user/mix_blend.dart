import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'cart_page.dart';
import 'home_user.dart';

class MixBlendPage extends StatefulWidget {
  const MixBlendPage({super.key});

  @override
  State<MixBlendPage> createState() => _MixBlendPageState();
}

class _MixBlendPageState extends State<MixBlendPage> with TickerProviderStateMixin {
  Map<String, BlendItem> selectedSpices = {};
  String blendName = "";
  bool showDisclaimer = true;
  bool isSaving = false;
  int cartItemCount = 0;
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _loadCartCount();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  Future<void> _loadCartCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartSnapshot = await FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .get();

    setState(() {
      cartItemCount = cartSnapshot.docs.length;
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

  double getTotalPrice() {
    double total = 0;
    selectedSpices.forEach((key, item) {
      total += item.totalPrice;
    });
    return total;
  }

  double getTotalWeight() {
    double total = 0;
    selectedSpices.forEach((key, item) {
      total += item.weightInGrams;
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated background gradient
          AnimatedBuilder(
            animation: _rotateController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black,
                      Colors.grey[900]!,
                      Colors.black,
                    ],
                    stops: [
                      0.0,
                      0.5 + (_rotateController.value * 0.3),
                      1.0,
                    ],
                  ),
                ),
              );
            },
          ),

          CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                backgroundColor: Colors.grey[900]!.withOpacity(0.95),
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(width: 1.5, color: Colors.white24),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => HomePage()),
                          );
                        }
                      }

                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.orange.withOpacity(0.3),
                          Colors.red.withOpacity(0.3),
                          Colors.yellow.withOpacity(0.2),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Mix & Blend",
                              style: GoogleFonts.playfairDisplay(
                                textStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Create Your Perfect Spice Blend",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Health Disclaimer
                    if (showDisclaimer)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.withOpacity(0.2),
                              Colors.orange.withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Important Health Notice",
                                    style: GoogleFonts.poppins(
                                      textStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                                  onPressed: () => setState(() => showDisclaimer = false),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "You are creating a custom spice blend at your own risk. We are not responsible for any health issues, allergic reactions, or adverse effects that may occur from your custom blend. Please ensure you are aware of any allergies or sensitivities before mixing spices. Consult a healthcare professional if unsure.",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Selected Spices Summary Card
                    if (selectedSpices.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.withOpacity(0.2),
                              Colors.red.withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange.withOpacity(0.5), width: 2),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Total Weight",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${getTotalWeight().toStringAsFixed(0)}g",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  height: 40,
                                  width: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.orange, Colors.red],
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Total Price",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Rs. ${getTotalPrice().toStringAsFixed(0)}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "${selectedSpices.length} spice${selectedSpices.length > 1 ? 's' : ''} selected",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Blend Name Input
                    if (selectedSpices.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24, width: 1.5),
                        ),
                        child: TextField(
                          onChanged: (value) => setState(() => blendName = value),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: "Name your blend (e.g., \"My Special Mix\") *Required",
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                            border: InputBorder.none,
                            icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                          ),
                        ),
                      ),

                    // Available Spices Section
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.orange, Colors.red],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Available Spices",
                            style: GoogleFonts.playfairDisplay(
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Spices Grid
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('products')
                          .where('availability', isEqualTo: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                              ),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(40),
                            child: Text(
                              "No spices available",
                              style: TextStyle(color: Colors.white70),
                            ),
                          );
                        }

                        final products = snapshot.data!.docs;

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: products.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 0.75,
                          ),
                          itemBuilder: (context, index) {
                            final data = products[index].data() as Map<String, dynamic>;
                            final productId = products[index].id;
                            final isSelected = selectedSpices.containsKey(productId);

                            return _buildSpiceCard(data, productId, isSelected);
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),

          // Floating Action Button - Dynamic based on state
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.red, Colors.yellow],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: selectedSpices.isNotEmpty && !isSaving
                      ? _addBlendToCart
                      : (cartItemCount > 0 ? _navigateToCart : null),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: isSaving
                        ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_cart, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          selectedSpices.isNotEmpty
                              ? "ADD BLEND TO CART"
                              : cartItemCount > 0
                              ? "$cartItemCount ITEM${cartItemCount > 1 ? 'S' : ''} IN YOUR CART"
                              : "SELECT SPICES TO START",
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpiceCard(Map<String, dynamic> data, String productId, bool isSelected) {
    return GestureDetector(
      onTap: () => _showWeightSelector(data, productId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.white24,
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.orange.withOpacity(0.5),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.orange.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      Expanded(
                        flex: 3,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          child: decodeImage(data['image']) != null
                              ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: Image.memory(
                              decodeImage(data['image'])!,
                              fit: BoxFit.cover,
                            ),
                          )
                              : const Icon(Icons.image, size: 60, color: Colors.grey),
                        ),
                      ),

                      // Details
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                data['title'] ?? 'No Title',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Colors.orange, Colors.red],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "Rs. ${data['pricePer250g'] ?? '0'}",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    "250g",
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Selected Badge
                  if (isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.orange, Colors.red],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.7),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 16),
                      ),
                    ),

                  // Quantity Badge
                  if (isSelected && selectedSpices[productId] != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange, width: 1),
                        ),
                        child: Text(
                          "${selectedSpices[productId]!.weightInGrams.toInt()}g",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showWeightSelector(Map<String, dynamic> data, String productId) {
    String selectedWeight = "250g";
    int quantity = 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          double getPrice() {
            final num raw = (data['pricePer250g'] ?? 0);
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

          double getWeightInGrams() {
            switch (selectedWeight) {
              case "250g":
                return 250;
              case "500g":
                return 500;
              case "1kg":
                return 1000;
              case "2kg":
                return 2000;
              default:
                return 250;
            }
          }

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey[900]!,
                  Colors.black,
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 5,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  data['title'] ?? 'Spice',
                  style: GoogleFonts.playfairDisplay(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Weight Selector
                const Text(
                  "Select Weight",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ["250g", "500g", "1kg", "2kg"].map((weight) {
                    final bool isSelected = selectedWeight == weight;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          selectedWeight = weight;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(colors: [Colors.orange, Colors.red])
                              : null,
                          color: isSelected ? null : Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
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

                const SizedBox(height: 30),

                // Quantity Selector
                const Text(
                  "Quantity",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          if (quantity > 1) {
                            setModalState(() => quantity--);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.remove, color: Colors.white, size: 20),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Text(
                          quantity.toString(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setModalState(() => quantity++);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.orange, Colors.red],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Price Display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withOpacity(0.5), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Price:",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "Rs. ${(getPrice() * quantity).toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Add Button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.orange, Colors.red, Colors.yellow],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedSpices[productId] = BlendItem(
                          productId: productId,
                          title: data['title'],
                          selectedWeight: selectedWeight,
                          unitPrice: getPrice(),
                          quantity: quantity,
                          totalPrice: getPrice() * quantity,
                          weightInGrams: getWeightInGrams() * quantity,
                          image: data['image'],
                        );
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      selectedSpices.containsKey(productId) ? "UPDATE" : "ADD TO BLEND",
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                // Remove Button if already added
                if (selectedSpices.containsKey(productId))
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          selectedSpices.remove(productId);
                        });
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                      label: const Text(
                        "Remove from Blend",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }

  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartPage()),
    );
  }

  Future<void> _addBlendToCart() async {
    if (selectedSpices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one spice"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (blendName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a name for your blend"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please login to add items to cart")),
        );
        return;
      }

      // Create a unique blend ID
      final blendId = "blend_${DateTime.now().millisecondsSinceEpoch}";

      // Use the provided blend name
      final finalBlendName = blendName.trim();

      // Create a combined image (use first spice image as representative)
      String blendImage = '';
      for (var item in selectedSpices.values) {
        if (item.image != null && item.image!.isNotEmpty) {
          blendImage = item.image!;
          break;
        }
      }

      // Create blend details for reference
      List<Map<String, dynamic>> blendDetails = [];
      selectedSpices.forEach((key, item) {
        blendDetails.add({
          'title': item.title,
          'weight': item.selectedWeight,
          'quantity': item.quantity,
          'weightInGrams': item.weightInGrams,
        });
      });

      // Format blend description for display
      String blendDescription = blendDetails.map((item) {
        return "${item['title']} (${item['weightInGrams'].toInt()}g)";
      }).join(", ");

      // Add to cart in the same format as regular products
      final cartRef = FirebaseFirestore.instance
          .collection('carts')
          .doc(user.uid)
          .collection('items')
          .doc(blendId);

      await cartRef.set({
        'productId': blendId,
        'title': finalBlendName,
        'image': blendImage,
        'selectedWeight': "${getTotalWeight().toInt()}g",
        'unitPrice': getTotalPrice(),
        'quantity': 1,
        'totalPrice': getTotalPrice(),
        'isBlend': true,
        'blendDescription': blendDescription,
        'blendDetails': blendDetails,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.red],
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Blend Added to Cart!",
                style: GoogleFonts.playfairDisplay(
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                finalBlendName,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.red],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Clear selections and update cart count
                    setState(() {
                      selectedSpices.clear();
                      blendName = "";
                      cartItemCount++;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    "DONE",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

    } catch (e) {
      print("Error adding blend to cart: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

}

// Model class for blend items
class BlendItem {
  final String productId;
  final String title;
  final String selectedWeight;
  final double unitPrice;
  final int quantity;
  final double totalPrice;
  final double weightInGrams;
  final String? image;

  BlendItem({
    required this.productId,
    required this.title,
    required this.selectedWeight,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
    required this.weightInGrams,
    this.image,
  });
}
