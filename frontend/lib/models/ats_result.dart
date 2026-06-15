//ats_resut.dart
class ATSResult {
  final double finalScore;
  final double similarityScore;
  final double matchRate;

  final String verdict;
  final String recommendation;

  final List<dynamic> missingKeywords;
  final List<dynamic> matchedKeywords;
  final List<dynamic> atsIssues;

  ATSResult({
    required this.finalScore,
    required this.similarityScore,
    required this.matchRate,
    required this.verdict,
    required this.recommendation,
    required this.missingKeywords,
    required this.matchedKeywords,
    required this.atsIssues,
  });

  factory ATSResult.fromJson(Map<String, dynamic> json) {
    return ATSResult(
      finalScore: (json["final_score"] ?? 0).toDouble(),
      similarityScore: (json["similarity_score"] ?? 0).toDouble(),
      matchRate: (json["match_rate"] ?? 0).toDouble(),
      verdict: json["verdict"] ?? "",
      recommendation: json["recommendation"] ?? "",
      missingKeywords: json["missing_keywords"] ?? [],
      matchedKeywords: json["matched_keywords"] ?? [],
      atsIssues: json["ats_issues"] ?? [],
    );
  }
}