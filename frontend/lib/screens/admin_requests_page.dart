import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_page.dart';

class AdminRequestsPage extends StatefulWidget {
  final User user;

  const AdminRequestsPage({Key? key, required this.user}) : super(key: key);

  @override
  _AdminRequestsPageState createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<AdminRequestsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
                // Top Navigation Bar with Back Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    // Title
                    const Text(
                      "Signup Requests",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Empty space for alignment
                    const SizedBox(width: 40),
                  ],
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

                // Requests List
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('requests').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      }

                      var requests = snapshot.data!.docs;
                      
                      // Filter to only show pending requests
                      var pendingRequests = requests.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        return data['status'] == 'pending';
                      }).toList();

                      if (pendingRequests.isEmpty) {
                        return const Center(
                          child: Text(
                            'No pending requests.',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: pendingRequests.length,
                        itemBuilder: (context, index) {
                          var requestData = pendingRequests[index].data() as Map<String, dynamic>;
                          String email = pendingRequests[index].id;
                          String role = requestData['role'] ?? 'No role';
                          Timestamp timestamp = requestData['timestamp'] as Timestamp? ?? Timestamp.now();
                          DateTime requestDate = timestamp.toDate();
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              email,
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Role: $role",
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Requested on: ${requestDate.toString().split('.')[0]}",
                                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          // Approve Button
                                          IconButton(
                                            icon: const Icon(Icons.check_circle, color: Colors.green),
                                            onPressed: () => _handleRequest(email, role, 'approved'),
                                          ),
                                          // Reject Button
                                          IconButton(
                                            icon: const Icon(Icons.cancel, color: Colors.red),
                                            onPressed: () => _handleRequest(email, role, 'rejected'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRequest(String email, String role, String status) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = "";
      });
      
      // Show confirmation dialog
      bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Confirm ${status == 'approved' ? 'Approval' : 'Rejection'}"),
          content: Text("Are you sure you want to ${status == 'approved' ? 'approve' : 'reject'} the request for $email?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                status == 'approved' ? "Approve" : "Reject", 
                style: TextStyle(color: status == 'approved' ? Colors.green : Colors.red),
              ),
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
      
      // Update the request status
      await _firestore.collection('requests').doc(email).update({
        'status': status,
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': widget.user.email,
      });
      
      // If approved, create the user account
      if (status == 'approved') {
        // Get the request data
        final requestDoc = await _firestore.collection('requests').doc(email).get();
        final requestData = requestDoc.data();
        
        if (requestData != null) {
          final String password = requestData['password'];
          
          // Create the user account
          final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          
          // Save role to Firestore
          await _firestore.collection('user_roles').doc(email).set({
            'role': role,
            'uid': userCredential.user?.uid,
          });
          
          // Save user info to users collection
          await _firestore.collection('users').doc(email).set({
            'email': email,
            'role': role,
            'uid': userCredential.user?.uid,
          });
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Request ${status == 'approved' ? 'approved' : 'rejected'} successfully")),
      );
    } catch (e) {
      setState(() {
        _errorMessage = "Error processing request: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
} 