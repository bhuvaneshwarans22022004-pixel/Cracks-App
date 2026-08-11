import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'constants.dart';

class WhatsAppHelper {
  /// Dynamic store phone number configured via Firebase Remote Config
  static String get defaultStorePhone => AppConstants.whatsappNumber;

  /// Cleans and formats phone number for WhatsApp wa.me links
  static String cleanPhoneNumber(String rawPhone) {
    String cleaned = rawPhone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length == 10) {
      cleaned = '91$cleaned';
    }
    return cleaned.isEmpty ? defaultStorePhone : cleaned;
  }

  /// Launch WhatsApp with given phone and message
  static Future<bool> launchWhatsApp({
    String? phone,
    required String message,
  }) async {
    final String targetPhone = cleanPhoneNumber(phone ?? defaultStorePhone);
    final String encodedText = Uri.encodeComponent(message);
    
    // Universal API URL working across all browsers & native apps
    final String webUrlStr = "https://api.whatsapp.com/send?phone=$targetPhone&text=$encodedText";
    final Uri webUri = Uri.parse(webUrlStr);

    try {
      if (kIsWeb) {
        return await launchUrl(webUri, mode: LaunchMode.platformDefault);
      }
      
      bool launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        final Uri waMeUri = Uri.parse("https://wa.me/$targetPhone?text=$encodedText");
        launched = await launchUrl(waMeUri, mode: LaunchMode.platformDefault);
      }
      return launched;
    } catch (e) {
      debugPrint("Error launching WhatsApp URL: $e");
      try {
        return await launchUrl(webUri);
      } catch (_) {
        return false;
      }
    }
  }

  /// 1. General Support / Home Page Chat
  static Future<bool> launchGeneralChat({String? customMessage}) {
    final msg = customMessage ??
        "Hello FestiveKart! 🎆\nI have an enquiry regarding firecrackers / orders.";
    return launchWhatsApp(message: msg);
  }

  /// 2. Order Placed Notification (Customer -> Seller / Share Order)
  static Future<bool> launchOrderPlacedNotice({
    required String orderId,
    String? rawId,
    required String customerName,
    required String phone,
    required double totalAmount,
    required String address,
    required List<dynamic> items,
    String? paymentStatus,
  }) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln("🎉 *NEW ORDER PLACED ON FESTIVEKART* 🎉");
    buffer.writeln("--------------------------------------");
    buffer.writeln("🆔 *Order ID:* #$orderId");
    buffer.writeln("👤 *Customer Name:* $customerName");
    buffer.writeln("📞 *Phone:* $phone");
    buffer.writeln("💰 *Total Amount:* ₹${totalAmount.toStringAsFixed(0)}");
    if (paymentStatus != null && paymentStatus.isNotEmpty) {
      buffer.writeln("💳 *Payment Status:* ${paymentStatus.toUpperCase()}");
    }
    buffer.writeln("📍 *Delivery Address:* $address");
    buffer.writeln();
    buffer.writeln("🛒 *Ordered Items:*");

    for (var item in items) {
      String name = item['name'] ?? item['title'] ?? item['product']?['name'] ?? 'Product';
      int qty = item['quantity'] ?? item['qty'] ?? 1;
      num price = item['price'] ?? item['finalPrice'] ?? 0;
      buffer.writeln(" • $name (x$qty) - ₹${(price * qty).toStringAsFixed(0)}");
    }

    if (rawId != null && rawId.isNotEmpty) {
      buffer.writeln();
      buffer.writeln("📄 *Invoice PDF:* ${AppConstants.baseUrl}/api/orders/$rawId/invoice");
    }

    buffer.writeln();
    buffer.writeln("Please confirm my order and share delivery updates. Thank you! 🎆");

    return launchWhatsApp(message: buffer.toString());
  }

  /// 3. Customer Querying Order Status
  static Future<bool> launchOrderStatusQuery({
    required String orderId,
    String? rawId,
    required String currentStatus,
    double? totalAmount,
  }) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln("Hello FestiveKart! 🎆");
    buffer.writeln("I would like to check the delivery status of my order:");
    buffer.writeln("🆔 *Order ID:* #$orderId");
    buffer.writeln("📌 *Current Status:* ${currentStatus.toUpperCase()}");
    if (totalAmount != null) {
      buffer.writeln("💰 *Total Amount:* ₹${totalAmount.toStringAsFixed(0)}");
    }
    if (rawId != null && rawId.isNotEmpty) {
      buffer.writeln("📄 *Invoice PDF:* ${AppConstants.baseUrl}/api/orders/$rawId/invoice");
    }
    buffer.writeln("Please provide an update on dispatch / tracking. Thanks!");

    return launchWhatsApp(message: buffer.toString());
  }

  /// 4. Admin Sending Order Status Update to Customer (Placed / Shipped / Delivered / Invoice)
  static Future<bool> launchAdminStatusUpdateToCustomer({
    required String customerPhone,
    required String customerName,
    required String orderId,
    String? mongoId,
    required String newStatus,
    String? trackingNumber,
    String? transportName,
  }) {
    final StringBuffer buffer = StringBuffer();
    final String statusUpper = newStatus.trim().toUpperCase();

    if (statusUpper == 'SHIPPED' || statusUpper == 'DISPATCHED') {
      buffer.writeln("🚚 *YOUR ORDER IS SHIPPED / DISPATCHED* 🚚");
      buffer.writeln("--------------------------------------");
      buffer.writeln("Hello $customerName! 👋");
      buffer.writeln("Great news! Your FestiveKart order *#$orderId* has been dispatched.");
      buffer.writeln("📌 *Status:* *SHIPPED 🚚*");
      if (transportName != null && transportName.isNotEmpty) {
        buffer.writeln("🏬 *Supplier / Transport:* $transportName");
      }
      if (trackingNumber != null && trackingNumber.isNotEmpty) {
        buffer.writeln("🔢 *LR / Tracking No:* $trackingNumber");
      }
    } else if (statusUpper == 'DELIVERED') {
      buffer.writeln("✅ *YOUR ORDER HAS BEEN DELIVERED* ✅");
      buffer.writeln("--------------------------------------");
      buffer.writeln("Hello $customerName! 👋");
      buffer.writeln("Your FestiveKart order *#$orderId* has been successfully delivered!");
      buffer.writeln("📌 *Status:* *DELIVERED 🎉*");
      buffer.writeln("We hope you love your firecrackers! Have a bright & joyful celebration.");
    } else {
      buffer.writeln("📌 *ORDER STATUS UPDATE - FESTIVEKART* 📌");
      buffer.writeln("--------------------------------------");
      buffer.writeln("Hello $customerName! 👋");
      buffer.writeln("Your FestiveKart Order *#$orderId* update:");
      buffer.writeln("📌 *Status:* *${statusUpper}*");
      if (transportName != null && transportName.isNotEmpty) {
        buffer.writeln("🏬 *Supplier:* $transportName");
      }
    }

    if (mongoId != null && mongoId.isNotEmpty) {
      buffer.writeln();
      buffer.writeln("📄 *Download Invoice PDF:* ${AppConstants.baseUrl}/api/orders/$mongoId/invoice");
    }

    buffer.writeln();
    buffer.writeln("Customer Support / Helpline: 9385757220");
    buffer.writeln("Thank you for shopping with FestiveKart! 🎆");

    return launchWhatsApp(
      phone: customerPhone,
      message: buffer.toString(),
    );
  }

  /// 5. Bulk Order / Wholesale Enquiry
  static Future<bool> launchBulkOrderEnquiry({
    required String name,
    required String phone,
    required String city,
    String? notes,
    List<dynamic>? items,
    double? totalAmount,
  }) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln("📦 *BULK ORDER ENQUIRY - FESTIVEKART* 📦");
    buffer.writeln("--------------------------------------");
    buffer.writeln("👤 *Name:* $name");
    buffer.writeln("📞 *Phone:* $phone");
    buffer.writeln("📍 *City / District:* $city");
    if (notes != null && notes.isNotEmpty) {
      buffer.writeln("📝 *Notes / Requirements:* $notes");
    }
    if (totalAmount != null && totalAmount > 0) {
      buffer.writeln("💰 *Estimated Total:* ₹${totalAmount.toStringAsFixed(0)}");
    }

    if (items != null && items.isNotEmpty) {
      buffer.writeln();
      buffer.writeln("🛒 *Items Requested for Bulk:*");
      for (var item in items) {
        String itemName = item['name'] ?? item['title'] ?? 'Item';
        int qty = item['quantity'] ?? item['qty'] ?? 1;
        buffer.writeln(" • $itemName (Qty: $qty)");
      }
    }

    buffer.writeln();
    buffer.writeln("Please provide your best wholesale pricing and bulk delivery availability. Thanks!");

    return launchWhatsApp(message: buffer.toString());
  }
}
