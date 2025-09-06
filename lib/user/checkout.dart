import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project/services/validation.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedPayment = 'Cash on Delivery';

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
    required Function(String?) onSaved,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(icon, hint),
      validator: validator,
      onSaved: onSaved,
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

  // place order
  Future<void> placeOrder(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartRef = FirebaseFirestore.instance
        .collection("carts")
        .doc(user.uid)
        .collection("items");

    final cartSnapshot = await cartRef.get();
    final cartItems = cartSnapshot.docs.map((doc) => doc.data()).toList();

    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("🛒 Cart is empty")));
      return;
    }

    await FirebaseFirestore.instance.collection("orders").add({
      "userId": user.uid,
      "items": cartItems,
      "status": "pending",
      "createdAt": FieldValue.serverTimestamp(),
      "customerName": _nameController.text.trim(),
      "address": _addressController.text.trim(),
      "paymentMethod": _selectedPayment,
    });

    for (var doc in cartSnapshot.docs) {
      await doc.reference.delete();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Order placed successfully!")),
    );

    Navigator.pop(context);
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
        title: const Text(
          "🛍️ Checkout",
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

          final cartItems = snapshot.data ?? [];
          if (cartItems.isEmpty) {
            return const Center(
              child: Text(
                "🛒 Cart is empty",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          double total = cartItems.fold(
            0,
            (sum, item) =>
                sum + ((item["quantity"] ?? 0) * (item["unitPrice"] ?? 0)),
          );

          return Stack(
            children: [
              // 🔥 background
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/bg.jpg"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(color: Colors.black.withOpacity(0.65)),

              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        // -------- Name --------
                        _buildTextField(
                          controller: _nameController,
                          hint: "Full Name",
                          icon: Icons.person,
                          validator: validateFullName,
                          onSaved: (val) {},
                        ),
                        const SizedBox(height: 14),

                        // -------- Address --------
                        _buildTextField(
                          controller: _addressController,
                          hint: "Address",
                          icon: Icons.home,
                          validator: validateAddress,
                          onSaved: (val) {},
                        ),
                        const SizedBox(height: 14),

                        // -------- Payment --------
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

                        // -------- Order Details --------
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
                            data: Theme.of(
                              context,
                            ).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              collapsedIconColor: Colors.orangeAccent,
                              iconColor: Colors.orangeAccent,
                              textColor: Colors.orangeAccent,
                              backgroundColor: Colors.transparent,
                              tilePadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              // 👇 Extra space hata diya
                              childrenPadding: EdgeInsets.zero,
                              expandedCrossAxisAlignment:
                                  CrossAxisAlignment.start,
                              title: Row(
                                children: const [
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
                                  children: List.generate(cartItems.length, (
                                    index,
                                  ) {
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
                                          // left side
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
                                          // right side
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
                                        "Total:",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        "Rs. $total",
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

                        // -------- Place Order Button --------
                        _buildGradientButton(
                          text: "PLACE ORDER",
                          onTap: () => placeOrder(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
