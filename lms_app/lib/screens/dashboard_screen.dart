import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  final AuthService authService;

  const DashboardScreen({super.key, required this.authService});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  User? _user;
  bool _isLoading = true;
  int _currentIndex = 0; // For bottom navigation

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final result = await widget.authService.getUserProfile();
      if (result['success']) {
        setState(() {
          _user = widget.authService.currentUser;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading user data: $e')));
    }
  }

  void _logout() async {
    await widget.authService.logout();
    // Navigate back to auth screen
    Navigator.of(context).pushReplacementNamed('/auth');
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;

      // Navigate to different screens based on index
      switch (index) {
        case 0:
          // Home/Dashboard - stay on current screen
          break;
        case 1:
          // Courses
          Navigator.pushNamed(context, '/courses');
          break;
        case 2:
          // Social Feed
          Navigator.pushNamed(
            context,
            '/social-feed',
            arguments: {
              'userId': _user?.id ?? 1,
              'token': widget.authService.token,
            },
          );
          break;
        case 3:
          // Profile
          Navigator.pushNamed(
            context,
            '/profile',
            arguments: {'authService': widget.authService},
          );
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(_user?.firstName ?? 'User'),
              accountEmail: Text(_user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child: Text(
                  _user?.firstName?.isNotEmpty == true
                      ? _user?.firstName?.substring(0, 1).toUpperCase() ?? 'U'
                      : 'U',
                  style: const TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('My Courses'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/courses');
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events),
              title: const Text('Achievements'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/achievements',
                  arguments: {
                    'userId': _user?.id ?? 1,
                    'token': widget.authService.token,
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Admin Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/admin-dashboard',
                  arguments: {
                    'userId': _user?.id ?? 1,
                    'token': widget.authService.token,
                    'authService':
                        widget.authService, // Pass the AuthService instance
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('AI CHAT'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/aichat',
                  arguments: {
                    'userId': _user?.id ?? 1,
                    'token': widget.authService.token,
                  },
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Analytics'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/analytics');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Chat'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/chat',
                  arguments: {
                    'userId': _user?.id ?? 1,
                    'token': widget.authService.token,
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Collaboration'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/collaboration',
                  arguments: {
                    'userId': _user?.id ?? 1,
                    'token': widget.authService.token,
                    'projectId': 1,
                    'projectName': 'Sample Project',
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.leaderboard),
              title: const Text('Leaderboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/leaderboard',
                  arguments: {
                    'userId': _user?.id ?? 1,
                    'token': widget.authService.token,
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Payment'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/payment',
                  arguments: {
                    'userId': _user?.id ?? 1,
                    'token': widget.authService.token,
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/privacy-settings',
                  arguments: {
                    'userId': _user?.id ?? 1,
                    'token': widget.authService.token,
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.track_changes),
              title: const Text('Progress Tracking'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/progress-tracking',
                  arguments: {
                    'userId': _user?.id ?? 1,
                    'token': widget.authService.token,
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.quiz),
              title: const Text('Quiz'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/quiz',
                  arguments: {'quizId': 1, 'token': widget.authService.token},
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.forum),
              title: const Text('Real-time Chat'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/realtime-chat',
                  arguments: {
                    'userId': _user?.id ?? 1,
                    'token': widget.authService.token,
                    'chatRoomId': 1,
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Reports'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/reports',
                  arguments: {
                    'reportType': 'engagement',
                    'token': widget.authService.token,
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts),
              title: const Text('Role Management'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/role-management',
                  arguments: {
                    'userId': _user?.id ?? 1,
                    'token': widget.authService.token,
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Security Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/security-settings',
                  arguments: {
                    'userId': _user?.id ?? 1,
                    'token': widget.authService.token,
                  },
                );
              },
            ),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadUserData,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome message
                        Text(
                          'Welcome back, ${_user?.firstName ?? 'User'}!',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Stats cards
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildStatCard(
                              Icons.school,
                              'Courses',
                              '5 enrolled',
                              Theme.of(context).colorScheme.primary,
                            ),
                            _buildStatCard(
                              Icons.emoji_events,
                              'Achievements',
                              '12 earned',
                              Theme.of(context).colorScheme.secondary,
                            ),
                            _buildStatCard(
                              Icons.leaderboard,
                              'Rank',
                              '#15',
                              Theme.of(context).colorScheme.tertiary,
                            ),
                            _buildStatCard(
                              Icons.calendar_today,
                              'Streak',
                              '7 days',
                              Theme.of(context).colorScheme.error,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Recent activity
                        const Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _ActivityItem(
                                  icon: Icons.school,
                                  title: 'Completed Python Basics Course',
                                  subtitle: 'You scored 95% on the final exam',
                                  time: '2 hours ago',
                                ),
                                const Divider(),
                                _ActivityItem(
                                  icon: Icons.emoji_events,
                                  title: 'New Achievement Unlocked',
                                  subtitle:
                                      'Quiz Master - Scored 100% on 5 quizzes',
                                  time: '1 day ago',
                                ),
                                const Divider(),
                                _ActivityItem(
                                  icon: Icons.leaderboard,
                                  title: 'Rank Improved',
                                  subtitle:
                                      'You moved up to #15 in the leaderboard',
                                  time: '2 days ago',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Courses'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Social'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
