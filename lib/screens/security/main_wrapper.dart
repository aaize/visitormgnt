// lib/screens/security/main_wrapper.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visitormgnt/screens/security/dashboard.dart';
import 'package:visitormgnt/screens/security/security_screen.dart';
import 'package:visitormgnt/screens/security/navbar.dart';

import '../login_screen.dart';

class MainWrapper extends StatefulWidget {
  final String userId;

  const MainWrapper({super.key, required this.userId});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _notificationCount = 0; // Changed from bool to int
  DateTime? _lastNotificationCheckTime;

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _loadNotificationState();
    _listenForNewNotifications();
  }

  Future<void> _loadNotificationState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationCount = prefs.getInt('notificationCount') ?? 0;
    });
  }

  void _onNavTapped(int index) {
    if (index == 0 || index == 1) {
      setState(() {
        _currentIndex = index;
      });
    } else if (index == 2) {
      _showNotifications();
    } else if (index == 3) {
      _showProfileOptions();
    }
  }

  void _onNotificationStateChanged() {
    setState(() => _notificationCount = 0);
    _saveNotificationState(0);
  }

  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1A2F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Profile Options',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text('Settings', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // Add navigation to settings screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.help, color: Colors.white),
              title: const Text('Help & Support', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // Add navigation to help screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.white),
              title: const Text('About', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // Add navigation to about screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveNotificationState(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notificationCount', count);
  }

  void _listenForNewNotifications() {
    // Listen to visitors-met collection
    FirebaseFirestore.instance
        .collection('visitors-met')
        .orderBy('met_at', descending: true)
        .snapshots()
        .listen((snapshot) {
      _checkForRecentChanges(snapshot.docs, 'met_at');
    });

    // Listen to visitors-cancelled collection
    FirebaseFirestore.instance
        .collection('visitors-cancelled')
        .orderBy('cancelled_at', descending: true)
        .snapshots()
        .listen((snapshot) {
      _checkForRecentChanges(snapshot.docs, 'cancelled_at');
    });
  }

  void _checkForRecentChanges(List<dynamic> docs, String timeField) {
    final now = DateTime.now();
    int recentChangesCount = 0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final timestampStr = data[timeField] as String?;
      final time = DateTime.tryParse(timestampStr ?? '');

      // Check if the change happened after the last notification check
      if (time != null) {
        if (_lastNotificationCheckTime == null) {
          // If no previous check time, consider changes in the last minute
          if (now.difference(time).inMinutes < 1) {
            recentChangesCount++;
          }
        } else {
          // Check changes after the last notification check
          if (time.isAfter(_lastNotificationCheckTime!)) {
            recentChangesCount++;
          }
        }
      }
    }

    // Update notification count if there are new changes
    if (recentChangesCount > 0) {
      setState(() {
        _notificationCount += recentChangesCount;
      });
      _saveNotificationState(_notificationCount);
    }
  }

  void _showNotifications() async {
    // Mark notifications as seen (reset count to 0)
    setState(() {
      _notificationCount = 0;
    });
    await _saveNotificationState(0);

    // Track when we last checked notifications
    _lastNotificationCheckTime = DateTime.now();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1A2F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DefaultTabController(
        length: 2,
        child: Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Visitor Summary',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tab Bar with custom styling
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.2),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Visited'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Cancelled'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tab Views
              Expanded(
                child: TabBarView(
                  children: [
                    // Visited Tab
                    _buildVisitorTab(isVisitedTab: true),
                    // Cancelled Tab
                    _buildVisitorTab(isVisitedTab: false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisitorTab({required bool isVisitedTab}) {
    final now = DateTime.now();
    final hiddenIds = <String>{}; // Local state to keep track of dismissed cards

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(isVisitedTab ? 'visitors-met' : 'visitors-cancelled')
          .orderBy(isVisitedTab ? 'met_at' : 'cancelled_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(isVisitedTab);
        }

        final recentDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final timestampStr = data[isVisitedTab ? 'met_at' : 'cancelled_at'] as String?;
          final time = DateTime.tryParse(timestampStr ?? '');
          return time != null &&
              now.difference(time).inMinutes < 1 &&
              !hiddenIds.contains(doc.id);
        }).toList();

        if (recentDocs.isEmpty) return _buildEmptyState(isVisitedTab);

        return Column(
          children: [
            _buildSummaryCard(recentDocs.length, isVisitedTab),
            Expanded(
              child: ListView.builder(
                itemCount: recentDocs.length,
                itemBuilder: (context, index) {
                  final doc = recentDocs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  final name = data['name'] ?? 'Unknown';
                  final phone = data['phone'] ?? 'Not provided';
                  final department = data['department'] ?? 'N/A';
                  final visitedTo = data['visited_to_display'] ?? 'Faculty';
                  final timeStr = data[isVisitedTab ? 'met_at' : 'cancelled_at'] ?? '';
                  final time = timeStr.toString().split('T').join(' ').split('.').first;

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
                      child: const Icon(Icons.visibility_off, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      hiddenIds.add(doc.id);
                      (context as Element).markNeedsBuild(); // Trigger rebuild
                    },
                    child: _buildVisitorCard(name, phone, department, visitedTo, time, isVisitedTab),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(bool isVisitedTab) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isVisitedTab ? Icons.people_outline : Icons.cancel_outlined,
            color: Colors.white30,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            isVisitedTab ? 'No recent visitors' : 'No cancelled visits',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int count, bool isVisitedTab) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isVisitedTab
              ? [Colors.green.withOpacity(0.3), Colors.green.withOpacity(0.1)]
              : [Colors.red.withOpacity(0.3), Colors.red.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVisitedTab ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isVisitedTab ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isVisitedTab ? Icons.people : Icons.cancel,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count ${isVisitedTab ? 'Visitors Met' : 'Visits Cancelled'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isVisitedTab
                      ? 'Successfully completed visits'
                      : 'Cancelled or rejected visits',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitorCard(String name, String phone, String department, String visitedTo, String time, bool isVisitedTab) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isVisitedTab ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: isVisitedTab ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward, size: 16, color: Colors.white70),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        visitedTo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Dept: $department', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text('Phone: $phone', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                Text('Time: $time', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            isVisitedTab ? Icons.check_circle : Icons.cancel,
            color: isVisitedTab ? Colors.green : Colors.red,
            size: 20,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      SecurityScreen(userId: widget.userId),
      const AllVisitorsDashboard(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0A1A2F),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: screens[_currentIndex],
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onNavTapped,
        notificationCount: _notificationCount, // Pass the count instead of boolean
        onNotificationStateChanged: _onNotificationStateChanged,
      ),
    );
  }
}