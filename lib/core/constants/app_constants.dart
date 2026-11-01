/// App-wide constants. Change the allowed email domains here only.
class AppConstants {
  AppConstants._();

  static const String studentEmailDomain = 'alustudent.com';
  static const String staffEmailDomain = 'alueducation.com';

  static const List<String> allowedEmailDomains = [
    studentEmailDomain,
    staffEmailDomain,
  ];

  /// True if the email ends with an allowed ALU domain.
  /// This is a UX check only; email verification and Firestore rules are what actually enforce access.
  static bool isAllowedEmail(String email) {
    final value = email.trim().toLowerCase();
    return allowedEmailDomains.any((domain) => value.endsWith('@$domain'));
  }
}
