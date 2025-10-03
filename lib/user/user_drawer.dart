import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/user/feedback_page.dart';
import 'package:project/user/home_user.dart';
import 'package:project/user/my_orders.dart';
import 'package:project/user/product_page.dart';
import 'package:project/user/about_us.dart';
import '../logout_page.dart';
import 'bug_report_page.dart';
import 'mix_blend.dart';

class UserDrawer extends StatelessWidget {
  final Function(String) onMenuItemSelected;

  const UserDrawer({super.key, required this.onMenuItemSelected});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 250,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.85),
                Colors.black.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border(
              right: BorderSide(
                color: Colors.white.withOpacity(0.15),
                width: 1.2,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _drawerHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _menuItem(context, Icons.home, "Home", route: HomePage()),
                      _menuItem(context, Icons.shopping_bag, "Shop", route: UserProductPage()),
                      _menuItem(context, Icons.receipt_long, "My Orders", route: MyOrdersPage()),
                      _menuItem(context, Icons.blender, "Mix Blend", route: MixBlendPage()),
                      _menuItem(context, Icons.question_mark_sharp, "About", route: AboutUsPage()),
                      _menuItem(context, Icons.feedback, "Feedback", route: FeedbackFormPage()),
                      _menuItem(context, Icons.logout, "Logout", isLogout: true),
                      SizedBox(height: 60,)
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _drawerHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ClipRRect(
          //   borderRadius: BorderRadius.circular(12),
          //   child: Image.asset(
          //     'assets/images/sasta_logo.png',
          //     height: 130,
          //     width: 220,
          //
          //   ),
          // ),
          // const SizedBox(height: 14),
          Text(
            "\t \t \t MirchBazaar",
            style: GoogleFonts.playfairDisplay(
              textStyle: const TextStyle(
                fontSize: 20,

                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Your shopping companion",
            style: GoogleFonts.poppins(
              textStyle: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String title,
      {Widget? route, bool isLogout = false}) {
    return InkWell(
      onTap: () async {
        if (isLogout) {
          await LogoutHelper.confirmLogout(context);
        } else if (route != null) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => route));
        }
        onMenuItemSelected(title);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.orange, size: 20),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: Colors.white.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
