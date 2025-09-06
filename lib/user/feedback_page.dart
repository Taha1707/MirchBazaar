import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/user/user_drawer.dart';
import '../services/authentication.dart';
import '../services/validation.dart';

final user = FirebaseAuth.instance.currentUser;
final userEmail = user?.email ?? 'No Email';

class FeedbackFormPage extends StatefulWidget {
  static const String routeName = '/FeedbackFormPage';
  @override
  State<FeedbackFormPage> createState() => _FeedbackFormPageState();
}

class _FeedbackFormPageState extends State<FeedbackFormPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  String _feedbackType = 'General';
  int _rating = 0;
  bool _isSending = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
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

  void _submitFeedback() async {
    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    final feedbackData = {
      'email': user?.email ?? 'No Email',
      'type': _feedbackType,
      'rating': _rating,
      'message': _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('feedbacks').add(feedbackData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Feedback submitted successfully!'),
          backgroundColor: Colors.orange,
        ),
      );

      clearData();

      setState(() {
        _feedbackType = 'General';
        _rating = 0;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to send feedback. Please try again.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }

    setState(() => _isSending = false);
  }

  Widget _buildStarRating() {
    return Row(
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return IconButton(
          icon: Icon(
            _rating >= starIndex ? Icons.star : Icons.star_border,
            color: Colors.orange,
            size: 28,
          ),
          onPressed: () {
            setState(() => _rating = starIndex);
          },
        );
      }),
    );
  }

  // Section Heading with Orange Underline (same as About Us)
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

  // Themed Input Field
  Widget _buildThemedTextField({
    required String hintText,
    required IconData icon,
    TextEditingController? controller,
    String? initialValue,
    bool enabled = true,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        initialValue: initialValue,
        enabled: enabled,
        maxLines: maxLines,
        validator: validator,
        style: GoogleFonts.poppins(
          textStyle: TextStyle(
            color: enabled ? Colors.white : Colors.white54,
            fontSize: 16,
          ),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            textStyle: const TextStyle(
              color: Colors.white38,
              fontSize: 16,
            ),
          ),
          prefixIcon: maxLines > 1
              ? Padding(
            padding: const EdgeInsets.only(bottom: 48),
            child: Icon(icon, color: Colors.orange),
          )
              : Icon(icon, color: Colors.orange),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.orange, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  // Themed Dropdown
  Widget _buildThemedDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _feedbackType,
        dropdownColor: Colors.grey[800],
        style: GoogleFonts.poppins(
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        decoration: InputDecoration(
          hintText: "Select Feedback Type",
          hintStyle: GoogleFonts.poppins(
            textStyle: const TextStyle(
              color: Colors.white38,
              fontSize: 16,
            ),
          ),
          prefixIcon: Icon(Icons.category_outlined, color: Colors.orange),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.orange, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: ['General', 'Bug Report', 'Feature Request', 'Other']
            .map(
              (type) => DropdownMenuItem(
            value: type,
            child: Text(
              type,
              style: GoogleFonts.poppins(
                textStyle: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        )
            .toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() => _feedbackType = val);
          }
        },
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
          icon: _controller != null
              ? AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _controller,
            color: Colors.white,
          )
              : Icon(Icons.menu, color: Colors.white),
          onPressed: _toggleMenu,
        ),

        actions: <Widget>[
          IconButton(
            onPressed: () async {
              await AuthenticationHelper().signOut();
              Navigator.pushReplacementNamed(context, "/LoginPage");
            },
            icon: Icon(Icons.logout_outlined, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Hero Section with Glass Card
                Stack(
                  children: [
                    // Background Banner
                    Container(
                      height: MediaQuery.of(context).size.height * 0.35,
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
                      height: MediaQuery.of(context).size.height * 0.35,
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
                              Icon(Icons.feedback, size: 50, color: Colors.orange),
                              const SizedBox(height: 14),
                              Text(
                                "We Value Your Feedback",
                                style: GoogleFonts.playfairDisplay(
                                  textStyle: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Help us improve MirchBazaar with your thoughts and suggestions ✨",
                                style: GoogleFonts.poppins(
                                  textStyle: const TextStyle(
                                    fontSize: 14,
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

                // Feedback Form Section
                _sectionHeading("Share Your Experience"),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email Warning
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            "⚠️ Your email cannot be edited!",
                            style: GoogleFonts.poppins(
                              textStyle: TextStyle(
                                color: Colors.red.shade400,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),

                        // Email Field
                        _buildThemedTextField(
                          hintText: "Email Address",
                          icon: Icons.email_outlined,
                          initialValue: FirebaseAuth.instance.currentUser?.email ?? 'No Email',
                          enabled: false,
                        ),

                        // Feedback Type Dropdown
                        _buildThemedDropdown(),

                        // Rating Section
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            "Rate Your Experience",
                            style: GoogleFonts.poppins(
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange.withOpacity(0.4)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: _buildStarRating(),
                        ),

                        // Message Field
                        _buildThemedTextField(
                          hintText: "Describe your feedback or suggestions...",
                          icon: Icons.message_outlined,
                          controller: _messageController,
                          maxLines: 5,
                          validator: validateMessage,
                        ),

                        const SizedBox(height: 10),

                        // Send Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isSending ? null : _submitFeedback,
                            icon: _isSending
                                ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                                : Icon(Icons.send_rounded, color: Colors.white),
                            label: Text(
                              _isSending ? "Sending..." : "Send Feedback",
                              style: GoogleFonts.poppins(
                                textStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              elevation: 8,
                              shadowColor: Colors.orange.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),

          // Drawer (same as About Us)
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

  void clearData() {
    _emailController.clear();
    _messageController.clear();
  }
}