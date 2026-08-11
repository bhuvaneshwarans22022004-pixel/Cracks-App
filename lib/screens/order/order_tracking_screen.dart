import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import 'invoice_screen.dart';
import 'utr_dialog.dart';
import '../../utils/whatsapp_helper.dart';


class OrderTrackingScreen extends StatelessWidget {
  final Order order;

  const OrderTrackingScreen({super.key, required this.order});

  String get displayOrderId {
    if (order.id.length >= 8) {
      return "FK${order.id.substring(order.id.length - 8).toUpperCase()}";
    }
    return "FK${order.id.toUpperCase()}";
  }

  int getActiveStageIndex(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0; // Confirmed
      case 'processing':
        return 1; // Packed
      case 'shipped':
      case 'dispatched':
        return 2; // Dispatched
      case 'out for delivery':
      case 'outfordelivery':
        return 3; // Out for Delivery
      case 'delivered':
        return 4; // Delivered
      default:
        return 1; // Default to Processing/Packed
    }
  }

  String formatStageTime(DateTime base, int index, int activeIndex) {
    if (index > activeIndex) {
      if (index == 4) {
        return "Expected by ${DateFormat('dd MMM yyyy').format(base.add(const Duration(days: 3)))}";
      }
      return "Expected time pending";
    }

    final timeFormat = DateFormat('dd MMM yyyy, hh:mm a');
    switch (index) {
      case 0:
        return timeFormat.format(base);
      case 1:
        return timeFormat.format(base.add(const Duration(hours: 4)));
      case 2:
        return timeFormat.format(base.add(const Duration(days: 1, hours: 2)));
      case 3:
        return timeFormat.format(base.add(const Duration(days: 2, hours: 1)));
      case 4:
        return timeFormat.format(order.createdAt.add(const Duration(days: 3))); // Or actual delivered time if any
      default:
        return timeFormat.format(base);
    }
  }

  Widget _buildTrackingStep({
    required String title,
    required String subtitle,
    required int stepIndex,
    required int activeIndex,
    required bool isLast,
  }) {
    final isCompleted = stepIndex < activeIndex;
    final isCurrent = stepIndex == activeIndex;

    Widget iconWidget;
    if (isCompleted) {
      iconWidget = const Icon(Icons.check_rounded, color: Colors.white, size: 14);
    } else if (isCurrent) {
      iconWidget = const Icon(Icons.watch_later_outlined, color: Color(0xFFFF8C00), size: 14);
    } else {
      iconWidget = Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: BoxShape.circle,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFF4CAF50)
                    : isCurrent
                        ? const Color(0xFFFF8C00).withOpacity(0.08)
                        : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFF4CAF50)
                      : isCurrent
                          ? const Color(0xFFFF8C00)
                          : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Center(child: iconWidget),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: isCompleted ? const Color(0xFF4CAF50) : Colors.grey[200],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: isCurrent || isCompleted ? FontWeight.bold : FontWeight.w500,
                  color: isCompleted || isCurrent ? Colors.black87 : Colors.grey[400],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: isCompleted || isCurrent ? Colors.grey[600] : Colors.grey[400],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  void _showMapModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Color(0xFFFAF8F5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Pull indicator
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Live Order Tracking",
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Map Area
                  Expanded(
                    child: Stack(
                      children: [
                        // Map Background Canvas Grid
                        Container(
                          color: const Color(0xFFEFEFEF),
                          child: GridPaper(
                            color: Colors.white.withOpacity(0.4),
                            interval: 50,
                            divisions: 2,
                            subdivisions: 1,
                            child: Container(),
                          ),
                        ),
                        // Simulated Road Paths
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _MapRoadPainter(),
                          ),
                        ),
                        // FestiveKart Hub Pin
                        Positioned(
                          left: 40,
                          top: 100,
                          child: _buildMapPin(
                            icon: Icons.store_rounded,
                            color: const Color(0xFFFF8C00),
                            label: "FestiveKart Hub",
                          ),
                        ),
                        // Customer Home Pin
                        Positioned(
                          right: 40,
                          bottom: 120,
                          child: _buildMapPin(
                            icon: Icons.home_rounded,
                            color: const Color(0xFF007AFF),
                            label: "Your Address",
                          ),
                        ),
                        // Delivery Vehicle Pin (Scooter)
                        const Positioned(
                          left: 160,
                          top: 180,
                          child: _AnimatedDeliveryMarker(),
                        ),
                      ],
                    ),
                  ),
                  // Delivery Agent Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        )
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFFFF8C00).withOpacity(0.1),
                            child: const Icon(Icons.person, color: Color(0xFFFF8C00), size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Ramesh Kumar",
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Delivery Partner (4.8 ★)",
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.phone_rounded, color: Colors.green),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMapPin({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Text(
            label,
            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 800;
    final activeIndex = getActiveStageIndex(order.status);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8C00),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Order Tracking",
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
            constraints: BoxConstraints(
              maxWidth: isWeb ? 800 : double.infinity,
            ),
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
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order details card header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF8F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[100]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Order ID: $displayOrderId",
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Placed on ${DateFormat('dd MMM yyyy').format(order.createdAt)}",
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (order.transactionId == 'PENDING') ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF44336).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFF44336).withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Color(0xFFF44336), size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Payment Verification Pending",
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: const Color(0xFFF44336),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Please enter the 12-digit UTR/Reference ID to confirm payment.",
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF44336),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => UtrDialog(orderId: order.id),
                                    );
                                  },
                                  child: Text(
                                    "Enter",
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),

                        // Timeline steps
                        _buildTrackingStep(
                          title: "Order Confirmed",
                          subtitle: formatStageTime(order.createdAt, 0, activeIndex),
                          stepIndex: 0,
                          activeIndex: activeIndex,
                          isLast: false,
                        ),
                        _buildTrackingStep(
                          title: "Packed",
                          subtitle: formatStageTime(order.createdAt, 1, activeIndex),
                          stepIndex: 1,
                          activeIndex: activeIndex,
                          isLast: false,
                        ),
                        _buildTrackingStep(
                          title: "Dispatched",
                          subtitle: formatStageTime(order.createdAt, 2, activeIndex),
                          stepIndex: 2,
                          activeIndex: activeIndex,
                          isLast: false,
                        ),
                        _buildTrackingStep(
                          title: "Out for Delivery",
                          subtitle: formatStageTime(order.createdAt, 3, activeIndex),
                          stepIndex: 3,
                          activeIndex: activeIndex,
                          isLast: false,
                        ),
                        _buildTrackingStep(
                          title: "Delivered",
                          subtitle: formatStageTime(order.createdAt, 4, activeIndex),
                          stepIndex: 4,
                          activeIndex: activeIndex,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ),
                // Footer buttons
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // WhatsApp Query Status Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
                          label: Text(
                            "Query Status on WhatsApp 💬",
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            WhatsAppHelper.launchOrderStatusQuery(
                              orderId: displayOrderId,
                              rawId: order.id,
                              currentStatus: order.status,
                              totalAmount: order.totalAmount,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.receipt_long_rounded, color: Color(0xFFFF8C00), size: 18),
                                label: Text(
                                  "View Invoice",
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFF8C00),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFFF8C00), width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => InvoiceScreen(order: order),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.map_rounded, color: Colors.white, size: 18),
                                label: Text(
                                  "Track on Map",
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF8C00),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => _showMapModal(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapRoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roadBorder = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw simulated streets connecting Hub to Home
    final path = Path();
    path.moveTo(60, 130);
    path.lineTo(120, 130);
    path.lineTo(120, 240);
    path.lineTo(260, 240);
    path.lineTo(260, 310);
    path.lineTo(size.width - 60, 310);

    canvas.drawPath(path, roadBorder);
    canvas.drawPath(path, roadPaint);

    // Dotted route path for scooter
    final dotPaint = Paint()
      ..color = const Color(0xFFFF8C00)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final routePath = Path();
    routePath.moveTo(60, 130);
    routePath.lineTo(120, 130);
    routePath.lineTo(120, 240);
    routePath.lineTo(260, 240);

    // Draw simple dashed line
    double dashWidth = 5, dashSpace = 4, distance = 0;
    for (double i = 0; i < 200; i += dashWidth + dashSpace) {
      canvas.drawCircle(Offset(120, 130 + i), 1.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _AnimatedDeliveryMarker extends StatefulWidget {
  const _AnimatedDeliveryMarker();

  @override
  State<_AnimatedDeliveryMarker> createState() => _AnimatedDeliveryMarkerState();
}

class _AnimatedDeliveryMarkerState extends State<_AnimatedDeliveryMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -10 * _controller.value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "On Way",
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 16),
              ),
            ],
          ),
        );
      },
    );
  }
}
