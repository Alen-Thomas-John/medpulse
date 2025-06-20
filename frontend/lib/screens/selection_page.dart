import 'package:flutter/material.dart';
import 'data_entry_login.dart'; // Import Data Entry Login Page
import 'doctor_login.dart'; // Import Doctor Login Page
import 'admin_login.dart'; // Import Admin Login Page

class SelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1565C0), Color.fromARGB(255, 252, 166, 45)], // Deep Blue Theme
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Image
              Image.asset(
                'assets/logoname.png',
                height: 120,
              ),
              const SizedBox(height: 40),

              // "Data Entry" Button
              _buildButton(
                text: "Data Entry",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DataEntryLoginPage()),
                  );
                },
              ),

              const SizedBox(height: 20),

              // "Doctor" Button
              _buildButton(
                text: "Doctor",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DoctorLoginPage()),
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              // "Admin" Button
              _buildButton(
                text: "Admin",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdminLoginPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // **Reusable Button Widget**
  Widget _buildButton({required String text, required VoidCallback onPressed}) {
    return SizedBox(
      width: 220,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue.shade900,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          elevation: 5,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
