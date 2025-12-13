import 'package:flutter/material.dart';
import '../models/social.dart';
import '../services/social_service.dart';

class LeaderboardScreen extends StatefulWidget {
  final int userId;
  final String? token;

  const LeaderboardScreen({super.key, required this.userId, this.token});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late SocialService _socialService;
  List<Leaderboard> _leaderboard = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _userRank = 0;
  int _userPoints = 0;

  @override
  void initState() {
    super.initState();
    _socialService = SocialService(token: widget.token);
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    try {
      final leaderboard = await _socialService.getLeaderboard();

      // Find user's rank and points
      final userEntry = leaderboard.firstWhere(
        (entry) => entry.userId == widget.userId,
        orElse:
            () => Leaderboard(
              id: 0,
              userId: widget.userId,
              points: 0,
              rank: 0,
              lastUpdated: DateTime.now(),
            ),
      );

      setState(() {
        _leaderboard = leaderboard;
        _userRank = userEntry.rank;
        _userPoints = userEntry.points;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load leaderboard: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
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
                      onPressed: _loadLeaderboard,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadLeaderboard,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User's rank card
                        Card(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color:
                                        _userRank == 1
                                            ? Colors.yellow
                                            : _userRank == 2
                                            ? Colors.grey
                                            : _userRank == 3
                                            ? Colors.brown
                                            : Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$_userRank',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Your Rank',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('$_userPoints points'),
                                  ],
                                ),
                                const Spacer(),
                                ElevatedButton(
                                  onPressed: () {
                                    // View achievements
                                  },
                                  child: const Text('View Achievements'),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Leaderboard list
                        const Text(
                          'Top Learners',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _leaderboard.length,
                          itemBuilder: (context, index) {
                            final entry = _leaderboard[index];
                            final isUser = entry.userId == widget.userId;

                            return Card(
                              color:
                                  isUser
                                      ? Theme.of(
                                        context,
                                      ).colorScheme.secondaryContainer
                                      : null,
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color:
                                        entry.rank == 1
                                            ? Colors.yellow
                                            : entry.rank == 2
                                            ? Colors.grey
                                            : entry.rank == 3
                                            ? Colors.brown
                                            : Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${entry.rank}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text('User ${entry.userId}'),
                                subtitle: Text(
                                  'Last updated: ${entry.lastUpdated.day}/${entry.lastUpdated.month}/${entry.lastUpdated.year}',
                                ),
                                trailing: Text(
                                  '${entry.points} pts',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // How ranking works
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'How Ranking Works',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  '• Earn points by completing courses\n'
                                  '• Take quizzes and score high\n'
                                  '• Participate in discussions\n'
                                  '• Submit assignments on time\n'
                                  '• Help other learners\n'
                                  '• Maintain learning streaks',
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
    );
  }
}
