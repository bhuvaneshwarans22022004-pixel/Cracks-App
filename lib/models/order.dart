class Order {
  final String id;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final String shippingAddress;
  final String paymentMethod;

  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.shippingAddress,
    required this.paymentMethod,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'],
      items: (json['orderItems'] as List).map((i) => OrderItem.fromJson(i)).toList(),
      totalAmount: json['totalPrice'].toDouble(),
      status: json['status'] ?? 'Processing',
      createdAt: DateTime.parse(json['createdAt']),
      shippingAddress: json['shippingAddress'] ?? '',
      paymentMethod: json['paymentMethod'] ?? 'COD',
    );
  }
}

class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final String image;

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.image,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product'],
      name: json['name'],
      quantity: json['qty'],
      price: json['price'].toDouble(),
      image: json['image'],
    );
  }
}
