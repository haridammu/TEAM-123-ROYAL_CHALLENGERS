import 'package:flutter/material.dart';
import '../models/social.dart';
import '../services/social_service.dart';

class SocialFeedScreen extends StatefulWidget {
  final int userId;
  final String? token;

  const SocialFeedScreen({super.key, required this.userId, this.token});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  late SocialService _socialService;
  List<Post> _posts = [];
  List<Achievement> _achievements = [];
  List<Leaderboard> _leaderboard = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _postController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _socialService = SocialService(token: widget.token);
    _loadFeed();
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _loadFeed() async {
    try {
      final posts = await _socialService.getPosts();
      final achievements = await _socialService.getAchievements(widget.userId);
      final leaderboard = await _socialService.getLeaderboard();

      setState(() {
        _posts = posts;
        _achievements = achievements;
        _leaderboard = leaderboard;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load feed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createPost() async {
    if (_postController.text.trim().isEmpty) return;

    try {
      await _socialService.createPost(
        authorId: widget.userId,
        content: _postController.text.trim(),
      );

      // Clear the input field
      _postController.clear();

      // Reload the feed
      _loadFeed();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create post: $e';
      });
    }
  }

  Future<void> _likePost(int postId) async {
    try {
      await _socialService.likePost(postId, widget.userId);
      // Reload the feed to show updated like count
      _loadFeed();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to like post: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Feed'),
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
                      onPressed: _loadFeed,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadFeed,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Create post section
                      Card(
                        margin: const EdgeInsets.all(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              TextField(
                                controller: _postController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  hintText:
                                      'Share something with the community...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _createPost,
                                child: const Text('Post'),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Achievements section
                      if (_achievements.isNotEmpty)
                        Card(
                          margin: const EdgeInsets.all(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your Achievements',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 80,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _achievements.length,
                                    itemBuilder: (context, index) {
                                      final achievement = _achievements[index];
                                      return Card(
                                        margin: const EdgeInsets.only(
                                          right: 10,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                achievement.icon != null
                                                    ? Icons.emoji_events
                                                    : Icons
                                                        .emoji_events_outlined,
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                achievement.title,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Leaderboard section
                      if (_leaderboard.isNotEmpty)
                        Card(
                          margin: const EdgeInsets.all(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                  itemCount:
                                      _leaderboard.length > 3
                                          ? 3
                                          : _leaderboard.length,
                                  itemBuilder: (context, index) {
                                    final entry = _leaderboard[index];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        child: Text(
                                          '${entry.rank}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      title: Text('User ${entry.userId}'),
                                      trailing: Text('${entry.points} pts'),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Posts feed
                      if (_posts.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No posts yet. Be the first to share something!',
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _posts.length,
                          itemBuilder: (context, index) {
                            final post = _posts[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor:
                                              Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                          child: Text(
                                            post.authorId.toString()[0],
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'User ${post.authorId}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(post.content),
                                    // Display post image if available
                                    if (post.imageUrl != null &&
                                        post.imageUrl!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            post.imageUrl!,
                                            height: 200,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.favorite_border,
                                          ),
                                          onPressed: () => _likePost(post.id),
                                        ),
                                        Text('${post.likesCount}'),
                                        const SizedBox(width: 16),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.comment_outlined,
                                          ),
                                          onPressed: () {
                                            // Handle comment
                                          },
                                        ),
                                        Text('${post.commentsCount}'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create post screen
          Navigator.pushNamed(
            context,
            '/create-post',
            arguments: {'userId': widget.userId, 'token': widget.token},
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
