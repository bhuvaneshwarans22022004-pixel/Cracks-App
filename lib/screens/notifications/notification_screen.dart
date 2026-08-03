import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/api_service.dart';
import '../../models/order.dart';
import '../order/order_tracking_screen.dart';
import '../home/home_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<UserNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final token = Provider.of<AuthProvider>(context, listen: false).user?.token;
    if (token == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await ApiService.get('notifications/my', token: token);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _notifications = data.map((json) => UserNotification.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching notifications: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleNotificationTap(UserNotification note) async {
    final token = Provider.of<AuthProvider>(context, listen: false).user?.token;
    
    // 1. Delete/read notification on backend
    if (token != null) {
      try {
        await ApiService.put('notifications/${note.id}/read', {}, token: token);
      } catch (e) {
        print("Error marking notification read: $e");
      }
    }

    // Remove from local list instantly
    setState(() {
      _notifications.removeWhere((n) => n.id == note.id);
    });

    // 2. Fetch/match corresponding order for routing
    if (note.orderId.isNotEmpty && mounted) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      
      // Ensure orders list is fresh
      if (token != null) {
        await orderProvider.fetchOrders(token);
      }

      Order? foundOrder;
      for (final o in orderProvider.orders) {
        if (o.id == note.orderId) {
          foundOrder = o;
          break;
        }
      }

      if (mounted) {
        if (foundOrder != null) {
          // Route directly to tracking page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderTrackingScreen(order: foundOrder!),
            ),
          );
        } else {
          // Fallback to Order History tab
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => HomeScreen(initialIndex: 2),
            ),
            (route) => false,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5), // Soft cream
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8C00),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notifications",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: isWeb ? 800 : double.infinity),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: isWeb
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : null,
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8C00)))
                : _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_rounded, size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              "No notifications found",
                              style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final note = _notifications[index];
                          final formattedTime = DateFormat('dd MMM, hh:mm a').format(note.createdAt);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[100]!),
                            ),
                            child: ListTile(
                              onTap: () => _handleNotificationTap(note),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFFF8C00).withOpacity(0.08),
                                child: const Icon(Icons.shopping_bag_rounded, color: Color(0xFFFF8C00), size: 20),
                              ),
                              title: Text(
                                "Order Update",
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    note.details,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    formattedTime,
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                            ),
                          );
                        },
                      ),
          ),
        ),
      ),
    );
  }
}

class UserNotification {
  final String id;
  final String type;
  final String orderId;
  final String details;
  final DateTime createdAt;

  UserNotification({
    required this.id,
    required this.type,
    required this.orderId,
    required this.details,
    required this.createdAt,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: json['_id'],
      type: json['type'] ?? 'order_status',
      orderId: json['orderId'] ?? '',
      details: json['details'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
