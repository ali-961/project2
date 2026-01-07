import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart';
import 'item.dart';
import 'receipe_screen.dart';

class DashboardScreen extends StatefulWidget {
  final int userId;
  const DashboardScreen({super.key, required this.userId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Item> _items = [];
  List<Item> _filteredItems = [];
  
  final String _baseUrl = "http://hassankhalifeh.atwebpages.com"; 
  bool _isLoading = false;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  
  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
       Uri.parse('$_baseUrl/get_items.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': widget.userId}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        if (decodedData['success'] == true) {
          final List<dynamic> fetchedItems = decodedData['items']; 
          setState(() {
            _items = fetchedItems.map((j) => Item.fromJson(j)).toList();
            _filterItems(); 
          });
        }
      }
    } catch (e) {

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fetch Error: $e')));

    } finally {
       setState(() => _isLoading = false);
    }
  }

  
  Future<void> _deleteItem(int itemId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/delete_item.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': itemId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Item removed from fridge')),
            );
          }
          _loadItems();
        }

    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  
  void _confirmDelete(Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('Are you sure you want to remove ${item.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteItem(item.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _filterItems() {
    setState(() {
      if (_selectedFilter == 'All') {
        _filteredItems = _items;
      } else {
        _filteredItems = _items.where((item) => 
          item.status.toLowerCase() == _selectedFilter.toLowerCase()
        ).toList();
      }
    });
  }

  Color _getColor(String status) {
    switch (status.toLowerCase()) {
      case 'expired': return Colors.red[100]!;
      case 'warning': return Colors.orange[100]!;
      default: return Colors.green[100]!;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'dairy': return Icons.egg;
      case 'meat': return Icons.food_bank;
      case 'vegetable': case 'fruit': return Icons.eco;
      case 'beverage': return Icons.local_drink;
      default: return Icons.kitchen;
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));

  }

  void _showAddDialog(BuildContext context) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    String selectedCategory = 'Dairy';
    final List<String> categories = ['Dairy', 'Meat', 'Vegetable', 'Fruit', 'Beverage', 'Other'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Item Name', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    TextField(controller: quantityController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setDialogState(() => selectedCategory = v!),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 730)));
                        if (picked != null) setDialogState(() => selectedDate = picked);
                      },
                      child: InputDecorator(decoration: const InputDecoration(labelText: 'Expiry Date', border: OutlineInputBorder()), child: Text(DateFormat('yyyy-MM-dd').format(selectedDate))),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      await http.post(Uri.parse('$_baseUrl/add_item.php'), headers: {'Content-Type': 'application/json'},
                        body: json.encode({
                          'user_id': widget.userId,
                          'name': nameController.text,
                          'category': selectedCategory,
                          'quantity': quantityController.text,
                          'expiry_date': DateFormat('yyyy-MM-dd').format(selectedDate),
                          'status': 'Fresh',
                        }),
                      );
                      if (mounted) { Navigator.pop(context); _loadItems(); }
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Fridge'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout)],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: ['All', 'Fresh', 'Warning', 'Expired'].map((filter) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                        _filterItems();
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadItems,
                    child: _filteredItems.isEmpty 
                      ? const Center(child: Text("No items to display"))
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            return Card(
                              color: _getColor(item.status),
                              child: ListTile(
                      
                             onTap: () {
                             if (item.status.toLowerCase() == 'warning') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                 builder: (context) => RecipeScreen(
                                 itemName: item.name, 
                                   baseUrl: _baseUrl,
                                 ),
                                ),
                              );
                           } 
                             else if (item.status.toLowerCase() == 'expired') {
                               ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("This item is expired throw it away."))
                              );
                             }
                              else {
                              ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text("This item is still fresh! No recipe needed yet."))
                             );
                           }
                            },
                                leading: CircleAvatar(child: Icon(_getCategoryIcon(item.category))),
                                title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Expires: ${item.expiryDate}\nQty: ${item.quantity}'),
                                isThreeLine: true,
                                
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () => _confirmDelete(item),
                                ),
                              ),
                            );
                          },
                        
                        ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}