import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/authentication.dart';
import '../services/validation.dart';
import 'auth&role_check_page.dart';
import 'login_page.dart';
import './admin/view_product_page.dart';

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

  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();

    // 🔥 Setup video background
    _videoController = VideoPlayerController.asset("assets/images/firework.mp4")
      ..initialize().then((_) {
        _videoController.setLooping(true);
        _videoController.setVolume(0);
        _videoController.play();
        setState(() {}); // refresh after video init
      });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Future.delayed(Duration.zero, () {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => ViewProductPage()));
      });
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🎥 Background Video
          if (_videoController.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: VideoPlayer(_videoController),
              ),
            )
          else
            Container(color: Colors.black), // fallback before video loads

          // Form with Glassmorphism
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  const LinearGradient(
                                    colors: [Colors.orange, Colors.yellow],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds),
                              child: const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Join us and explore amazing products.",
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 40),

                            _buildGradientTextField(
                              controller: fullnameController,
                              hint: "Full Name",
                              icon: Icons.person_outline,
                              validator: validateName,
                              onSaved: (val) => fullName = val,
                            ),
                            const SizedBox(height: 18),

                            _buildGradientTextField(
                              controller: phoneNumberController,
                              hint: "Phone Number",
                              icon: Icons.phone_outlined,
                              validator: validatePhoneNumber,
                              onSaved: (val) => phoneNumber = val,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 18),

                            _buildGradientTextField(
                              controller: addressController,
                              hint: "Address",
                              icon: Icons.home_outlined,
                              validator: validateAddress,
                              onSaved: (val) => address = val,
                            ),
                            const SizedBox(height: 18),

                            _buildGradientTextField(
                              controller: emailController,
                              hint: "Email",
                              icon: Icons.email_outlined,
                              validator: validateEmail,
                              onSaved: (val) => email = val,
                            ),
                            const SizedBox(height: 18),

                            // Password field
                            TextFormField(
                              controller: passwordController,
                              obscureText: _isObscure,
                              style: const TextStyle(color: Colors.white),
                              decoration: _gradientInputDecoration(
                                hint: "Password",
                                icon: Icons.lock_outline,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: ShaderMask(
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                          colors: [Colors.orange, Colors.yellow],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ).createShader(bounds),
                                    child: Icon(
                                      _isObscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.white,
                                    ),
                                  ),
                                  onPressed: () => setState(
                                          () => _isObscure = !_isObscure),
                                ),
                              ),
                              validator: validatePassword,
                              onSaved: (val) => password = val,
                            ),
                            const SizedBox(height: 30),

                            // Gradient Button
                            isRegisterLoading
                                ? ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Colors.orangeAccent, Colors.orange, Colors.red, Colors.yellow],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: const CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                                : Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.orange, Colors.red, Colors.yellow],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton(
                                onPressed: _signUpUser,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "SIGN UP",
                                  style: TextStyle(
                                    letterSpacing: 3,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 15),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Already have an account? ",
                                  style: TextStyle(color: Colors.white),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const LoginPage()),
                                    );
                                  },
                                  child: const Text(
                                    "Login",
                                    style: TextStyle(
                                      color: Colors.yellow,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Gradient text field builder
  Widget _buildGradientTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      decoration: _gradientInputDecoration(hint: hint, icon: icon),
      validator: validator,
      onSaved: onSaved,
    );
  }

  InputDecoration _gradientInputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      prefixIcon: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Colors.orange, Colors.yellow],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: Icon(icon, color: Colors.white),
      ),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.yellow, width: 2),
      ),
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
}
