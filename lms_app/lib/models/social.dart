class Follow {
  final int id;
  final int followerId;
  final int followedId;
  final DateTime createdAt;

  Follow({
    required this.id,
    required this.followerId,
    required this.followedId,
    required this.createdAt,
  });

  factory Follow.fromJson(Map<String, dynamic> json) {
    return Follow(
      id: json['id'],
      followerId: json['follower'],
      followedId: json['followed'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'follower': followerId,
      'followed': followedId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Connection {
  final int id;
  final int requesterId;
  final int receiverId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Connection({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      id: json['id'],
      requesterId: json['requester_id'],
      receiverId: json['receiver_id'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requester_id': requesterId,
      'receiver_id': receiverId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Post {
  final int id;
  final int authorId;
  final String content;
  final String? image;
  final String? imageUrl;
  final List<int> likeIds;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Post({
    required this.id,
    required this.authorId,
    required this.content,
    this.image,
    this.imageUrl,
    required this.likeIds,
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    List<int> likes = [];
    if (json['likes'] != null) {
      likes = List<int>.from(json['likes']);
    }

    return Post(
      id: json['id'],
      authorId: json['author'],
      content: json['content'],
      image: json['image'],
      imageUrl: json['image_url'],
      likeIds: likes,
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': authorId,
      'content': content,
      'image': image,
      'image_url': imageUrl,
      'likes': likeIds,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Comment {
  final int id;
  final int postId;
  final int authorId;
  final String content;
  final List<int> likeIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    required this.likeIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    List<int> likes = [];
    if (json['likes'] != null) {
      likes = List<int>.from(json['likes']);
    }

    return Comment(
      id: json['id'],
      postId: json['post'],
      authorId: json['author'],
      content: json['content'],
      likeIds: likes,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post': postId,
      'author': authorId,
      'content': content,
      'likes': likeIds,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Achievement {
  final int id;
  final int userId;
  final String title;
  final String description;
  final String? icon;
  final DateTime earnedAt;

  Achievement({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.icon,
    required this.earnedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      userId: json['user'],
      title: json['title'],
      description: json['description'],
      icon: json['icon'],
      earnedAt: DateTime.parse(json['earned_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'title': title,
      'description': description,
      'icon': icon,
      'earned_at': earnedAt.toIso8601String(),
    };
  }
}

class Leaderboard {
  final int id;
  final int userId;
  final int points;
  final int rank;
  final DateTime lastUpdated;

  Leaderboard({
    required this.id,
    required this.userId,
    required this.points,
    required this.rank,
    required this.lastUpdated,
  });

  factory Leaderboard.fromJson(Map<String, dynamic> json) {
    return Leaderboard(
      id: json['id'],
      userId: json['user'],
      points: json['points'],
      rank: json['rank'],
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'points': points,
      'rank': rank,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}
