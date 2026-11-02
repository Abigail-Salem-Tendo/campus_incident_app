import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/report_model.dart';
import '../services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _service;

  ReportProvider({ReportService? service})
    : _service = service ?? ReportService();

  bool _isBusy = false;
  String? _errorMessage;

  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;

  /// Returns true if the report was saved.
  Future<bool> submitReport({
    required String title,
    required String description,
    required ReportCategory category,
    required String location,
    required bool isAnonymous,
    required String reporterId,
    required String reporterName,
  }) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final report = ReportModel(
        id: '', // Firestore generates the real ID
        title: title.trim(),
        description: description.trim(),
        category: category,
        location: location,
        status: ReportStatus.submitted,
        reporterId: reporterId,
        reporterName: reporterName,
        isAnonymous: isAnonymous,
      );

      await _service.createReport(report);
      return true;
    } on FirebaseException catch (e) {
      _errorMessage = _friendlyMessage(e);
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _friendlyMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You do not have permission to submit this report.';
      case 'unavailable':
        return 'No connection. Check your internet and try again.';
      default:
        return 'Could not submit the report. Please try again.';
    }
  }
}
