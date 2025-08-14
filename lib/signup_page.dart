import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/user/product_page.dart';
import './admin/view_product_page.dart';
import '../services/authentication.dart';
import '../services/validation.dart';
import 'auth&role_check_page.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final fullnameController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? fullName = '';
  String? phoneNumber = '';
  String? address = '';
  String? email = '';
  String? password = '';

  bool _isObscure = true;
  bool isRegisterLoading = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Future.delayed(Duration.zero, () {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => ViewProductPage()));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    'Create Account',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Join us and explore amazing products.",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Full Name Field
                  TextFormField(
                    controller: fullnameController,
                    decoration: _inputDecoration(Icons.person_outline, "Full Name"),
                    validator: validateName,
                    onSaved: (value) => fullName = value,
                  ),
                  const SizedBox(height: 20),

                  // Phone Number Field
                  TextFormField(
                    controller: phoneNumberController,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration(Icons.phone_outlined, "Phone Number"),
                    validator: validatePhoneNumber,
                    onSaved: (value) => phoneNumber = value,
                  ),
                  const SizedBox(height: 20),

                  // Address Field
                  TextFormField(
                    controller: addressController,
                    decoration: _inputDecoration(Icons.home_outlined, "Address"),
                    validator: validateAddress,
                    onSaved: (value) => address = value,
                  ),
                  const SizedBox(height: 20),

                  // Email Field
                  TextFormField(
                    controller: emailController,
                    decoration: _inputDecoration(Icons.email_outlined, "Email"),
                    validator: validateEmail,
                    onSaved: (value) => email = value,
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  TextFormField(
                    controller: passwordController,
                    obscureText: _isObscure,
                    decoration: _inputDecoration(Icons.lock_outlined, "Password").copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.deepPurple,
                        ),
                        onPressed: () =>
                            setState(() => _isObscure = !_isObscure),
                      ),
                    ),
                    validator: validatePassword,
                    onSaved: (value) => password = value,
                  ),
                  const SizedBox(height: 20),

                  // Register Button
                  isRegisterLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _signUpUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        "SIGN UP",
                        style: TextStyle(
                            letterSpacing: 4,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Login prompt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? ",
                          style: TextStyle(color: Colors.black87)),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                          );
                        },
                        child: const Text("Login",
                            style: TextStyle(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(IconData icon, String hint) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF7EDF9),
      prefixIcon: Icon(icon, color: Colors.deepPurple),
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  void _signUpUser() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => isRegisterLoading = true);

      var result = await AuthenticationHelper().signUp(
        email: email!,
        password: password!,
        fullName: fullName!,
        phoneNumber: phoneNumber!,
        address: address!,
      );

      setState(() => isRegisterLoading = false);

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Signup Successful")),
        );

        await AuthRoleNavigator.navigateBasedOnRole(context);

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.toString())),
        );
      }
    }
  }


  void clearData() {
    fullnameController.clear();
    phoneNumberController.clear();
    addressController.clear();
    emailController.clear();
    passwordController.clear();
  }
}
