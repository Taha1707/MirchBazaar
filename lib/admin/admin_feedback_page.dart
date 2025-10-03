import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_drawer.dart';

class AdminFeedbackPage extends StatefulWidget {
  const AdminFeedbackPage({super.key});

  @override
  State<AdminFeedbackPage> createState() => _AdminFeedbackPageState();
}

class _AdminFeedbackPageState extends State<AdminFeedbackPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
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

  Future<void> _deleteFeedback(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container
              (
              width: MediaQuery.of(ctx).size.width * 0.8,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.orange, Colors.yellow],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.orange, Colors.yellow],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Text(
                      "Delete Feedback",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Are you sure you want to delete this feedback? This action cannot be undone.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.white70,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.orange, Colors.red, Colors.yellow],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "DELETE",
                            style: TextStyle(
                              letterSpacing: 2,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('feedbacks').doc(docId).delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback deleted')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _controller,
            color: Colors.white,
          ),
          onPressed: _toggleMenu,
        ),
        title: const Text(
          '📝 All Feedbacks',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomLeft,
                radius: 1,
                colors: [Colors.black, Colors.black, Colors.black, Colors.black],
                stops: [0.1, 0.7, 0.2, 0.2],
              ),
            ),
          ),
          Positioned.fill(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('feedbacks')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No feedbacks found', style: TextStyle(color: Colors.white70)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final email = data['email'] ?? 'No Email';
                    final type = data['type'] ?? 'Feedback';
                    final rating = (data['rating'] ?? 0) as int;
                    final message = data['message'] ?? '';
                    final ts = data['timestamp'];
                    DateTime? dateTime;
                    if (ts is Timestamp) dateTime = ts.toDate();
                    final dateStr = dateTime?.toLocal().toString() ?? '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange.withOpacity(0.15),
                                  Colors.red.withOpacity(0.15),
                                  Colors.yellow.withOpacity(0.15),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Row(
                                children: [
                                  const Icon(Icons.person_outline, color: Colors.orangeAccent),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      email,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      type,
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: Colors.white70),
                                    color: Colors.black,
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(color: Colors.white.withOpacity(0.12), width: 1),
                                    ),
                                    onSelected: (value) {
                                      if (value == 'delete') {
                                        _deleteFeedback(context, doc.id);
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline, color: Colors.redAccent),
                                            SizedBox(width: 8),
                                            Text('Delete', style: TextStyle(color: Colors.white)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Row(
                                        children: List.generate(5, (i) => Icon(
                                              i < rating ? Icons.star : Icons.star_border,
                                              color: Colors.orange,
                                              size: 18,
                                            )),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(dateStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    message,
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double slide = 250 * _controller.value;
              return Transform.translate(
                offset: Offset(-250 + slide, 0),
                child: AdminDrawer(
                  onMenuItemSelected: (title) {
                    _controller.reverse();
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}


