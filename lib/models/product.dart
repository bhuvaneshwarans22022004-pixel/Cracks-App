class Product {
  final String id;
  final String name;
  final String tamilName;
  final String description;
  final double price;
  final String category;
  final String image;
  final int countInStock;
  final double rating;
  final int numReviews;

  Product({
    required this.id,
    required this.name,
    required this.tamilName,
    required this.description,
    required this.price,
    required this.category,
    required this.image,
    required this.countInStock,
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
      category: json['category'],
      image: json['image'],
      countInStock: json['countInStock'],
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
      'category': category,
      'image': image,
      'countInStock': countInStock,
      'rating': rating,
      'numReviews': numReviews,
    };
  }
}
