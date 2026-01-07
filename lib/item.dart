class Item {
  final int id;
  final String name;
  final String category;
  final int quantity;
  final String expiryDate;
  final String status;

  Item({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.expiryDate,
    required this.status,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      quantity: int.parse(json['quantity'].toString()),
      expiryDate: json['expiry_date'] ?? '',
      status: json['status'] ?? 'fresh',
    );
  }
}