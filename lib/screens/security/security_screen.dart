import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:face_camera/face_camera.dart';
import 'package:visitormgnt/screens/security/dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:visitormgnt/screens/login_screen.dart';
import 'package:visitormgnt/screens/security/dashboard.dart';
import 'package:visitormgnt/screens/security/face_camera.dart';
import 'package:visitormgnt/screens/security/detail_screen.dart';

class SecurityScreen extends StatefulWidget {
  final String userId;

  const SecurityScreen({Key? key, required this.userId}) : super(key: key);



  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> with TickerProviderStateMixin {
  File? _profileImage;
  bool _hasCapturedImage = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onPhotoTaken(File? image) {
    if (image != null) {
      setState(() {
        _profileImage = image;
        _hasCapturedImage = true;
      });
    }
  }

  void _retakePhoto() {
    setState(() {
      _profileImage = null;
      _hasCapturedImage = false;
    });
  }

  void _usePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Login successful!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1A2F),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed:() {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) =>
                      LoginScreen(),
                ),
              );
            },

            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
            color: Color(0xFF0A1A2F)  // A professional blue similar to the image
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/amclogo.png', // make sure logo.png exists and is declared in pubspec.yaml
                    height: 140,
                    width: 220,
                  ),
                  SizedBox(height: 30,),
                  // App Logo/Title
                  // Circular Face Capture Area
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _hasCapturedImage && _profileImage != null
                          ? Image.file(
                        _profileImage!,
                        fit: BoxFit.cover,
                        width: 244,
                        height: 250,
                      )
                          : CircularFaceCaptureWidget(
                        onPhotoTaken: _onPhotoTaken,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Instructions Text
                  Text(
                    _hasCapturedImage
                        ? 'Face captured successfully!'
                        : 'Position your face in the circle above',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 50),


                  // Action Buttons (shown only when photo is taken)
                  if (_hasCapturedImage) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: CupertinoIcons.refresh,
                          label: '',
                          onTap: _retakePhoto,
                          isPrimary: false,

                        ),
                        _buildActionButton(
                          icon: CupertinoIcons.checkmark_alt,
                          label: '',
                          onTap: () {
                            if (_profileImage != null) {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => DetailScreen(profileImage: _profileImage!),
                                ),
                              );
                            } else {
                              print('No photo selected');
                            }
                          },
                          isPrimary: true,
                          color: Colors.green,
                        ),


                      ],
                    ),

                  ],
                  const SizedBox(height: 60),
                  _buildUsernameLoginButton(),

                  // Additional Login Options
                  if (!_hasCapturedImage) ...[
                    _buildAlternativeLoginButton(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
    Color? color, // Accept custom color
  }) {
    final backgroundColor = color ?? (isPrimary ? Colors.white : Colors.white.withOpacity(0.2));
    final iconTextColor = color != null
        ? Colors.white
        : (isPrimary ? const Color(0xFF667eea) : Colors.white);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: iconTextColor,
              size: 18,
            ),
            if (label.isNotEmpty) const SizedBox(width: 8),
            if (label.isNotEmpty)
              Text(
                label,
                style: TextStyle(
                  color: iconTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }


  Widget _buildUsernameLoginButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AllVisitorsDashboard(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white, // White background
          borderRadius: BorderRadius.circular(30), // iOS-style pill shape
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text(
          'Dashboard',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF0A1A2F), // Dark iOS background for text
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }



  Widget _buildAlternativeLoginButton() {
    return GestureDetector(
      onTap: () {
        // Alternative login method
        /*Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AMCDetailsScreen()),
        );*/
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),


        child: Text(
          'About Us',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}