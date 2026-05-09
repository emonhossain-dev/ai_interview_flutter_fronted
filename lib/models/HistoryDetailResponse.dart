class HistoryDetailResponse {
  final HistoryDetailSession session;
  final AnalysisResult analysis;
  final List<InterviewMessage> messages;

  HistoryDetailResponse({
    required this.session,
    required this.analysis,
    required this.messages,
  });

  factory HistoryDetailResponse.fromJson(Map<String, dynamic> json) {
    return HistoryDetailResponse(
      session:  HistoryDetailSession.fromJson(json['session']),
      analysis: AnalysisResult.fromJson(json['analysis']),
      messages: (json['messages'] as List)
          .map((e) => InterviewMessage.fromJson(e))
          .toList(),
    );
  }
}

class HistoryDetailSession {
  final String id;
  final String title;
  final String candidateName;
  final String category;
  final List<String> topics;
  final String difficulty;
  final int questionCount;
  final String mode;
  final int? score;
  final String duration;
  final String date;

  HistoryDetailSession({
    required this.id,
    required this.title,
    required this.candidateName,
    required this.category,
    required this.topics,
    required this.difficulty,
    required this.questionCount,
    required this.mode,
    required this.score,
    required this.duration,
    required this.date,
  });

  factory HistoryDetailSession.fromJson(Map<String, dynamic> json) {
    return HistoryDetailSession(
      id:            json['session_id']    as String,
      title:         json['title']         as String,
      candidateName: json['candidate_name']as String,
      category:      json['category']      as String,
      topics:        List<String>.from(json['topics']),
      difficulty:    json['difficulty']    as String,
      questionCount: json['question_count']as int,
      mode:          json['mode']          as String,
      score:         json['score'] != null ? (json['score'] as num).toInt() : null,
      duration:      json['duration']      as String,
      date:          json['created_at']    as String,
    );
  }
}

class PerformanceBreakdown {
  final int communication;
  final int technicalAccuracy;
  final int confidence;
  final int structure;

  PerformanceBreakdown({
    required this.communication,
    required this.technicalAccuracy,
    required this.confidence,
    required this.structure,
  });

  factory PerformanceBreakdown.fromJson(Map<String, dynamic> json) {
    return PerformanceBreakdown(
      communication:    (json['communication']      as num).toInt(),
      technicalAccuracy:(json['technical_accuracy'] as num).toInt(),
      confidence:       (json['confidence']         as num).toInt(),
      structure:        (json['structure']           as num).toInt(),
    );
  }
}

class AnalysisResult {
  final String headline;
  final String overallSummary;
  final String scoreJustification;
  final PerformanceBreakdown performance;
  final List<AnalysisPoint> strengths;
  final List<AnalysisPoint> weaknesses;
  final List<AnalysisPoint> suggestions;
  final String verdict;

  AnalysisResult({
    required this.headline,
    required this.overallSummary,
    required this.scoreJustification,
    required this.performance,
    required this.strengths,
    required this.weaknesses,
    required this.suggestions,
    required this.verdict,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      headline:           json['headline']            as String,
      overallSummary:     json['overall_summary']     as String,
      scoreJustification: json['score_justification'] as String,
      performance:        PerformanceBreakdown.fromJson(json['performance']),
      strengths:          _parsePoints(json['strengths']),
      weaknesses:         _parsePoints(json['weaknesses']),
      suggestions:        _parsePoints(json['suggestions']),
      verdict:            json['verdict']             as String,
    );
  }

  static List<AnalysisPoint> _parsePoints(dynamic list) {
    return (list as List)
        .map((e) => AnalysisPoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class AnalysisPoint {
  final String title;
  final String detail;
  final String tag;

  AnalysisPoint({required this.title, required this.detail, required this.tag});

  factory AnalysisPoint.fromJson(Map<String, dynamic> json) {
    return AnalysisPoint(
      title:  json['title']  as String,
      detail: json['detail'] as String,
      tag:    json['tag']    as String? ?? '',
    );
  }
}

class InterviewMessage {
  final String id;
  final String role;
  final String content;
  final String createdAt;

  InterviewMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory InterviewMessage.fromJson(Map<String, dynamic> json) {
    return InterviewMessage(
      id:        json['id']         as String,
      role:      json['role']       as String,
      content:   json['content']    as String,
      createdAt: json['created_at'] as String,
    );
  }
}