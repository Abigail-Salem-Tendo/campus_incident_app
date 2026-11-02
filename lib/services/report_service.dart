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
}
