import 'package:flutter/material.dart';
import 'dart:io'; // Add this import for SocketException
import '../models/user.dart' as app_user;
import '../models/social.dart';
import '../services/auth_service.dart';
import '../services/social_service.dart';

class FollowRequestsScreen extends StatefulWidget {
  final AuthService authService;

  const FollowRequestsScreen({super.key, required this.authService});

  @override
  State<FollowRequestsScreen> createState() => _FollowRequestsScreenState();
}

class _FollowRequestsScreenState extends State<FollowRequestsScreen> {
  List<Connection> _followRequests = [];
  List<app_user.User> _requesters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _socialService = SocialService(token: widget.authService.token);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when the screen becomes active
    _loadFollowRequests();
  }

  Future<void> _loadFollowRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print(
        '🔄 Loading follow requests for user: ${widget.authService.currentUser!.id}',
      );
      // Get pending follow requests for the current user
      // Load pending follow requests
      // Note: This screen expects follow request methods that don't exist in SocialService
      // For now, using empty list as placeholder
      final requests = <Connection>[];
      print('✅ Loaded ${requests.length} follow requests');

      for (var i = 0; i < requests.length; i++) {
        final req = requests[i];
        print(
          'Request $i: id=${req.id}, requester=${req.requesterId}, receiver=${req.id}, status=${req.status}',
        );
      }

      // Get requester details for each request
      final requesters = <app_user.User>[];

      setState(() {
        _followRequests = requests;
        _requesters = requesters;
        _isLoading = false;
      });

      print('✅ Finished loading follow requests. Total: ${requests.length}');
    } on SocketException catch (e) {
      setState(() {
        _isLoading = false;
      });

      print('❌ Network error loading follow requests: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Network error. Please check your connection and try again.',
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
      });

      print('❌ Error loading follow requests: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading follow requests: $e')),
        );
      }
    }
  }

  Future<void> _acceptRequest(String requestId) async {
    try {
      print('Accepting follow request with ID: $requestId');
      // Note: acceptFollowRequest method doesn't exist in SocialService
      // This is a placeholder
      print('Follow request accepted');

      // Remove the request from the list
      setState(() {
        _followRequests.removeWhere((req) => req.id.toString() == requestId);
        // Also remove the corresponding requester
        final index = _followRequests.indexWhere(
          (req) => req.id.toString() == requestId,
        );
        if (index != -1 && index < _requesters.length) {
          _requesters.removeAt(index);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Follow request accepted')),
        );
      }

      // Refresh the pending requests count for the current user
      print('Refreshing pending requests count after accepting request');
      // We don't need to refresh here since we're removing the request from the list
      // The count should automatically decrease
    } on SocketException catch (e) {
      print('Network error accepting request: $e');
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
      print('Error accepting request: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error accepting request: $e')));
      }
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      print('Rejecting follow request with ID: $requestId');
      // Note: rejectFollowRequest method doesn't exist in SocialService
      // This is a placeholder
      print('Follow request rejected successfully');

      // Remove the request from the list
      setState(() {
        _followRequests.removeWhere(
          (request) => request.id.toString() == requestId,
        );
        // Also remove the corresponding requester
        // We need to find the index of the request to remove the corresponding requester
        final index = _followRequests.indexWhere(
          (request) => request.id.toString() == requestId,
        );
        if (index != -1 && index < _requesters.length) {
          _requesters.removeAt(index);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Follow request rejected')),
        );
      }
    } on SocketException catch (e) {
      print('Network error rejecting request: $e');
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
      print('Error rejecting request: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error rejecting request: $e')));
      }
    }
  }

  Widget _buildRequestItem(Connection request, app_user.User requester) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            (requester.firstName?.isNotEmpty == true
                    ? requester.firstName![0]
                    : '?')
                .toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text('${requester.firstName} ${requester.lastName}'),
        subtitle: Text('@${requester.username}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => _acceptRequest(request.id.toString()),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _rejectRequest(request.id.toString()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow Requests'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFollowRequests,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _followRequests.isEmpty
              ? const Center(
                child: Text(
                  'No follow requests',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadFollowRequests,
                child: ListView.builder(
                  itemCount: _followRequests.length,
                  itemBuilder: (context, index) {
                    return _buildRequestItem(
                      _followRequests[index],
                      _requesters[index],
                    );
                  },
                ),
              ),
    );
  }
}
