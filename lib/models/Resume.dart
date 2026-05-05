class ResumeFile {
  final String name;
  final String size;
  final String updatedAt;
  final String? localPath;

  ResumeFile({
    required this.name,
    required this.size,
    required this.updatedAt,
    this.localPath,
  });
}