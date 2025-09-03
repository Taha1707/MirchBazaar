import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/user/user_drawer.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          SingleChildScrollView(
            child: Column(
              children: [
                // 🔹 Hero Section (Glassy Intro)
                Stack(
                  children: [
                    // Background Banner
                    Container(
                      height: MediaQuery.of(context).size.height * 0.53,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage("assets/images/banner_2.jpg"),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // Dark overlay
                    Container(
                      height: MediaQuery.of(context).size.height * 0.53,
                      width: double.infinity,
                      color: Colors.black.withOpacity(0.5),
                    ),

                    // Center Glass Card
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.orange.withOpacity(0.4)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "About MirchBazaar",
                                style: GoogleFonts.playfairDisplay(
                                  textStyle: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                "Spices are more than flavor — they’re culture, heritage, and memories. 🌶✨\n\nAt MirchBazaar, we craft experiences that bring families together through the love of authentic spices.",
                                style: GoogleFonts.poppins(
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                    height: 1.5,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // 🔹 Our Story (Timeline)
                _sectionHeading("Our Story"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    children: [
                      _timelineCard("2010", "🌶",
                          "Founded with a mission to bring authentic spices to every kitchen."),
                      _timelineCard("2015", "🥘",
                          "Expanded our collection, adding regional and rare masalas."),
                      _timelineCard("2020", "⚡",
                          "Introduced Mix & Blend feature for custom masala creations."),
                      _timelineCard("2025", "🌍",
                          "Served over 1 million spice enthusiasts worldwide."),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 🔹 Mission & Vision
                _sectionHeading("Our Mission & Vision"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _infoCard("🌟", "Mission",
                          "To deliver pure, fresh, and flavorful spices that make every meal unforgettable."),
                      _infoCard("🚀", "Vision",
                          "To be the world’s most trusted name in authentic and custom spice blends."),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 🔹 Why Choose Us
                _sectionHeading("Why Choose Us"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      _featureCard(Icons.local_fire_department, "Hot & Fresh",
                          "Spices delivered fresh & aromatic."),
                      _featureCard(Icons.eco, "Natural & Pure",
                          "100% organic, no artificial additives."),
                      _featureCard(Icons.restaurant, "Perfect Taste",
                          "Handpicked for authentic flavor."),
                      _featureCard(Icons.spa, "Aromatic",
                          "A sensory delight in every sprinkle."),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 🔹 Fun Facts / Legacy
                _sectionHeading("Spice Legacy"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Wrap(
                    spacing: 30,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      _statCard("🌶", "10,000+", "Unique spice blends created"),
                      _statCard("🍲", "500k+", "Recipes enhanced with our flavors"),
                      _statCard("🌍", "1M+", "Happy spice lovers worldwide"),
                      _statCard("⏳", "15+ Years", "Crafting spice traditions with love"),


                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 🔹 Meet The Team
                _sectionHeading("Meet The Team"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      _teamMember(
                          "Taha Shakeel", "Developer", "assets/images/Taha.png"),
                      _teamMember("Muhammad Yousuf", "Developer",
                          "assets/images/Yousuf.jpg"),
                      _teamMember(
                          "Hassan Rafiq", "Vendor", "assets/images/Hassan.jpg"),
                    ],
                  ),
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),

          // 🔹 Drawer
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double slide = 250 * _controller.value;
              return Transform.translate(
                offset: Offset(-250 + slide, 0),
                child: UserDrawer(
                  onMenuItemSelected: (_) => _controller.reverse(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 🔹 Section Heading with Orange Underline
  Widget _sectionHeading(String title) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 3,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }

  // 🔹 Info Card (Mission / Vision)
  Widget _infoCard(String emoji, String title, String desc) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 6),
            Text(desc,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // 🔹 Stats Card (Fun Facts)
  Widget _statCard(String emoji, String number, String label) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 6),
          Text(number,
              style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // 🔹 Feature Card
  Widget _featureCard(IconData icon, String title, String description) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.orange),
          const SizedBox(height: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(description,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // 🔹 Team Member Card
  Widget _teamMember(String name, String role, String asset) {
    return SizedBox(
      width: 120,
      child: Column(
        children: [
          CircleAvatar(radius: 40, backgroundImage: AssetImage(asset)),
          const SizedBox(height: 8),
          Text(name,
              style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(role,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// 🔹 Timeline Card
Widget _timelineCard(String year, String emoji, String description) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.orange.withOpacity(0.5)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 6,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Text(
              year,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            Text(
              emoji,
              style: const TextStyle(fontSize: 22),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}
