class HistoryResponse {
  final List<HistoryItem> sessions;
  final PaginationInfo pagination;

  HistoryResponse({required this.sessions, required this.pagination});

  factory HistoryResponse.fromJson(Map<String, dynamic> json) {
    final list = json['sessions'] as List<dynamic>? ?? [];
    return HistoryResponse(
      sessions: list
          .map((e) => HistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: PaginationInfo.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page:       json['page']        as int?  ?? 1,
      limit:      json['limit']       as int?  ?? 20,
      total:      json['total']       as int?  ?? 0,
      totalPages: json['total_pages'] as int?  ?? 1,
      hasNext:    json['has_next']    as bool? ?? false,
      hasPrev:    json['has_prev']    as bool? ?? false,
    );
  }
}

class HistoryItem {
  final String id;
  final String title;
  final String candidateName;
  final String category;
  final List<String> topics;
  final String difficulty;
  final int questionCount;
  final bool isComplete;
  final String mode;
  final int? score;
  final String duration;
  final String date;

  HistoryItem({
    required this.id,
    required this.title,
    required this.candidateName,
    required this.category,
    required this.topics,
    required this.difficulty,
    required this.questionCount,
    required this.isComplete,
    required this.mode,
    required this.score,
    required this.duration,
    required this.date,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id:            json['session_id']    as String? ?? '',
      title:         json['title']         as String? ?? '',
      candidateName: json['candidate_name']as String? ?? '',
      category:      json['category']      as String? ?? '',
      topics:        List<String>.from(json['topics'] as List? ?? []),
      difficulty:    json['difficulty']    as String? ?? '',
      questionCount: json['question_count']as int?    ?? 0,
      isComplete:    json['is_complete']   as bool?   ?? false,
      mode:          json['mode']          as String? ?? 'In-Person',
      score:         json['score'] != null ? (json['score'] as num).toInt() : null,
      duration:      json['duration']      as String? ?? 'N/A',
      date:          json['created_at']    as String? ?? '',
    );
  }
}