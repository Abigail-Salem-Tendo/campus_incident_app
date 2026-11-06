import 'package:flutter_test/flutter_test.dart';
import 'package:campus_incident_app/models/report_model.dart';

void main() {
  group('ReportStatus', () {
    test('fromName finds every status by its stored name', () {
      for (final status in ReportStatus.values) {
        expect(ReportStatus.fromName(status.name), status);
      }
    });

    test('fromName falls back to submitted for unknown or null', () {
      expect(ReportStatus.fromName('nonsense'), ReportStatus.submitted);
      expect(ReportStatus.fromName(null), ReportStatus.submitted);
    });

    test('labels are the text shown in the app', () {
      expect(ReportStatus.underReview.label, 'Under Review');
      expect(ReportStatus.inProgress.label, 'In Progress');
    });

    test('stored names match the Firestore security rules', () {
      expect(ReportStatus.values.map((s) => s.name).toList(), [
        'submitted',
        'underReview',
        'inProgress',
        'resolved',
      ]);
    });
  });

  group('ReportCategory', () {
    test('fromName finds every category by its stored name', () {
      for (final category in ReportCategory.values) {
        expect(ReportCategory.fromName(category.name), category);
      }
    });

    test('fromName falls back to other for unknown or null', () {
      expect(ReportCategory.fromName('nonsense'), ReportCategory.other);
      expect(ReportCategory.fromName(null), ReportCategory.other);
    });

    test('IT category has the label shown in the app', () {
      expect(ReportCategory.it.label, 'IT & Network');
    });

    test('stored names match the Firestore security rules', () {
      expect(ReportCategory.values.map((c) => c.name).toList(), [
        'maintenance',
        'safety',
        'cleanliness',
        'utilities',
        'it',
        'other',
      ]);
    });
  });
}
