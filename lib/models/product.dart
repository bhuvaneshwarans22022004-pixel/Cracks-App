class ComboItem {
  final String name;
  final int quantity;
  final double price;
  final double originalPrice;

  ComboItem({
    required this.name,
    this.quantity = 1,
    this.price = 0.0,
    this.originalPrice = 0.0,
  });

  factory ComboItem.fromJson(Map<String, dynamic> json) {
    return ComboItem(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: json['price'] != null ? json['price'].toDouble() : 0.0,
      originalPrice: json['originalPrice'] != null ? json['originalPrice'].toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'originalPrice': originalPrice,
    };
  }
}

class Product {
  final String id;
  final String name;
  final String tamilName;
  final String description;
  final double price;
  final double originalPrice;
  final String category;
  final String image;
  final List<String> images;
  final int countInStock;
  final int packSize;
  final double rating;
  final int numReviews;

  // Combo fields
  final bool isCombo;
  final double comboDiscountPercent;
  final List<ComboItem> comboItems;

  Product({
    required this.id,
    required this.name,
    required this.tamilName,
    required this.description,
    required this.price,
    this.originalPrice = 0.0,
    required this.category,
    required this.image,
    this.images = const [],
    required this.countInStock,
    this.packSize = 1,
    this.rating = 0,
    this.numReviews = 0,
    this.isCombo = false,
    this.comboDiscountPercent = 0.0,
    this.comboItems = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    List<String> parsedImages = [];
    if (json['images'] != null && json['images'] is List) {
      parsedImages = (json['images'] as List).map((e) => e.toString()).toList();
    }
    if (parsedImages.isEmpty && json['image'] != null) {
      parsedImages.add(json['image'].toString());
    }

    List<ComboItem> parsedCombo = [];
    if (json['comboItems'] != null && json['comboItems'] is List) {
      parsedCombo = (json['comboItems'] as List).map((i) => ComboItem.fromJson(i)).toList();
    }

    return Product(
      id: json['_id'],
      name: json['name'],
      tamilName: json['tamilName'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] != null ? json['price'].toDouble() : 0.0,
      originalPrice: json['originalPrice']?.toDouble() ?? 0.0,
      category: json['category'] ?? '',
      image: json['image'] ?? '',
      images: parsedImages,
      countInStock: json['countInStock'] ?? 0,
      packSize: json['packSize'] ?? 1,
      rating: json['rating']?.toDouble() ?? 0.0,
      numReviews: json['numReviews'] ?? 0,
      isCombo: json['isCombo'] ?? (json['category'] == 'Combo Products' || json['category'] == 'Combo'),
      comboDiscountPercent: json['comboDiscountPercent']?.toDouble() ?? 0.0,
      comboItems: parsedCombo,
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
      'images': images,
      'countInStock': countInStock,
      'packSize': packSize,
      'rating': rating,
      'numReviews': numReviews,
      'isCombo': isCombo,
      'comboDiscountPercent': comboDiscountPercent,
      'comboItems': comboItems.map((e) => e.toJson()).toList(),
    };
  }

  double get displayRating {
    if (rating > 0.0) return rating;
    final int seed = (id.hashCode.abs()) + (name.hashCode.abs());
    final int baseRating = 5;
    final int count = 3 + (seed % 3);
    
    double sum = 0.0;
    for (int i = 0; i < count; i++) {
      int r = baseRating;
      if (i % 3 == 1 && r > 1) r -= 1;
      if (i % 5 == 0 && r < 5) r += 1;
      r = r.clamp(1, 5);
      sum += r;
    }
    return double.parse((sum / count).toStringAsFixed(1));
  }

  int get displayNumReviews {
    if (numReviews > 0) return numReviews;
    final int seed = (id.hashCode.abs()) + (name.hashCode.abs());
    final int count = 3 + (seed % 3);
    return count * 5;
  }
}
