import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/admin/admin_users_page.dart';
import 'package:project/admin/home_admin.dart';
import '../admin/view_product_page.dart';
import 'admin_feedback_page.dart';
import 'admin_bug_reports_page.dart';
import 'admin_orders_page.dart';
import '../logout_page.dart';

class AdminDrawer extends StatelessWidget {
  final Function(String) onMenuItemSelected;

  const AdminDrawer({super.key, required this.onMenuItemSelected});

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
                      _menuItem(context, Icons.dashboard, "Dashboard", route: AdminHomePage()),
                      _menuItem(context, Icons.inventory, "Manage Products", route: ViewProductPage()),
                      _menuItem(context, Icons.receipt_long, "Orders", route: AdminOrdersPage()),
                      _menuItem(context, Icons.people, "Users", route: AdminUsersPage()),
                      _menuItem(context, Icons.bug_report, "Bug Reports", route: AdminBugReportsPage()),
                      _menuItem(context, Icons.rate_review, "Feedbacks", route: AdminFeedbackPage()),
                      _menuItem(context, Icons.logout, "Logout", isLogout: true),
                      const SizedBox(height: 10),
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
          Text(
            "\t \t \t \t Admin Panel",
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
            "Manage your store efficiently",
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
