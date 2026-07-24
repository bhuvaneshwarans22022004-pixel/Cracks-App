class Order {
  final String id;
  final List<OrderItem> items;
  final double totalAmount;
  final double itemsPrice;
  final double shippingPrice;
  final String status;
  final DateTime createdAt;
  final String shippingAddress;
  final String paymentMethod;
  final bool isPaid;
  final DateTime? paidAt;
  final String? transactionId;
  final String? userPhone;
  final String? userEmail;
  final String? userName;

  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    this.itemsPrice = 0.0,
    this.shippingPrice = 0.0,
    required this.status,
    required this.createdAt,
    required this.shippingAddress,
    required this.paymentMethod,
    this.isPaid = false,
    this.paidAt,
    this.transactionId,
    this.userPhone,
    this.userEmail,
    this.userName,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'],
      items: (json['orderItems'] as List).map((i) => OrderItem.fromJson(i)).toList(),
      totalAmount: json['totalPrice'] != null ? json['totalPrice'].toDouble() : 0.0,
      itemsPrice: json['itemsPrice'] != null ? json['itemsPrice'].toDouble() : 0.0,
      shippingPrice: json['shippingPrice'] != null ? json['shippingPrice'].toDouble() : 0.0,
      status: json['status'] ?? 'Processing',
      createdAt: DateTime.parse(json['createdAt']),
      shippingAddress: json['shippingAddress'] ?? '',
      paymentMethod: json['paymentMethod'] ?? 'COD',
      isPaid: json['isPaid'] ?? false,
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      transactionId: json['paymentResult'] != null ? json['paymentResult']['id'] as String? : null,
      userName: json['user'] != null ? (json['user'] is Map ? json['user']['name'] : null) : null,
      userPhone: json['user'] != null ? (json['user'] is Map ? json['user']['phone'] : null) : null,
      userEmail: json['user'] != null ? (json['user'] is Map ? json['user']['email'] : null) : null,
    );
  }
}

class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final double originalPrice;
  final String image;

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    this.originalPrice = 0.0,
    required this.image,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final double p = json['price'] != null ? json['price'].toDouble() : 0.0;
    final double op = json['originalPrice'] != null ? json['originalPrice'].toDouble() : p;
    return OrderItem(
      productId: json['product'],
      name: json['name'],
      quantity: json['qty'],
      price: p,
      originalPrice: op > 0 ? op : p,
      image: json['image'] ?? '',
    );
  }
}
