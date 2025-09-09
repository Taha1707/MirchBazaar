import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  final user = FirebaseAuth.instance.currentUser;

  // Cache decoded images to reduce repeated decoding
  final Map<String, Uint8List?> _imageCache = {};

  Uint8List? decodeImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    if (_imageCache.containsKey(base64String)) return _imageCache[base64String];
    try {
      final bytes = base64Decode(base64String);
      _imageCache[base64String] = bytes;
      return bytes;
    } catch (e) {
      _imageCache[base64String] = null;
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text("Please login to see your orders"));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user!.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No orders found"));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final cartItems =
              List<Map<String, dynamic>>.from(order['cartItems'] ?? []);
              final total = order['total'] ?? 0;
              final name = order['name'] ?? '';
              final address = order['address'] ?? '';
              final paymentMethod = order['paymentMethod'] ?? '';
              final status = order['status'] ?? 'Pending';
              final timestamp = order['timestamp'] as Timestamp?;
              final orderTime = timestamp != null
                  ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate())
                  : '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: ExpansionTile(
                  title: Text("Order: $status"),
                  subtitle: Text("Total: \$${total.toString()}"),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Name: $name"),
                          Text("Address: $address"),
                          Text("Payment: $paymentMethod"),
                          Text("Ordered on: $orderTime"),
                          const SizedBox(height: 8),
                          const Text("Items:",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          ...cartItems.map((item) {
                            final itemName = item['name'] ?? '';
                            final itemQty = item['quantity'] ?? 0;
                            final itemPrice = item['price'] ?? 0;
                            final itemImage = item['image'] ?? '';

                            final decodedImage = decodeImage(itemImage);

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: decodedImage != null
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  decodedImage,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              )
                                  : const Icon(Icons.image_not_supported),
                              title: Text(itemName),
                              subtitle: Text(
                                  "Qty: $itemQty | Price: \$${itemPrice.toString()}"),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
