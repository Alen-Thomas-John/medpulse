import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'selection_page.dart';
import 'admin_page.dart';

class AdminLoginPage extends StatefulWidget {
  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1565C0), Color.fromARGB(255, 252, 166, 45)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Back Button
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => SelectionPage()),
                        );
                      },
                    ),
                  ),
                  // Logo
                  Image.asset('assets/logoname.png', height: 120),
                  const SizedBox(height: 30),

                  // Email Field
                  _buildTextField(emailController, 'Email', Icons.email, false),
                  const SizedBox(height: 16),

                  // Password Field
                  _buildTextField(passwordController, 'Password', Icons.lock, true),
                  const SizedBox(height: 20),

                  // Error Message
                  if (errorMessage.isNotEmpty) _errorMessageWidget(),

                  // Login Button
                  _buildLoginButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // **Reusable Widgets**
  Widget _buildTextField(
      TextEditingController controller, String hintText, IconData icon, bool isPassword) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: Colors.white70),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
        ),
      ),
    );
  }

  Widget _errorMessageWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        errorMessage,
        style: const TextStyle(color: Colors.red, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: () async {
        try {
          // Check if the credentials match the admin credentials
          if (emailController.text.trim() == "alenthomj@gmail.com" && 
              passwordController.text.trim() == "Bennybobby13%") {
            
            // Sign in with Firebase
            String? error = await authService.signIn(
              emailController.text.trim(),
              passwordController.text.trim(),
              'admin', // Verify admin role
            );

            if (error == null) {
              User? user = _auth.currentUser;
              if (user != null) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AdminPage(user: user)),
                );
              }
            } else {
              setState(() {
                errorMessage = error;
              });
            }
          } else {
            setState(() {
              errorMessage = "Invalid admin credentials";
            });
          }
        } catch (e) {
          setState(() {
            errorMessage = "Login failed. Check your credentials.";
          });
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
      ),
      child: const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
    );
  }
} 