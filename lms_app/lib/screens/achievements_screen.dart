import 'package:flutter/material.dart';
import '../models/social.dart';
import '../services/social_service.dart';

class AchievementsScreen extends StatefulWidget {
  final int userId;
  final String? token;

  const AchievementsScreen({super.key, required this.userId, this.token});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late SocialService _socialService;
  List<Achievement> _achievements = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _socialService = SocialService(token: widget.token);
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    try {
      final achievements = await _socialService.getAchievements(widget.userId);
      setState(() {
        _achievements = achievements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load achievements: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_errorMessage),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadAchievements,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadAchievements,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Achievement stats
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _AchievementStat(
                                  icon: Icons.emoji_events,
                                  label: 'Total',
                                  value: '${_achievements.length}',
                                ),
                                _AchievementStat(
                                  icon: Icons.star,
                                  label: 'Points',
                                  value: '${_calculateTotalPoints()}',
                                ),
                                _AchievementStat(
                                  icon: Icons.trending_up,
                                  label: 'Rank',
                                  value: '#${_calculateRank()}',
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Achievements grid
                        const Text(
                          'Your Achievements',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_achievements.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No achievements yet. Keep learning to earn badges!',
                              ),
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.8,
                                ),
                            itemCount:
                                _achievements.length +
                                5, // Add placeholders for locked achievements
                            itemBuilder: (context, index) {
                              if (index < _achievements.length) {
                                final achievement = _achievements[index];
                                return _AchievementCard(
                                  achievement: achievement,
                                );
                              } else {
                                // Locked achievement placeholder
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.lock_outline,
                                          size: 40,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Locked',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        const Text(
                                          'Complete more courses',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            },
                          ),

                        const SizedBox(height: 20),

                        // Achievement categories
                        const Text(
                          'Achievement Categories',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            _CategoryChip(label: 'Course Completion'),
                            _CategoryChip(label: 'Quiz Master'),
                            _CategoryChip(label: 'Streak Keeper'),
                            _CategoryChip(label: 'Community Helper'),
                            _CategoryChip(label: 'Early Bird'),
                            _CategoryChip(label: 'Night Owl'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  int _calculateTotalPoints() {
    // In a real implementation, this would calculate based on achievement values
    return _achievements.length * 100;
  }

  int _calculateRank() {
    // In a real implementation, this would fetch from the backend
    return 15;
  }
}

class _AchievementStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AchievementStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              achievement.icon != null
                  ? Icons.emoji_events
                  : Icons.emoji_events_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 10),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              '${achievement.earnedAt.day}/${achievement.earnedAt.month}/${achievement.earnedAt.year}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;

  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
    );
  }
}
