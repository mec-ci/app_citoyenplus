class UtilisateurProfile {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String? coverPhoto;
  final String? bio;
  final String? city;
  final DateTime? joinDate;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;
  final int postsCount;

  UtilisateurProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.coverPhoto,
    this.bio,
    this.city,
    this.joinDate,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowing = false,
    this.postsCount = 0,
  });

  factory UtilisateurProfile.fromJson(Map<String, dynamic> json) {
    return UtilisateurProfile(
      id: json['id'] ?? json['uid'] ?? '',
      name: json['name'] ?? json['username'] ?? json['firstName'] ?? 'Utilisateur',
      email: json['email'] ?? '',
      avatar: json['avatar'] ?? json['avatarUrl'] ?? json['photo'],
      coverPhoto: json['coverPhoto'] ?? json['cover_photo'] ?? json['coverPhotoUrl'],
      bio: json['bio'] ?? json['description'] ?? '',
      city: json['city'] ?? json['location'] ?? '',
      joinDate: json['joinDate'] != null
          ? DateTime.parse(json['joinDate'].toString())
          : null,
      followersCount: json['followersCount'] ?? json['followers_count'] ?? 0,
      followingCount: json['followingCount'] ?? json['following_count'] ?? 0,
      isFollowing: json['isFollowing'] ?? json['is_following'] ?? false,
      postsCount: json['postsCount'] ?? json['posts_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatar': avatar,
        'coverPhoto': coverPhoto,
        'bio': bio,
        'city': city,
        'joinDate': joinDate?.toIso8601String(),
        'followersCount': followersCount,
        'followingCount': followingCount,
        'isFollowing': isFollowing,
        'postsCount': postsCount,
      };
}
