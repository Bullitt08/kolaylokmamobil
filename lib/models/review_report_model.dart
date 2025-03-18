import 'package:uuid/uuid.dart';

enum ReportStatus { pending, resolved, rejected }

class ReviewReportModel {
  final String id;
  final String reviewId;
  final String reporterId;
  final String reason;
  final ReportStatus status;
  final DateTime createdAt;

  ReviewReportModel({
    String? id,
    required this.reviewId,
    required this.reporterId,
    required this.reason,
    this.status = ReportStatus.pending,
    DateTime? createdAt,
  })  : this.id = id ?? const Uuid().v4(),
        this.createdAt = createdAt ?? DateTime.now();

  factory ReviewReportModel.fromMap(Map<String, dynamic> map) {
    return ReviewReportModel(
      id: map['id'],
      reviewId: map['review_id'],
      reporterId: map['reporter_id'],
      reason: map['reason'],
      status: ReportStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (map['status'] ?? 'pending'),
        orElse: () => ReportStatus.pending,
      ),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'review_id': reviewId,
      'reporter_id': reporterId,
      'reason': reason,
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ReviewReportModel copyWith({
    String? id,
    String? reviewId,
    String? reporterId,
    String? reason,
    ReportStatus? status,
    DateTime? createdAt,
  }) {
    return ReviewReportModel(
      id: id ?? this.id,
      reviewId: reviewId ?? this.reviewId,
      reporterId: reporterId ?? this.reporterId,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
