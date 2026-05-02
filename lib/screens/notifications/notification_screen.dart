import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock notifications
    final notifications = [
      {"title": "Order Shipped", "body": "Your order #ORD-7421 has been shipped!", "time": "2 hours ago"},
      {"title": "Diwali Offer", "body": "Get 20% extra discount on gift hampers.", "time": "5 hours ago"},
      {"title": "Welcome", "body": "Welcome to FestiveKart! Start shopping now.", "time": "1 day ago"},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final note = notifications[index];
          return Card(
            color: Colors.white10,
            margin: const EdgeInsets.only(bottom: 15),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFF8C00),
                child: Icon(Icons.notifications, color: Colors.white),
              ),
              title: Text(note['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(note['body']!),
              trailing: Text(note['time']!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ),
          );
        },
      ),
    );
  }
}
