import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/report_model.dart';

class ReportService {
  final FirebaseFirestore _firestore;

  ReportService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports');

  /// Saves a new report and returns its document ID.
  Future<String> createReport(ReportModel report) async {
    final doc = await _reports.add(report.toCreateMap());
    return doc.id;
  }

  /// Updates only the fields a student is allowed to change.
  Future<void> updateReport({
    required String id,
    required String title,
    required String description,
    required ReportCategory category,
    required String location,
    required bool isAnonymous,
  }) {
    return _reports.doc(id).update({
      'title': title,
      'description': description,
      'category': category.name,
      'location': location,
      'isAnonymous': isAnonymous,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes a report document.
  Future<void> deleteReport(String id) {
    return _reports.doc(id).delete();
  }

  // live list of all reports, newest first
  Stream<List<ReportModel>> watchReports() {
    return _reports
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ReportModel.fromDoc).toList());
  }
}
