import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:typed_data';

class ProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    Uint8List? decodeImage(String? base64String) {
      if (base64String == null || base64String.isEmpty) return null;
      try {
        return base64Decode(base64String);
      } catch (e) {
        return null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(product['title'] ?? 'Product Detail'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            if (decodeImage(product['image']) != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  decodeImage(product['image'])!,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.image, size: 80, color: Colors.grey),
              ),

            const SizedBox(height: 20),

            // Title
            Text(
              product['title'] ?? 'No Title',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // Description
            Text(
              product['description'] ?? 'No Description',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),

            const SizedBox(height: 20),

            // Price
            Row(
              children: [
                const Icon(Icons.attach_money, color: Colors.green),
                const SizedBox(width: 6),
                Text(
                  "${product['pricePer250g'] ?? 'N/A'} / 250g",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Category
            Row(
              children: [
                const Icon(Icons.category, color: Colors.blue),
                const SizedBox(width: 6),
                Text(
                  product['category'] ?? 'N/A',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Availability
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.orangeAccent),
                const SizedBox(width: 6),
                Text(
                  (product['availability'] == true ||
                      product['availability']?.toString().toLowerCase() == "available")
                      ? "Available"
                      : "Out of Stock",
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Review
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

            // Spice Meter Image
            if (decodeImage(product['spiceMeterImage']) != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Spice Meter",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Image.memory(
                    decodeImage(product['spiceMeterImage'])!,
                    height: 50,
                  ),
                ],
              ),

            const SizedBox(height: 25),

            // Timestamp
            if (product['timestamp'] != null)
              Text(
                "Added on: ${product['timestamp']}",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
