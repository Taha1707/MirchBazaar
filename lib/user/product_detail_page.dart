import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int quantity = 1;
  String selectedWeight = "250g";

  Uint8List? decodeImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (e) {
      return null;
    }
  }

  double getPrice() {
    double pricePer250g = widget.product['pricePer250g']?.toDouble() ?? 0;
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
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          SizedBox(height: 50,),
        // Top Image Container
        Container(
        width: 250,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
          image: decodeImage(product['image']) != null
              ? DecorationImage(
            image: MemoryImage(decodeImage(product['image'])!),
            fit: BoxFit.cover,
          )
              : null,
        ),
        child: decodeImage(product['image']) == null
            ? const Center(
          child: Icon(Icons.image, size: 80, color: Colors.grey),
        )
            : null,
      ),

      const SizedBox(height: 20),

      // Elevated Bottom Container
      Expanded(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Price Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product['title'] ?? 'No Title',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      "${getPrice().toStringAsFixed(2)} / $selectedWeight",
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Description
                Text(
                  product['description'] ?? 'No Description',
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),

                const SizedBox(height: 20),

                // Weight Selector
                Row(
                  children: ["250g", "500g", "1kg", "2kg"].map((weight) {
                    bool isSelected = selectedWeight == weight;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedWeight = weight;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.orange : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          weight,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Quantity & Availability Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "Quantity: ",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            if (quantity > 1) setState(() => quantity--);
                          },
                        ),
                        Text(quantity.toString(),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            setState(() => quantity++);
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          (product['availability'] == true ||
                              product['availability']
                                  ?.toString()
                                  .toLowerCase() ==
                                  "available")
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: (product['availability'] == true ||
                              product['availability']
                                  ?.toString()
                                  .toLowerCase() ==
                                  "available")
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          (product['availability'] == true ||
                              product['availability']
                                  ?.toString()
                                  .toLowerCase() ==
                                  "available")
                              ? "Available"
                              : "Out of Stock",
                          style: TextStyle(
                              fontSize: 16,
                              color: (product['availability'] == true ||
                                  product['availability']
                                      ?.toString()
                                      .toLowerCase() ==
                                      "available")
                                  ? Colors.green
                                  : Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // Rating
                if (product['review'] != null)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 6),
                      Text(
                        product['review'].toString(),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),

                const SizedBox(height: 15),

                // Spice Meter
                if (decodeImage(product['spiceMeterImage']) != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Spice Meter",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Image.memory(
                        decodeImage(product['spiceMeterImage'])!,
                        height: 50,
                      ),
                    ],
                  ),

                const SizedBox(height: 30),

                // Add to Cart Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text(
                      "Add to Cart",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      final cartCollection =
                      FirebaseFirestore.instance.collection('Cart');

                      await cartCollection.add({
                        'productId': product['id'],
                        'productName': product['title'],
                        'price': getPrice(),
                        'weight': selectedWeight,
                        'quantity': quantity,
                        'userId': FirebaseAuth.instance.currentUser!.uid,
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Product added to cart')),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
        ],
      ),
    );
  }
}
