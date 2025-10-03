import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/user/home_user.dart';

import '../services/validation.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _passFormKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _loadingProfile = true;
  bool _savingProfile = false;
  bool _changingPassword = false;
  bool _isCurrentVerified = false;
  bool _verifyingCurrent = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loadingProfile = false;
      });
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data() ?? {};
      _nameController.text = (data['fullName'] ?? '').toString();
      _emailController.text = (data['email'] ?? user.email ?? '').toString();
      _phoneController.text = (data['phoneNumber'] ?? '').toString();
      _addressController.text = (data['address'] ?? '').toString();
    } catch (e) {
      _showError('Failed to load profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingProfile = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _savingProfile = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fullName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _showSuccess('Profile updated successfully');
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
    } catch (e) {
      _showError('Failed to update profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _savingProfile = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    if (!_passFormKey.currentState!.validate()) return;
    if (!_isCurrentVerified) {
      _showError('Please verify current password first');
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _changingPassword = true;
    });

    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text.trim(),
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_newPasswordController.text.trim());

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      _showSuccess('Password changed successfully');
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Failed to change password');
    } catch (e) {
      _showError('Failed to change password: $e');
    } finally {
      if (mounted) {
        setState(() {
          _changingPassword = false;
        });
      }
    }
  }

  Future<void> _verifyCurrentPassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final current = _currentPasswordController.text.trim();
    if (current.isEmpty) {
      _showError("Enter current password to verify");
      return;
    }
    try {
      if (mounted) {
        setState(() {
          _verifyingCurrent = true;
        });
      }
      final cred = EmailAuthProvider.credential(email: user.email!, password: current);
      await user.reauthenticateWithCredential(cred);
      if (mounted) {
        setState(() {
          _isCurrentVerified = true;
        });
      }
      _showSuccess('Current password verified');
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isCurrentVerified = false;
        });
      }
      _showError(e.message ?? 'Verification failed');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCurrentVerified = false;
        });
      }
      _showError('Verification failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _verifyingCurrent = false;
        });
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          '✏️  Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(width: 1.5, color: Colors.white24),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomLeft,
                radius: 1.4,
                colors: [
                  Colors.black,
                  Colors.black,
                  Colors.black,
                  Colors.black,
                ],
                stops: [0.1, 0.4, 0.7, 1.0],
              ),
            ),
          ),
          if (_loadingProfile)
            const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            )
          else
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    // Profile form container
                    _glass(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeader('Personal Information', Icons.person),
                            const SizedBox(height: 14),

                            Text("❗ Email will not be changed",
                              style: TextStyle(
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 3),
                            _textField(
                              controller: _emailController,
                              hint: 'Email Address',
                              icon: Icons.email_outlined,
                              readOnly: true,
                              enabled: false,
                              validator: validateEmail,
                            ),

                            const SizedBox(height: 16),

                            _textField(
                              controller: _nameController,
                              hint: 'Full Name',
                              icon: Icons.badge_outlined,
                              validator: validateFullName,
                            ),

                            const SizedBox(height: 14),
                            _textField(
                              controller: _phoneController,
                              hint: 'Phone Number',
                              icon: Icons.phone_outlined,
                              validator: validatePhoneNumber,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 14),
                            _textField(
                              controller: _addressController,
                              hint: 'Address',
                              icon: Icons.location_on_outlined,
                              validator: validateAddress,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              child: _savingProfile
                                  ? _loadingButton('SAVING...')
                                  : _gradientButton(
                                      text: 'SAVE CHANGES',
                                      onTap: _saveProfile,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Password section
                    _glass(
                      child: Form(
                        key: _passFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeader('Change Password (Optional)', Icons.lock_outline),
                            const SizedBox(height: 16),
                            // Current password + verify
                            Row(
                              children: [
                                Expanded(
                                  child: _textField(
                                    controller: _currentPasswordController,
                                    hint: 'Current Password',
                                    icon: Icons.lock_clock_outlined,
                                    obscure: true,
                                    validator: (v) => (v == null || v.isEmpty) ? "Password can't be empty" : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _verifyingCurrent
                                    ? const SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                                        ),
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(colors: [Colors.orange, Colors.red, Colors.yellow]),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: ElevatedButton(
                                          onPressed: _verifyCurrentPassword,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          child: const Text(
                                            'VERIFY',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ),
                                      )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  _isCurrentVerified ? Icons.verified : Icons.info_outline,
                                  size: 16,
                                  color: _isCurrentVerified ? Colors.green : Colors.white54,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isCurrentVerified ? 'Verified' : 'Verify current password to enable change',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                )
                              ],
                            ),
                            const SizedBox(height: 14),
                            Opacity(
                              opacity: _isCurrentVerified ? 1 : 0.5,
                              child: IgnorePointer(
                                ignoring: !_isCurrentVerified,
                                child: _textField(
                                  controller: _newPasswordController,
                                  hint: 'New Password',
                                  icon: Icons.password_outlined,
                                  obscure: true,
                                  validator: validatePassword,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Opacity(
                              opacity: _isCurrentVerified ? 1 : 0.5,
                              child: IgnorePointer(
                                ignoring: !_isCurrentVerified,
                                child: _textField(
                                  controller: _confirmPasswordController,
                                  hint: 'Confirm New Password',
                                  icon: Icons.verified_user_outlined,
                                  obscure: true,
                                  validator: (v) => validateConfirmPassword(v, _newPasswordController.text),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              child: Opacity(
                                opacity: _isCurrentVerified ? 1 : 0.6,
                                child: _changingPassword
                                    ? _loadingButton('UPDATING...')
                                    : _gradientButton(
                                        text: 'CHANGE PASSWORD',
                                        onTap: _changePassword,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _glass({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.orange, Colors.red, Colors.yellow],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool enabled = true,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      enabled: enabled,
      keyboardType: keyboardType,
      obscureText: obscure,
      maxLines: obscure ? 1 : maxLines,
      readOnly: readOnly,
      style: GoogleFonts.poppins(textStyle: const TextStyle(color: Colors.white, fontSize: 16)),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.black.withOpacity(0.35),
        prefixIcon: Icon(icon, color: Colors.orange),
        hintText: hint,
        hintStyle: GoogleFonts.poppins(textStyle: const TextStyle(color: Colors.white70, fontSize: 14)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _gradientButton({required String text, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.orange, Colors.red, Colors.yellow]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 6)),
        ],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          text,
          style: GoogleFonts.playfairDisplay(
            textStyle: const TextStyle(
              fontSize: 16,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadingButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.orange.withOpacity(0.6),
          Colors.red.withOpacity(0.6),
          Colors.yellow.withOpacity(0.6),
        ]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.playfairDisplay(
              textStyle: const TextStyle(
                fontSize: 16,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


