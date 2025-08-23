import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import './view_product_page.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({Key? key}) : super(key: key);

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _titleController = TextEditingController();
  final _price250gController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _reviewController = TextEditingController();

  Uint8List? _imageBytes;
  String? _base64Image;

  Uint8List? _spiceImageBytes;
  String? _base64SpiceImage;

  bool _availability = true;
  bool isSaving = false;

  double _rating = 0.0; // ⭐ review stars

  // 🔥 Category dropdown
  String? _selectedCategory;
  final List<String> _categories = ["Mild", "Spicy", "Hot", "Fiery"];

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage({bool isSpice = false}) async {
    try {
      final XFile? pickedFile =
      await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          if (isSpice) {
            _spiceImageBytes = bytes;
            _base64SpiceImage = base64Encode(bytes);
          } else {
            _imageBytes = bytes;
            _base64Image = base64Encode(bytes);
          }
        });
      }
    } catch (e) {
      print('❗ Error picking image: $e');
    }
  }

  Future<void> _saveProduct() async {
    if (_titleController.text.isEmpty ||
        _price250gController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _base64Image == null ||
        _base64SpiceImage == null ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❗ Please complete all required fields')),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await FirebaseFirestore.instance.collection('products').add({
        'title': _titleController.text,
        'pricePer250g': double.parse(_price250gController.text),
        'description': _descriptionController.text,
        'review': _rating,
        'availability': _availability,
        'category': _selectedCategory,
        'image': _base64Image,
        'spiceMeterImage': _base64SpiceImage,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Product added successfully')),
      );

      clearData();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ViewProductPage()),
      );
    } catch (e) {
      print('❌ Error saving product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❗ Failed to add product')),
      );
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  void clearData() {
    _titleController.clear();
    _price250gController.clear();
    _descriptionController.clear();
    _reviewController.clear();
    _imageBytes = null;
    _base64Image = null;
    _spiceImageBytes = null;
    _base64SpiceImage = null;
    _availability = true;
    _selectedCategory = null;
    _rating = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Add Product',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomLeft,
                radius: 1.4,
                colors: [
                  Colors.deepOrange,
                  Colors.black,
                  Colors.black,
                  Colors.black,
                ],
                stops: [0.1, 0.7, 0.2, 0.2],
              ),
            ),
          ),

          // Content
          Container(
            margin: const EdgeInsets.only(top: 50),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(_titleController, 'Product Title'),
                        const SizedBox(height: 12),
                        _buildTextField(_price250gController, 'Price (250g)',
                            isNumber: true),
                        const SizedBox(height: 12),
                        _buildTextField(_descriptionController, 'Description',
                            maxLines: 3),
                        const SizedBox(height: 20),

                        // 🔥 Category Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          items: _categories
                              .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat,
                                style: const TextStyle(
                                    color: Colors.white)),
                          ))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedCategory = val;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: "Category",
                            labelStyle:
                            const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.black.withOpacity(0.3),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                              const BorderSide(color: Colors.white24),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: Colors.white54, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          dropdownColor: Colors.black87,
                        ),

                        const SizedBox(height: 20),

                        // Availability Toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(10),
                              child: Text("Availability",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16)),
                            ),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: _availability,
                                activeColor: Colors.deepOrange,
                                onChanged: (val) {
                                  setState(() {
                                    _availability = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // rating
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Review",
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              RatingBar.builder(
                                initialRating: _rating,
                                minRating: 1,
                                direction: Axis.horizontal,
                                allowHalfRating: true,
                                itemCount: 5,
                                itemSize: 32,
                                unratedColor: Colors.white24,
                                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                                itemBuilder: (context, _) =>
                                const Icon(Icons.star, color: Colors.orangeAccent),
                                onRatingUpdate: (rating) {
                                  setState(() {
                                    _rating = rating;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Product Image Picker
                        GestureDetector(
                          onTap: () => _pickImage(),
                          child: _buildImageBox(
                              _imageBytes, "Tap to select product image"),
                        ),
                        const SizedBox(height: 20),

                        // SpiceMeter Image Picker
                        GestureDetector(
                          onTap: () => _pickImage(isSpice: true),
                          child: _buildImageBox(_spiceImageBytes,
                              "Tap to select spice meter image"),
                        ),

                        const SizedBox(height: 20),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: isSaving
                              ? Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor:
                                AlwaysStoppedAnimation<Color>(
                                    Colors.deepOrange),
                              ),
                            ),
                          )
                              : _buildGradientButton(
                            text: "SAVE PRODUCT",
                            onTap: _saveProduct,
                          ),
                        )
                      ],
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

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white54, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildImageBox(Uint8List? bytes, String text) {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withOpacity(0.3),
      ),
      child: bytes != null
          ? ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(bytes, fit: BoxFit.cover),
      )
          : Center(
        child:
        Text(text, style: const TextStyle(color: Colors.white70)),
      ),
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
}
