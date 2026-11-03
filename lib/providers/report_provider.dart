import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/report_model.dart';
import '../services/report_service.dart';
import '../services/storage_service.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _service;
  final StorageService _storage;

  ReportProvider({ReportService? service, StorageService? storage})
    : _service = service ?? ReportService(),
      _storage = storage ?? StorageService();

  bool _isBusy = false;
  String? _errorMessage;

  StreamSubscription<List<ReportModel>>? _subscription;
  List<ReportModel> _reports = [];
  bool _isLoading = true;
  String? _listError;

  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;

  List<ReportModel> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get listError => _listError;

  /// Returns true if the report was saved.
  Future<bool> submitReport({
    required String title,
    required String description,
    required ReportCategory category,
    required String location,
    required bool isAnonymous,
    required String reporterId,
    required String reporterName,
    File? photo,
  }) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    bool uploading = false;
    String? uploadedUrl;

    try {
      // 1. Upload the photo first (if any) to get its download URL.
      if (photo != null) {
        uploading = true;
        uploadedUrl = await _storage
            .uploadReportPhoto(file: photo, uid: reporterId)
            .timeout(const Duration(seconds: 60));
        uploading = false;
      }

      // 2. Save the report with the photo URL (or null).
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
        photoUrl: uploadedUrl,
      );

      await _service.createReport(report);
      return true;
    } on TimeoutException {
      _errorMessage =
          'Photo upload timed out. Check your connection and try again.';
      await _discardPhoto(uploadedUrl);
      return false;
    } on FirebaseException catch (e) {
      _errorMessage = uploading ? _storageMessage(e) : _friendlyMessage(e);
      await _discardPhoto(uploadedUrl);
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      await _discardPhoto(uploadedUrl);
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

  //this satart the live reports stream and can be called more then once
  void startListening() {
    if (_subscription != null) return;
    _isLoading = true;
    _listError = null;
  
    _subscription = _service.watchReports().listen(
      (reports) {
        _reports = reports;
        _isLoading = false;
        _listError = null;
        notifyListeners();
      },
      onError: (Object error) {
        _listError = error is FirebaseException && error.code == 'permission-denied'
        ? 'You do not have permission to view reports.'
        : 'Could not load reports. Check your connection.';
        _isLoading = false;
        _subscription?.cancel();
        _subscription = null;
        notifyListeners();
      },
    );
  }

  // used by the retry button it restarts the stream and shows the spinner
  void retry() {
    startListening();
    notifyListeners();
  }

  /// Stops listening and clears the list (e.g. on sign out).
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _reports = [];
    _isLoading = true;
    _listError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// Removes an uploaded photo if the report could not be saved.
  Future<void> _discardPhoto(String? url) async {
    if (url != null) {
      await _storage.deleteByUrl(url);
    }
  }

  String _storageMessage(FirebaseException e) {
    switch (e.code) {
      case 'unauthorized':
        return 'You do not have permission to upload photos.';
      case 'retry-limit-exceeded':
      case 'network-request-failed':
        return 'No connection. Check your internet and try again.';
      default:
        return 'Photo upload failed. Please try again.';
    }
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
