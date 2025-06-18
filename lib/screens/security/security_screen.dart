import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:face_camera/face_camera.dart';
import 'package:visitormgnt/screens/security/dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:visitormgnt/screens/login_screen.dart';
import 'package:visitormgnt/screens/security/detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'face_camera.dart';

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
  bool _showRedDot = false;
  DateTime? _lastNotificationCheckTime;

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
    _loadNotificationState();
  }

  Future<void> _loadNotificationState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showRedDot = prefs.getBool('showRedDot') ?? false;
    });
  }

  Future<void> _saveNotificationState(bool state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showRedDot', state);
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
        ));
    }

  void _showNotifications() async {
    // Mark notifications as seen (remove red dot)
    setState(() {
      _showRedDot = false;
    });
    await _saveNotificationState(false);

    // Track when we last checked notifications
    _lastNotificationCheckTime = DateTime.now();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1A2F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Notifications',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _clearAllNotifications(),
                      child: const Text(
                        'Clear All',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .orderBy('timestamp', descending: true)
                    .limit(5) // Always show latest 5
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No notifications yet.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return Dismissible(
                        key: Key(doc.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        onDismissed: (direction) {
                          _deleteNotification(doc.id);
                        },
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context); // Close the modal first
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AllVisitorsDashboard()),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${data['visitor_name'] ?? 'Unknown'} - ${data['action'] ?? 'Unknown Action'}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Phone: ${data['details']?['phone'] ?? data['phone_number'] ?? 'Not provided'}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Time: ${(data['timestamp'] as Timestamp?)?.toDate().toLocal().toString().split('.')[0] ?? 'Unknown'}',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
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
    );
  }

  void _deleteNotification(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(docId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  void _clearAllNotifications() async {
    try {
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .get();

      for (var doc in notifications.docs) {
        await doc.reference.delete();
      }

      Navigator.pop(context); // Close the modal after clearing
    } catch (e) {
      print('Error clearing notifications: $e');
    }
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
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (context) => LoginScreen()),
              );
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFF0A1A2F)),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    Image.asset(
                      'assets/amclogo.png',
                      height: 140,
                      width: 220,
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1),
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
                            ? Image.file(_profileImage!, fit: BoxFit.cover)
                            : CircularFaceCaptureWidget(onPhotoTaken: _onPhotoTaken),
                      ),
                    ),
                    const SizedBox(height: 30),
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
                    const SizedBox(height: 40),
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
                                    builder: (context) =>
                                        DetailScreen(profileImage: _profileImage!),
                                  ),
                                );
                              }
                            },
                            isPrimary: true,
                            color: Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],

                    const SizedBox(height: 30),
                    // Dashboard button with notification icon
                    Row(
                      children: [
                        Expanded(
                          child: _buildUsernameLoginButton(),
                        ),
                        const SizedBox(width: 15),
                        _buildNotificationIcon(),

                      ],

                    ),

                    _buildAlternativeLoginButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(1) // We only need to check if there are any new notifications
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final latestNotification = snapshot.data!.docs.first;
          final timestamp = (latestNotification.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;

          // If we have a new notification that arrived after the last check
          if (timestamp != null &&
              (_lastNotificationCheckTime == null ||
                  timestamp.toDate().isAfter(_lastNotificationCheckTime!))) {
            // Only update state if needed
            if (!_showRedDot) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _showRedDot = true;
                });
                _saveNotificationState(true);
              });
            }
          }
        }

        return GestureDetector(
          onTap: _showNotifications,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.notifications,
                    color: Color(0xFF0A1A2F),
                    size: 28,
                  ),
                ),
                if (_showRedDot)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },


    );

  }


  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
    Color? color,
  }) {
    final backgroundColor =
        color ?? (isPrimary ? Colors.white : Colors.white.withOpacity(0.2));
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
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
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
            Icon(icon, color: iconTextColor, size: 18),
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
          MaterialPageRoute(builder: (context) => const AllVisitorsDashboard()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
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
            color: Color(0xFF0A1A2F),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAlternativeLoginButton() {
    return Container(
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
    );
  }


}