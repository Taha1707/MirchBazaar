import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project/services/validation.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final user = FirebaseAuth.instance.currentUser;
  final userId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _removeItem(String docId, String title) async {
    await FirebaseFirestore.instance
        .collection('carts')
        .doc(user!.uid)
        .collection('items')
        .doc(docId)
        .delete();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('🗑️ Removed "$title" from cart')));
  }

  Future<void> _updateQuantity(String docId, int newQuantity) async {
    if (newQuantity > 0) {
      await FirebaseFirestore.instance
          .collection('carts')
          .doc(user!.uid)
          .collection('items')
          .doc(docId)
          .update({'quantity': newQuantity});
    }
  }

  void showCheckoutDialog(
    BuildContext context,
    List<Map<String, dynamic>> cartItems,
    String userId,
  ) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController addressController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    String selectedPayment = 'Cash on Delivery';

    // Total Price Calculate
    double totalPrice = cartItems.fold(0, (sum, item) {
      return sum + (item['price'] ?? 0) * (item['quantity'] ?? 1);
    });

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: EdgeInsets.zero, // width control ke liye padding kam
          titlePadding: EdgeInsets.only(top: 16, left: 16, right: 16),
          title: Center(
            child: Text(
              'Checkout',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.deepPurple,
              ),
            ),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(minWidth: 399), // width fix
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(),
                    ...cartItems.map(
                      (item) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          "${item['name']}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text("Quantity ${item['quantity']}"),
                        trailing: Text(
                          "Rs ${(item['price'] * item['quantity']).toStringAsFixed(2)}",
                        ),
                      ),
                    ),
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        "Total Price: Rs ${totalPrice.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: 'Delivery Address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.home, color: Colors.deepPurple),
                      ),
                      validator: validateAddress,
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.phone, color: Colors.deepPurple),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: validatePhoneNumber,
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: selectedPayment,
                      items: ['Cash on Delivery', 'Easypaisa', 'JazzCash']
                          .map(
                            (method) => DropdownMenuItem(
                              value: method,
                              child: Text(method),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        selectedPayment = value!;
                      },
                      decoration: InputDecoration(
                        labelText: 'Payment Method',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(
                          Icons.payment,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
          actionsPadding: EdgeInsets.only(bottom: 20, right: 24),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),

              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  // Loading dialog show
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => Center(
                      child: CircularProgressIndicator(
                        color: Colors.deepPurple,
                      ),
                    ),
                  );

                  try {
                    await Future.delayed(
                      Duration(seconds: 2),
                    );

                    await FirebaseFirestore.instance.collection('orders').add({
                      'items': cartItems ?? [],
                      'totalPrice': totalPrice ?? 0,
                      'address': addressController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'paymentMethod': selectedPayment ?? 'Cash',
                      'status': 'pending',
                      'timestamp': FieldValue.serverTimestamp(),
                      'userId': userId ?? '',
                    });

                    final cartSnapshot = await FirebaseFirestore.instance
                        .collection('carts')
                        .doc(userId)
                        .collection('items')
                        .get();

                    for (var doc in cartSnapshot.docs) {
                      await doc.reference.delete();
                    }

                    Navigator.pop(context); // Close loading
                    Navigator.pop(dialogContext); // Close checkout dialog

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Order placed successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context); // Close loading
                    print("🔥 Firestore error: $e");
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Order failed: $e')));
                  }
                }
              },

              child: Text('Confirm', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 3,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('carts')
            .doc(user!.uid)
            .collection('items')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                '🛒 Your cart is empty!',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final items = snapshot.data!.docs;

          // ✅ Ye banaya list jo checkout dialog me pass hoga
          List<Map<String, dynamic>> cartItemsList = items.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'name': data['title'],
              'quantity': data['quantity'],
              'price': data['price'],
            };
          }).toList();

          double totalPrice = 0;
          for (var item in items) {
            totalPrice += (item['price'] as num) * (item['quantity'] as num);
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final doc = items[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                base64Decode(data['image']),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['title'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rs. ${data['price']}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () {
                                          if (data['quantity'] > 1) {
                                            _updateQuantity(
                                              doc.id,
                                              data['quantity'] - 1,
                                            );
                                          }
                                        },
                                      ),
                                      Text(
                                        '${data['quantity']}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle,
                                          color: Colors.green,
                                        ),
                                        onPressed: () {
                                          _updateQuantity(
                                            doc.id,
                                            data['quantity'] + 1,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _removeItem(doc.id, data['title']);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.black, width: 1),
                  ),
                  color: Colors.deepPurple.shade50,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: Rs. ${totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        showCheckoutDialog(context, cartItemsList, userId);
                      },
                      child: const Text(
                        'Proceed',
                        style: TextStyle(color: Colors.white),
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
