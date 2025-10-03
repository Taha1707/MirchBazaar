import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_drawer.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  String _search = '';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: AnimatedIcon(icon: AnimatedIcons.menu_close, progress: _controller, color: Colors.white),
          onPressed: _toggleMenu,
        ),
        title: const Text('Users', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomLeft,
                radius: 1.2,
                colors: [Colors.black, Colors.black, Colors.black, Colors.black],
                stops: [0.1, 0.6, 0.8, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.18)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'Search users by name or email',
                                  hintStyle: TextStyle(color: Colors.white70),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'user')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.orange));
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
                        );
                      }
                      final docs = snapshot.data?.docs ?? [];
                      final filtered = docs.where((d) {
                        final data = (d.data() as Map<String, dynamic>? ) ?? {};
                        final name = (data['fullName'] ?? '').toString().toLowerCase();
                        final email = (data['email'] ?? '').toString().toLowerCase();
                        if (_search.isEmpty) return true;
                        return name.contains(_search) || email.contains(_search);
                      }).toList();

                      if (filtered.isEmpty) {
                        return const Center(
                          child: Text('No users found', style: TextStyle(color: Colors.white70)),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final d = filtered[i];
                          final data = (d.data() as Map<String, dynamic>? ) ?? {};
                          return _UserCard(data: data);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double slide = 250 * _controller.value;
              return Transform.translate(
                offset: Offset(-250 + slide, 0),
                child: AdminDrawer(onMenuItemSelected: (_) => _controller.reverse()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _UserCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final String name = (data['fullName'] ?? 'User') as String;
    final String email = (data['email'] ?? '') as String;
    final String phone = (data['phoneNumber'] ?? '-') as String;
    final String address = (data['address'] ?? '-') as String;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.withOpacity(0.15),
                Colors.red.withOpacity(0.15),
                Colors.yellow.withOpacity(0.15),
                // Colors.white.withOpacity(0.10),
                // Colors.white.withOpacity(0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                color: Colors.black.withOpacity(0.2),
              ),
              child: const Icon(Icons.person, color: Colors.orange),
            ),
            title: Text(
              name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, color: Colors.white70, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(email, style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, color: Colors.white70, size: 14),
                      const SizedBox(width: 6),
                      Text(phone, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.white70, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(address, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
                color: Colors.white.withOpacity(0.06),
              ),
              child: const Text('User', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }
}


