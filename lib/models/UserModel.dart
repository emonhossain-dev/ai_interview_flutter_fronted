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

  final ResumeModel? resume; // ⭐ NEW

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

      // ⭐ resume parsing
      resume: json["resume"] != null ? ResumeModel.fromJson(json["resume"]) : null,


    );
  }
}