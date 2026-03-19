List<Map<String, String>> _parseSocialLinks(dynamic raw) {
  if (raw is! List) return [];
  return raw.map<Map<String, String>>((e) {
    if (e is Map) {
      return {
        'platform': (e['platform'] ?? '').toString(),
        'url': (e['url'] ?? '').toString(),
      };
    }
    return {'platform': '', 'url': ''};
  }).toList();
}

class User {
  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    this.avatarUrl,
    this.teamId,
    this.workspaceId,
    this.phone,
    this.bio,
    this.position,
    this.timezone,
    this.handle,
    this.language,
    this.coverUrl,
    this.twoFactorEnabled = false,
    this.publicProfileEnabled = false,
    this.showCommentsOnProfile = true,
    this.socialLinks = const [],
  });

  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String role; // 'admin' | 'member'
  final String? teamId;
  final String? workspaceId;
  final DateTime createdAt;

  // Profile fields (stored in user.settings JSON on the API)
  final String? phone;
  final String? bio;
  final String? position;
  final String? timezone;
  final String? handle;
  final String? language;
  final String? coverUrl;
  final bool twoFactorEnabled;
  final bool publicProfileEnabled;
  final bool showCommentsOnProfile;
  final List<Map<String, String>> socialLinks;

  factory User.fromJson(Map<String, dynamic> json) {
    final settings = json['settings'] as Map<String, dynamic>? ?? {};
    final prefs = settings['preferences'] as Map<String, dynamic>? ?? {};

    return User(
      id: json['id'].toString(),
      email: (json['email'] ?? '') as String,
      name: (json['name'] ?? json['display_name'] ?? '') as String,
      avatarUrl: json['avatar_url'] as String?,
      role: (json['role'] ?? 'member') as String,
      teamId: json['team_id']?.toString(),
      workspaceId: json['workspace_id']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      phone: settings['phone'] as String?,
      bio: settings['bio'] as String?,
      position: settings['position'] as String?,
      timezone: settings['timezone'] as String?,
      handle: settings['handle'] as String?,
      language: (prefs['language'] as String?) ?? 'en',
      coverUrl: settings['cover_url'] as String?,
      twoFactorEnabled: json['two_factor_enabled'] == true,
      publicProfileEnabled: settings['public_profile_enabled'] == true,
      showCommentsOnProfile:
          (settings['show_comments_on_profile'] ?? 'true') != 'false',
      socialLinks: _parseSocialLinks(settings['social_links']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'avatar_url': avatarUrl,
    'role': role,
    'team_id': teamId,
    'workspace_id': workspaceId,
    'created_at': createdAt.toIso8601String(),
  };

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    String? role,
    String? teamId,
    String? workspaceId,
    DateTime? createdAt,
    String? phone,
    String? bio,
    String? position,
    String? timezone,
    String? handle,
    String? language,
    String? coverUrl,
    bool? twoFactorEnabled,
    bool? publicProfileEnabled,
    bool? showCommentsOnProfile,
    List<Map<String, String>>? socialLinks,
  }) => User(
    id: id ?? this.id,
    email: email ?? this.email,
    name: name ?? this.name,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    role: role ?? this.role,
    teamId: teamId ?? this.teamId,
    workspaceId: workspaceId ?? this.workspaceId,
    createdAt: createdAt ?? this.createdAt,
    phone: phone ?? this.phone,
    bio: bio ?? this.bio,
    position: position ?? this.position,
    timezone: timezone ?? this.timezone,
    handle: handle ?? this.handle,
    language: language ?? this.language,
    coverUrl: coverUrl ?? this.coverUrl,
    twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
    publicProfileEnabled: publicProfileEnabled ?? this.publicProfileEnabled,
    showCommentsOnProfile: showCommentsOnProfile ?? this.showCommentsOnProfile,
    socialLinks: socialLinks ?? this.socialLinks,
  );
}
