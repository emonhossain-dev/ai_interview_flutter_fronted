import 'ResumeResponse.dart';

class UserModel {
  final int id;
  final String email;
  final String? name;           // ← nullable করলাম
  final String? mobile;         // ← nullable করলাম
  final String? currentPosition;
  final bool isVerified;
  final String? authProvider;   // ← nullable করলাম
  final String? profilePic;
  final String? createdAt;      // ← nullable করলাম
  final String? updatedAt;      // ← nullable করলাম
  final ResumeModel? resume;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.mobile,
    this.currentPosition,
    this.isVerified = false,
    this.authProvider,
    this.profilePic,
    this.createdAt,
    this.updatedAt,
    this.resume,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:              json["id"]           as int,
      email:           json["email"]        as String,
      name:            json["name"]         as String?,
      mobile:          json["mobile"]?.toString(),
      currentPosition: json["current_position"] as String?,
      isVerified:      json["is_verified"]  as bool? ?? false,
      authProvider:    json["auth_provider"] as String?,
      profilePic:      json["profile_pic"]  as String?,
      createdAt:       json["created_at"]?.toString(),
      updatedAt:       json["updated_at"]?.toString(),
      resume: json["resume"] != null
          ? ResumeModel.fromJson(json["resume"])
          : null,
    );
  }

  // ─────────────────────────────────────
  // GETTERS
  // ─────────────────────────────────────

  String get userId => id.toString();

  String get displayName => (name != null && name!.isNotEmpty) ? name! : "Unknown User";

  String get phone => mobile ?? "";

  String get position => currentPosition ?? "Not specified";

  bool get hasResume => resume != null;

  String get profileImage =>
      profilePic ?? "https://ui-avatars.com/api/?name=${displayName.replaceAll(' ', '+')}";

  String get createdDateOnly => createdAt?.split("T").first ?? "";

  String get initials {
    final safeName = displayName.trim();
    final parts = safeName.split(" ");
    if (parts.isEmpty || safeName.isEmpty) return "?";
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}