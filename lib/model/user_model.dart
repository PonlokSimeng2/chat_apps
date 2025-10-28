class UserModel {
  final String? id; // Changed from int? to String?
  final String username;
  final String email;
  final String displayName;
  final String? profilePictureUrl;
  final String? phoneNumber;
  final String? bio;
  final String? website;
  final bool? isOnline;
  final DateTime? lastSeenAt;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    this.id,
    required this.username,
    required this.email,
    required this.displayName,
    this.profilePictureUrl,
    this.phoneNumber,
    this.bio,
    this.website,
    this.isOnline,
    this.lastSeenAt,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString(), // Simplified - just convert to string
      username: json['username'].toString(),
      email: json['email'].toString(),
      displayName: json['display_name'].toString(),
      profilePictureUrl: json['profile_picture_url']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      bio: json['bio']?.toString(),
      website: json['website']?.toString(),
      isOnline: json['is_online'],
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'])
          : null,
      status: json['status']?.toString(),
      createdAt:
          json['created_at'] !=
              null // Note: should be 'created_at' not 'create_at'
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt:
          json['updated_at'] !=
              null // Note: should be 'updated_at' not 'update_at'
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'display_name': displayName,
      'profile_picture_url': profilePictureUrl,
      'phone_number': phoneNumber,
      'bio': bio,
      'website': website,
      'is_online': isOnline ?? false,
      'status': status ?? 'active',
    };
  }
}
