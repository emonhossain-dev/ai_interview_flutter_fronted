import 'ResumeResponse.dart';

class UserModel {
  final int id;
  final String email;
  final String name;
  final String mobile;
  final String? currentPosition;
  final bool isVerified;
  final String authProvider;
  final String? profilePic;
  final String createdAt;
  final String updatedAt;
  final ResumeModel? resume;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.mobile,
    this.currentPosition,
    required this.isVerified,
    required this.authProvider,
    this.profilePic,
    required this.createdAt,
    required this.updatedAt,
    this.resume,
  });


  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json["id"],
      email: json["email"],
      name: json["name"],
      mobile: json["mobile"].toString(),
      isVerified: json["is_verified"],
      authProvider: json["auth_provider"],
      profilePic: json["profile_pic"],
      createdAt: json["created_at"],
      updatedAt: json["updated_at"],
      resume: json["resume"] != null
          ? ResumeModel.fromJson(json["resume"])
          : null,
    );
  }

  // ─────────────────────────────────────
  // 🔥 GETTERS (easy access helpers)
  // ─────────────────────────────────────

  String get userId => id.toString();

  String get displayName => name.isNotEmpty ? name : "Unknown User";

  String get phone => mobile;

  String get position => currentPosition ?? "Not specified";

  bool get hasResume => resume != null;

  String get profileImage =>
      profilePic ?? "https://ui-avatars.com/api/?name=$name";

  String get createdDateOnly => createdAt.split("T").first;

  String get initials {
    final parts = name.trim().split(" ");
    if (parts.isEmpty) return "";
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}