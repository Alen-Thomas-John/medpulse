import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'selection_page.dart';
import 'admin_requests_page.dart';

class AdminPage extends StatefulWidget {
  final User user;

  const AdminPage({Key? key, required this.user}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String _errorMessage = "";

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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Top Navigation Bar with Back Button and Requests Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => SelectionPage()),
                        );
                      },
                    ),
                    // Requests Button
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to the requests page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminRequestsPage(user: widget.user),
                          ),
                        );
                      },
                      icon: const Icon(Icons.notifications, color: Colors.white),
                      label: const Text("Requests", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                const Text(
                  "Admin Dashboard",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Error Message
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),

                // User Management Section
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('user_roles').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      }

                      var users = snapshot.data!.docs;
                      
                      // Filter out the admin user
                      var filteredUsers = users.where((doc) {
                        String email = doc.id;
                        return email != "alenthomj@gmail.com";
                      }).toList();

                      if (filteredUsers.isEmpty) {
                        return const Center(
                          child: Text(
                            'No users found.',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          var userData = filteredUsers[index].data() as Map<String, dynamic>;
                          String email = filteredUsers[index].id;
                          String role = userData['role'] ?? 'No role';
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 3,
                            child: ListTile(
                              title: Text(
                                email,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text("Role: $role"),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteUser(email),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                
                // Logout Button
                ElevatedButton(
                  onPressed: () async {
                    await _auth.signOut();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => SelectionPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue.shade900,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                  ),
                  child: const Text('Logout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteUser(String email) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = "";
      });
      
      // Show confirmation dialog
      bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Confirm Deletion"),
          content: Text("Are you sure you want to delete user $email?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ) ?? false;
      
      if (!confirm) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Delete from user_roles collection
      await _firestore.collection('user_roles').doc(email).delete();
      
      // Delete from users collection if it exists
      try {
        await _firestore.collection('users').doc(email).delete();
      } catch (e) {
        print("Error deleting from users collection: $e");
      }
      
      // Delete from Firebase Authentication
      try {
        // Get the user by email
        final userRecord = await _auth.fetchSignInMethodsForEmail(email);
        if (userRecord.isNotEmpty) {
          // We need to use Admin SDK to delete users, which isn't available in client-side code
          // This is a limitation of Firebase Auth in client-side applications
          // The user will need to be deleted from the Firebase Console or using a backend service
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("User deleted from Firestore. Note: User authentication record can only be deleted from Firebase Console."),
              duration: Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        print("Error deleting from Firebase Auth: $e");
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User deleted successfully")),
      );
    } catch (e) {
      setState(() {
        _errorMessage = "Error deleting user: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
} 