import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'checkout.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final user = FirebaseAuth.instance.currentUser!;

  Future<void> _removeItems(List<String> docIds, String title) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (String docId in docIds) {
      final ref = FirebaseFirestore.instance
          .collection('carts')
          .doc(user.uid)
          .collection('items')
          .doc(docId);

      batch.delete(ref);
    }

    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🗑️ "$title" removed from cart'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _updateQuantity(
      String docId,
      int newQuantity,
      dynamic unitPrice,
      ) async {
    if (newQuantity > 0) {
      double price = 0;
      if (unitPrice is int) {
        price = unitPrice.toDouble();
      } else if (unitPrice is double) {
        price = unitPrice;
      } else {
        price = double.tryParse(unitPrice.toString()) ?? 0;
      }

      await FirebaseFirestore.instance
          .collection('carts')
          .doc(user.uid)
          .collection('items')
          .doc(docId)
          .update({
        'quantity': newQuantity,
        'totalPrice': price * newQuantity,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          "🛒  My Cart",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
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
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('carts')
            .doc(user.uid)
            .collection('items')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                '🛒 Your cart is empty!',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          final items = snapshot.data!.docs;

          // ✅ Grouping by product + weight (preserving blend info)
          Map<String, Map<String, dynamic>> groupedItems = {};

          for (var doc in items) {
            final data = doc.data() as Map<String, dynamic>;
            final productId = data['title'];
            final weight = data['selectedWeight'];
            final key = "$productId-$weight"; // ✅ unique key
            final quantity = (data['quantity'] as num).toInt();
            final isBlend = data['isBlend'] ?? false;

            if (!groupedItems.containsKey(key)) {
              groupedItems[key] = {
                'docIds': [doc.id],
                'title': data['title'],
                'image': data['image'],
                'unitPrice': data['unitPrice'],
                'weight': weight,
                'quantity': quantity,
                'totalPrice': (data['totalPrice'] as num).toDouble(),
                'isBlend': isBlend, // ✅ Preserve blend flag
                'blendDescription': data['blendDescription'], // ✅ Preserve blend description
                'blendDetails': data['blendDetails'], // ✅ Preserve blend details
              };
            } else {
              groupedItems[key]!['quantity'] =
                  (groupedItems[key]!['quantity'] as int) + quantity;
              groupedItems[key]!['totalPrice'] =
                  (groupedItems[key]!['totalPrice'] as double) +
                      (data['totalPrice'] as num).toDouble();
              groupedItems[key]!['docIds'].add(doc.id);
            }
          }

          double totalPrice = groupedItems.values.fold(
            0,
                (sum, item) => sum + (item['totalPrice'] as num).toDouble(),
          );

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groupedItems.length,
                  itemBuilder: (context, index) {
                    final item = groupedItems.values.elementAt(index);
                    final docIds = item['docIds'];
                    final docId = docIds[0];
                    final isBlend = item['isBlend'] ?? false;
                    final blendDescription = item['blendDescription'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.withOpacity(0.4),
                            Colors.red.withOpacity(0.4),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                width: 1.2,
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: item['image'] != null && item['image'].toString().isNotEmpty
                                          ? Image.memory(
                                        base64Decode(item['image']),
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      )
                                          : Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[800],
                                        child: const Icon(Icons.restaurant, color: Colors.white54, size: 40),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Flexible(
                                                          child: Text(
                                                            item['title'],
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                        ),
                                                        // ✅ Blend Badge
                                                        if (isBlend) ...[
                                                          const SizedBox(width: 6),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              gradient: const LinearGradient(
                                                                colors: [Colors.purple, Colors.deepPurple],
                                                              ),
                                                              borderRadius: BorderRadius.circular(6),
                                                            ),
                                                            child: const Text(
                                                              "BLEND",
                                                              style: TextStyle(
                                                                fontSize: 9,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.white,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                    // ✅ Show blend description in cart
                                                    if (isBlend && blendDescription != null) ...[
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        blendDescription,
                                                        style: TextStyle(
                                                          color: Colors.orange.shade300,
                                                          fontSize: 10,
                                                          fontStyle: FontStyle.italic,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [Colors.orange, Colors.red],
                                                  ),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  "Rs. ${item['unitPrice']}",
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Weight: ${item['weight']} | Qty: ${item['quantity']}",
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 10,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    InkWell(
                                                      borderRadius: BorderRadius.circular(8),
                                                      onTap: () {
                                                        int quantity = item['quantity'];
                                                        if (quantity > 1) {
                                                          setState(() {
                                                            quantity--;
                                                            item['quantity'] = quantity;
                                                          });
                                                          _updateQuantity(docId, quantity, item['unitPrice']);
                                                        }
                                                      },
                                                      child: const Padding(
                                                        padding: EdgeInsets.all(4),
                                                        child: Icon(Icons.remove, color: Colors.white, size: 14),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                                      child: Text(
                                                        item['quantity'].toString(),
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                    InkWell(
                                                      borderRadius: BorderRadius.circular(8),
                                                      onTap: () {
                                                        int quantity = item['quantity'];
                                                        setState(() {
                                                          quantity++;
                                                          item['quantity'] = quantity;
                                                        });
                                                        _updateQuantity(docId, quantity, item['unitPrice']);
                                                      },
                                                      child: const Padding(
                                                        padding: EdgeInsets.all(4),
                                                        child: Icon(Icons.add, color: Colors.white, size: 14),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.bottomRight,
                                                child: Container(
                                                  height: 30,
                                                  width: 30,
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [Colors.redAccent, Colors.orange],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  padding: const EdgeInsets.all(0.2),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: BackdropFilter(
                                                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          color: Colors.black.withOpacity(0.3),
                                                          borderRadius: BorderRadius.circular(6),
                                                          border: Border.all(
                                                            color: Colors.white.withOpacity(0.1),
                                                            width: 0.6,
                                                          ),
                                                        ),
                                                        child: IconButton(
                                                          icon: const Icon(
                                                            Icons.delete,
                                                            color: Colors.white,
                                                            size: 16,
                                                          ),
                                                          onPressed: () async {
                                                            await _removeItems(item['docIds'], item['title']);
                                                          },
                                                          splashRadius: 16,
                                                          tooltip: "Remove Item",
                                                          padding: EdgeInsets.zero,
                                                          constraints: const BoxConstraints(
                                                            minWidth: 26,
                                                            minHeight: 26,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.withOpacity(0.7),
                      Colors.red.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Total",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Rs ${totalPrice.toStringAsFixed(0)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CheckoutPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: Colors.black38,
                        backgroundColor: Colors.transparent,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.yellow, Colors.redAccent, Colors.orange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          alignment: Alignment.center,
                          child: const Text(
                            "Proceed",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
