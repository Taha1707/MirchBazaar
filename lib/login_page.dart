import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:project/signup_page.dart';
import 'package:project/user/home_user.dart';
import './admin/view_product_page.dart';
import '../services/authentication.dart';
import '../services/validation.dart';
import 'auth&role_check_page.dart';
import 'forget_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? email = '';
  String? password = '';
  bool _isObscure = true;
  bool isLoginLoading = false;

  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();

    /// 🔹 Background MP4 video setup
    _videoController = VideoPlayerController.asset("assets/images/Firework.mp4")
      ..initialize().then((_) {
        setState(() {}); // refresh when initialized
        _videoController.setLooping(true);
        _videoController.setVolume(0); // mute background
        _videoController.play();
      });

    /// 🔹 Auto-navigate if already logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Future.delayed(Duration.zero, () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage()),
        );
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
          // 🔹 MP4 Background
          if (_videoController.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            Container(color: Colors.black), // fallback until video loads

          // 🔹 Main Content with Glassmorphism
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(24),
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Welcome Back!',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Sign in to continue",
                              style: TextStyle(
                                  fontSize: 15, color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),

                            // Email
                            _buildTextField(
                              controller: emailController,
                              hint: "Email",
                              icon: Icons.email_outlined,
                              validator: validateEmail,
                              onSaved: (value) => email = value,
                            ),
                            const SizedBox(height: 20),

                            // Password
                            _buildTextField(
                              controller: passwordController,
                              hint: "Password",
                              icon: Icons.lock_outline,
                              validator: validatePassword,
                              obscureText: _isObscure,
                              suffix: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isObscure = !_isObscure;
                                  });
                                },
                                icon: ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: [Colors.orange, Colors.yellow],
                                      ).createShader(bounds),
                                  child: Icon(
                                    _isObscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              onSaved: (value) => password = value,
                            ),
                            const SizedBox(height: 10),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ForgetPasswordPage()));
                                },
                                child: const Text(
                                  "Forgot Password?",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),

                            // Login Button
                            isLoginLoading
                                ? ShaderMask(
                              shaderCallback: (bounds) =>
                                  const LinearGradient(
                                    colors: [
                                      Colors.orangeAccent,
                                      Colors.orange,
                                      Colors.red,
                                      Colors.yellow
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds),
                              child: const CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor:
                                AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                                : _buildGradientButton(
                              text: "LOGIN",
                              onTap: _loginUser,
                            ),

                            const SizedBox(height: 15),

                            // Sign Up Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Don't have an account? ",
                                    style: TextStyle(color: Colors.white)),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const SignUpPage()),
                                    );
                                  },
                                  child: const Text(
                                    "SignUp",
                                    style: TextStyle(
                                      color: Colors.orange,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    required Function(String?) onSaved,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      obscureText: obscureText,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.transparent,
        prefixIcon: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.orange, Colors.yellow],
          ).createShader(bounds),
          child: Icon(icon, color: Colors.white),
        ),
        suffixIcon: suffix,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white70, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.yellow, width: 1.5),
        ),
      ),
      validator: validator,
      onSaved: onSaved,
    );
  }

  Widget _buildGradientButton(
      {required String text, required VoidCallback onTap}) {
    return Container(
      width: double.infinity,
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
          style: const TextStyle(
              letterSpacing: 2,
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _loginUser() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => isLoginLoading = true);

      var result = await AuthenticationHelper().signIn(
        email: email!,
        password: password!,
      );

      setState(() => isLoginLoading = false);

      if (result == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("✅ Login Successful")));
        await AuthRoleNavigator.navigateBasedOnRole(context);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result.toString())));
      }
    }
  }
}
