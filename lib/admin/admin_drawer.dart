import 'package:flutter/material.dart';
import 'package:project/admin/home_admin.dart';
import '../admin/view_product_page.dart';
import 'admin_feedback_page.dart';
import 'admin_orders_page.dart';
import '../logout_page.dart';

class AdminDrawer extends StatelessWidget {
  final Function(String) onMenuItemSelected;

  const AdminDrawer({super.key, required this.onMenuItemSelected});

  @override
  Widget build(BuildContext context) {
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
                'assets/images/sasta_logo.png',
              ),
            ),
            _menuItem(context, Icons.dashboard, "Dashboard", route: AdminHomePage()),
            _menuItem(context, Icons.inventory, "Manage Products", route: ViewProductPage()),
            _menuItem(context, Icons.receipt_long, "Orders", route: AdminOrdersPage()),
            _menuItem(context, Icons.people, "Customers"),
            _menuItem(context, Icons.analytics, "Reports"),
            _menuItem(context, Icons.rate_review, "Feedbacks", route: AdminFeedbackPage()),
            _menuItem(context, Icons.settings, "Settings"),
            _menuItem(context, Icons.logout, "Logout", isLogout: true),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String title,
      {Widget? route, bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: () async {
        if (isLogout) {
          await LogoutHelper.confirmLogout(context);
        } else if (route != null) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => route));
        }
        onMenuItemSelected(title);
      },
    );
  }
}
