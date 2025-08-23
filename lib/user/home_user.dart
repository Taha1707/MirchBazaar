import 'dart:convert';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


import '../logout_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

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

// 🔹 Category with Urdu + English + Product list
  Widget _buildCategory(String english, String urdu) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading row with Urdu (right) and English (left)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ✅ English on the left
              Text(
                english,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              // ✅ Urdu on the right
              Text(
                urdu,
                style: GoogleFonts.notoNastaliqUrdu(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 🔹 Product list (dynamic from Firestore now)
          SizedBox(
            height: 220,
            child: StreamBuilder(
              stream:
              FirebaseFirestore.instance.collection("products").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final products = snapshot.data!.docs;

                if (products.isEmpty) {
                  return const Center(
                    child: Text(
                      "No products found",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final data =
                    products[index].data() as Map<String, dynamic>;

                    return Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                              ),
                              child: (data['image'] != null &&
                                  data['image'].toString().isNotEmpty)
                                  ? Image.memory(
                                base64Decode(data['image']),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              )
                                  : const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white54,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['title'] ?? "No Name",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Rs ${data['pricePer250g'] ?? 0}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: () {},
                                          icon: const Icon(
                                            Icons.shopping_cart_outlined,
                                            color: Colors.orange,
                                            size: 22,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () {},
                                          icon: const Icon(
                                            Icons.favorite_border,
                                            color: Colors.orange,
                                            size: 22,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
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
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // 👈 allow hero section behind AppBar
      backgroundColor: Colors.black,
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
          // 🔹 Main content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Hero Section
                Container(
                  height: MediaQuery.of(context).size.height * 0.55,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/banner_2.jpg"),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "MIRCH BAZAAR",
                      // lobster
                          style: GoogleFonts.cinzel(
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w500,
                              shadows: [
                                Shadow(
                                  blurRadius: 6,
                                  color: Colors.black54,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                        Text(
                          "Discover the finest collection"
                          "\nof spices, masalas\n"
                          "and authentic ingredients!",
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              height: 1.4, // ✅ Adds nice spacing between lines
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black45,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                          // textAlign: TextAlign.center, // ✅ keep centered
                        ),


                        const SizedBox(height: 15),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {},
                          child: Text(
                            "Shop Now",
                            style: GoogleFonts.breeSerif(
                              textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // ✅ Text color white

                            ),
                          ),

                        ),
                        )
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 🔹 Centered Section Heading (Spices)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Spices",
                        // lobster
                        style: GoogleFonts.playfairDisplay(
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold

                          ),
                        ),
                      ),

                      const SizedBox(height: 6),
                      Center(
                        child: SizedBox(
                          width: 300, // set a max width for nice wrapping
                          child: Text(
                            "Explore our handpicked authentic spices that bring taste & aroma to your dishes.",
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.4, // ✅ nice spacing between lines
                            ),
                            textAlign: TextAlign.center, // ✅ keeps both lines centered
                          ),
                        ),
                      ),

                    ],
                  ),
                ),






                const SizedBox(height: 20),
                // 🔹 Categories + Products
                _buildCategory("Mild Spice", "ہلکی مرچ مصالحہ"),
                _buildCategory("Medium Spice", "درمیانی مرچ مصالحہ"),
                _buildCategory("Hot Spice", "تیز مرچ مصالحہ"),
                _buildCategory("Cogarive", "کوگارائیو"),





              ],


            ),


          ),




          // Animated Hamburger Menu Drawer
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double slide = 250 * _controller.value;
              return Transform.translate(
                offset: Offset(-250 + slide, 0),
                child: _buildMenu(),
              );
            },
          ),
        ],
      ),



    );




  }




  Widget _buildMenu() {
    return Container(
      width: 250,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Image.asset(
                'assets/images/sasta_logo.png', // your logo
                height: 30,
              ),
            ),
            _menuItem(Icons.home, "Home", () {}),
            _menuItem(Icons.shopping_bag, "Shop", () {}),
            _menuItem(Icons.favorite, "Wishlist", () {}),
            _menuItem(Icons.receipt_long, "My Orders", () {}),
            _menuItem(Icons.local_offer, "Offers", () {}),
            _menuItem(Icons.contact_support, "Support", () {}),
            _menuItem(Icons.settings, "Settings", () {}),
            _menuItem(Icons.logout, "Logout", () {
              LogoutHelper.confirmLogout(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: onTap,
    );
  }



  // Glassmorphism container
  static Widget _glassBox({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }



  // Feature card
  static Widget _featureCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: _glassBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.orange, Colors.yellow],
              ).createShader(bounds),
              child: Icon(icon, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }
}

