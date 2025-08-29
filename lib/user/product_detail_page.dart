import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

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
      body: CustomScrollView(
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
                border: Border.all(
                  width: 1.5,
                  color: Colors.white24,
                ),
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
              decoration: BoxDecoration(
                color: Colors.grey[900],
              ),
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

                  SizedBox(height: 20,),

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
                              icon: const Icon(Icons.remove,
                                  color: Colors.white, size: 16),
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
                              icon: const Icon(Icons.add,
                                  color: Colors.white, size: 16),
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
                          final int spiceValue = _spiceMeter.round().clamp(0, 6);

                          // Color logic
                          final Color bandColor = (index < 2)
                              ? Colors.green
                              : (index < 4 ? Colors.yellow : Colors.red);

                          final bool filled = index < spiceValue;
                          final Color iconColor = filled ? bandColor : Colors.white24;

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
                        // TODO: add-to-cart logic
                      },
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
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
}
