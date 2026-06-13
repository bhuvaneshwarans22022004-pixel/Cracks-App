import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController();
  String _paymentMethod = 'COD';

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Shipping Address", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: _addressController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Enter full address",
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 30),
                const Text("Payment Method", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                RadioListTile(
                  title: const Text("Cash on Delivery"),
                  value: 'COD',
                  groupValue: _paymentMethod,
                  onChanged: (val) => setState(() => _paymentMethod = val!),
                  activeColor: const Color(0xFFFF8C00),
                ),
                RadioListTile(
                  title: const Text("Online Payment"),
                  value: 'Online',
                  groupValue: _paymentMethod,
                  onChanged: (val) => setState(() => _paymentMethod = val!),
                  activeColor: const Color(0xFFFF8C00),
                ),
                const SizedBox(height: 30),
                const Text("Order Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Items Total"),
                    Text("₹${cart.totalAmount.toStringAsFixed(2)}"),
                  ],
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Delivery Charges"),
                    Text("₹50.00"),
                  ],
                ),
                const Divider(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Grand Total", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text("₹${(cart.totalAmount + 50).toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                  ],
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Prepare order data
                      final orderData = {
                        'orderItems': cart.items.values.map((item) => {
                          'name': item.product.name,
                          'qty': item.quantity,
                          'image': item.product.image,
                          'price': item.product.price,
                          'product': item.product.id,
                        }).toList(),
                        'shippingAddress': _addressController.text,
                        'paymentMethod': _paymentMethod,
                        'itemsPrice': cart.totalAmount,
                        'shippingPrice': 50.0,
                        'totalPrice': cart.totalAmount + 50.0,
                      };
    
                      final token = auth.user?.token;
                      if (token == null) return;
    
                      final success = await orderProvider.createOrder(orderData, token);
    
                      if (success) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Placed Successfully!")));
                          cart.clear();
                          Navigator.popUntil(context, (route) => route.isFirst);
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to place order")));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00)),
                    child: const Text("Place Order", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
