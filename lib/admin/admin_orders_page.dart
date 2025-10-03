import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'admin_drawer.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage>
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

  Future<void> _updateStatus(String orderId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update({'status': newStatus});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $newStatus')),
      );
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
          "📦  All Orders",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
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
                colors: [
                  Colors.black,
                  Colors.black,
                  Colors.black,
                  Colors.black,
                ],
                stops: [0.1, 0.7, 0.2, 0.2],
              ),
            ),
          ),
          // Dim overlay when drawer is open
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final value = _controller.value;
              return IgnorePointer(
                ignoring: value == 0,
                child: Opacity(
                  opacity: 0.35 * value,
                  child: Container(color: Colors.black),
                ),
              );
            },
          ),
          Positioned.fill(
            child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'No orders found',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>? ?? {};
                final orderId = doc.id;
                final name = data['name'] ?? '';
                final total = (data['total'] ?? 0).toDouble();
                    final status = (data['status'] ?? 'Pending') as String;
                final ts = data['timestamp'];
                DateTime? dateTime;
                if (ts is Timestamp) dateTime = ts.toDate();
                final dateStr = dateTime != null
                    ? DateFormat('dd MMM yyyy, hh:mm a').format(dateTime)
                    : '';

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
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Row(
                                children: [
                                  const Text(
                                    'Order Id  ',
                                    style: TextStyle(
                                      color: Colors.orangeAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      orderId,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Name: $name',
                                          style: const TextStyle(color: Colors.white70),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(colors: [Colors.orange, Colors.red]),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          status,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Total: ${total.toInt()}',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                  Text(
                                    'Placed: $dateStr',
                                    style: const TextStyle(color: Colors.white54),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: Colors.white70),
                                color: Colors.black,
                                onSelected: (value) => _updateStatus(orderId, value),
                                itemBuilder: (context) => const [
                                  PopupMenuItem(value: 'Pending', child: Text('Pending', style: TextStyle(color: Colors.white))),
                                  PopupMenuItem(value: 'Processing', child: Text('Processing', style: TextStyle(color: Colors.white))),
                                  PopupMenuItem(value: 'Delivered', child: Text('Delivered', style: TextStyle(color: Colors.white))),
                                  PopupMenuItem(value: 'Cancelled', child: Text('Cancelled', style: TextStyle(color: Colors.white))),
                                ],
                              ),
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => _OrderDetailsSheet(
                                    orderId: orderId,
                                    data: data,
                                    onChangeStatus: (s) => _updateStatus(orderId, s),
                                  ),
                                );
                              },
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

class _OrderDetailsSheet extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;
  final void Function(String newStatus)? onChangeStatus;

  const _OrderDetailsSheet({required this.orderId, required this.data, this.onChangeStatus});

  @override
  Widget build(BuildContext context) {
    final cartItems = List<Map<String, dynamic>>.from(data['cartItems'] ?? []);
    final name = data['name'] ?? '';
    final address = data['address'] ?? '';
    final payment = data['paymentMethod'] ?? '';
    final deliveryCharges = (data['deliveryCharges'] ?? 0).toDouble();
    final itemsTotal = (data['itemsTotal'] ?? 0).toDouble();
    final total = (data['total'] ?? 0).toDouble();
    final currentStatus = (data['status'] ?? 'Pending') as String;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.06),
                Colors.white.withOpacity(0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.18)),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grab handle
                Center(
                  child: Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Header with icon and ID
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.08),
                        Colors.white.withOpacity(0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.orange,
                        child: Icon(Icons.receipt_long, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Order Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: Text(
                          orderId,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Status row
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white.withOpacity(0.04),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      const Text('Status', style: TextStyle(color: Colors.white70)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Colors.orange, Colors.red]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(currentStatus, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.edit, color: Colors.white70),
                        color: Colors.black,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white.withOpacity(0.12), width: 1),
                        ),
                        onSelected: (value) => onChangeStatus?.call(value),
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'Pending', child: Text('Pending', style: TextStyle(color: Colors.white))),
                          PopupMenuItem(value: 'Processing', child: Text('Processing', style: TextStyle(color: Colors.white))),
                          PopupMenuItem(value: 'Delivered', child: Text('Delivered', style: TextStyle(color: Colors.white))),
                          PopupMenuItem(value: 'Cancelled', child: Text('Cancelled', style: TextStyle(color: Colors.white))),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Name + Payment (left) & Address (right)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white.withOpacity(0.04),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.person_outline, color: Colors.white70, size: 18),
                                SizedBox(width: 6),
                                Text('Name', style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            const Row(
                              children: [
                                Icon(Icons.payment, color: Colors.white70, size: 18),
                                SizedBox(width: 6),
                                Text('Payment', style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(payment, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white.withOpacity(0.04),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.location_on_outlined, color: Colors.white70, size: 18),
                                SizedBox(width: 6),
                                Text('Address', style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('$address', style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Items section
                const Text('Items', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...cartItems.map((item) {
                  final title = item['title'] ?? '';
                  final qty = item['quantity'] ?? 0;
                  final weight = item['selectedWeight'] ?? '';
                  final price = (item['unitPrice'] ?? 0).toDouble();
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withOpacity(0.035),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text('x$qty', style: const TextStyle(color: Colors.white70)),
                        const SizedBox(width: 8),
                        Text('$weight', style: const TextStyle(color: Colors.white54)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(price.toInt().toString(), style: const TextStyle(color: Colors.white70)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const Divider(color: Colors.white24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Items Total', style: TextStyle(color: Colors.white70)),
                    Text(itemsTotal.toInt().toString(), style: const TextStyle(color: Colors.white)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Delivery', style: TextStyle(color: Colors.white70)),
                    Text(deliveryCharges.toInt().toString(), style: const TextStyle(color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Grand Total', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                    Text(total.toInt().toString(), style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


