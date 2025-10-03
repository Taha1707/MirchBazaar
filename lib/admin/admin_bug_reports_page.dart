import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_drawer.dart';

class AdminBugReportsPage extends StatefulWidget {
  const AdminBugReportsPage({super.key});

  @override
  State<AdminBugReportsPage> createState() => _AdminBugReportsPageState();
}

class _AdminBugReportsPageState extends State<AdminBugReportsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
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

  Future<void> _updateStatus(String id, String status) async {
    await FirebaseFirestore.instance.collection('bug_reports').doc(id).update({
      'status': status,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status updated to $status'),
        backgroundColor: Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return const Color(0xFF3B82F6);
      case 'in progress':
        return const Color(0xFFF59E0B);
      case 'fixed':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return Icons.new_releases_outlined;
      case 'in progress':
        return Icons.refresh_rounded;
      case 'fixed':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
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
          '🐞 Bug Reports',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildBugReportsList(),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double slide = 250 * _controller.value;
              return Transform.translate(
                offset: Offset(-250 + slide, 0),
                child: AdminDrawer(
                  onMenuItemSelected: (_) => _controller.reverse(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBugReportsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bug_reports')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  'Error loading reports',
                  style: TextStyle(color: Colors.red.shade400, fontSize: 16),
                ),
              ],
            ),
          );
        }

        var docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 80,
                  color: Colors.white.withOpacity(0.2),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No bug reports',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i];
            final data = d.data() as Map<String, dynamic>? ?? {};
            return _buildBugReportCard(d.id, data);
          },
        );
      },
    );
  }

  Widget _buildBugReportCard(String id, Map<String, dynamic> data) {
    final title = data['title'] ?? 'Untitled';
    final userName = data['userName'] ?? 'Unknown';
    final userId = data['userId'] ?? '';
    final priority = data['priority'] ?? 'Medium';
    final status = data['status'] ?? 'New';
    final types = (data['types'] as List?)?.cast<String>() ?? [];
    final description = data['description'] ?? '';
    final screenshot = data['screenshotUrl'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.orange.withOpacity(0.15),
                  Colors.red.withOpacity(0.15),
                  Colors.yellow.withOpacity(0.15),
                  // Colors.orange.withOpacity(0.1),
                  // Colors.yellow.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(id, title, status, priority),
                _buildCardContent(
                  userName,
                  userId,
                  types,
                  description,
                  screenshot,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(
      String id,
      String title,
      String status,
      String priority,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getStatusColor(status).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(status),
                            size: 14,
                            color: _getStatusColor(status),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(priority).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getPriorityColor(priority).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        priority,
                        style: TextStyle(
                          color: _getPriorityColor(priority),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: const Icon(
                Icons.more_vert,
                color: Colors.white70,
                size: 18,
              ),
            ),
            color: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            onSelected: (v) => _updateStatus(id, v),
            itemBuilder: (context) => [
              _buildPopupMenuItem(
                'New',
                Icons.new_releases_outlined,
                const Color(0xFF3B82F6),
              ),
              _buildPopupMenuItem(
                'In Progress',
                Icons.refresh_rounded,
                const Color(0xFFF59E0B),
              ),
              _buildPopupMenuItem(
                'Fixed',
                Icons.check_circle_outline,
                const Color(0xFF10B981),
              ),
              _buildPopupMenuItem(
                'Rejected',
                Icons.cancel_outlined,
                const Color(0xFFEF4444),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
      String text,
      IconData icon,
      Color color,
      ) {
    return PopupMenuItem(
      value: text,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent(
      String userName,
      String userId,
      List<String> types,
      String description,
      String screenshot,
      ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white70,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (userId.isNotEmpty)
                      Text(
                        'ID: $userId',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (types.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: types.map((t) => _buildTypeChip(t)).toList(),
            ),
          ],
          if (description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ],
          if (screenshot.isNotEmpty) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.image_outlined,
                        color: Colors.orange.shade400,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'View Screenshot',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withOpacity(0.4),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}