import 'package:flutter/material.dart';
import 'dart:io'; // Add this import for SocketException
import '../models/user.dart' as app_user;
import '../models/social.dart';
import '../services/auth_service.dart';
import '../services/social_service.dart';

class UserSearchScreen extends StatefulWidget {
  final AuthService authService;

  const UserSearchScreen({super.key, required this.authService});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  List<app_user.User> _allUsers = [];
  List<app_user.User> _filteredUsers = [];
  List<String> _followingIds = [];
  List<String> _outgoingRequestIds = [];
  String _searchQuery = '';
  bool _isLoading = true;
  late SocialService _socialService;

  @override
  void initState() {
    super.initState();
    _socialService = SocialService(token: widget.authService.token);
    _loadUsers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when the screen becomes active
    _loadUsers();
  }

  @override
  void didUpdateWidget(covariant UserSearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh when the widget is updated
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all users from the database
      final response = await widget.authService.getAllUsers();

      if (response['success']) {
        final usersData = response['users'] as List;
        final users =
            usersData.map((data) => app_user.User.fromJson(data)).toList();

        // Get current user's following list
        final following = await _socialService.getFollowing(
          widget.authService.currentUser!.id,
        );

        final followingIds =
            following.map((follow) => follow.followedId).toList();

        // Get current user's outgoing follow requests
        final outgoingRequests = await _socialService.getOutgoingFollowRequests(
          widget.authService.currentUser!.id,
        );

        final outgoingRequestIds =
            outgoingRequests.map((req) => req.targetUserId).toList();

        setState(() {
          _allUsers = users;
          _filteredUsers = users;
          _followingIds = followingIds;
          _outgoingRequestIds = outgoingRequestIds;
          _isLoading = false;
        });
      } else {
        throw Exception(response['error']);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading users: $e')));
      }
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;

      if (query.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers =
            _allUsers.where((user) {
              final fullName =
                  '${user.firstName} ${user.lastName}'.toLowerCase();
              final username = user.username.toLowerCase();
              final searchLower = query.toLowerCase();

              return fullName.contains(searchLower) ||
                  username.contains(searchLower);
            }).toList();
      }
    });
  }

  Future<void> _followUser(String userId) async {
    try {
      print('Attempting to follow user: $userId');
      // Check if already following
      if (_followingIds.contains(userId)) {
        print('Already following user: $userId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are already following this user'),
            ),
          );
        }
        return;
      }

      // First, check if the target user has a private account
      final userProfile = await widget.authService.getUserProfileById(userId);
      print('Retrieved user profile for $userId: ${userProfile['success']}');

      if (userProfile['success']) {
        final targetUser = app_user.User.fromJson(userProfile['data']);
        print('Target user isPrivate: ${targetUser.isPrivate}');

        // If the target user has a private account, create a follow request
        if (targetUser.isPrivate) {
          print('Target user has private account, creating follow request');
          // Create a follow request
          print(
            'Creating follow request from ${widget.authService.currentUser!.id} to $userId',
          );
          final connection = await _socialService.createFollowRequest(
            requesterId: widget.authService.currentUser!.id,
            targetUserId: userId,
          );
          print(
            'Follow request created successfully with ID: ${connection.id}',
          );
          print(
            'Connection details: requester=${connection.requesterId}, target=${connection.targetUserId}, status=${connection.status}',
          );

          // Update outgoing requests list
          setState(() {
            _outgoingRequestIds.add(userId);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Follow request sent! The user will review your request.',
                ),
              ),
            );
          }
          return;
        }
      }

      // For public accounts or if there was an error checking privacy, proceed with direct follow
      print(
        'Following user directly (public account or error checking privacy)',
      );
      await _socialService.followUser(
        widget.authService.currentUser!.id,
        userId,
      );

      // Update following list
      setState(() {
        _followingIds.add(userId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Followed user successfully!')),
        );
      }
    } on SocketException catch (e) {
      print('Network error following user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Network error. Please check your connection and try again.',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error following user: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error following user: $e')));
      }
    }
  }

  Future<void> _unfollowUser(String userId) async {
    try {
      await _socialService.unfollowUser(
        widget.authService.currentUser!.id,
        userId,
      );

      // Update following list
      setState(() {
        _followingIds.remove(userId);
        // Also remove from outgoing requests in case there was a pending request
        _outgoingRequestIds.remove(userId);
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Unfollowed user')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error unfollowing user: $e')));
      }
    }
  }

  Future<void> _cancelFollowRequest(String userId) async {
    try {
      await _socialService.cancelOutgoingFollowRequest(
        requesterId: widget.authService.currentUser!.id,
        targetUserId: userId,
      );

      // Update outgoing requests list
      setState(() {
        _outgoingRequestIds.remove(userId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cancelled follow request')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling follow request: $e')),
        );
      }
    }
  }

  Widget _buildUserItem(app_user.User user) {
    final isCurrentUser = user.id == widget.authService.currentUser!.id;
    final isFollowing = _followingIds.contains(user.id);
    final hasOutgoingRequest = _outgoingRequestIds.contains(user.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            (user.firstName?.isNotEmpty == true ? user.firstName![0] : '?')
                .toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text('${user.firstName ?? ''} ${user.lastName ?? ''}'),
        subtitle: Text('@${user.username ?? 'unknown'}'),
        trailing:
            isCurrentUser
                ? null
                : isFollowing
                ? OutlinedButton(
                  onPressed: () => _unfollowUser(user.id),
                  child: const Text('Following'),
                )
                : hasOutgoingRequest
                ? OutlinedButton(
                  onPressed: () => _cancelFollowRequest(user.id),
                  child: const Text('Cancel Request'),
                )
                : ElevatedButton(
                  onPressed: () => _followUser(user.id),
                  child: const Text('Follow'),
                ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Users'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
              ),
              onChanged: _filterUsers,
            ),
          ),

          // User list
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredUsers.isEmpty
                    ? const Center(
                      child: Text(
                        'No users found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _loadUsers,
                      child: ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          return _buildUserItem(_filteredUsers[index]);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
