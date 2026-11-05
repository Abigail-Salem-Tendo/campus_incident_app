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
  String _searchQuery = '';
  ReportStatus? _statusFilter;
  ReportCategory? _categoryFilter;
  String? _mineUid;

  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;

  List<ReportModel> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get listError => _listError;
  String get searchQuery => _searchQuery;
  ReportStatus? get statusFilter => _statusFilter;
  ReportCategory? get categoryFilter => _categoryFilter;
  bool get isMineOnly => _mineUid != null;

  //true when my reports is selected and the user has submitted nothing
  bool get isMineEmpty =>
      _mineUid != null && !_reports.any((r) => r.reporterId == _mineUid);

  // number of reports in each status, it ignores all filter for staff tiles
  Map<ReportStatus, int> get statusCount {
    final counts = {for (final s in ReportStatus.values) s: 0};
    for (final r in _reports) {
      counts[r.status] = (counts[r.status] ?? 0) + 1;
    }
    return counts;
  }

  void showMine(String uid) {
    _mineUid = uid;
    notifyListeners();
  }

  void showAll() {
    _mineUid = null;
    notifyListeners();
  }

  // live list with the current search applied
  List<ReportModel> get filteredReports {
    final query = _searchQuery.trim().toLowerCase();
    return _reports.where((r) {
      final matchesOwner = _mineUid == null || r.reporterId == _mineUid;
      final matchesStatus = _statusFilter == null || r.status == _statusFilter;
      final matchesCategory =
          _categoryFilter == null || r.category == _categoryFilter;
      final matchesQuery =
          query.isEmpty || r.title.toLowerCase().contains(query);
      return matchesOwner && matchesStatus && matchesCategory && matchesQuery;
    }).toList();
  }

  void setStatusFilter(ReportStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setCategoryFilter(ReportCategory? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  // resets the search, status and category back
  void clearFilters() {
    _searchQuery = '';
    _statusFilter = null;
    _categoryFilter = null;
    notifyListeners();
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

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

  /// Returns true if the changes were saved.
  Future<bool> updateReport({
    required String id,
    required String title,
    required String description,
    required ReportCategory category,
    required String location,
    required bool isAnonymous,
  }) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service
          .updateReport(
            id: id,
            title: title.trim(),
            description: description.trim(),
            category: category,
            location: location,
            isAnonymous: isAnonymous,
          )
          .timeout(const Duration(seconds: 15));
      return true;
    } on TimeoutException {
      _errorMessage = 'Saving timed out. Check your connection and try again.';
      return false;
    } on FirebaseException catch (e) {
      _errorMessage = _updateMessage(e);
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Deletes the report, then its photo (if any). Returns true if deleted.
  Future<bool> deleteReport(ReportModel report) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service
          .deleteReport(report.id)
          .timeout(const Duration(seconds: 15));

      // Best-effort cleanup: the report is already gone at this point.
      final url = report.photoUrl;
      if (url != null && url.isNotEmpty) {
        await _storage.deleteByUrl(url);
      }
      return true;
    } on TimeoutException {
      _errorMessage =
          'Deleting timed out. Check your connection and try again.';
      return false;
    } on FirebaseException catch (e) {
      _errorMessage = _deleteMessage(e);
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Changes a report's status (staff only). Returns true if saved.
  Future<bool> updateStatus({
    required String id,
    required ReportStatus status,
  }) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service
          .updateStatus(id: id, status: status)
          .timeout(const Duration(seconds: 15));
      return true;
    } on TimeoutException {
      _errorMessage = 'Saving timed out. Check your connection and try again.';
      return false;
    } on FirebaseException catch (e) {
      _errorMessage = _statusMessage(e);
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  String _statusMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Only staff can change a report\'s status.';
      case 'unavailable':
        return 'No connection. Check your internet and try again.';
      default:
        return 'Could not update the status. Please try again.';
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
        _listError =
            error is FirebaseException && error.code == 'permission-denied'
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
    _searchQuery = '';
    _statusFilter = null;
    _categoryFilter = null;
    _mineUid = null;
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

  String _updateMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You can only edit your own reports while they are still '
            'Submitted.';
      case 'unavailable':
        return 'No connection. Check your internet and try again.';
      default:
        return 'Could not save your changes. Please try again.';
    }
  }

  String _deleteMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You can only delete your own reports while they are still '
            'Submitted.';
      case 'unavailable':
        return 'No connection. Check your internet and try again.';
      default:
        return 'Could not delete the report. Please try again.';
    }
  }
}
