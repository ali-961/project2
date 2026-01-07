import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  final String _baseUrl = "http://hassankhalifeh.atwebpages.com";
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkStoredLogin();
  }

  void _checkStoredLogin() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    if (userId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen(userId: int.parse(userId))),
      );
    }
  }

  void _showRegisterDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isRegistering = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              TextField(controller: nameController,decoration: const InputDecoration(labelText: 'Name'),),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isRegistering ? null : () async {
                setDialogState(() => isRegistering = true);
                try {
                  final response = await http.post(
                    Uri.parse('$_baseUrl/register.php'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({
                      'name': nameController.text.trim(),
                      'email': emailController.text.trim(),
                      'password': passwordController.text,
                    }),
                  );

                    final data = json.decode(response.body);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
                    if (data['success']) Navigator.pop(context);

                } finally {
                  setDialogState(() => isRegistering = false);
                }
              },
              child: isRegistering ? const CircularProgressIndicator() : const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }


  void _login() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final data = json.decode(response.body);
      if (data['success']) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', data['user_id'].toString());
       Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardScreen(userId: int.parse(data['user_id'].toString()))));
      } else {
        setState(() => _errorMessage = data['message']);
      }
    } catch (e) {
      setState(() => _errorMessage = "Connection error");
    } finally {
       setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(Icons.kitchen, size: 80, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text('FridgePal', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
                  if (_errorMessage.isNotEmpty) Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(onPressed: _isLoading ? null : _login, child: const Text('LOGIN')),
                  ),
                  
                 
                  TextButton(
                    onPressed: _showRegisterDialog, 
                    child: const Text("Don't have an account? Register here"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}