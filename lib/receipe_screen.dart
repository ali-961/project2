import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecipeScreen extends StatefulWidget {
  final String itemName;
  final String baseUrl;

 
  const RecipeScreen({super.key, required this.itemName, required this.baseUrl});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  List<dynamic> _recipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  
  Future<void> _fetchRecipes() async {
    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/get_recipes.php'),
        headers: {'Content-Type': 'application/json'},
       
        body: json.encode({'item_name': widget.itemName}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _recipes = data['recipes'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
     
      debugPrint("Error fetching recipes: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipes for ${widget.itemName}'),
        backgroundColor: Colors.orangeAccent,
      ),
     
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recipes.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      "No specific recipes found for this ingredient. Try searching for general uses!",
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = _recipes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      elevation: 3,
                      child: ExpansionTile(
                        leading: const Icon(Icons.restaurant, color: Colors.orange),
                        title: Text(
                          recipe['name'] ?? 'Recipe Name',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Prep time: ${recipe['prep_time'] ?? 'N/A'} mins"),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Ingredients:", style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(recipe['ingredients'] ?? 'N/A'),
                                const Divider(),
                                const Text("Instructions:", style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(recipe['instructions'] ?? 'No instructions available.'),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}