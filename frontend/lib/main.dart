import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Corrected Import
import 'screens/splash_screen.dart'; // Ensure this file exists
import 'screens/selection_page.dart'; // Include for navigation
import 'package:firebase_storage/firebase_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Required for Web
  );
  print("Storage Bucket: ${FirebaseStorage.instance.bucket}");
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      initialRoute: '/',  // Set initial screen
      routes: {
        '/': (context) => SplashScreen(),
        '/selection': (context) => SelectionPage(), // Ensure SelectionPage exists
      },
    );
  }
}
