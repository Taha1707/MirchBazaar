import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_product_page.dart';
import 'admin_drawer.dart';
import 'edit_product_page.dart';

class ViewProductPage extends StatefulWidget {
  const ViewProductPage({super.key});

  @override
  State<ViewProductPage> createState() => _ViewProductPageState();
}

class _ViewProductPageState extends State<ViewProductPage> {
  String _searchQuery = '';

  // ✅ Asal delete logic
  Future<void> _deleteProduct(String docId, String title) async {
    try {
      await FirebaseFirestore.instance.collection('products').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🗑️ "$title" deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to delete "$title"')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,

      drawer: AdminDrawer(
        onMenuItemSelected: (menu) {
          debugPrint("Selected: $menu");
        },
      ),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          "Product Management",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),

      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomLeft,
                radius: 1.4,
                colors: [
                  Colors.deepOrange,
                  Colors.black,
                  Colors.black,
                  Colors.black,
                ],
                stops: [0.1, 0.7, 0.2, 0.2],
              ),
            ),
          ),

          Column(
            children: [
              const SizedBox(height: kToolbarHeight + 20),

              // 🔎 Search + ➕ Add
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    // Search Bar
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              style: const TextStyle(color: Colors.white),
                              onChanged: (val) {
                                setState(() => _searchQuery = val.toLowerCase());
                              },
                              decoration: const InputDecoration(
                                hintText: "Search Products...",
                                hintStyle: TextStyle(color: Colors.white70),
                                prefixIcon: Icon(Icons.search, color: Colors.orangeAccent),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // ➕ Add Button
                    SizedBox(
                      height: 42,
                      width: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddProductPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black.withOpacity(0.6),
                              shadowColor: Colors.orangeAccent.withOpacity(0.8),
                              elevation: 12,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Icon(Icons.add, color: Colors.orangeAccent, size: 22),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 📦 Products List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.orange),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text("❗ No products found", style: TextStyle(color: Colors.white70)),
                      );
                    }

                    final products = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final title = data['title']?.toString().toLowerCase() ?? '';
                      return title.contains(_searchQuery);
                    }).toList();

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final doc = products[index];
                        final data = doc.data() as Map<String, dynamic>;

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Card(
                              color: Colors.white.withOpacity(0.08),
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // 🖼 Product Image
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.memory(
                                            base64Decode(data['image']),
                                            width: 64,
                                            height: 64,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 14),

                                        // Text + Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Title + Price
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      data['title'] ?? 'No Title',
                                                      style: const TextStyle(
                                                        fontSize: 13, // 🔹 smaller
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // 🔹 tighter
                                                    decoration: BoxDecoration(
                                                      gradient: const LinearGradient(
                                                        colors: [Colors.orange, Colors.red],
                                                      ),
                                                      borderRadius: BorderRadius.circular(5),
                                                    ),
                                                    child: Text(
                                                      (data['pricePer250g'] != null)
                                                          ? "Rs. ${data['pricePer250g']} (250g)"
                                                          : "Rs. 0 (250g)",
                                                      style: const TextStyle(
                                                        fontSize: 8, // 🔹 smaller text
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 4), // 🔹 less spacing

                                              // Timestamp
                                              Text(
                                                (data['timestamp'] != null)
                                                    ? (data['timestamp'] as Timestamp).toDate().toString().substring(0, 16)
                                                    : "No Date",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 9, color: Colors.white70),
                                              ),

                                              const SizedBox(height: 6), // 🔹 reduced

                                              // Availability + Buttons
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    (data['availability'] == true) ? "✅ Available" : "❌ Not Available",
                                                    style: TextStyle(
                                                      fontSize: 8, // 🔹 smaller
                                                      fontWeight: FontWeight.w500,
                                                      color: (data['availability'] == true)
                                                          ? Colors.greenAccent
                                                          : Colors.redAccent,
                                                      shadows: [
                                                        Shadow(
                                                          color: Colors.black.withOpacity(0.8),
                                                          blurRadius: 3,
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                  Row(
                                                    children: [
                                                      // ✏️ Edit Button
                                                      ElevatedButton.icon(
                                                        onPressed: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) => EditProductPage(
                                                                productId: doc.id,
                                                                productData: data,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        icon: const Icon(Icons.edit, size: 12, color: Colors.greenAccent),
                                                        label: const Text(
                                                          "Edit",
                                                          style: TextStyle(fontSize: 9, color: Colors.greenAccent),
                                                        ),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.black.withOpacity(0.7),
                                                          elevation: 6,
                                                          shadowColor: Colors.greenAccent.withOpacity(0.8),
                                                          minimumSize: const Size(58, 28), // 🔹 smaller button
                                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                            side: const BorderSide(color: Colors.greenAccent, width: 0.8),
                                                          ),
                                                        ),
                                                      ),

                                                      const SizedBox(width: 6),

                                                      // 🗑 Delete Button
                                                      ElevatedButton.icon(
                                                        onPressed: () async {
                                                          bool confirm = await DeleteHelper.confirmDelete(context, data['title']);
                                                          if (confirm) {
                                                            _deleteProduct(doc.id, data['title']);
                                                          }
                                                        },
                                                        icon: const Icon(Icons.delete, size: 12, color: Colors.redAccent),
                                                        label: const Text(
                                                          "Delete",
                                                          style: TextStyle(fontSize: 9, color: Colors.redAccent),
                                                        ),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.black.withOpacity(0.7),
                                                          elevation: 6,
                                                          shadowColor: Colors.redAccent.withOpacity(0.8),
                                                          minimumSize: const Size(58, 28), // 🔹 smaller button
                                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                            side: const BorderSide(color: Colors.redAccent, width: 0.8),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
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
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ✅ DeleteHelper sirf confirm dialog return karega
class DeleteHelper {
  static Future<bool> confirmDelete(BuildContext context, String title) async {
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.red, Colors.orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Icon(Icons.delete_forever, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.red, Colors.orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Text(
                      "Delete Product",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, decoration: TextDecoration.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Are you sure you want to delete \"$title\"?",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: Colors.white70, decoration: TextDecoration.none),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel", style: TextStyle(color: Colors.white70, decoration: TextDecoration.none)),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.red, Colors.orange, Colors.yellow],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            "DELETE",
                            style: TextStyle(letterSpacing: 2, color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return shouldDelete ?? false;
  }
}
