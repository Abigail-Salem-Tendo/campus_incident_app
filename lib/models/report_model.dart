import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportStatus {
  submitted('Submitted'),
  underReview('Under Review'),
  inProgress('In Progress'),
  resolved('Resolved');

  final String label;
  const ReportStatus(this.label);

  static ReportStatus fromName(String? name) {
    return ReportStatus.values.firstWhere(
      (s) => s.name == name,
      orElse: () => ReportStatus.submitted,
    );
  }
}

enum ReportCategory {
  maintenance('Maintenance'),
  safety('Safety'),
  cleanliness('Cleanliness'),
  utilities('Utilities'),
  it('IT & Network'),
  other('Other');

  final String label;
  const ReportCategory(this.label);

  static ReportCategory fromName(String? name) {
    return ReportCategory.values.firstWhere(
      (c) => c.name == name,
      orElse: () => ReportCategory.other,
    );
  }
}

class ReportModel {
  final String id;
  final String title;
  final String description;
  final ReportCategory category;
  final String location;
  final ReportStatus status;
  final String reporterId;
  final String reporterName;
  final bool isAnonymous;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ReportModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.status,
    required this.reporterId,
    required this.reporterName,
    required this.isAnonymous,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// Used when creating a new report. Timestamps are set by the server.
  Map<String, dynamic> toCreateMap() {
    return {
      'title': title,
      'description': description,
      'category': category.name,
      'location': location,
      'status': ReportStatus.submitted.name,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'isAnonymous': isAnonymous,
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory ReportModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ReportModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: ReportCategory.fromName(data['category'] as String?),
      location: data['location'] as String? ?? '',
      status: ReportStatus.fromName(data['status'] as String?),
      reporterId: data['reporterId'] as String? ?? '',
      reporterName: data['reporterName'] as String? ?? '',
      isAnonymous: data['isAnonymous'] as bool? ?? false,
      photoUrl: data['photoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
