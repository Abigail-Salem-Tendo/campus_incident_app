import 'package:flutter_test/flutter_test.dart';
import 'package:campus_incident_app/core/utils/validators.dart';

void main() {
  group('Validators.name', () {
    test('rejects empty and whitespace-only names', () {
      expect(Validators.name(null), 'Enter your full name');
      expect(Validators.name('   '), 'Enter your full name');
    });

    test('rejects a one-letter name', () {
      expect(Validators.name('A'), 'Name is too short');
    });

    test('accepts a normal name', () {
      expect(Validators.name('Abby Sal'), isNull);
    });
  });

  group('Validators.email', () {
    test('rejects empty input', () {
      expect(Validators.email(''), 'Enter your email');
      expect(Validators.email(null), 'Enter your email');
    });

    test('rejects badly formed addresses', () {
      expect(Validators.email('abby'), 'Enter a valid email address');
      expect(
        Validators.email('abby@alustudent'),
        'Enter a valid email address',
      );
    });

    test('rejects a valid address from a non-ALU domain', () {
      expect(Validators.email('abby@gmail.com'), isNotNull);
    });

    test('accepts the student and staff domains', () {
      expect(Validators.email('abby@alustudent.com'), isNull);
      expect(Validators.email('teacher@alueducation.com'), isNull);
    });

    test('ignores spaces around the address', () {
      expect(Validators.email('  abby@alustudent.com  '), isNull);
    });
  });

  group('Validators.password', () {
    test('rejects empty input', () {
      expect(Validators.password(''), 'Enter a password');
      expect(Validators.password(null), 'Enter a password');
    });

    test('rejects passwords shorter than 8 characters', () {
      expect(Validators.password('1234567'), 'Use at least 8 characters');
    });

    test('accepts 8 characters or more', () {
      expect(Validators.password('12345678'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('rejects empty confirmation', () {
      expect(
        Validators.confirmPassword('', 'secret123'),
        'Confirm your password',
      );
      expect(
        Validators.confirmPassword(null, 'secret123'),
        'Confirm your password',
      );
    });

    test('rejects a mismatch', () {
      expect(
        Validators.confirmPassword('secret124', 'secret123'),
        'Passwords do not match',
      );
    });

    test('accepts a match', () {
      expect(Validators.confirmPassword('secret123', 'secret123'), isNull);
    });
  });
}
