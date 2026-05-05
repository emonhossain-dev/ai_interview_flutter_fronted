class ResumeModel {
  final int? id;
  final String? title;
  final String? summary;
  final String? fileUrl;
  final String? createdAt;

  ResumeModel({
    this.id,
    this.title,
    this.summary,
    this.fileUrl,
    this.createdAt,
  });

  factory ResumeModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ResumeModel();

    return ResumeModel(
      id: json["id"],
      title: json["title"],
      summary: json["summary"],
      fileUrl: json["file_url"],
      createdAt: json["created_at"],
    );
  }
}