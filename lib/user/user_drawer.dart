import 'package:flutter/material.dart';
import 'package:project/user/home_user.dart';
import 'package:project/user/product_page.dart';
import 'package:project/user/about_us.dart';
import '../logout_page.dart';
import '../admin/view_product_page.dart'; // example route for navigation

class UserDrawer extends StatelessWidget {
  final Function(String) onMenuItemSelected;

  const UserDrawer({super.key, required this.onMenuItemSelected});

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
                height: 30,
              ),
            ),
            _menuItem(context, Icons.home, "Home", route: HomePage()),
            _menuItem(context, Icons.shopping_bag, "Shop", route: UserProductPage()), // example route
            _menuItem(context, Icons.favorite, "Wishlist"),
            _menuItem(context, Icons.receipt_long, "My Orders"),
            _menuItem(context, Icons.local_offer, "Offers"),
            _menuItem(context, Icons.contact_support, "Support"),
            _menuItem(context, Icons.question_mark_sharp, "About", route: AboutUsPage()),
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
