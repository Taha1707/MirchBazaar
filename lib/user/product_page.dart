import 'dart:convert';
import 'dart:ui';
import 'package:badges/badges.dart' as badges;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project/user/product_detail_page.dart';
import '../logout_page.dart';
import 'cart_page.dart';
import 'user_drawer.dart';

class UserProductPage extends StatefulWidget {
  const UserProductPage({super.key});

  @override
  State<UserProductPage> createState() => _UserProductPageState();
}

class _UserProductPageState extends State<UserProductPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _toggleMenu() {
    if (_controller.isCompleted) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _controller,
            color: Colors.white,
          ),
          onPressed: _toggleMenu,
        ),
      ),
      body: Stack(
        children: [
          // Gradient background black → deep orange
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomLeft,
                radius: 1.4,
                colors: [
                  Colors.black,
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
              const SizedBox(height: 14),

              const Text(
                '🛍 Products',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // Search bar with 3 icons
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
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
                    const SizedBox(width: 8),
                    // cart button
                    buildCartButton(context),

                    // fav button

                    // IconButton(
                    //   icon: const Icon(
                    //     Icons.favorite_border,
                    //     color: Colors.white,
                    //   ),
                    //   onPressed: () {},
                    // ),

                    // filter button
                    IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              // Products grid
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
                        child: Text(
                          '❗ No products found',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final products = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final title =
                          data['title']?.toString().toLowerCase() ?? '';
                      return title.contains(_searchQuery);
                    }).toList();

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.8,
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 20,
                            // mainAxisExtent: 200
                          ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final data =
                            products[index].data() as Map<String, dynamic>;

                        return GestureDetector(
                          onTap: () {
                            final bool isAvailable = data['availability'] == true;

                            if (!isAvailable) {
                              // Agar product out of stock hai to sirf snackbar dikhayege
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.transparent, // hide default bg
                                  elevation: 0,
                                  duration: const Duration(seconds: 2),
                                  content: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), // glass blur
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6), // blacky glass effect
                                          borderRadius: BorderRadius.circular(15),
                                          border: const Border(
                                            top: BorderSide(
                                              width: 2,
                                              style: BorderStyle.solid,
                                              color: Colors.red, // placeholder (overridden below)
                                            ),
                                            bottom: BorderSide(
                                              width: 2,
                                              style: BorderStyle.solid,
                                              color: Colors.red, // placeholder (overridden below)
                                            ),
                                            right: BorderSide(
                                              width: 2,
                                              style: BorderStyle.solid,
                                              color: Colors.red, // placeholder (overridden below)
                                            ),
                                            left: BorderSide(
                                              width: 2,
                                              style: BorderStyle.solid,
                                              color: Colors.red, // placeholder (overridden below)
                                            ),
                                          ),
                                        ),
                                        child: Stack(
                                          children: [
                                            // Text Content
                                            const Padding(
                                              padding: EdgeInsets.all(14),
                                              child: Center(
                                                child: Text(
                                                  "PRODUCT STATUS IS OUT OF STOCK",
                                                  style: TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 1),
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


                            } else {
                              // Agar available hai to details page khulega
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
                            }
                          },

                          child: Material(
                            elevation: 6,
                            borderRadius: BorderRadius.circular(16),
                            // 🔹 Out of stock ko dull / faded banane ke liye opacity
                            color: data['availability'] == true
                                ? Colors.white.withOpacity(0.12)
                                : Colors.white.withOpacity(0.05),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: ColorFiltered(
                                  colorFilter: data['availability'] == true
                                      ? const ColorFilter.mode(
                                      Colors.transparent, BlendMode.multiply)
                                      : const ColorFilter.mode(
                                      Colors.black12, BlendMode.saturation), // 🔹 greyscale for out of stock
                                  child: Opacity(
                                    opacity: data['availability'] == true ? 1.0 : 0.5, // 🔹 dull effect
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.12),
                                          width: 1.5,
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
                                                height: 200,
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
                                                const SizedBox(height: 10),

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
                                                const SizedBox(height: 10),

                                                // 🔹 Availability Badge
                                                Row(
                                                  children: [
                                                    Icon(
                                                      data['availability'] == true
                                                          ? Icons.check_circle
                                                          : Icons.cancel,
                                                      size: 14,
                                                      color: data['availability'] == true
                                                          ? Colors.greenAccent
                                                          : Colors.redAccent,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      data['availability'] == true
                                                          ? "Available"
                                                          : "Out of Stock",
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w500,
                                                        color: data['availability'] == true
                                                            ? Colors.greenAccent
                                                            : Colors.redAccent,
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

          // UserDrawer
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double slide = 250 * _controller.value;
              return Transform.translate(
                offset: Offset(-250 + slide, 0),
                child: UserDrawer(
                  onMenuItemSelected: (title) => _controller.reverse(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }


  IconButton buildCartButton(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return IconButton(
      onPressed: () {
        // Cart Page par navigate
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartPage()),
        );
      },
      icon: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('carts')
            .doc(user?.uid ?? "guest")
            .collection('items')
            .snapshots(),
        builder: (context, snapshot) {
          int itemCount = 0;
          if (snapshot.hasData) {
            itemCount = snapshot.data!.docs.length;
          }

          return badges.Badge(
            position: badges.BadgePosition.topEnd(top: -10, end: -10),
            showBadge: itemCount > 0,
            badgeContent: Text(
              itemCount.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            badgeStyle: badges.BadgeStyle(
              badgeColor: Colors.deepOrange,
            ),
            child: const Icon(
              Icons.add_shopping_cart,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }

}
