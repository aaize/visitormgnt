import 'package:face_camera/face_camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:visitormgnt/screens/login_screen.dart';
import 'package:visitormgnt/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FaceCamera.initialize(); // Initialize face camera
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  );
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://menujxctgbuhjsiilssd.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1lbnVqeGN0Z2J1aGpzaWlsc3NkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkyMTQ1NjEsImV4cCI6MjA2NDc5MDU2MX0.MyaqrlEqJdwdwJO6PPH9hm3IkkH4BcLEGKvfE70L-OU',
  );

  runApp(const MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Visitor Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0A1A2F),
      ),
      home: const SplashScreen(),
    );
  }
}