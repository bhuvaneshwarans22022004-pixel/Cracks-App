class User {
  final String id;
  final String buyerId;
  final String name;
  final String email;
  final String phone;
  final String role;
  final int loyaltyPoints;
  final String? token;
  final String? profileImage;

  User({
    required this.id,
    required this.buyerId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.loyaltyPoints = 0,
    this.token,
    this.profileImage = '',
  });

  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      buyerId: json['buyerId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'user',
      loyaltyPoints: json['loyaltyPoints'] ?? 0,
      token: token ?? json['token'],
      profileImage: json['profileImage'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'buyerId': buyerId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'loyaltyPoints': loyaltyPoints,
      'token': token,
      'profileImage': profileImage,
    };
  }
}
