import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/admin/home_admin.dart';
import 'package:project/admin/view_product_page.dart';
import 'package:project/user/home_user.dart';
import 'package:project/user/product_page.dart';
import 'login_page.dart';


class Auth_Role_Check extends StatelessWidget {
  const Auth_Role_Check({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AuthRoleNavigator.navigateBasedOnRole(context, returnWidget: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data ?? const LoginPage(); // default fallback
      },
    );
  }
}


class AuthRoleNavigator {
  static Future<Widget?> navigateBasedOnRole(
      BuildContext context, {
        bool returnWidget = false,
      }) async {
    final user = FirebaseAuth.instance.currentUser;

    // Agar login hi nahi
    if (user == null) {
      if (returnWidget) return const LoginPage();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return null;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final role = doc.data()?['role'] ?? 'user';

      if (returnWidget) {
        return role == 'admin' ? const AdminHomePage() : const HomePage();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => role == 'admin' ? const AdminHomePage() : const HomePage(),
        ),
      );

      return null;
    } catch (e) {
      debugPrint("Error fetching role: $e");
      if (returnWidget) return const LoginPage();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return null;
    }
  }
}
