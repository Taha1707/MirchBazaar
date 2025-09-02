import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/user/product_detail_page.dart'; // 👈 import detail page
import 'package:project/user/product_page.dart';
import 'package:project/user/user_drawer.dart'; // 👈 custom drawer import
import '../logout_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _selectedMenu = "Home";

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

  // 🔹 Category Widget (English + Urdu + Products)
  Widget _buildCategory(String english, [String? urdu]) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading row with English + Urdu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                english,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (urdu != null)
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

          // 🔹 Product list from Firestore
          SizedBox(
            height: 220,
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("products")
                  .where("category", arrayContains: english)
                  .snapshots(),
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

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailPage(product: data), // 👈 go to detail page
                          ),
                        );
                      },
                      child: Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
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

                            const SizedBox(height: 6),

                            // Product Name
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                data['title'] ?? "No Name",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            const SizedBox(height: 4),

                            // Price + Buttons Row
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
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
                                        onPressed: () {
                                          // TODO: Add to cart
                                        },
                                        icon: const Icon(
                                          Icons.shopping_cart_outlined,
                                          color: Colors.orange,
                                          size: 20,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton(
                                        onPressed: () {
                                          // TODO: Add to wishlist
                                        },
                                        icon: const Icon(
                                          Icons.favorite_border,
                                          color: Colors.orange,
                                          size: 20,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
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
                          "Discover the finest collection\n"
                              "of spices, masalas\n"
                              "and authentic ingredients!",
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              height: 1.4,
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black45,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildGradientButton(text: "Shop Now", onTap: () {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => UserProductPage()));
                        }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                // 🔹 Section Heading
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Spices",
                        style: GoogleFonts.playfairDisplay(
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: SizedBox(
                          width: 300,
                          child: Text(
                            "Explore our handpicked authentic spices that bring taste & aroma to your dishes.",
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

// ✅ Responsive Spice Features Section (Centered)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800), // keeps it neat on big screens
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 600) {
                            // ✅ For wider screens → row layout
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(child: _buildFeature(Icons.local_fire_department, "Hot & Spicy")),
                                Expanded(child: _buildFeature(Icons.eco, "Natural & Pure")),
                                Expanded(child: _buildFeature(Icons.restaurant, "Perfect Taste")),
                                Expanded(child: _buildFeature(Icons.spa, "Aromatic")),
                              ],
                            );
                          } else {
                            // ✅ For small screens → auto-wrap
                            return Wrap(
                              spacing: 24,
                              runSpacing: 20,
                              alignment: WrapAlignment.center, // ✅ center align features
                              children: [
                                _buildFeature(Icons.local_fire_department, "Hot & Spicy"),
                                _buildFeature(Icons.eco, "Natural & Pure"),
                                _buildFeature(Icons.restaurant, "Perfect Taste"),
                                _buildFeature(Icons.spa, "Aromatic"),
                              ],
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),


    const SizedBox(height: 20),

                // 🔹 Categories + Products

                _buildCategory("Daily Cooking Masalas", "روزانہ کے مصالحے"),
                const SizedBox(height: 20),
                const SpiceometerBanner(),
                const SizedBox(height: 20),
                _buildCategory("Rice & Biryani Specials", "بریانی مصالحے"),
                const SizedBox(height: 10),
                _buildCategory("Karahi & Curry Lovers", "کڑاہی و سالن مصالحے"),
                const SizedBox(height: 10),
                const MixBlendBanner(),
                const SizedBox(height: 20),
                _buildCategory("BBQ & Grilled Specials", "باربی کیو مصالحے"),
                const SizedBox(height: 10),
                _buildCategory("Snacks & Street Food", "سنیک و اسٹریٹ فوڈ"),
                const SizedBox(height: 30),
                const TestimonialSection(),
              ],

            ),

          ),


          // ✅ Replaced with UserDrawer
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double slide = 250 * _controller.value;
              return Transform.translate(
                offset: Offset(-250 + slide, 0),
                child: UserDrawer(
                  onMenuItemSelected: (selected) {
                    setState(() {
                      _selectedMenu = selected;
                    });
                  },
                ),
              );
            },
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
      width: 120,
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
          style: GoogleFonts.playfairDisplay(
            textStyle: const TextStyle(
              fontSize: 16,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}


Widget _buildFeature(IconData icon, String label) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white12,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.orange, width: 1.5),
        ),
        child: Icon(
          icon,
          size: 22,
          color: Colors.orange,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    ],
  );
}


class SpiceometerBanner extends StatelessWidget {
  const SpiceometerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none, // ✅ allow chilli to overflow
      children: [
        // ✅ Glossy Glass Container
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "🌶️ NOW INTRODUCING",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                      decoration: TextDecoration.none,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ✅ Gradient text for SPICEOMETER
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.orange, Colors.red, Colors.yellow],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Text(
                      "🔥 SPICEOMETER",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // masked by gradient
                        decoration: TextDecoration.none,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),
                  const Text(
                    "Buy the heat that matches your spice need! ️",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ✅ Chili image floating outside the right side
        Positioned(
          right: -10, // moves outside
          top: -5, // a little above for effect
          child: Image.asset(
            "assets/images/chilli.png",
            height: 90,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}




class MixBlendBanner extends StatelessWidget {
  const MixBlendBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none, // ✅ allow floating image to overflow
      children: [
        // ✅ Glossy Glass Container
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "🏮 NEW FEATURE",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                      decoration: TextDecoration.none,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ✅ Gradient text for MIX & BLEND (same warm gradient as Spiceometer)
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.orange, Colors.red, Colors.yellow],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Text(
                      "✨ MIX & BLEND",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // masked by gradient
                        decoration: TextDecoration.none,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),
                  const Text(
                    "Turn simple spices into your signature flavor explosion!",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ✅ Floating mixer image
        Positioned(
          right: -8,
          top: -4,
          child: Transform.rotate(
            angle: 0.18, // tilt in radians (-0.1 is slight counter-clockwise)
            child: Image.asset(
              "assets/images/mixer.png",
              height: 85,
              fit: BoxFit.contain,
            ),
          ),
        ),

      ],
    );
  }
}





/* ───────────── Testimonials Section ───────────── */
class TestimonialSection extends StatefulWidget {
  const TestimonialSection({super.key});

  @override
  State<TestimonialSection> createState() => _TestimonialSectionState();
}

class _TestimonialSectionState extends State<TestimonialSection> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _activeIndex = 0;
  Timer? _autoTimer;

  final List<Map<String, String>> _testimonials = [
    {
      'name': 'Ayesha Khan',
      'role': 'Biyrani Specialist',
      'gender': 'female',
      'review':
      'This spice exceeded my expectations! Fresh, aromatic, and perfect for my dishes. Highly recommend 🌶️',
    },
    {
      'name': 'Hamza Iqbal',
      'role': 'Haleem Specialist',
      'gender': 'male',
      'review':
      'Fast delivery, rich flavors, and amazing aroma. Easily the best masala buying experience!',
    },
    {
      'name': 'Mehwish Saleem',
      'role': 'Karahi Specialist',
      'gender': 'female',
      'review':
      'Premium quality spices and always on time. Mirch Bazaar is now my go-to place!',
    },
  ];

  @override
  void initState() {
    super.initState();
    _autoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_pageController.hasClients) {
        final next = (_activeIndex + 1) % _testimonials.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🔹 Heading
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Testimonials",
                style: GoogleFonts.playfairDisplay(
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: SizedBox(
                  width: 300,
                  child: Text(
                    "Hear what spice lovers say about the flavors that transformed their cooking!",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 🔹 Testimonial Cards
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _testimonials.length,
            onPageChanged: (i) => setState(() => _activeIndex = i),
            itemBuilder: (_, i) => AnimatedPadding(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: _activeIndex == i ? 0 : 16,
              ),
              child: _TestimonialCard(
                data: _testimonials[i],
                isActive: _activeIndex == i,
              ),
            ),
          ),
        ),

        // 🔹 Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _testimonials.length,
                (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
              width: _activeIndex == i ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _activeIndex == i ? Colors.orange : Colors.white30,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/* ───────────── Testimonial Card ───────────── */
class _TestimonialCard extends StatelessWidget {
  final Map<String, String> data;
  final bool isActive;

  const _TestimonialCard({required this.data, required this.isActive});

  @override
  Widget build(BuildContext context) {
    IconData faceIcon;
    switch (data['gender']) {
      case 'female':
        faceIcon = Icons.face_4_rounded;
        break;
      case 'male':
        faceIcon = Icons.face_6_rounded;
        break;
      default:
        faceIcon = Icons.face;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              width: 1.4,
              color: Colors.white.withOpacity(0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.orange, Colors.red, Colors.yellow],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.black.withOpacity(0.15),
                  child: Icon(faceIcon, size: 34, color: Colors.white),
                ),
              ),
              const SizedBox(height: 14),

              // Review text
              Expanded(
                child: isActive
                    ? SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    '"${data['review']!}"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      decoration: TextDecoration.none,
                    ),
                  ),
                )
                    : Text(
                  '"${data['review']!}"',
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Name
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.orange, Colors.yellow],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  data['name']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),

              // Role
              Text(
                data['role']!,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
