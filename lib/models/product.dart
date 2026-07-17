class Product {
  final String id;
  final String name;
  final String tamilName;
  final String description;
  final double price;
  final double originalPrice;
  final String category;
  final String image;
  final int countInStock;
  final int packSize;
  final double rating;
  final int numReviews;

  Product({
    required this.id,
    required this.name,
    required this.tamilName,
    required this.description,
    required this.price,
    this.originalPrice = 0.0,
    required this.category,
    required this.image,
    required this.countInStock,
    this.packSize = 1,
    this.rating = 0,
    this.numReviews = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'],
      name: json['name'],
      tamilName: json['tamilName'] ?? '',
      description: json['description'],
      price: json['price'].toDouble(),
      originalPrice: json['originalPrice']?.toDouble() ?? 0.0,
      category: json['category'],
      image: json['image'],
      countInStock: json['countInStock'],
      packSize: json['packSize'] ?? 1,
      rating: json['rating']?.toDouble() ?? 0.0,
      numReviews: json['numReviews'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'tamilName': tamilName,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'category': category,
      'image': image,
      'countInStock': countInStock,
      'packSize': packSize,
      'rating': rating,
      'numReviews': numReviews,
    };
  }
}
